# Home Server Stack

> The language, framework, auth model, and process layout for the home server's services. Phase 4 implementation; the decision is recorded here so schema and code can be designed against it from the start.

This document complements [`data-flow.md`](data-flow.md) (which describes what flows between machines) by specifying *what runs on the server*.

---

## Decision

**Python 3.11+ with FastAPI** for the sync REST endpoint and the aggregator. Single language across the entire server stack. Single virtualenv. Single repository subfolder.

Auth: long-random Bearer tokens. Wire format: JSON over HTTPS with gzip compression. Process management: launchd on macOS (or systemd on Linux for forkers). Storage: SQLite via stdlib `sqlite3` plus SQLAlchemy where queries get complex.

This document explains why, what the server tree looks like, and how the pieces fit together at runtime.

---

## Why Python + FastAPI

### Single-language unification

The aggregator is going to be Python regardless of what we choose for the sync endpoint — pandas, scikit-learn, sentence-transformers, the data-science ecosystem is Python-dominant. Making the sync endpoint also Python means:

- One language for forkers to learn.
- One virtualenv to manage.
- Code can be shared between the sync endpoint and the aggregator (database models, validation logic, schema definitions).
- One set of tooling, one set of testing patterns.

A polyglot codebase (Go-for-sync, Python-for-aggregator) doubles cognitive load for forkers without buying performance the workload actually needs.

### FastAPI specifically

- **Type-checked at the boundary** via Pydantic models. Misshapen requests get rejected before they hit the handler.
- **Automatic OpenAPI docs** at `/docs` — useful for debugging the phone client and for forkers who want to write their own clients.
- **Async support** matters for the aggregator triggering long-running jobs without blocking the sync endpoint.
- **Memory footprint**: ~100–150 MB resident for a basic FastAPI app under uvicorn. Fits comfortably within the Mac mini's 4–5 GB headroom alongside Xcode.
- **Mature**: stable for years, well-documented, large ecosystem.

### Why not Go

Go would be the obvious alternative. Smaller memory footprint (~20–30 MB), single static binary, excellent for daemons. But:

- Splitting the codebase between Go-for-API and Python-for-aggregator is the cognitive-load problem above.
- Go's SQLite story is fine but not as mature as Python's for the analysis side.
- The performance Go buys (microseconds vs. milliseconds) is invisible at this workload — we're talking ~1k requests per hour at most.

If a Phase 6+ scaling pressure ever emerges, the FastAPI sync endpoint can be replaced with a Go service at the API boundary without rewriting the aggregator. The interface is JSON over HTTP; the internals are swappable.

### Why not Rust

Same reasoning as Go, plus longer compile times (a real cost on an 8 GB Mac mini), plus a steeper learning curve for forkers. The right tool when the wrong tool is "any GC language"; that condition is not met here.

### Why not Node

Node is fine, but bringing TypeScript, npm, and the Node runtime into a project that's already going to have Python and Dart adds a third toolchain to maintain. Forkers don't benefit; the project gets harder to operate.

---

## Server folder structure

