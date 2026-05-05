# Daily Briefing

The home-screen artifact the user sees each day. The Panopticon equivalent of FitForge's `AiCoachCard` daily report, generalized across the much wider Panopticon dataset.

This document specifies what the briefing contains, what tone it takes, how concerns are surfaced, and how it's stored.

## Purpose

Take everything the system observed and inferred about the user yesterday — passive collectors, journal prose, sliding scales, instrument responses, biometrics — and produce a single readable take in the user's chosen persona's voice. Surface patterns the user spotted, validate or refute them, surface patterns the user didn't, and flag concerns inside the prose rather than as interruptions.

The briefing is the project's main human-readable output. Everything else is plumbing in service of this.

## Sections

A briefing is a sequence of sections, each one optional but ordered consistently when present.

### 1. Bottom-line read

One paragraph in the persona's voice. What kind of day was it. Not a summary of events — an interpretation. This is the headline.

> *"Yesterday looked like a recovery day after Tuesday's crash. Sleep was solid, mood crept back to a 6, you finished the law reading you'd been avoiding, and the run actually didn't end at Burger King this time — small win. Energy was still flat in the afternoon though, and you spent two hours on Reddit at 11pm. We've been here before."*

### 2. Pattern validations

Self-hypotheses extracted from yesterday's (and recent) journal prose, tested against the data. Each surfaces with the verbatim claim, the evidence, and the verdict.

> *"Two weeks ago you said 'I always fuck up after a run by eating like shit.' Tested over the last 90 days — 11 of 14 post-run windows showed fast food or sugar within 4 hours. So yes, the pattern is real, 79%. Yesterday was one of the 3 exceptions — what was different?"*

### 3. New patterns spotted

Things the data shows that the user *hasn't* flagged. Surfaced gently and as observations, not pronouncements.

> *"Something I noticed that you haven't mentioned: every Sunday for the last 6 weeks, your screen time after 10pm has been 2-3x your weekday average. Doesn't show up in the journal. Anything to that?"*

### 4. Contradictions

Places where the user's stated belief about themselves diverges from what the log shows. These are delicate — the goal is honesty, not gotchas.

> *"You wrote on Monday that you 'never get any work done on Sundays.' The data says otherwise — 4 of the last 6 Sundays had focus blocks of 90+ minutes on coding apps. Worth updating the story?"*

### 5. Anomalies vs personal baseline

Notable departures from the user's own rolling baselines. Not judgmental — just *different*.

> *"Your HRV last night was 18% below your 30-day average. Sleep quality scored 4. You also logged 3 alcohol servings yesterday, which is on the higher end for you. These usually move together."*

### 6. Concerns

Clinical-scale shifts, suicidality mentions, withdrawal patterns, distress signals. Surfaced inside the prose in the persona's voice. **Never as a popup or modal.** Crisis resources, when warranted, appear inline as a one-tap link.

> *"Heads up — three journal entries this week mentioned you'd 'rather not exist,' your PHQ-9 jumped from 6 to 14, and you skipped check-ins Wednesday and Thursday. That's a lot moving the same direction. If it gets sharp: 988 is one tap away. If it's not crisis but it's heavy, maybe time to call someone anyway."*

The decision rule for surfacing concerns: any flag with `severity >= "concern"` from the underlying data sources gets surfaced; flags at `urgent` get surfaced first and with crisis resources inline.

### 7. Open questions

Things the system can't tell from passive data and wants the user to address in tomorrow's journal. Stored as `open_questions[]` so the next day's briefing can check whether they were answered.

> *"Two things I can't tell from out here:*
> *— What was the 11pm-1am Reddit dive about last night? Looking for something or just stuck?*
> *— You mentioned 'the thing with mom' on Tuesday and never came back to it. Still on your mind?"*

## Tone rules

These are inviolable for the briefing layer. They flow from PROJECT_PRINCIPLES.md.

### No modals, ever

Concerns surface in the briefing prose, not as popups, gating screens, or crisis-prompt walls. The user opens the app and gets the briefing. Crisis resources, when surfaced, are one-tap links inside the text.

### No moralizing

The briefing reports patterns. It doesn't lecture about what the user "should" do. "You binged Burger King again" — neutral. "You really need to stop eating that garbage" — out of bounds. The persona observes; the user judges.

### No headline scores

No "your day rated 6.5/10," no overall wellness number. The bottom-line read is qualitative, in prose. Quantitative trends appear in their natural units in the relevant sections.

### Trauma-informed framing by default

When user context indicates chronic illness, neurodivergence, grief, caregiving load, or acute stress, the briefing avoids framing reduced output as moral failure. Acknowledges constraints the system can see. Defaults to questions over directives. Doesn't erase the persona's voice — direct personas stay direct, gentle personas stay gentle, but the framing of *what* gets said adjusts.

