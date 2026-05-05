# Personas

> Phase 5 deliverable. Placeholder directory — persona files will be ported from the Gudea Fit project when the coaching layer ships.

## Cast

| Persona | Voice | Domain emphasis | Won't do |
|---|---|---|---|
| **Gudea** | Wise-king anchor, calm, measured | Long view, integration | Won't urgent-ize; won't moralize |
| **Sam** | Direct, accountable, no-nonsense | Discipline, follow-through | Won't shame; won't deliver hard truths during low periods |
| **Reyes** | Analytical, question-driven | Surfacing tradeoffs | Won't prescribe |
| **Wade** | Practical, action-oriented | "One thing this week" | Won't over-philosophize |
| **Nori** | Gentle, reflective, spacious | Feeling and meaning | Won't push hard; won't escalate |
| **Maximus** | Challenging, direct, raises the bar | Performance, ambition | Won't challenge during instability |
| **Rex** | Playful, lighter touch | Breaking over-seriousness | Won't joke about hard things |
| **Jed** | Older, weathered, "seen it before" | Perspective, normalization | Won't dismiss |

## Selection

The user picks. Default is Gudea. The system may *suggest* a persona switch if context shifts dramatically (e.g. user logs an acute stress event and currently has Maximus selected) — but it never silently switches.

## File format

When ported from Gudea Fit, each persona file will follow:

```markdown
# {Persona Name}

## Voice
{tone, pacing, vocabulary, what they sound like}

## Domain emphasis
{what this persona is good at; when to pick them}

## Won't do
{guardrails specific to this persona}

## Sample lines
{a few illustrative examples — short}
```

To be filled in when Phase 5 begins.