```
server/
├── pyproject.toml
├── README.md
├── .env.example                    # template for server-side env vars
├── alembic/                        # SQLAlchemy migrations
│   └── versions/
├── panopticon_server/
│   ├── __init__.py
│   ├── main.py                     # uvicorn entrypoint
│   ├── config.py                   # env-loaded config object
│   ├── api/
│   │   ├── __init__.py
│   │   ├── auth.py                 # Bearer token middleware
│   │   ├── events.py               # POST /sync/events
│   │   ├── context.py              # POST /sync/context, GET /sync/context
│   │   ├── screening.py            # POST /sync/screening
│   │   ├── insights.py             # GET /insights
│   │   ├── aggregates.py           # GET /aggregates/* for phone-pull
│   │   └── health.py               # GET /healthz, /readyz
│   ├── db/
│   │   ├── __init__.py
│   │   ├── models.py               # SQLAlchemy ORM
│   │   └── session.py
│   ├── aggregator/
│   │   ├── __init__.py
│   │   ├── rollups.py              # daily/weekly/monthly rollups
│   │   ├── prune.py                # retention pruning
│   │   ├── dns_summary.py          # DNS daily summarization
│   │   └── runner.py               # CLI entrypoint
│   ├── dns/
│   │   ├── __init__.py
│   │   ├── ingest.py               # AdGuard Home query log → events.db
│   │   └── allowlist.py            # device MAC filter
│   ├── coaching/
│   │   ├── __init__.py
│   │   ├── prompt_assembler.py
│   │   ├── ollama_client.py
│   │   └── anthropic_client.py
│   ├── embeddings/
│   │   ├── __init__.py
│   │   └── index.py                # sentence-transformers indices
│   └── shared/
│       ├── schemas.py              # Pydantic models matching schema/*.json
│       └── retention.py            # retention policy constants
└── tests/
    ├── api/
    ├── aggregator/
    └── conftest.py
```

The structure mirrors the Phase 4+ data flow: `api/` for the sync surface, `aggregator/` for the nightly job, `dns/` for the network ingestion, `coaching/` for LLM dispatch, `embeddings/` for semantic search.

---

## Auth model

Single-user, single-server design. Auth is intentionally simple.

### Token format

A long random string (64 bytes, base64-encoded) generated once during server setup. Stored in `server/.env` as `PANOPTICON_SYNC_TOKEN=...`. Never committed.

### How it gets onto the phone

The setup wizard on the phone has a "Pair with home server" step. The user either:

- **Types the token manually** (fine for one-time setup).
- **Scans a QR code** the server emits during initial setup (Phase 5+).

The phone stores the token in Android's `EncryptedSharedPreferences`. iOS uses Keychain.

### Wire-level

Every request from the phone to the server includes:

```
Authorization: Bearer <token>
```

The server validates with constant-time comparison. Any auth failure logs a structured event (timestamp, client IP, route, failure reason) for review. Brute-force protection: rate-limit auth failures at 10/minute per IP.

### Rotation

Phase 4 ships without rotation tooling. If the token leaks, the user generates a new one on the server, updates the phone's setup-wizard token field, and restarts the server. The old token is invalidated immediately on server restart.

Phase 6+ adds rotation: server accepts both old and new for a 24h window during transition.

### What we explicitly don't do

- **No JWT.** Single-user system; the complexity buys nothing.
- **No mTLS.** Same reasoning; LAN-only deployment, the threat model doesn't require it.
- **No OAuth.** Self-hosted single-user; an OAuth provider is overkill.
- **No username/password.** Token-only is simpler and equally secure for this use case.

---

## Wire format

### Default

JSON, gzip-compressed when the body is >1 KB. Both phone and server set `Accept-Encoding: gzip` and `Content-Encoding: gzip` as appropriate.

JSON is debuggable, well-supported by every language a forker might use, and the data volumes are well within range for it. A typical sync batch (500 events) compresses to ~30–50 KB.

### Why not Protobuf / CBOR / MessagePack

Considered. The wire format is invisible to users; the cost is in dev tooling (no `curl | jq` for debugging, harder to inspect on the wire). For a project that wants to be approachable for forkers, the readability win of JSON outweighs the marginal size win of a binary format.

If a future scaling pressure justifies it, the server's API layer can negotiate per-content-type — Pydantic happily emits any of these.

### Idempotency

Each event has a client-assigned UUID. Server's events table has a unique index on that UUID. Replays are no-ops; the server returns the same 200 ACK on replay as on first receipt. This means the phone can retry safely without bookkeeping the exact ACK boundary.

---

## Process model

### macOS (Mac mini home server)

Two `launchd` plists:

1. **`com.velovault.panopticon.api.plist`** — runs uvicorn with the FastAPI app. Auto-restart on crash. Logs to `/var/log/panopticon/api.log`.
2. **`com.velovault.panopticon.aggregator.plist`** — runs the aggregator nightly at the configured hour. Triggered by `StartCalendarInterval`.