### Calibrated honesty

The briefing tells the user what the data actually shows, even when uncomfortable. Especially when uncomfortable. Sycophancy is a failure mode — "great job today!" when the data says otherwise is a worse output than "yesterday was rough, here's how."

But calibrated: the briefing distinguishes between "data shows X" (high confidence) and "data hints at X" (low confidence) and language reflects that.

### Persona voice, consistently

The persona system (Sam, Maximus, Nori, etc., per `prompts/`) defines voice. The briefing respects whichever persona the user has selected. Different personas express the same observation differently:

- **Sam (warm, peer-like):** *"Three rough days in a row, you doing okay? The PHQ jump caught my eye."*
- **Maximus (direct, no bullshit):** *"PHQ-9 went from 6 to 14 in a week. Three entries mentioned not wanting to exist. This needs attention. Today, not next week."*
- **Nori (gentle, careful):** *"Some heavier signals this week — the PHQ-9 climbed and a few entries went to dark places. I want to name that without making it bigger than it is. How are you, really?"*

Same data, same flag, three voices. The user picks which one suits how they want to be talked to.

## Storage

Each briefing is written to the event log as a `coach.briefing` event. This makes briefings:

- Queryable later: "show me every briefing where you flagged my sleep over the last 6 months."
- Auditable: the user can see what the coach said, when, and why (via `supporting_event_ids`).
- Trendable: do the same patterns keep getting surfaced? Are concerns escalating?

Schema is in `schema/events.schema.json` under `$defs.coach_briefing_payload`. Key fields:

```
date                  the date the briefing covers
persona_id            which persona wrote it
sections[]            ordered, each with section_type, text, supporting_event_ids
flags[]               structured flags surfaced (suicidality, scale_crash, etc.)
open_questions[]      deferred to tomorrow's journal
model_id              which LLM produced the prose (for reproducibility)
```

## Generation flow

Daily, on app open (or scheduled time, user configurable):

1. **Aggregate yesterday's data** — pull all events from the last 24 hours plus relevant rolling baselines.
2. **Run pipeline post-processing** if not already done — segment journal entries, test self-hypotheses, compute scale deltas vs baseline, run flag rules against instrument responses.
3. **Assemble structured input** — a prompt-friendly summary of: scale snapshot + deltas, journal sections, instrument changes, biometric anomalies, untested and recently-tested hypotheses, surfaced flags.
4. **LLM call** (or local model) with the persona system prompt + the structured input + the previous briefing for continuity.
5. **Validate output structure** — must conform to the section schema; reject and re-prompt if not.
6. **Write the `coach.briefing` event** to the log.
7. **Render in the home-screen card** when the user opens the app.

If the user's `aiCoachEnabled` toggle is off (per the same convention as FitForge), skip steps 4-6 and show a "data view" card with the raw scale + flag summary, no narrative.

## Failure modes to design against

- **Sycophancy.** The model softens uncomfortable findings. Mitigation: explicit anti-sycophancy in the persona prompt, with "calibrated honesty" examples.
- **Over-confident claims.** The model treats correlations as causes. Mitigation: structured confidence levels in the prompt; require hedge language for low-N findings.
- **Stale flags.** The same concern surfaces every day after the initial event. Mitigation: each flag has a `cool_off_days` and isn't re-surfaced unless the underlying data refreshes it.
- **Drift from data.** The briefing prose refers to events that didn't happen. Mitigation: every claim in the briefing must cite `supporting_event_ids`; validate post-generation that the cited events exist.
- **Persona collapse.** Different personas start sounding the same. Mitigation: voice tests in the persona prompt set; periodic A/B comparison of briefings written by different personas on the same input.

## Ask-anything follow-up

Below the briefing, an input field for follow-up questions (matching FitForge's pattern). The user can ask:

- *"How does my sleep last week compare to last month?"*
- *"You flagged Reddit — show me my late-night usage trend."*
- *"What did I say about mom on Tuesday?"*
- *"Why do you think I crashed Wednesday?"*

The coach answers using the same data substrate, in the same persona voice. Each Q&A is logged as part of the same coach session for memory continuity.

## What this is not

- Not a therapist. The briefing surfaces patterns; it doesn't diagnose, treat, or prescribe.
- Not a crisis intervention system. When suicidality flags fire, resources appear inline — the user, not the system, takes action.
- Not a productivity tool. There are no goals to hit, no streaks to maintain, no "you're on a 12-day journaling streak" gamification. The briefing exists to tell the truth, not to drive engagement.
