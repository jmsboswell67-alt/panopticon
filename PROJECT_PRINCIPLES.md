# Project Principles

This document supersedes the previous `ETHICS.md`. It states what Panopticon *is*, what it *aims for*, and what constraints are inviolable. Everything else in this repo — schema, collectors, prompts, briefings — flows from these principles.

## What this is

Panopticon is a research and development project. The author is the sole test subject. There is no commercial application planned, no product roadmap to a paying market, no users beyond forkers who choose to run it on themselves. The job is done when the job is done.

The aim is unapologetic:

> **Build the most invasive self-instrumentation system possible without exposing personal data — the author's, once it leaves their devices, or any third party's, ever — and produce a more comprehensive behavioral and psychological portrait of one person than any clinician could assemble through interview alone.**

That ambition is the whole point. If a feature would make the portrait sharper and the data stays under the user's control, it belongs in scope. If it would compromise privacy — the user's by sending data somewhere they don't trust, or anyone else's at any point — it doesn't.

## What this is NOT

- Not a product. Not on any app store. Not for sale.
- Not multi-tenant. Every install is an island. There is no shared backend.
- Not a system that surveils non-consenting third parties. The user is the subject.
- Not a substitute for medical, psychiatric, or therapeutic care.

## Inviolable constraints

These are not stylistic preferences. Removing any of them changes what the project is.

### 1. Data stays under the user's control

The default state is local-only storage on the user's own devices. Cloud sync, LLM API calls, exports — each is a separate explicit toggle, off by default. Each surfaces clearly what it does and where the data goes before it flips on. There is no telemetry, no crash reporting, no "anonymous usage stats" that phone home.

### 2. No surveillance of third parties

Panopticon observes the user's behavior. Notification *content* from messaging apps is captured for the user's own analysis only. It is never used to dossier the people sending those notifications, and it never leaves the user's devices except via the user's explicit per-source toggle. Contacts, locations, biometrics, or content of conversations from other people are not collected.

If a future collector is proposed that would touch third-party data (e.g., home network capture across household members), it gets its own consent flow, its own risk write-up, and its own opt-in — and it ships only if the third-party exposure can be eliminated or reduced to incidental, non-stored metadata.

### 3. Hard delete, always

Every event, every journal entry, every scale, every instrument response, every briefing — deletable by the user. Hard delete, not soft. If a feature can't honor this, it doesn't ship.

### 4. The portrait belongs to the subject

The user owns the data, the analysis, the briefings, and the model of themselves that emerges. No remote operator can read it. No advertiser can buy it. The MIT license lets forkers build whatever they want from this code; the principle is that *each install's data belongs to that install's user*.

## Design rules

These follow from the principles. They are how the principles cash out in code and prompts.

### Depth over adherence

This is not a habit-tracker fighting for daily engagement. There are no streaks, no notifications begging the user back, no shortened forms designed to maximize completion rates. If a journal entry takes 20 minutes because the day was dense, it takes 20 minutes. If the user skips three days, they skip three days. Honesty and depth are the optimization targets; adherence is downstream.

### No headline scores

Subscale dimensions are kept distinct. There is no single "intelligence" number, no overall "wellbeing" number, no daily score out of 10. Compressing rich multidimensional data into a single number is exactly the kind of false summary the project exists to avoid. Trends per subscale, named for what they actually measure, are the unit of insight.

### No modal interruptions, ever

Concerns — including suicidality, withdrawal patterns, scale crashes — surface inside the daily briefing in the persona's voice. Never as popup modals, never as crisis-prompt walls, never as gating screens. The user gets the data and the take, not a paternalistic intervention. Crisis resources (988, Samaritans, findahelpline.com) appear when the briefing flags warrant them, woven into the prose, one tap away — not blocking the experience.

### Self-hypothesis is first-class data

When the user writes "I always X after Y" in a journal entry, that's not just prose — it's a testable claim. The pipeline tags self-hypotheses, queries the data, and reports back: validated, refuted, partial, untested. The portrait is sharper because the subject's own theories about themselves are checked against the log, not merely recorded.

### Behavior over trait, except where there's ground truth

Behavioral signals get named for the behavior (`late_night_phone_minutes`, `avg_response_latency_to_partner`), not the trait they're proxying for. Trait-level interpretations happen only where there's ground-truth anchor: validated instruments (PHQ-9, IRI, MFQ), self-reported sliding scales (libido, mood), or built-in cognitive tests (N-back, RT) that produce reproducible scores under controlled conditions.

### Trauma-informed by default in coaching tone

When user context indicates chronic illness, neurodivergence, grief, caregiving load, or acute stress, the coaching layer adjusts framing — questions over directives, acknowledged constraints, no moralizing about reduced output. This isn't politeness; it's recognizing that feedback delivered without context is just worse feedback. The persona system carries this.

## What this means if you fork this

Fork it. It's MIT-licensed. Strip whatever you want.

If you remove the principles above, the system still runs. It will produce different outputs. It will not be Panopticon anymore — it'll be your variant. That's fine. The principles are documented so the choice is conscious.

If you find principles that should join these, open an issue. Better rails are welcome.

## Crisis resources

Panopticon is not a clinician and not safe to rely on in crisis. If you need help:

- **US:** 988 (Suicide & Crisis Lifeline)
- **UK:** 116 123 (Samaritans)
- **International:** [findahelpline.com](https://findahelpline.com)
