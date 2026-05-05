# Screening Instruments

> Reference document for the validated psychological screening instruments Panopticon uses, with licensing notes, crisis-path requirements, and rules for how the coaching layer may interpret scores.

This document is load-bearing. The instruments listed here are clinical tools with decades of validation behind them. Using them carelessly is worse than not using them — a poorly-administered or misinterpreted screen can produce false reassurance, unwarranted alarm, or active iatrogenic harm. Read this document end-to-end before touching the screening code.

---

## The single most important rule

**A screen is not a diagnosis.**

Every instrument in this document is a *screening tool*. A high score on PHQ-9 says "this person should discuss depression with a clinician." It does **not** say "this person has depression." Conflating the two is the single largest harm vector in self-screening apps.

This rule is enforced in three places:

1. **In code:** scores are stored and displayed. Diagnostic labels are never derived from scores.
2. **In prompts:** the trauma-informed base prompt prohibits the LLM from making diagnostic claims based on scores. See [`prompts/trauma_informed_base.md`](../prompts/trauma_informed_base.md).
3. **In UI:** every screen result is presented with explicit "this is a screening tool, not a diagnosis" framing, with crisis resources visible.

Violations of this rule are not stylistic preferences. They are bugs.

---

## Why use validated instruments at all

The PHQ-9 isn't valuable because the questions are clever. It's valuable because thousands of subjects have taken it, scores have been correlated against clinician-confirmed diagnoses, cutoffs have been calibrated, test-retest reliability has been measured, and measurement invariance has been tested across demographics. **That validation work is the instrument** — the questions are just the surface.

A homemade equivalent has no known sensitivity, no calibrated cutoffs, no comparability across people or even across the same person over time, and may systematically over- or under-detect on populations the author didn't anticipate. We don't build homemade clinical instruments. We use the validated ones.

For project-specific measurements that aren't trying to be clinical instruments, see [`custom-measurements.md`](custom-measurements.md).

---

## The instrument set

All instruments below are public domain or freely licensable for non-commercial / open-source use as of the time of writing. **Verify the current license status at integration time** — some non-commercial licenses change, and some "freely available" instruments have copyright holders who can revise terms.

### Mood and affect

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **PHQ-9** | 9 | Depression | Spitzer / Kroenke / Williams. Public. Q9 is a self-harm trigger — crisis path required. Cutoffs: 5 mild / 10 moderate / 15 moderately severe / 20 severe. |
| **GAD-7** | 7 | Generalized anxiety | Same authors, same status. Cutoffs: 5 / 10 / 15. |
| **MDQ** | 13 + 2 | Bipolar spectrum screen | Hirschfeld et al. Published in journals; widely used for non-commercial purposes. Verify current license. Screen only — heavy false-positive rate, not a diagnostic. |
| **QIDS-SR-16** | 16 | Depression depth | Free. Useful as a deeper alternative to PHQ-9 when warranted. |
| **CES-D** | 20 | Depression | Public. Older but still valid. |

### Trauma and stress

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **PCL-5** | 20 | PTSD | US National Center for PTSD. Public domain. Asks about traumatic events explicitly — requires trauma-informed administration. Cutoff for probable PTSD: 31–33 (population-dependent). |
| **ACE-Q** | 10 | Adverse childhood experiences | Felitti / Anda, CDC-Kaiser study. Public. **Highly triggering** — needs intro and exit screens. Score of 4+ associated with elevated risk of a wide range of adult conditions, but is *not* a diagnostic of anything. |
| **DES-II** | 28 | Dissociation | Bernstein / Putnam. Free for clinical / research use; verify for open-source distribution. Score >30 elevates clinical concern. |

### Neurodevelopmental

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **ASRS-v1.1** | 6 (screener) / 18 (full) | Adult ADHD | World Health Organization. Public. The 6-item screener is a fast first pass; the 18-item version maps to DSM symptom criteria. |
| **AQ-10** | 10 | Autism (adult screen) | Cambridge Autism Research Centre. Free for non-commercial. Score ≥6 suggests further assessment. |
| **AQ-50** | 50 | Autism (adult, deeper) | Same author. Use when AQ-10 flags or the user requests depth. |

### Substance use

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **AUDIT-C** | 3 | Alcohol use | World Health Organization. Public. Three-question screener; AUDIT-10 is the longer version. |
| **DAST-10** | 10 | Drug use | Skinner 1982. Public. Past-12-month substance use screen. |

### Personality

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **PID-5** | 220 (full) / 25 (brief) | Personality (DSM-5) | American Psychiatric Association. **Free, public.** This is the modern open answer to MMPI-style coverage — 25 facets across 5 domains (Negative Affectivity, Detachment, Antagonism, Disinhibition, Psychoticism). The 25-item brief is a triage; the full 220 is for users who want depth. |
| **BFI-2** | 60 | Big Five personality | Soto & John 2017. Free. Major upgrade from the original BFI. |
| **IPIP-NEO-120** | 120 | Big Five (deeper) | Goldberg / IPIP framework. Public domain. |
| **PDQ-4+** | 99 | Personality disorder screen | Hyler. Free for non-commercial. Heavy false-positive rate; screen only. |

