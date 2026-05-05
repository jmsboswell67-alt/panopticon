# Insights Cookbook

> Phase 3+ deliverable. Recipes for finding patterns in your own Panopticon data.

This is a living document. Each recipe is self-contained: a question, the SQL or notebook code that answers it, and notes on what to watch out for in the interpretation.

---

## How to use this cookbook

The recipes here run against your local SQLite database. You can either:

1. Open the database with the SQLite CLI: `sqlite3 path/to/panopticon.db`
2. Use the Jupyter notebooks in [`analyses/`](../analyses/), which import the database into pandas.
3. Build the recipe into the app as a saved query (Phase 5+).

---

## Recipes

> These are placeholders for now. Each will be filled in as Phase 3 lands and we have real data shapes to query against.

### Focus session lengths over time

*Question:* How has my median uninterrupted focus session length changed week-over-week?

*To be written when `app_sessions` table is populated.*

### Notification flood detection

*Question:* When in the day am I getting hit hardest with notifications? Has that changed?

*To be written.*

### Stated value vs. enacted time

*Question:* I said I value "deep reading." How much time did I actually spend on Kindle / Pocket / etc. this month?

*To be written. This is the values audit, surfaced as raw data rather than as a coaching insight.*

### Sleep proxy via screen state

*Question:* Without Health Connect, can I approximate sleep from "screen off" events?

*To be written. Be careful with interpretation — long screen-off periods include lots of non-sleep activities.*

### App switching as a stress signal

*Question:* Does my app-switching rate spike before or during stressful periods (where "stressful" is correlated with notification volume from specific apps)?

*To be written. This is a multi-source recipe — combines accessibility + notification data.*

---

## Contributing recipes

If you fork Panopticon and find a useful query, PR it here. Each recipe should include:

1. The **question** in plain English.
2. The **query** (SQL or notebook code).
3. **Interpretation notes** — what the answer does and doesn't tell you.
4. **Caveats** — what could mislead you about the result.

Don't include data, sample outputs, or screenshots from your own database. The cookbook is a recipe collection, not a case study.
