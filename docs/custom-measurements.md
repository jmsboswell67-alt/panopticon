# Custom Measurements

> Panopticon collects four distinct kinds of self-and-behavioral data. They have different validation status, different interpretation rules, and different rules for what the LLM coaching layer may say about them. Conflating these tiers is the easiest way to make the system misleading or harmful.

This document defines the four tiers and the rules that govern each. Companion to [`screening-instruments.md`](screening-instruments.md), which covers Tier 1 in depth.

---

## The four tiers

| Tier | What it is | Validation status | LLM interpretation rules |
|---|---|---|---|
| **1. Validated screens** | PHQ-9, GAD-7, PCL-5, PID-5, etc. | Decades of clinical validation | Score against published cutoffs; never diagnose |
| **2. Custom context intake** | Background, life history, values, circumstances | None — descriptive context | Treat as framing context, not measurement |
| **3. Behavioral correlates** | Computed from your own event log | None needed — descriptive observations of own behavior | Compare to own baseline only; never to others |
| **4. Project-specific self-report** | Custom Likert scales for Panopticon-specific concepts | None — labeled non-validated | Trends meaningful for self only; never imply clinical interpretation |

The system stores each tier in a different schema namespace. The coaching layer applies different rules per tier. The UI labels each tier visibly so the user always knows what kind of data they're looking at.

---

## Tier 1 — Validated screens

See [`screening-instruments.md`](screening-instruments.md) for the full instrument list, licensing notes, crisis-path requirements, and the rules governing what the LLM may say about scores.

**Bottom line for this document:** these are the only measurements in the system that have published interpretation cutoffs. They are also the only measurements that can trigger the crisis path. They live in their own schema (`schema/screening.schema.json`, to be added Phase 2).

---

## Tier 2 — Custom context intake

The Phase 2 intake flow populates the user's context document (`schema/context.schema.json`). This is rich, free-text and structured information about who the user is and what they're working with:

- Background and life history.
- Significant events with rough timestamps.
- Relationship, parenting, caregiving status.
- Financial and life-circumstance stressors.
- Stated values and current goals.
- Patterns the user has already self-identified.
- Preferences for coaching tone and persona.

### Validation status

None. This is descriptive context. It does not pretend to be a measurement.

### Interpretation rules

The LLM uses Tier 2 data to **frame** observations from Tiers 1, 3, and 4:

- "Your PHQ-9 has been elevated for three months — your context document mentions a chronic illness flare that started around the same time. That's consistent with what you'd expect, not a personal failing."
- "You said you valued time with family; your screen-time data shows your working hours have crept later. That gap is what you flagged as a known pattern in your intake."

The LLM **does not**:

- Treat context fields as predictors. "You scored an ACE 6, therefore you are likely to..." is a violation regardless of the structure of the surrounding sentence.
- Use immutable traits (demographics, family-of-origin facts, height, etc.) as scoring inputs. See [`ETHICS.md`](../ETHICS.md) hard rail.
- Surface context fields in coaching output without the user's consent for that surfacing — some context is provided to inform tone but not to be quoted back.

### Why this isn't a measurement

A custom intake question like "How would you describe your childhood stability?" is useful context but is not a calibrated instrument. Two users answering "moderate" mean different things. The user answering "moderate" today and "moderate" in six months may also mean different things. We treat these as descriptive context, not data points to plot.

If a particular concept needs to be tracked over time as a measurement, it belongs in Tier 4 (a labeled project-specific self-report scale) — not in Tier 2 free-text.

---

## Tier 3 — Behavioral correlates

This is where Panopticon does something a clinician's office cannot. Behavioral correlates are quantitative observations computed from the user's own event log:

- Days in the last 30 with at least one 30-minute uninterrupted focus session.
- Median time-to-first-screen-on after the user's typical wake window.
- Notification volume from social apps in the period leading into a self-reported low mood.
- Variability in sleep window (proxied via screen-off duration in the late-night hours).
- App-switching rate during user-defined "deep work" hours.
- Ratio of stated-value-aligned time to total active screen time.

### Validation status

Not applicable in the clinical sense. These are **descriptive observations of the user's own past behavior**, computed from the event log. They are not pretending to be calibrated instruments.

### Interpretation rules

Tier 3 measurements are interpretable **only against the user's own baseline**. The system never compares them to:

- Other Panopticon users (there is no user community to compare to, by design).
- Demographic norms.
- Published "healthy" thresholds, even when such thresholds exist for adjacent constructs.

When the LLM cites a Tier 3 correlate, it does so descriptively:

- "Your median focus session length over the last 30 days is 18 minutes. Six months ago it was 7 minutes."
- "Your social-app notification volume on weekend mornings has dropped roughly 60% since you set that boundary in March."

Comparison framing is always against the user's own past, never against external norms.

### Why this is novel

Validated clinical instruments work from self-report, not from 24/7 behavioral telemetry. A psychologist administering PHQ-9 cannot also see your last 90 days of app-switching patterns. Panopticon can. The combination of a validated screen + a Tier 3 correlate that overlaps the same construct produces a richer picture than either alone — without claiming to be a clinical instrument itself.