### Other

| Instrument | Items | Domain | Notes |
|---|---|---|---|
| **DSM-5 Cross-Cutting Symptom Measure (Level 1)** | 23 | Symptom breadth | APA. Free with attribution. Covers 13 domains in 23 items — excellent intake "first pass" before deciding which deeper instruments to administer. |
| **Y-BOCS-SR** | 10 | OCD severity | Self-report adaptation. Public. Use after OCI-R flags. |
| **OCI-R** | 18 | OCD screening | Foa et al. 2002. Free. Six subscales. |
| **EDE-Q** | 28 | Eating disorder | Public domain in many forms. |
| **SCOFF** | 5 | Eating disorder (rough screen) | Morgan et al. 1999. Public. |
| **ECR-R** | 36 | Adult attachment style | Fraley et al. Public. Two dimensions: anxiety and avoidance. |
| **PROMIS** scales | varies | Wellbeing, sleep, fatigue, pain, etc. | NIH. Open, modular, validated. |

### Not used

The following are intentionally excluded:

- **MMPI / MMPI-3** — copyrighted, licensed via Pearson, requires clinical training to interpret. PID-5 + BFI-2 + symptom-specific instruments cover the same ground license-clean.
- **BDI-II** — copyrighted via Pearson. PHQ-9 / QIDS-SR provide equivalent screening.
- **MCMI-IV** — copyrighted, licensed. PID-5 + PDQ-4+ provide overlapping coverage.
- **SCID** — clinician-administered structured interview; cannot be self-administered correctly.
- **TAT, Rorschach** — projective tests requiring clinician scoring; outside the project's scope.

Do not paraphrase any of the excluded instruments to "make our own version." Functionally similar items in the same domain may constitute a derivative work, and the result would be unvalidated regardless. Use the public alternatives.

---

## Crisis path requirements

Several instruments contain items that, if endorsed, indicate immediate clinical concern. The crisis path is **non-negotiable** and bypasses the normal coaching layer entirely.

### Triggers (Phase 2 must implement all of these)

1. **PHQ-9 item 9** — "Thoughts that you would be better off dead, or of hurting yourself in some way." Any non-zero response triggers the crisis path.
2. **PCL-5 elevated total + Criterion A endorsement of recent trauma** — surfaces crisis resources alongside the score.
3. **DAST-10 score ≥6** combined with self-reported active use — surfaces substance use resources.
4. **ACE-Q with high score AND user reports current safety concerns in free-text intake** — surfaces resources.
5. **Free-text intake containing language flagged by a small set of safety regexes** (suicidal ideation phrasing, active self-harm) — surfaces crisis resources regardless of any instrument completion.

### Crisis path behavior

When a trigger fires:

1. The current screen is paused. The user is shown a crisis resources screen with:
   - **US:** 988 (Suicide & Crisis Lifeline) — call or text
   - **UK:** 116 123 (Samaritans)
   - **International:** [findahelpline.com](https://findahelpline.com)
   - Local emergency services number (911 / 999 / 112) if user has set their region.
2. The user can dismiss and continue, but the resources remain visible at the top of the screen.
3. The LLM coaching layer is **bypassed** for this session. No persona response is generated. The user sees only the crisis resources and a brief, plain message.
4. The trigger is logged with timestamp, but the response itself is not stored if the user requests no-storage on the crisis screen.
5. If the trigger fires three times within seven days, the app surfaces a "would you like to set up a check-in with a clinician?" flow with locale-appropriate referral options.

### What the crisis path is NOT

- It is not a referral service. Panopticon does not refer the user to specific clinicians or services beyond established hotlines.
- It is not a treatment intervention. It is a "stop the app, here are real resources, go talk to a person" off-ramp.
- It does not phone home. The trigger does not generate any outbound network call.

---

## Administration requirements

### Intro / exit screens for trauma-adjacent instruments

PCL-5, ACE-Q, and any instrument that asks about traumatic events or self-harm requires:

**Intro screen:**

> The next questions ask about hard things — events from your past, or current symptoms that may be uncomfortable to think about. You can stop at any time. Some people find it helpful to pause partway through and come back. There is no penalty for skipping any item.
>
> Crisis resources are always available at the top of the screen.

**Exit screen:**

> You finished. Some people feel a residue after questions like these — a heaviness, a fogginess, an urge to be alone or to not be alone. That's a normal response, not a sign that anything is wrong with you.
>
> Some things people do to settle: a walk, a glass of water, calling a friend, getting outside, putting the phone down for an hour.
>
> If anything came up that feels acute, the resources at the top of the screen are real and available right now.

These screens are not skippable. They appear regardless of how the user scored.

### Retake cadence

| Instrument | Suggested retake | Why |
|---|---|---|
| PHQ-9, GAD-7 | 2 weeks minimum, monthly typical | State measures — designed for repeat administration. |
| PCL-5 | Quarterly | State-ish; trajectory is meaningful but item content is heavy. |
| ASRS, AQ | Yearly | Trait-leaning. Repeat administration adds little. |
| ACE-Q | Once, with rare reasons to retake | Retrospective lifetime measure. |
| PID-5, BFI-2 | Yearly | Trait. |
| AUDIT-C, DAST-10 | Quarterly | State; useful for trajectory. |
| Cross-Cutting Level 1 | Quarterly | Designed as a periodic broad screen. |

The app does not push retakes. It surfaces "you last took this N months ago, would you like to retake?" when the user opens the relevant section. The user is the one who decides cadence.

### Score storage

Each completed instrument stores:

- **Raw item responses** (1 row per item).
- **Computed total and subscale scores.**
- **Instrument version** (instruments get revised; PHQ-9 is stable but PCL-5 has had revisions; PID-5 brief vs. full are different).
- **Administration timestamp** and timezone offset.
- **Administration mode** (full intake / retake / triggered by user request).

Both raw responses and computed scores must be deletable per the Phase 1 "delete everything" guarantee. Per-item deletion arrives in Phase 3.

Schema: see `schema/screening.schema.json` (to be added when Phase 2 begins).

---

## What the LLM may and may not say about scores

The coaching layer must follow these rules. They are an extension of [`prompts/trauma_informed_base.md`](../prompts/trauma_informed_base.md).

### The LLM may

- Describe the score plainly: "Your PHQ-9 score in March was 14, which is in the moderate-to-severe range on the published cutoffs."
- Describe trajectory: "Your GAD-7 has trended down from 16 to 9 over the last six months."
- Connect scores to behavioral data: "Your AUDIT-C drift upward overlaps the period your sleep window collapsed — those often travel together."
- Suggest professional support: "A change of this size is usually worth discussing with a clinician."
- Reflect symptom-cluster patterns *as observed*: "Your PCL-5 hyperarousal subscale is elevated relative to the avoidance subscale."

### The LLM may NOT

- **Diagnose.** Never. "You have depression," "you have ADHD," "you have PTSD" — never. The model says "your scores on instrument X are in range Y, which the literature associates with Z." It does not pronounce.
- **Predict outcomes.** "Given your scores, you are likely to..." — forbidden.
- **Compare to other people.** "Most men your age score..." — forbidden. The trauma-informed base already prohibits this; it applies doubly to clinical scores.
- **Recommend medication or specific treatments.** It can say "this is something a clinician can help with." It does not name medications, modalities, or providers.
- **Re-score the instrument or modify items.** Items are administered verbatim. Paraphrasing for "tone" invalidates the instrument and breaks comparability.
- **Override crisis path output.** If a crisis trigger has fired, the LLM does not generate a response — the crisis screen is the response.

---

## Sources and provenance

When implementing each instrument, source it from the canonical location, not from a third-party site:

- **PHQ-9 / GAD-7**: [phqscreeners.com](https://www.phqscreeners.com/)
- **PCL-5**: [US National Center for PTSD](https://www.ptsd.va.gov/professional/assessment/adult-sr/ptsd-checklist.asp)
- **ASRS-v1.1**: [Harvard NCS-R Adult ASRS Symptom Checklist](https://www.hcp.med.harvard.edu/ncs/asrs.php)
- **AQ-10 / AQ-50**: Cambridge Autism Research Centre original publications
- **ACE-Q**: CDC-Kaiser ACE Study materials
- **AUDIT-C**: WHO AUDIT manual
- **DAST-10**: Skinner 1982, original publication
- **PID-5**: APA — [`psychiatry.org`](https://www.psychiatry.org/) (Personality Inventory for DSM-5)
- **DSM-5 Cross-Cutting Symptom Measure**: APA — same source as PID-5
- **BFI-2**: Soto & John 2017, [colby.edu/psyc-faculty/csoto](https://www.colby.edu/psychology/personality-lab/) (or current author site)
- **IPIP-NEO**: [ipip.ori.org](https://ipip.ori.org/)
- **Y-BOCS-SR**: original validation studies; widely available
- **OCI-R**: Foa et al. 2002 publication
- **PROMIS**: [healthmeasures.net](https://www.healthmeasures.net/)

Each implementation must store the source URL it was transcribed from in a comment in the relevant code module, for future audit.

---

## Open questions

- **Item text licensing**: For the few instruments with ambiguous open-source distribution rights (AQ, MDQ, DES-II), whether to ship item text in the repo vs. fetch at runtime from the canonical source. Lean toward fetching where ambiguity exists, with a fallback to a manual user-entered URL.
- **Localization**: Translations of validated instruments are themselves validated separately. We ship English-only at first; non-English locales should not auto-translate items — they should fetch the validated translation or skip the instrument.
- **Adolescent / minor versions**: Out of scope for now. Project assumes adult subjects.
