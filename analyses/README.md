# analyses/

Reusable analysis scripts and Jupyter notebooks. **Phase 3+ deliverable — not yet present.**

## Planned

- `focus_patterns.ipynb` — focus session length analysis, productive vs. fragmented periods.
- `communication_health.ipynb` — notification load, social-app focus, weekend vs. weekday divergence.
- `values_vs_time.ipynb` — interactive values audit notebook backing the Phase 5 prompt.

These notebooks read from the local Panopticon SQLite database and produce charts / tables for the user to inspect their own data outside the app UI. They are tools for the user, not pre-computed reports.

To be filled in when Phase 3+ data exists to query against.

## Conventions

- Notebooks read from a configurable SQLite path; never hardcode.
- Notebooks must not write outputs (cell outputs cleared) before commit, since outputs may contain personal data. A pre-commit hook will enforce this in Phase 3.
- Charts that screenshot well end up in `docs/insights-cookbook.md`; the notebook itself stays here as the runnable artifact.
