---
name: writing-specs
description: Use when a project has no living spec and needs one — a new project starting from an idea, or existing code whose purpose, decisions and open questions live only in someone's head. Triggers on "napisz spec", "stwórz spec.md", "zbierz wymagania", "write a spec for this project", "co ten projekt właściwie robi", and on reaching a project with no spec at the start of pipeline work. Not for amending an existing spec — brainstorming does that per change.
---

# Writing Specs

A living spec states what a project **is right now**: its purpose, scope,
architecture, the decisions in force, and what is still open. It is written once
per project and then kept true by every change that touches it.

This is a bootstrap job — one document, one sitting, its own user gate. It is not
a stage of the pipeline and it opens no run state; a change to *code* comes
afterwards, through development-workflow as usual.

## Two readers, and only one of them can ask

The spec is a hybrid document. A person reads it weeks later, having forgotten;
an implementer subagent reads it to build from, gets one shot, and **cannot ask a
follow-up**. Mostly they want the same thing. Where they diverge, the agent's
constraints decide — its failure mode is worse.

| | The person | The implementer |
|---|---|---|
| reads it | selectively, to re-orient | in full, on every task, paying context per line |
| meets a gap by | asking you, or using judgment | inventing an answer and committing it |
| reads "about 10 seconds" as | fine, roughly ten | `timeout=10` or `timeout=10000`, a coin flip |
| needs | the why, the shape, enough to disagree | exact values, one interpretation, stable anchors to cite |

What follows from that:

- **Exact values, verbatim.** Numbers with units, identifiers spelled as in code,
  user-facing strings in quotes. "A friendly error message" is not a requirement;
  `"Nie udało się zapisać — spróbuj ponownie"` is.
- **One interpretation per sentence.** For the person, ambiguity is a matter of
  style; for the agent it is a coin flip that ends up in a commit. If a sentence
  admits two readings, pick one and write it — or move it to the open points and
  say what would settle it.
- **Number the sections and keep the numbers stable.** Both readers cite them
  ("§5.2", "D14"); silent renumbering breaks every reference in plans, briefs and
  commit messages.
- **Rationale earns its place.** The "why" behind a decision is what stops either
  reader reopening it — the one kind of prose that pays for itself with both.
- **Nothing purely decorative.** A paragraph that motivates but decides nothing
  costs the person a minute and the agent context on every single task.

## Match the house, do not invent a structure

**Read a sibling spec before writing a line.** Other projects here already have
one (`~/work/*/spec.md`, `~/projects/*/spec.md`, sometimes per component:
`agent/spec.md`, `webui/spec.md`). Open the closest relative — same stack, same
author, similar size — and follow its shape.

What is already consistent across them, and what you therefore keep:

