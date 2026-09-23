---
name: development-workflow
description: Use at the very start of any feature, bugfix, refactor, or other code change — before brainstorming, planning, or writing any code.
---

# Development Workflow

The end-to-end pipeline for every code change. This is the map — each stage
invokes its own skill; read that skill when you reach the stage. Run
continuously between the user gates (✋); never pause to ask "should I
continue?".

## Five rules that decide whether a run succeeds

**1. Triage first — not every change earns the pipeline.** Trivial → just do
it: edit, verify, done. Trivial means ALL of: one obviously-correct outcome,
mechanical, low blast radius, reversible, no behavior change you would want a
test for — a config value, a style token, a typo, a `.gitignore` entry, a
version bump, a mechanical rename. Anything else → stage 1, with the ceremony
scaled down. When in doubt it is not trivial. (Details under Triage below.)

**2. The run's state lives in a file, not in your memory.** Conversation
memory does not survive compaction, and a worktree path you merely remember
is a worktree you will lose. `~/.claude/hooks/flow-state` owns it:

```bash
~/.claude/hooks/flow-state init <task-slug>     # entering the pipeline
~/.claude/hooks/flow-state set stage=plan spec=.flow/specs/<file>.md
~/.claude/hooks/flow-state show                 # after compaction: where am I?
~/.claude/hooks/flow-state clear                # run finished
```

Fields: `task stage spec plan worktree branch base`, plus a per-task ledger.
One file per repository (`<main-checkout>/.flow/run/state.json`), shared by the
main checkout and every worktree, git-ignored.

**3. Once the run has a workspace, you do not write code — you dispatch
implementers.** Your context is for coordination: the plan, cross-task
interfaces, review adjudication. An implementer that starts fresh from a task
brief outperforms a controller carrying six tasks of history, and a controller
that spends its context on edits has none left for the decisions only it can
make. A PreToolUse hook enforces this — Edit/Write from the main thread is
denied from the moment `worktree` is recorded until the run reaches `finish` —
and writing code through Bash instead is defeating the mechanism, not passing
it. If a run genuinely should be inline, record it (`flow-state set
stage=inline`) and say so.

**4. One writer per working tree, ever** — parallel dispatch is for read-only
agents (exploration, review, independent diagnosis), issued in one response.
Two agents writing in one tree collide on the index and the lock. Nothing
enforces this one, so it is on you.

**5. The project's living spec is context in and output out** (CLAUDE.md rule
6): read it before asking anything; the decision goes in at the design gate, the
state sections via the plan's last task (writing-plans). Nothing enforces this
one either, and it is the rule most likely to lapse.

## The Pipeline

| # | Stage | Skill | State when the stage completes | Output | User gate |
|---|-------|-------|----------------|--------|-----------|
| 0 | Bootstrap — **once per project**, only when it has no living spec | writing-specs | — (no run state; this is not a code change) | `spec.md` interviewed into existence and committed | ✋ review the spec |
| 1 | Understand + design | brainstorming (grill-gate embedded) | `stage=design spec=<living spec.md>` | decision recorded in the project's living spec + deliberation record in `.flow/specs/`, one commit | ✋ approve design (the written record is shown again at the plan gate) |
| 2 | Plan | writing-plans (red-team on non-trivial plans) | `stage=plan plan=<path>` | plan of 2-5 min tasks with TDD steps → `.flow/plans/` | ✋ approve plan ("go") |
| 3 | Isolate | using-git-worktrees | `stage=isolate worktree= branch= base=` | worktree + clean test baseline | — |
| 4 | Implement | subagent-driven-development | `stage=implement`, plus a ledger entry per task | fresh implementer per task (strict TDD), per-task review, fix loop, final whole-branch review | — |
| 5 | Finish | finishing-a-development-branch | `stage=finish` | full suite green, then merge / PR / cleanup | ✋ pick integration option |

**Always-on discipline** — fires whenever its trigger matches, at any stage:
test-driven-development (before implementation code), systematic-debugging
(any bug or unexpected behavior), receiving-code-review (acting on feedback).
Evidence before any "done / passing / fixed" claim is CLAUDE.md's rule 4, not a
skill: name the command that proves it, run it, quote the output.

## Model & effort per stage

Session default is **Sonnet 5 · xhigh** (`settings.json` → `modelSettings`) — the
baseline for every stage you run **inline**. Escalate to **Opus 5.5 · xhigh**
only for a stage that is genuinely complex or demanding (a hard design call, a gnarly debug, a plan with many
interacting parts), not as the default cost of doing design or planning at all.
Ten review rounds and a milestone eating a full day in real runs were partly a
symptom of running everything at maximum depth by default instead of reserving
it for what actually needed it.

**Dispatched roles carry their own model and effort** in their definition under
`~/.claude/agents/` — that is where per-role thinking depth lives, since the
Agent tool call itself takes `model` but no effort. Pass `model:` on a dispatch
only to override the definition for one case.

