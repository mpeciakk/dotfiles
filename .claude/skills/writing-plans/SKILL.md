---
name: writing-plans
description: Use when opening a planned run — turns a request, an idea or a provided spec into one plan with the change's decisions and its tasks, before any code. The first stage of development-workflow.
---

# Writing Plans

One document per run: what this change decides, and the tasks that build it.
The user approves it once, at the plan gate. No code before that "go".

## 1. Context first

Open the run if nobody has: `~/.claude/hooks/flow-state init <slug>`, then
`flow-state set stage=plan`.

Read the project's living spec before asking anything — for a split spec, the
index and the topic files this change touches. Then the code: cbm
(`get_architecture`, `search_graph`, `trace_path`) for structure and blast
radius, Read for branch-new code and non-code files. Recent commits.

If the request spans several independent subsystems, say so first and plan
the first one; each gets its own run.

**A provided spec** ("implement @spec.md", an attached file) is the design.
Do not re-author it: grill its gaps, fold the answers back into it, commit it
into the repo (copy it under `.flow/` if it lives outside), then plan from it.

## 2. Questions and decisions

Ask one question at a time, each with your recommended default. Facts you look
up; decisions you ask. Before writing the plan, run the grill scan
(`grill-gate.md` in this directory): stay silent when nothing is open, grill
until nothing is.

Where there is a real fork, give 2–3 options with trade-offs and your
recommendation. Where there is none, do not invent one.

## 3. The plan

Save to `.flow/plans/YYYY-MM-DD-<slug>.md`. Target 100–250 lines. Past ~300,
look at why before going on: usually the plan carries what an implementer can
decide — cut it; if the scope itself is too big for one run, propose a split
to the user.

```markdown
# <Change> — plan

## Goal
One sentence. Spec: <path to the living spec>, <decision number(s) added>
(omit if the project has none).

## Decisions
- D<n> <decision> — <why>. Rejected: <alternative> (<why not>).

## Constraints
Project-wide requirements a task must not break, one line each, values
verbatim from the spec. `None.` if there are none.

## Verification
The end-to-end check the branch review runs: the scenario, command or data
that shows the change works for real, not only that tests pass.

## Task 1: <domain of the change>
**Outcome:** what exists and works when this task is done.
**Acceptance:** the behaviours its tests must show, including the edge cases
that matter.
**Area:** modules and files it owns.
**Context:** spec sections to read, the pattern to follow (path + symbol),
what earlier tasks produced that it builds on.
```

Everything above the first `## Task` reaches every implementer: `task-brief`
prepends it to each brief.

**A task is one domain of this change** — "session core: status contract and
events, session tests green", not "add a field to the model". It ends with a
checkable result and leaves the tree in a state you could stop at and resume
from. Most runs have 2–5 tasks.

**What the plan fixes and what it leaves.** The implementer writes the tests
and the code. The plan fixes only what the implementer cannot decide alone:
names of a public API, formats, exact values the user chose, the shape of an
external API. No code, no test code, no step lists.

**Verify external assumptions first.** If a task depends on how a third-party
API, tool or real dataset actually behaves, the first task makes one cheap
real call and the rest build on its result. Review checks code against the
plan; only a real call checks the plan against reality.

## 4. The living spec

At the gate, write the approved decisions into the living spec the way it
already records them: a row in its decision table (continue the numbering) or
a dated sentence in the section the decision governs. New unknowns go to its
open points; unknowns this change closes get struck, dated. Cite code by path
and symbol, never by line. For a split spec, the row goes into the topic file
that owns the section, and the index's next free D number moves in the same
commit. If the file you write into is over 40 KB, say so in one line — the
split is a separate writing-specs job.

Sections describing state (architecture, data model, API) change after the
last task, before the branch review — not here: the code does not exist yet.

No living spec: the plan's Decisions section is the record; offer
writing-specs as a separate job.

## 5. Self-check

- Every requirement has a task; every task has acceptance a test can fail on.
- No "handle errors appropriately", "add validation", "TBD": name the
  behaviour.
- Names and interfaces agree across tasks.
- The Verification section is something someone can actually run.

## 6. Red-team (2+ tasks)

Dispatch `plan-red-team` with `run_in_background: true`, passing the plan and
spec paths only, then end the turn. Skip it for a single-task plan.

On return: blocking or serious objections go to the user verbatim, with your
take on each, and get resolved — by amending the plan or by the user accepting
the risk — before "go". Minor objections only: apply them yourself and name
them in one line at the gate.

## 7. The gate

Commit the plan and the spec change together, then record:

```bash
git add .flow/plans/<file>.md <spec files> && git commit -m "plan: <change>"
~/.claude/hooks/flow-state set stage=plan plan="$(git rev-parse --show-toplevel)/.flow/plans/<file>.md" spec=<absolute spec path>
```

The commit lands on the current branch before any worktree exists — the
worktree branches from HEAD and needs it. Say so.

Present: the decisions, the tasks (one line each), the red-team verdict, the
commit. Wait for "go".

On "go": using-git-worktrees, then subagent-driven-development. If the user
asks to run it inline instead, record `flow-state set stage=inline` and work
the tasks yourself in the worktree.