- **Polish**, unless the project's own artifacts are English
- Numbered `## N. Section` headings
- Opens with the purpose (`## 1. Cel`, `## 1. Czym jest X`)
- **Closes with open points** — every spec here has that section; use the name
  the sibling uses ("Punkty otwarte", "Otwarte kwestie i flagi", "Otwarte
  decyzje"), do not introduce an eighth name for it. Two different things end up
  there and the existing headings each name only one: **unanswered questions**
  (someone must decide) and **flags** (a known risk nobody has to decide today).
  If you have both, give them subsections under that heading rather than
  overloading it — one spec here already splits them into non-blocking versus
  gates-before-production, which is the distinction that matters
- The middle is entirely project-shaped: architecture, data model, protocol,
  stack, configuration, security, whatever this project actually has

A new structure invented per project is why one section already answers to seven
different names. Invent only when there is genuinely no sibling to copy.

**Decisions in force** are the part most worth getting right: what was chosen,
and *why*, so a later reader does not reopen a settled question. One project here
keeps them in a numbered table with a rationale column, which is the strongest
form and worth proposing; most keep them inside the section they govern. Either
is fine, as long as the rationale survives.

## Draft first, then grill

Do not open with a questionnaire. Fifteen questions in a vacuum produce "nie
wiem" for half of them — including the ones the code already answers.

1. **Build a strawman.** For existing code: read it first with codebase-memory
   (`get_architecture`, then `search_graph`/`trace_path` for the parts that
   matter), plus the README, the config, the dependency manifest, and the commit
   history — intent is often clearer in commit messages than in code. For a
   greenfield project: the strawman comes from the user's opening description and
   from how their other projects are built.
2. **Show it and say what you guessed.** Mark every inference explicitly. The
   user corrects a concrete draft far faster than they answer abstract questions,
   and a wrong guess in front of them is worth more than a right question.
3. **Then grill only the gaps** — one question at a time, each with your
   recommended default so a nod is a complete answer. Ask about intent,
   constraints, non-functional requirements and scope boundaries: the things no
   amount of code reading can tell you. **REQUIRED BACKGROUND:** the grill
   protocol at `~/.claude/skills/brainstorming/grill-gate.md` (a reference file,
   not a skill — read it directly) — apply it to the decisions this spec is about
   to record, and stay silent where nothing is genuinely open.

   **Push every answer to an exact value.** "Kilka sekund", "raczej szybko",
   "jakiś rozsądny limit" are not answers — ask for the number, the string, the
   name. If the user genuinely does not know yet, that is an open point with a
   stated default, not something for you to round off: an implementer will turn
   your rounding into a constant.
4. **Write assumptions down as assumptions.** Anything you could not confirm goes
   in its own numbered list, not smuggled into prose as fact. An auditable
   assumption gets corrected later; a buried one becomes folklore. The same
   applies to rationale you reconstructed rather than were told: on old code the
   "why" is often gone, so mark those `(wnioskowane)` instead of asserting a
   motive the author never stated.

**If the user is unavailable** — an agent running this alone, or "just do it" —
you do not get to answer for them. Record each question you would have asked in
the open points, with your recommended default, and say in the handoff that the
spec is provisional until those are settled.

## Scale to the project

The spec's job is to be read. Length follows the project, not ambition.

| Project | Descriptive body |
|---|---|
| A single-purpose tool, one service, a hobby repo | 60–150 lines |
| A real application with a data model and integrations | 150–350 lines |
| A system with external contracts, auth, several components | 350+, and consider one spec per component |

The bands cover the part that **describes** the project. Open points, recorded
questions and the assumptions list are additive and do not compete with them: on
a legacy project the unknowns can legitimately outweigh the facts, and cutting
them to hit a line count would mean silently answering questions the user has not
answered. Overshoot and say why, rather than deciding something to look concise.

A 300-line description of a 20-file project is a document nobody will maintain,
and an unmaintained spec is worse than none: it lies with authority.

## What does not belong in it

The spec says what **is**. Anything that would become false next week without
anyone deciding anything belongs elsewhere:

- **Defect lists, TODOs, known bugs** → issues, or a `Znane problemy` line at
  most. A spec is not a bug tracker.
- **Task breakdowns, phases, "definition of done"** → writing-plans owns those,
  per change.
- **Code** → beyond the odd contract snippet (a schema, an event shape, a config
  key), the code is the code.

Test each line before you keep it: *would this need a decision to change?* If
yes, it is spec. If it merely needs someone to fix something, it is not.

## Finishing

Put the file where the code it describes lives: project root for a single
codebase, next to the component in a monorepo. Commit it on its own — this is a
documentation act and should be reviewable as one. If you cannot write into the
repository at all (read-only checkout, no permission), say so, write it where you
can, and state in the handoff where it belongs — do not silently drop the
placement decision.

Then hand it to the user and say plainly which parts are their answers, which are
your inferences from the code, and which questions stayed open. Point out that
from here on the spec is kept true by the pipeline: decisions land at the design
gate, state sections get updated by the plan's last task.

## Red flags

- Asking questions before reading the code. The answers are half in there.
- A structure that matches none of the project's siblings.
- "TBD" or an empty section left in the delivered document — either the question
  is open (say so in the open points, with what would settle it) or it is not.
- A spec longer than the code deserves.
- "Około", "roughly", "jakiś", "odpowiedni", "w miarę" surviving into the
  delivered document. Each one is a decision you left for a subagent to make
  silently.
- Writing it as a plan: phases, tasks, checkboxes, estimates.
- Quietly resolving something the user has not decided. An open question stated
  as an open question is a finished spec; an invented answer is a broken one.