| Role | Where it is set | Default |
|---|---|---|
| Brainstorm / grill / planning / debugging (inline) | session | Sonnet 5 · xhigh (Opus 5.5 · xhigh for a genuinely hard case) |
| `implementer` | agent definition | Haiku 4.5, no effort setting (override to Sonnet 5 for a genuinely hard task) |
| `fixer` | agent definition | Sonnet 5 · high (override to Opus 5.5 for one genuinely hard task) |
| `task-reviewer` | agent definition | Sonnet 5 · high (override to Opus 5.5 for non-trivial / security / concurrency) |
| `branch-reviewer` | agent definition | Opus 5.5 · high |
| `plan-red-team` | agent definition | Opus 5.5 · xhigh |
| Read-only exploration (`Explore`) | dispatch | Haiku 4.5 |
| Finish (tests, git, diff summary) | inline or Haiku 4.5 | — |

Keep a reviewer at least as strong as what it reviews: a reviewer weaker than the
code it judges rubber-stamps it. The reviewers' definitions also withhold
Edit/Write, so read-only is enforced by the harness rather than asked for in
prose — a reviewer that can fix things stops reporting them.

## Rules

- **Run continuously between gates.** The approved plan is the instruction.
  Stop only on: a user gate, a BLOCKED task you cannot resolve, or ambiguity
  the spec does not settle.
- **Escalation contract.** Ambiguity outside the spec → stop and ask. A fact
  you can look up — a SHA, a branch's real state, an API's actual shape, a
  test's actual output, existing pattern — never gets reconstructed from memory
  or assumption; check it with a tool call before you write it down or act on
  it. `git cat-file -t <sha>` costs a second and is the difference between
  "this session made it up" and "this session read the wrong state" — a hash
  written down before it was read has, in a real run, turned out not to exist.
- **Code discipline.** Simplicity, surgical changes, no guessing — CLAUDE.md.

## Triage — does this even need the pipeline?

**Small, with one decision → the small lane.** ALL of: one or two files, a
single real decision you can state in one sentence, one test covers it,
reversible, no new abstraction, nothing security- or data-sensitive. A different
error message, a changed default timeout, one flag on an existing command. See
The Small Lane below.

**Everything else → stage 1.** Several decisions, an unclear shape, a contract
other code depends on, anything security- or data-sensitive, or a bundle of
"trivial" edits that together shift behavior. A small feature with a contract
(say, a `--json` flag with output guarantees) belongs here, scaled down.

The bypass is for changes whose correctness is self-evident, not for work you
would rather not process. A triaged-out change still gets candor, and still gets
run and shown to work before you call it done.

**A trivial change that arrives mid-run is not a bypass.** With a run open at
`stage=implement`, the guard denies your edit — correctly, because the run owns
the tree. Either park it until the run finishes, or dispatch a one-line
implementer for it. Never `flow-state set stage=inline`: that switches
enforcement off for the *real* run to squeeze in an unrelated edit.

A change that enters at stage 1 but is small scales each stage *down*: the
design is a sentence, the grill stays silent, the plan may be one task,
red-team is skipped. Scale the ceremony, not the gates — once in the pipeline,
the ✋ gates stay.

## The Small Lane

For a change with exactly one decision in it, the full pipeline costs two
committed documents, three dispatches and three gates — more process than the
change. This lane keeps what catches mistakes (an approved decision, a test
first, one independent review, a green suite) and drops what only documents
them.

1. **State the decision in one sentence and get one ✋ approval.** "Default
   timeout goes 30s → 10s; callers that relied on 30 get it explicitly." No
   deliberation record, no approaches — if you cannot put the decision in a
   sentence, this is not the small lane. If the project has a living spec and
   this decision belongs in its decision table, add the row now, at the gate —
   one line, and the lane's whole point is that one line is the documentation.
2. **Open the run with a `small/` slug**, so the lane is visible after
   compaction and in every guard message:
   `~/.claude/hooks/flow-state init small/<slug>`.
3. **Write the approved decision as a one-task brief** to
   `.flow/plans/YYYY-MM-DD-<slug>-small.md`, using writing-plans' task shape
   (`## Global Constraints` if the project has any, then `### Task 1: <name>`
   with the files, the failing test, and the change). Commit it and record it as
   the plan. One artifact instead of two, and the normal `task-brief` works
   unchanged.
4. **Isolate** (using-git-worktrees) — but the baseline is the tests covering
   what you are touching, not the whole suite. The full suite runs at finish,
   which is where it decides anything.
5. **One implementer, one review** (subagent-driven-development, single task).
   Skip the whole-branch review: with one task, the task review already saw the
   whole branch.
6. **Finish** (finishing-a-development-branch) — full suite, then the options.

Two dispatches, two gates, one artifact. If the work turns out to have a second
decision in it, stop and go to stage 1 — that is the signal, not an
inconvenience.
