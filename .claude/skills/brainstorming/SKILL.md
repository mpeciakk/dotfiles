---
name: brainstorming
description: "You MUST use this before any creative work — creating features, building components, adding functionality, modifying behavior, or implementing from a provided spec."
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to every project that reaches this skill. (Genuinely trivial, mechanical changes — a config value, a style token, a typo, a `.gitignore` line — are triaged out upstream by development-workflow and never reach brainstorming. If you are here, the change is non-trivial: do not wave it away as "too simple.")
</HARD-GATE>

**One carve-out, and it is upstream of you:** development-workflow's small lane
handles a change with exactly one statable decision. There the approved sentence
*is* the design — no spec document, no approaches — and the run's slug starts
with `small/`. That decision still gets a ✋ approval before any code; what the
lane drops is the paperwork, not the gate. Do not invoke this skill to
retro-document a small-lane change, and do not use "it's basically small" to
skip the design for work that has more than one decision in it.

## Entry: idea vs provided spec

Check one observable thing first: **did the user hand you a written spec / requirements doc to implement** (e.g. "implement @spec.md", an attached requirements file)?

- **No — starting from an idea** → run the full Checklist below (dialogue → approaches → design doc).
- **Yes — a spec was provided** → run the **spec-intake path**: their document IS the design. Do NOT generate approaches or author a new design doc — **skip Checklist steps 4–5**. Instead:
  0. Open the run (step 0) — a spec handed to you still needs run state, or every later stage and guard has nothing to read.
  1. Read the spec and explore project context (step 1).
  2. Run the **grill gate against their spec** (step 3): scan it for open decision points, ambiguities, contradictions, missing requirements, and undefined edge cases. If the spec is complete and unambiguous, the grill stays silent — proceed straight on. If it has real gaps, grill them one question at a time (each with a recommended default), and fold the resolved decisions back into the spec.
  3. Spec self-review (step 7): placeholders, internal consistency, scope, ambiguity — fix inline.
  4. Commit their spec into the repository and record it (step 6's tail). If the spec lives outside the repo (an attachment, `/tmp/spec.md`), copy it into `.flow/specs/` first — `git add` refuses a path outside the working tree. Then `git commit` and `~/.claude/hooks/flow-state set spec="$(git rev-parse --show-toplevel)/.flow/specs/<file>.md"` (absolute, so it still resolves from a subdirectory). The worktree branches from HEAD, so an uncommitted spec is absent from the workspace every implementer works in.
  5. Invoke writing-plans pointed at their spec file (step 8). The user signs off on the spec — including every change the grill folded into it — at the plan gate, where it is shown beside the plan.

The HARD-GATE holds on both paths: no implementation until the spec is validated and the user has approved it (at the design gate, or for a provided spec at the plan gate). With a provided spec you *validate their document* instead of authoring one — you never silently start coding just because a spec was attached. When the spec is solid, this path is nearly frictionless: grill stays quiet, self-review passes, plan.

## Checklist

Work through these items in order; none is optional:

0. **Open the run** — `~/.claude/hooks/flow-state init <task-slug>` (if development-workflow's triage has not already) and `set stage=design`. The run state is what later stages and the pipeline's guards read; a run nobody opened is a run that loses its worktree.
1. **Explore project context** — **read the project's living spec first** (see The Project Spec below); it states what the project is, which decisions are already in force, and what is still open, and it is the one document that makes your questions non-redundant. Then cbm (`get_architecture` for structure, `search_graph`/`search_code` to find relevant code), then docs and recent commits; Grep/Read only for non-code
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Grill gate** — scan for open decision points; if any remain, grill one question at a time until none do; if none, stay silent and move on. See `~/.claude/skills/brainstorming/grill-gate.md`
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Present design** — one message, sections scaled to complexity, then ask for approval once. Pause mid-design only when a section's answer changes the sections after it (that is a grill-gate dependency, not a checkpoint)
6. **Record the design in two places** — the deliberation record and the living spec. See The Project Spec below for exactly what goes where, then commit both in one commit and record the living spec's path: `~/.claude/hooks/flow-state set spec="<absolute path to the project's spec.md>"` (absolute — a relative path breaks from any subdirectory)
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
8. **Transition to implementation** — invoke writing-plans skill to create implementation plan. There is no separate "review the written spec" gate: what you wrote restates what the user just approved, so it is shown to them at the plan gate (commit + paths) instead of costing a round-trip of its own

Two loops inside that order: the grill gate sends you back to questions while
open decisions remain, and a design section the user rejects gets revised
before you move on. Everything else runs straight through.

## The Project Spec

Most projects here keep a **living spec** — `spec.md` at the project root, or
per-component (`agent/spec.md`, `webui/spec.md`) in a monorepo. Use the nearest
one above the code you are changing. It states what the project *is right now*:
its purpose, scope, architecture, data model, contracts, the decisions in force,
and the points still open. It is the highest-value context in the repo and the
most likely to be stale — in this user's projects, five of seven specs had not
been touched in over a month while their code moved on.

Their shape varies by project and you follow the one in front of you: numbered
`## N. Section` headings, Polish, opening with `## 1. Cel`, and closing with open
points (named "Punkty otwarte", "Otwarte kwestie i flagi", "Otwarte decyzje" —
whatever that file already calls it). One spec records decisions in a numbered
table with a rationale column; most record them inside the section they belong
to. Match the file, do not impose a format on it.

Two documents with **disjoint jobs**, which is what keeps them from drifting:

| | `spec.md` (living) | `.flow/specs/<date>-<topic>-design.md` |
|---|---|---|
| Holds | what is true **now** | what we deliberated **then** |
| Contains | the decision in force, architecture, model, open points | the options considered, what was rejected and **why** |
| Revised later? | yes — every change that alters it | **never**; it is a dated journal entry |

So the design record keeps the reasoning that a statement of current state
cannot hold, and the spec keeps the truth that a dated record goes stale about.
Nothing is duplicated: point one at the other — the record names the decision it
resolved, and the spec entry names the record.

**At this gate, write both:**

1. The deliberation record to `.flow/specs/YYYY-MM-DD-<topic>-design.md` —
   **the branch you did not take**: approaches considered, what you rejected and
   why, what this change deliberately leaves out of scope. Head each section with
   the decision it resolved (`## D29 — …`) so record and spec entry point at each
   other. Tens of lines, not hundreds.

   **Not the chosen design's mechanism.** That is state: it belongs in the spec
   entry below, and its execution belongs in the plan's tasks. Restating it here
   makes a third copy that goes stale the first time the implementation deviates
   — in this user's projects the records already run to two thirds the length of
   the spec, and the overlap is almost entirely chosen-design prose whose spec
   decision row says the same thing. Anything the plan writer will need about the
   chosen design goes into that row, not here.
2. The approved decision into the living spec, **the way that spec already
   records decisions**: a row in its decision table if it has one (continue its
   numbering, keep its columns), otherwise a sentence in the section the decision
   governs, dated. Any new unknown goes into its open-points section; an unknown
   this change *closes* gets struck there, dated.

If the spec has no decision record at all, propose adding one — a table with
what/choice/why is the strongest form and the one spec here that has it is the
most useful of the set — but propose it, do not retrofit someone's document as a
side effect of an unrelated change.

**Sections that describe state** — architecture, data model, API — are *not*
updated here. They describe what exists, and it does not exist yet; the plan's
last task updates them alongside the code, so they get reviewed together
(writing-plans owns that).

**If the project has no living spec at all:** that is a bootstrap job, not a side
effect of this change — say so and offer the writing-specs skill, which
interviews for one and writes it. If the answer is no, the deliberation record
alone is the output, exactly as before.

**The terminal state is invoking writing-plans.** Do NOT invoke any implementation or domain skill from here. The ONLY skill you invoke after brainstorming is writing-plans.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Present it in one message and ask for approval once; paragraph-by-paragraph sign-off is what makes a small feature feel like a heavy process
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## Spec self-review (Checklist step 7)

After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review — just fix and move on, then invoke
writing-plans. If the user objects to the written record at the plan gate, fix it,
re-run this review, and amend the plan if the fix touches it.
