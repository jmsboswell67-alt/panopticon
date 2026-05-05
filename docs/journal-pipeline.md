# Journal Pipeline

How free-form prose journal entries become structured, queryable data — without losing the original prose.

This document describes the analytical pipeline that runs on every `manual.journal_entry` event. It is the bridge between the user's raw narrative and everything downstream: pattern detection, anomaly flagging, the daily coach briefing, and longitudinal analysis.

## Design principle

The original prose is **never modified**. Pipeline outputs are *additive* — extracted entities, segmented sections, identified self-hypotheses, sentiment scores all live alongside the verbatim text in the same `payload_json`. The user can always re-read what they actually wrote, regardless of how the pipeline interpreted it.

If the pipeline gets better later, re-processing old entries is a single batch job over the existing prose. No data is lost to interpretation.

## Inputs

A `manual.journal_entry` event with at minimum:

```json
{
  "text": "Today I got up around four, let my dog out, and played video games...",
  "input_method": "typed",
  "completion_seconds": 720
}
```

## Pipeline stages

### Stage 1: Section segmentation

Walk the prose and tag spans with `section_type`. The same sentence can belong to multiple sections (a sentence about eating fast food after a run touches both `food` and `exercise`).

Section types currently recognized:

| Section type | What triggers it |
|---|---|
| `narrative` | Default. Anything that doesn't match a more specific section. |
| `food` | Mentions of meals, snacks, drinks, restaurants, cooking, hunger, fasting. |
| `sleep` | Bedtime, wake time, dreams, naps, sleep quality language. |
| `social` | Names of people, group activities, conversations, isolation language. |
| `work` | Job tasks, meetings, deadlines, school assignments, study sessions. |
| `exercise` | Workouts, runs, walks, sports, physical activity. |
| `media` | TV, movies, books, podcasts, social media consumption, news. |
| `spending` | Purchases, money mentions, financial decisions, regret/satisfaction about spending. |
| `animal_interaction` | Pets, wildlife, encounters with animals. |
| `cognitive_engagement` | Learning, problem-solving, classes, intellectual conversations, research. |
| `intimacy` | Sex, romantic interactions, physical closeness with a partner. |
| `substance_use` | Alcohol, cannabis, caffeine quantities, other substances. |
| `concern` | Worries, ruminations, anxieties, recurring topics. |
| `win` | Accomplishments, things that went well, moments of agency. |
| `self_hypothesis` | See Stage 3. |
| `other` | Caught explicitly so the pipeline can flag low-confidence segments for review. |

Each tagged span stores `text_span: {start, end}` indices into the original prose.

### Stage 2: Entity and event extraction

For each tagged section, extract structured data:

**Entities** — nouns and noun phrases that resolve to known categories:

- People: free-form labels (`mom`, `Cooper`, `Sarah from work`). The user's own dictionary maps these to consistent identifiers over time.
- Foods: items, with category tags (`fast_food`, `vegetable`, `sugar_heavy`, `protein`, etc.).
- Apps / sites / media titles.
- Places (cities, venues, room of the house).
- Substances (caffeine_mg, alcohol_servings, cannabis, prescription names).
- Activities (`5k_run`, `weightlifting_session`, `coding`).

**Events** — extracted with timestamps where the prose gives them, otherwise relative to the day boundary or other anchored events:

```json
{
  "event_type": "ate",
  "items": [{"name": "Whopper", "category": "fast_food"}, {"name": "soda", "category": "sugar_heavy"}],
  "approximate_time": "after_5k_run",
  "self_judgment_marker": "splurged"
}
```

Self-judgment markers (`splurged`, `fucked up`, `crushed it`, `gave in`, etc.) are flagged separately because the user's own affect about a behavior is itself signal.

### Stage 3: Self-hypothesis detection

This is the project's distinguishing analytical move. Look for prose patterns where the user generates a claim about themselves:

- "I always X when Y"
- "I never X"
- "Whenever X, I usually Y"
- "I'm the kind of person who..."
- "I keep doing X"
- "This is a pattern — X"
- "I tend to X"
- "It seems like every time X..."

Each detected hypothesis gets stored in `self_hypotheses[]` with `test_status: "untested"`. A separate test pass (run as part of the daily briefing or on demand) queries the event log to validate or refute it, then writes a `coach.hypothesis_test` event linking back.

**Worked example.** From a sample entry:

> "I splurged and ate Burger King and a bunch of sugary crap afterwards (see this is a pattern that I am catching myself, whenever I go on a run I usually fuck it up by eating like shit after)"

Extracted:

```json
{
  "self_hypotheses": [
    {
      "claim": "whenever I go on a run I usually fuck it up by eating like shit after",
      "scope_window": "ongoing pattern",
      "test_status": "untested",
      "supporting_evidence_query": "Among events where source='manual' and section='exercise' and activity='run' in the last 90 days, what fraction have a section='food' event with category in ('fast_food', 'sugar_heavy', 'high_calorie_low_nutrient') within 4 hours after?"
    }
  ]
}
```

The hypothesis tester runs that query, finds (e.g.) 11 of 14 post-run windows match, and emits a `coach.hypothesis_test` with `test_status: "supported"`, `n_observations: 14`, `n_supporting: 11`, ready for the next briefing to surface back.

### Stage 4: Sentiment and affect tagging

For each section (and the entry as a whole), compute:

- **Valence** (-1 to 1) — how positive or negative the prose feels.
- **Arousal** (0 to 1) — how activated/intense the prose feels.
- **Self-directed affect** — distinct from valence about the day, this measures how the user is talking *about themselves*. ("I'm such an idiot" reads negative-self-directed even if surrounded by neutral prose.)

These feed scale-correlation analysis: does prose-derived self-affect correlate with the next day's `self_compassion` slider? Diverging signals are interesting.

### Stage 5: Linguistic complexity metrics

Per entry, compute:

- Type-token ratio (vocabulary diversity)
- Mean sentence length
- Flesch-Kincaid reading level
- Frequency of low-register vs high-register words
- Subordinate clause depth (parser-dependent)

These feed the verbal/linguistic cognitive subscale tracking. Critically, they are **not** rolled into a single "intelligence score" — each is named and trended separately (see PROJECT_PRINCIPLES.md > "No headline scores").

### Stage 6: Topic-of-concern tracking

Search the entry for topics the user has flagged before as recurring concerns (built up over time from prior `concern` sections). Note when previously-flagged topics resurface, when new ones emerge, and when previously-frequent topics drop off.

The output is a topic-frequency map maintained across all journal entries, queryable as "what have I been spinning on this month."

## Outputs

After pipeline processing, the `manual.journal_entry` payload looks like:

```json
{
  "text": "...verbatim original prose...",
  "input_method": "typed",
  "completion_seconds": 720,
  "sections": [
    {"section_type": "exercise", "text_span": {"start": 142, "end": 178}, "extracted_events": [...]},
    {"section_type": "food", "text_span": {"start": 180, "end": 245}, "extracted_entities": {"foods": [...]}, "sentiment": {"valence": -0.4, "arousal": 0.3}},
    {"section_type": "self_hypothesis", "text_span": {"start": 247, "end": 340}}
  ],
  "self_hypotheses": [{"claim": "...", "test_status": "untested", "supporting_evidence_query": "..."}],
  "linguistic_metrics": {"ttr": 0.62, "mean_sentence_length": 14.2, "fk_grade": 8.4},
  "self_affect_valence": -0.2
}
```

Plus side-effect events written to the log:

- `coach.hypothesis_test` for each tested self-hypothesis
- `coach.flag` for any urgent concerns surfaced (suicidality language, substance-use spikes, withdrawal patterns)

## Where this runs

Phase 1 (current): pipeline runs locally on the user's device. Lightweight regex/rule-based segmentation is feasible without an LLM. Self-hypothesis pattern matching is regex on a curated list of templates.

Phase 5 (AI coaching layer): a stronger pipeline using an LLM (cloud or local Ollama, per user toggle) replaces the rule-based pass. The LLM's job is constrained — it produces structured output conforming to the section/entity/hypothesis schemas above, never free prose at this stage. Free prose generation is reserved for the daily briefing, not the journal pipeline.

## What this pipeline never does

- **Modify the original prose.** Verbatim text is sacred.
- **Send prose off-device without explicit per-call consent.** Cloud LLM calls show what's about to be sent and what's omitted before sending.
- **Surface anything to the UI as a popup.** Pipeline outputs feed the daily briefing and queryable history. They don't interrupt.
- **Score the entry.** No "writing quality 7/10," no "honesty meter." Sections, entities, hypotheses, sentiment — all named for what they are.

## Reprocessing

When the pipeline rules or model improves, all historical entries can be re-processed by:

1. Reading every `manual.journal_entry.text` value.
2. Running the new pipeline.
3. Replacing the structured fields (sections, hypotheses, metrics) while preserving the prose.
4. Bumping `schema_version` if the output shape changed.

Original prose is never touched. New analyses become available retroactively.