### Where Tier 3 lives

Schema: derived from the existing event log (`schema/events.schema.json`). Computed by the aggregator described in [`ARCHITECTURE.md`](../ARCHITECTURE.md). Not stored separately as raw data — computed on demand from events, optionally cached in `daily_rollups`.

---

## Tier 4 — Project-specific self-report

Sometimes a useful measurement is one no validated instrument captures. Tier 4 exists for these cases. Examples:

- "How aligned did you feel with your stated value of [X] this week?" 1–7 Likert.
- "How accurate did this week's coaching insight feel?" 1–5.
- "How much did this week's pattern surprise you?" 1–5.
- "Days since you last did the thing you said matters most to you." Free integer.

These are honest self-report scales that serve specific Panopticon functions. They do not pretend to be validated instruments.

### Validation status

**Explicitly none.** Each Tier 4 item is labeled in the UI as "Panopticon self-report — not a clinical measurement."

### Interpretation rules

- Trends within an individual user are meaningful for that user.
- The LLM may cite Tier 4 trends descriptively, never diagnostically.
- Tier 4 does not feed crisis-path triggers (only Tier 1 does).
- Tier 4 items can be deleted, edited, or removed entirely. They are not part of any clinical record because they are not clinical measurements.

### Why we have this tier rather than just "more questions"

Without an explicit Tier 4 separation, every project-specific Likert question gets implicitly compared to validated instruments by users who don't know the difference. Labeling Tier 4 as "this is project-specific self-report" makes the distinction visible. The user knows that their "values alignment" 1–7 trend is genuinely useful for them but not something to print out and bring to a clinician.

---

## Why this separation matters

The four tiers exist for a reason: they have different rules for **what an honest interpretation looks like**.

A score of 14 on PHQ-9 has clinical meaning. A score of 14 on a homemade depression-flavored questionnaire does not. A 1–7 self-report on "how connected did you feel this week" is meaningful as a personal trend and meaningless as a number compared to anyone else's.

Conflating these tiers is the failure mode that turns a thoughtful self-knowledge tool into a misleading one. Specifically:

- A user reads their Tier 4 self-report trend and assumes it has clinical meaning → potential alarm or reassurance neither warranted.
- The LLM treats Tier 2 context as a Tier 1 score → diagnostic-flavored outputs that violate ETHICS.md.
- The LLM treats Tier 3 behavioral correlates as norm-comparable → comparison to "people like you" creeps in despite the explicit prohibition.
- A Tier 4 self-report is presented alongside a PHQ-9 score in the same chart with the same styling → the user mentally collapses the distinction.

The UI, schema, and prompt assembly are responsible for keeping these separate. Visual styling, vocabulary, and prompt context all distinguish the tiers.

---

## Anti-patterns (do not do these)

1. **Paraphrasing a validated instrument and calling it Tier 4.** "Our own version of PHQ-9" is worse than not using PHQ-9 at all. If you want a depression measurement, use the validated one.
2. **Combining Tier 1 and Tier 4 scores into a single composite.** "Your overall wellbeing score this week is 73%" is exactly the kind of fake-precision the project explicitly rejects. See ETHICS.md "no scoring."
3. **Letting the LLM rephrase a validated instrument's items.** Items are administered verbatim. The model never modifies them.
4. **Treating Tier 2 context as predictive.** Context is for framing, not for forecasting. ETHICS.md hard rail #1.
5. **Surfacing Tier 3 correlates with norm-comparison framing.** "You spent 40% more time on social apps than the average user" — there is no average user, by design. Always frame against the user's own baseline.
6. **Cross-tier visual collapse.** Don't put a PHQ-9 trace and a "values alignment" Likert trace on the same chart with the same axis label.

---

## What this means for the UI

Phase 2+ UI must:

- Visually distinguish the four tiers (different chart styling, different vocabulary).
- Label every measurement at its source ("PHQ-9: validated screen" / "Self-report: project-specific").
- Show licensing and validation provenance on demand for Tier 1 instruments.
- Never present a Tier 4 self-report next to a Tier 1 score in a way that implies equivalence.

---

## What this means for the schema

- **Tier 1**: `schema/screening.schema.json` (Phase 2). Includes raw item responses, computed scores, instrument version, administration timestamp.
- **Tier 2**: `schema/context.schema.json` (already defined). Versioned document.
- **Tier 3**: derived from `schema/events.schema.json` (already defined). Computed, not stored as raw data.
- **Tier 4**: `schema/self_report.schema.json` (Phase 2). Includes the question text used, the response, and a flag clearly marking the item as project-specific non-validated.

---

## Where the LLM picks up the rules

Each tier's interpretation rules are encoded in the prompt assembler (Phase 5). The system prompt loaded for any coaching call includes:

1. The trauma-informed base prompt ([`prompts/trauma_informed_base.md`](../prompts/trauma_informed_base.md)).
2. The screening-interpretation rules from [`screening-instruments.md`](screening-instruments.md).
3. The tier-aware framing rules from this document.

If the LLM produces output that violates these rules, that's a prompt-engineering bug, not a stylistic preference. File an issue.