A third optional plist:

3. **`com.velovault.panopticon.dns_ingest.plist`** — only enabled if AdGuard Home is configured and a `personal/devices.json` allowlist exists. Tails the AdGuard query log and ingests into `events.db`.

### Linux (Pi 5 / mini PC forkers)

Equivalent systemd unit files. The AdGuard Home log path differs by package manager.

### Why not Docker

Considered. Reasons against:

- Docker on Apple Silicon Mac mini works but adds complexity and memory overhead (~500 MB for Docker Desktop).
- This is a single-user server; the isolation Docker provides isn't needed.
- The simplicity gain of "service starts at boot via launchd, logs go to text files, Python's familiar" matters more than the operational uniformity Docker would buy.

For forkers who *want* Docker, a `docker-compose.yml` may land in Phase 6 as an alternative deployment path. It's not the default.

---

## Database choice

**SQLite for everything in Phase 4**, with Litestream for replication-as-backup if needed in Phase 6+.

### Why SQLite

- Single file per database; trivial to back up by copying.
- Zero operational overhead — no separate database service to keep running.
- Performance is a non-issue at this workload (single user, sub-1k writes/minute peak).
- The `events.db` retention pruning is simple `DELETE WHERE timestamp_utc < cutoff` followed by `VACUUM`.

### Schema management

**Alembic** for migrations. Every schema change is a migration; no ad-hoc `ALTER TABLE` in production.

### Multiple databases vs. one

The `data-flow.md` storage layout shows separate `events.db`, `rollups.db`, `insights.db`, `screening.db`, `context.db`, `self_report.db`. This separation matters because:

- Different retention policies (events.db prunes; the rest don't).
- Different access patterns (the API mostly writes to events.db; reads are cross-database via SQLAlchemy ATTACH).
- A corrupted file affects only one slice of the system.

The cost is some cross-database query complexity. Worth it.

---

## Local development workflow

For working on the server code on your laptop or desktop, not the always-on home server:

```bash
cd panopticon/server
uv venv                                # or python -m venv .venv
source .venv/bin/activate              # Windows: .venv\Scripts\activate
uv pip install -e ".[dev]"             # editable install
cp .env.example .env                   # fill in dev token

# Run the API in dev mode
uvicorn panopticon_server.main:app --reload --port 8080

# Run the aggregator manually
python -m panopticon_server.aggregator.runner --once

# Run tests
pytest
```

The dev `.env` uses a separate token from production. Dev databases live in `server/dev_data/` (gitignored).

---

## Health, observability, debugging

### Health endpoints

- `GET /healthz` — returns 200 if the process is up. No DB check.
- `GET /readyz` — returns 200 if the DB is reachable. Used by the phone's "is the server alive?" check.

### Logging

Structured JSON logs to stdout (captured by launchd to `/var/log/panopticon/`). Fields:

- `timestamp_utc`, `level`, `route`, `latency_ms`, `client_ip`, `request_id`, `auth_status`.
- No PII in logs. Event payloads are not logged.

### Metrics (Phase 6+)

Optional Prometheus exporter. Off by default. The deployment is single-user; the user doesn't need monitoring infrastructure unless they want it.

---

## What this stack explicitly does NOT do

- **No multi-tenancy.** Single user, single token. Don't fork this and try to host it for others — the security model isn't designed for it.
- **No outbound calls except to configured LLM providers.** No analytics, no error reporting, no auto-update. The server is silent on the network except when the user explicitly configures it to talk somewhere.
- **No web UI on the server.** The Flutter app is the UI. The server only exposes the JSON API. (FastAPI's `/docs` is dev-only; disable in production.)

---

## Related

- [`data-flow.md`](data-flow.md) — what flows between machines
- [`retention-policy.md`](retention-policy.md) — what the aggregator prunes
- [`self-hosting.md`](self-hosting.md) — alternative sync targets if a forker wants Firebase instead
- [`devices.example.json`](devices.example.json) — example device allowlist
