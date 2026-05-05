# Retention Policy

> How long each kind of data lives, why, and how it's pruned. Phase 4+ implementation; the policy is set here so the schemas, aggregator, and UI all align from the start.

This document complements [`PRIVACY.md`](../PRIVACY.md) (which establishes the user's right to delete anything at any time) and [`data-flow.md`](data-flow.md) (which describes where each kind of data physically lives).

---

## Design intent

Different kinds of data have different value-per-byte over time. Raw events (every focus change, every notification) are high volume and lose nearly all per-item value the moment they're rolled up into daily aggregates. Aggregates, screening scores, and insights are tiny and gain value over time — the trajectory view across years is the entire point of the project.

The retention policy follows directly from that asymmetry: **prune the high-volume / low-information-density data aggressively; preserve the low-volume / high-meaning data indefinitely.**

This is also how the project keeps storage requirements manageable while still supporting "show me my last five years" queries on the things that matter.

---

## The retention tiers

| Data | Retention | Storage location | Pruning behavior |
|---|---|---|---|
| **Raw phone events** (focus changes, screen state, notifications) | 60 days rolling | Phone local SQLite + home server `events.db` | Auto-pruned nightly on both sides |
| **Raw DNS query logs** | 30 days rolling | Home server `dns_logs/` | Daily-rotated, oldest dropped |
| **Raw network flow data** (NetFlow/sFlow, if enabled) | 30 days rolling | Home server | Daily-rotated, oldest dropped |
| **Raw active-window events** (desktop) | 60 days rolling | Home server `events.db` | Auto-pruned nightly |
| **Daily rollups** (per-app foreground time, notification counts, focus session aggregates) | **Forever** | Home server `rollups.db` | Never pruned |
| **Weekly / monthly aggregates** | **Forever** | Home server `rollups.db` | Never pruned |
| **DNS query daily summaries** (top domains, request counts, hourly histograms) | **Forever** | Home server `rollups.db` | Never pruned (computed before raw logs are dropped) |
| **Insights / coaching outputs** | **Forever**, user-controlled | Home server `insights.db` | Never auto-pruned. User may delete individual or bulk. |
| **Validated screening scores + raw item responses** | **Forever**, user-controlled | Home server `screening.db` | Never auto-pruned. User may delete individual administrations. |
| **Self-report scales** (Tier 4) | **Forever**, user-controlled | Home server `self_report.db` | Never auto-pruned. User may delete. |
| **Context document** | **Forever**, with version history | Home server `context.db` | All historical versions kept; user may revert or wipe history |
| **Embedding indices** (over journal/insights) | Rebuilt on demand | Home server `embeddings/` | Rebuilt nightly; corrupted indices rebuild from source |
| **Journal entries** (if user keeps one) | **Forever**, user-controlled | Phone or local-only on phone | Phone-local; never auto-pruned |
| **Crisis-trigger logs** | 90 days metadata only | Home server `events.db` (event_type=`crisis_trigger`) | Logs that a trigger fired and which one; the response itself is not stored if user requested no-storage on the crisis screen |

### Why these specific numbers

- **60 days for raw phone events.** Long enough to recompute aggregates if a bug is found in the rollup logic. Short enough that the raw store stays in single-digit GB. Two months also covers most "what did I do last month" queries that the user might want to drill back into raw form for.
- **30 days for DNS / network flows.** Volume is much higher than phone events (50K-200K queries/day in a typical home). Two months would push storage uncomfortably; 30 days is plenty for the "what was happening on my network last week" investigations and for the daily summary jobs to compute their inputs reliably.
- **Forever for aggregates, insights, screening.** These are tiny in absolute terms (megabytes per year) and their value increases with time. Trajectory views are the entire reason this project exists.
- **Forever for context, with version history.** The context document changes over time — life changes, goals shift, diagnoses get added. The history of those changes is itself information the coaching layer may use. The user can wipe the history if they want; default is preservation.

---

## Auto-prune logic

### When pruning runs

The aggregator runs once nightly at a configurable time (default: local 3:00 AM). The pruning steps are part of that aggregator pass and run **after** the rollup computation. This ordering is critical: rollups must be computed from raw events before those raw events get dropped.

### Order of operations (each nightly run)

1. **Sync ingest**: pull any pending sync deltas from the phone (this is opportunistic; nightly is the catch-up window).
2. **Rollup computation**: for any day not yet rolled up, compute daily aggregates from raw events. Idempotent.
3. **Insight generation**: optional, only if the coaching schedule says today is an insight day. Runs against the just-computed rollups.
4. **DNS daily summarization**: compute the daily summary from yesterday's DNS logs.
5. **Pruning**: drop raw events older than the configured retention window. Drop DNS logs older than the configured retention window.
6. **Backup**: snapshot the relevant DBs to the `backups/` directory.

### What pruning never touches

- Aggregates and rollups (they're the point).
- Insights, screening, self-report, context — anything in the "forever" tier.
- Anything the user has explicitly flagged "do not delete" (rare; reserved for, e.g., an acute event the user wants the raw events of preserved indefinitely).

### Configurable, but with guardrails

Users can change retention windows in settings, with two guardrails:

- **Hard floor**: 14 days for raw events. Shorter than this and the rollup recomputation safety net (a bug in rollups that's caught >2 weeks later) becomes useless.
- **Hard floor**: 7 days for DNS logs. Shorter than this and even basic week-over-week comparisons of network behavior break.

The user can extend retention beyond defaults arbitrarily — limited only by available storage. The aggregator surfaces a warning when the projected raw store size will exceed 80% of the configured external SSD capacity.

---

## User-controlled retention

The auto-prune above runs by default. The user has explicit control via the Privacy screen:

### Bulk operations

- **"Delete everything"** — drops all DBs, hard delete, including aggregates, insights, screening, and context. Phase 1 implements this.
- **"Delete everything older than N days"** — drops *all* data (not just raw) older than a chosen threshold. For users who want a more aggressive footprint than the default tiered policy. Phase 3+.

### Per-data-type controls

- **"Delete all raw events"** — keeps aggregates, drops the raw events store. Useful if the user wants to go back to a smaller storage footprint without losing trajectory.
- **"Delete all DNS logs"** — drops network logs immediately, keeps daily summaries.
- **"Delete a specific insight"** — per-insight controls in the insights view.
- **"Delete a specific screening administration"** — per-administration controls in the screening history view.
- **"Wipe context history"** — keeps the latest context but drops the change log.

### Per-day operations (Phase 3+)

- **"Delete this day"** — drops all events from a given calendar day, recomputes aggregates without it. Useful if the user had a day they don't want represented at all (a triggering event, a boundary day they're not ready to look at, etc.).

All deletions are **hard deletes**. There is no soft-delete tombstone. There is no "undo." The Privacy screen warns the user explicitly.

---

## Deletion guarantees

Per [`ETHICS.md`](../ETHICS.md) hard rail #2: all data is user-deletable, always. This document refines that to the following operational guarantees:

1. **Hard delete on the home server.** When the user requests deletion, the relevant rows are removed from SQLite and the SQLite VACUUM is run to release the space. No tombstones.
2. **Hard delete on the phone.** Same, on the phone-local SQLite.
3. **Backup deletion.** Server-side nightly backups also need to honor deletion. The deletion request marks all backups containing the deleted records for re-snapshot. Within 24h of the next aggregator run, the deleted records are gone from current and historical backups alike.
4. **Sync target deletion.** If sync is configured, the deletion request propagates to the configured sync target (REST endpoint, Firebase, etc.). The user is warned before they delete that the deletion will propagate.
5. **No third-party deletion.** Anthropic API (and any other configured LLM provider) does not store user data persistently — but the user should review the provider's data retention terms separately. Panopticon does not control Anthropic's logs.

---

## Schema requirements

To support this policy, the schema needs:

### `events` table additions

- `created_utc` — already present (timestamp_utc).
- (Optional) `do_not_prune` — boolean flag for events the user has flagged for indefinite preservation. Defaults to false.

### `rollups` table

- `period_start_utc`, `period_end_utc`, `period_kind` (`daily`, `weekly`, `monthly`).
- `metric_key`, `metric_value_json`.
- No retention column — this table is forever.

### `dns_logs` table

- `query_time_utc`, `client_ip`, `client_mac`, `query_name`, `query_type`, `response_code`, `latency_ms`.
- Daily-partitioned table or daily-rotated file format. Old partitions get dropped wholesale rather than row-by-row deleted.

### `dns_summaries` table

- `date_utc`, `top_domains_json`, `query_count_total`, `hourly_histogram_json`.
- Forever.

### Retention metadata

- A `retention_config` row on the server records the active policy. If the user changes settings, the change is timestamped — so the audit trail shows when retention was tightened or loosened.

Schemas to be added in Phase 2 (alongside the screening schema) and Phase 4 (alongside the desktop collector and DNS pipeline).

---

## Anti-patterns

Things that look like good ideas and aren't:

1. **Soft-delete with tombstones.** "What if the user wants to undo?" — they don't, and tombstones leave deleted data findable on disk. The Privacy screen warns before deletion. Once they confirm, it's gone.
2. **Compressing raw events for longer retention.** Compression buys 5–10x. The aggregates already buy 10,000x and lose nothing the user actually queries. Compress aggregates if you need to; don't keep raw events longer just because they compress well.
3. **Keeping DNS logs longer than 30 days.** The signal density is too low. Daily summaries capture every meaningful pattern. Keeping months of raw queries is hoarding, not analysis.
4. **Auto-prune that runs more than nightly.** Premature optimization. The aggregator is the natural prune cadence — once a day, after the data has had its last chance to be looked at in raw form.
5. **Retention thresholds shorter than the rollup safety net.** If a bug in rollups is found, you need raw data old enough to recompute. 14 days is the hard floor for that reason.

---

## Related

- [`PRIVACY.md`](../PRIVACY.md) — user's right to delete anything
- [`ETHICS.md`](../ETHICS.md) — hard rails on data
- [`data-flow.md`](data-flow.md) — where data physically lives
- [`screening-instruments.md`](screening-instruments.md) — Tier 1 retention is "forever, user-controlled"
- [`custom-measurements.md`](custom-measurements.md) — Tier 4 retention is "forever, user-controlled"
