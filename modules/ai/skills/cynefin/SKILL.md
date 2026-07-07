---
name: cynefin-categoriser
description: Analyse any problem, decision, or situation through the Cynefin framework — decompose it into sub-problems, classify each into a Cynefin domain (Clear, Complicated, Complex, Chaotic, Confused), surface classification signals, flag misclassification risks, and recommend the domain-appropriate response strategy. Use this whenever the user asks to categorise or analyse a problem with Cynefin, asks "what kind of problem is this", is unsure whether to plan/analyse vs experiment/probe, is choosing between best practice and experimentation, feels stuck on how to approach a messy decision, or mentions Snowden, sense-making, complexity, or "complex vs complicated". Also use when the user describes a tangled multi-part situation and wants help figuring out how to attack it.
---

# Cynefin Problem Categoriser

Apply the Cynefin framework (Dave Snowden) to a problem the user describes. The goal is not the label — it's picking the right *response strategy*. Misclassifying a problem leads to predictable failure modes (e.g., hiring experts to analyse a complex problem, or running experiments on a burning building), so the analysis should make the classification defensible and the risks explicit.

## Core principle: decompose first

Almost no real-world problem lives in a single domain. "Migrate to microservices", "fix my team's morale", "should I take this job" are *bundles* of sub-problems that sit in different domains and need different treatment. Classifying the bundle as a whole produces mush.

So the first analytical move is always: break the stated problem into its distinct sub-problems, then classify each one separately. If the user's problem genuinely is atomic (rare), say so and classify it directly — don't invent artificial decomposition.

## The five domains

**Clear** (a.k.a. Obvious/Simple) — cause and effect are obvious to everyone. *Sense → Categorise → Respond.* Best practice exists; apply it. Signals: the answer is known and documented; anyone competent would do the same thing; it's been done thousands of times; constraints are rigid.

**Complicated** — cause and effect exist but require analysis or expertise to see. *Sense → Analyse → Respond.* Multiple good practices exist; experts can determine which fits. Signals: an expert could reliably solve it; the problem is analysable in advance; you can decompose it and the pieces behave predictably; the same inputs produce the same outputs.

**Complex** — cause and effect are only visible in retrospect. The system's behaviour emerges from interactions; it cannot be predicted, only probed. *Probe → Sense → Respond.* Run safe-to-fail experiments, amplify what works, dampen what doesn't. Signals: people (or markets, or other adaptive agents) are central to the system; the system changes in response to your intervention; experts disagree and all sound plausible; past attempts at "the right answer" produced surprises; you'd learn more by trying something small than by analysing further.

**Chaotic** — no perceivable cause and effect; the situation is unstable. *Act → Sense → Respond.* Stabilise first, then reassess. Analysis and experimentation are luxuries you don't have. Signals: things are actively degrading right now; there is no time to gather information; any decisive action beats deliberation; crisis language ("production is down", "she just quit mid-meeting", "the pipe is flooding the flat").

**Confused** (a.k.a. Disorder/Aporetic) — you don't yet know which domain you're in. This is the honest default state, not a failure. The danger of Confused is that people default to their comfort zone: bureaucrats treat everything as Clear, engineers as Complicated, facilitators as Complex, dictators as Chaotic. The exit from Confused is further decomposition and information gathering — *not* forcing a classification.

## Classification discipline

- **Classify from signals, not vibes.** For each sub-problem, name the concrete signals in the user's description that point to a domain. If the user's description lacks the signals needed to classify confidently, place the sub-problem in Confused and say exactly what information would resolve it. That's a more useful answer than a confident guess.
- **The Complicated/Complex boundary is where the money is.** It's the most common and most expensive misclassification in knowledge work. The test question: *would an expert's analysis done today still be valid after you start intervening?* If the system adapts to your moves (people, markets, organisational politics, incentive structures), it's Complex regardless of how technical it looks. Beware **retrospective coherence**: complex outcomes look predictable in hindsight, which tricks people into believing the next one is predictable in advance.
- **Watch the Clear→Chaotic cliff.** Cynefin draws Clear adjacent to Chaotic for a reason: complacency about a "solved" problem (the never-tested backup, the SOP nobody updated, the assumption that renewals are automatic) is how you fall off the cliff into crisis. When you classify something as Clear, check whether it's *actually* Clear or just habitual.
- **Domains are current state, not identity.** Problems move. The general management direction is toward Clear (Chaotic → stabilise → Complex → probe until patterns stabilise → Complicated → analyse into procedure → Clear). Note the likely trajectory where relevant — it changes what "success" means for the current phase.

## Domain-specific risks to flag

When a sub-problem lands in a domain, flag the failure modes native to that domain:

- **Clear**: complacency; oversimplifying something that has quietly become Complicated; the cliff into Chaotic. Also entrained "we've always done it this way" thinking blocking cheap improvements.
- **Complicated**: expert entrainment — experts overconfident in their frame, dismissing novel signals; analysis used to defer decisions; paying for analysis precision the decision doesn't need.
- **Complex**: the killer risk is treating it as Complicated — hiring consultants for a definitive answer, big up-front design, "best practice" imported from elsewhere. Also: premature convergence on the first probe that shows promise; probes that aren't actually safe-to-fail (too big, irreversible, no kill criteria); imposing rigid order and destroying the emergence you needed to observe.
- **Chaotic**: two opposite risks — dithering (probing/analysing while the building burns) and the strongman trap (the decisive crisis actor who won't relinquish command-and-control after stabilisation, freezing the org in Chaotic-mode management).
- **Confused**: forcing a premature classification that matches your habitual style rather than the problem.

## Recommended actions must match the domain

The value of the classification is the strategy change, so make recommendations concretely domain-shaped:

- Clear → name the best practice / checklist / SOP to apply, and who can just do it.
- Complicated → name what kind of expertise or analysis is needed, and what question the analysis must answer.
- Complex → propose 2–3 *specific* safe-to-fail probes: small, cheap, reversible, with an explicit signal to watch and amplify/dampen criteria. "Run experiments" without naming them is not a recommendation.
- Chaotic → name the single stabilising action to take *now*, and what to reassess once stable.
- Confused → name the specific missing information or the finer decomposition that would resolve the classification.

## Output structure

Use this template. Keep prose tight; this is an analysis, not an essay.

```
# Cynefin analysis: [problem in one line]

## The problem, restated
1–3 sentences showing you understood the actual situation, including what's at stake.

## Decomposition
The distinct sub-problems, one line each. (Skip if genuinely atomic — say so.)

## Classification

### [Sub-problem] — [DOMAIN]
- Signals: the concrete evidence from the user's description
- Risk if misclassified: the specific failure mode, tied to the most tempting wrong domain
- Approach: domain-appropriate action(s), concrete

(repeat per sub-problem)

## Overall read
Where the centre of gravity is, what to do first and why, expected domain
transitions, and the one misclassification that would hurt most.
```

Adapt headings to the conversation's language and register — if the user writes in Polish, answer in Polish; if it's a two-line personal dilemma, the analysis can be proportionally shorter, but never skip signals and risks.

## Tone and honesty

- Don't flatter the framework. If Cynefin adds little for this problem (e.g., the problem is plainly Clear and the user knows it), say so briefly and give the direct answer.
- Prefer disagreement over comfort: if the user has pre-classified ("this is clearly a complicated problem, we need a better architect"), test that claim against the signals rather than accepting it.
- One classification honestly marked Confused beats five confidently wrong.
