# Ethics

Panopticon is a sharp tool. A system that "knows everything about you" can drift, fast, into something that hurts you. This document records the hard rails that exist to prevent that drift.

These rails are enforced in **both** code and prompts. They are not aspirational — they are guardrails that, if relaxed, change what the project *is*.

## The hard rails

### 1. Context informs interpretation, never limits potential.

When you provide context (your background, diagnoses, life circumstances), the coaching layer uses it to *frame* current behavior — to understand why a pattern might exist, to be gentler when gentleness is warranted. It does **not** use it to predict that you will fail, to set ceilings on what you can achieve, or to weight your trajectory based on demographics.

A childhood marker is *not* an outcome predictor. A diagnosis is *not* a verdict.

### 2. All data is user-deletable, always.

Every event captured, every context entry, every insight generated — deletable by the user. Hard delete, not soft. If a feature can't honor this, the feature doesn't ship.

### 3. No data leaves the device without explicit per-source consent.

The default state is: everything stays local. Cloud sync, API calls to LLMs, exports to disk — each has its own toggle. Each toggle starts off. Each surfaces clearly what it does before you flip it.

### 4. The coaching tone is trauma-informed by default.

When context indicates trauma, chronic illness, neurodivergence, or acute life stress, the coaching layer adjusts framing accordingly. See [`prompts/trauma_informed_base.md`](prompts/trauma_informed_base.md).

This isn't optional politeness. It's recognizing that "honest feedback" delivered without regard for context is just a worse kind of feedback.

### 5. No surveillance of other people.

Panopticon observes the user's behavior. It does not capture content of conversations from other parties, contacts of others, or anything that would constitute surveillance of non-consenting third parties. Notification *content* is captured for the user's own behavioral analysis only — never to dossier the people sending those notifications.

## What this means for design choices

### No scoring system

There is no "you're a 7/10 today" number. There is no leaderboard. There is no comparison to demographic norms ("most men your age...").

The reason: scoring systems compress richly contextual data into a number that loses the context. The result is gamification of self-worth — the opposite of what self-knowledge is for.

You may see comparisons to **your own past** ("you were spending 40min/day on this app last quarter, now you're at 90min"). You will not see comparisons to other people.

### No predictions of life outcomes

The coaching layer will not say "based on these patterns, you are likely to fail at X." Trajectory views — "here's how this metric has changed over the last six months" — are fine. Forecasts of personal outcomes are not.

The reason: outcome predictions encode whatever biases the training data carried. For a project that takes people's life circumstances as input, that's a recipe for harm.

### No use of immutable traits as scoring inputs

Height, appearance, demographics: these may be stored as context if you choose to provide them, but the coaching layer is prompted not to weight them as success/failure predictors.

Example: "single 35-year-old male" is data the system may know, but the system is not allowed to derive "and therefore will likely…" from it. That conclusion does not improve self-knowledge — it imports the biases of whatever corpus trained the model.

### Trauma-informed defaults, escalated by context

When you provide context indicating chronic illness, ADHD, depression, recent grief, caregiving burden, etc., the coaching layer:

- Avoids framing reduced output as moral failure.
- Acknowledges constraints the system can see.
- Defaults to questions ("what would help?") over directives ("you should...").
- Respects the persona you've selected — some personas (Sam, Maximus) are direct; some (Nori) are gentle. The trauma-informed base prompt adjusts each persona's expression of its own voice, but does not erase it.

## What this means if you fork this

If you fork Panopticon and remove these rails:

- The system still runs.
- It will produce different outputs.
- It will not be Panopticon anymore — it will be your variant. That's fine; it's MIT-licensed. But it's worth understanding that these rails are a deliberate design choice, not a stylistic preference.

If you keep these rails and find new ones that should join them, open an issue. Better rails are welcome.

## What this is NOT

This document is not a clinical promise. Panopticon is not a therapist, not a substitute for medical care, and not safe to rely on if you're in crisis. If you need help:

- **US:** 988 (Suicide & Crisis Lifeline)
- **UK:** 116 123 (Samaritans)
- **International:** [findahelpline.com](https://findahelpline.com)
