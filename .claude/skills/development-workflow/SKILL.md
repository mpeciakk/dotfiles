---
name: development-workflow
description: Use at the very start of any feature, bugfix, refactor, or other code change — before brainstorming, planning, or writing any code.
---

# Development Workflow

The end-to-end pipeline for every code change. This is the map — each stage
invokes its own skill; read that skill when you reach the stage, don't
reimplement it here. Run continuously between the marked user gates (✋);
never pause to ask "should I continue?".

**REQUIRED BACKGROUND:** using-superpowers — the rule that you
invoke a relevant skill before acting, including before clarifying questions.

## The Pipeline

| # | Stage | Skill | Output | User gate |
|---|-------|-------|--------|-----------|
| 1 | Understand + design | brainstorming (grill-gate is embedded) | spec → `.flow/specs/` + commit | ✋ approve design, then review written spec |
| 2 | Plan | writing-plans (red-team pre-mortem on non-trivial plans) | plan of 2-5 min tasks with TDD steps → `.flow/plans/` | ✋ approve plan ("go") |
| 3 | Isolate | using-git-worktrees | worktree + clean test baseline | — |
| 4 | Implement | subagent-driven-development | fresh implementer per task (strict TDD), per-task review (spec + quality), fix loop, then broad whole-branch review | — |
| 5 | Finish | finishing-a-development-branch | full suite green, then merge / PR / cleanup | ✋ pick integration option |

**Always-on discipline skills** — fire whenever their trigger matches, at any stage:
- test-driven-development — before any implementation code
- systematic-debugging — any bug, test failure, or unexpected behavior
- verification-before-completion — before any "done / passing / fixed" claim
- receiving-code-review — when acting on review feedback

## Model & effort per stage

Session default is **Sonnet 5**. Two different levers: the thinking stages you run **inline** (brainstorm, planning, debugging) use your **manual** session model+effort switch — bump the session to Opus 4.8 / xhigh for them. **Dispatched subagents** (implementer, reviewer, fix) get their model set explicitly in the dispatch (omitting it inherits the session default).

| Stage / role | Model | Effort |
|---|---|---|
| Brainstorm / grill / planning | Opus 4.8 | xhigh |
| Debugging (systematic-debugging) | Opus 4.8 | xhigh |
| Read-only code exploration (Explore agent) | Haiku 4.5 | — |
| Implementer subagent (per task, TDD) | Sonnet 5 · Haiku if the task text is complete code · Opus for one genuinely hard task | high |
| Task reviewer subagent (spec + quality, one agent) | Sonnet 5 for small/mechanical diffs · Opus 4.8 for non-trivial / security / concurrency | high |
| Fix subagent | Sonnet 5 · escalate to Opus 4.8 if a fix keeps failing | high |
| Final whole-branch review | Opus 4.8 | high |
| Finish (tests, git, diff summary) | Haiku 4.5 | — |

**Why:** reasoning-heavy stages (design, debugging, final/critical review) earn Opus — errors there cascade. Implementation and fixes are the Sonnet workhorse. Mechanical / discovery work goes to Haiku. The reviewer should be at least as strong as the implementer, so a non-trivial diff pushes the reviewer to Opus.

## Rules

- **Run continuously between gates.** The approved plan is the instruction — don't check in between tasks. Stop only on: a user gate, a BLOCKED task you can't resolve, or ambiguity the spec doesn't settle.
- **Escalation contract.** Ambiguity outside the spec → STOP and ask the user. A fact you can look up (test runner, existing pattern, API shape) → look it up, never ask.
- **Model & effort.** See the table above — inline thinking stages are your manual session lever (Opus 4.8 / xhigh); subagents get their model at dispatch.
- **Code discipline.** Simplicity, surgical changes, no guessing — see CLAUDE.md and the karpathy-guidelines skill.

## Triage first — does this even need the pipeline?

Not every change earns the pipeline. Before stage 1, classify the request:

**Trivial → just do it.** Make the edit directly, verify it, done — no brainstorming, spec, plan, worktree, or subagent. Trivial means ALL of: one obviously-correct outcome (no design choice), mechanical, low blast-radius, reversible, and no behavior/logic change you'd want a test for. Examples: a config value or toggle, a style token / color, a typo or copy fix, a `.gitignore` or dependency-manifest entry, a version bump, a mechanical rename.

**Everything else → enter the pipeline at stage 1.** Any design choice, any behavior or logic change, anything ambiguous, anything security- or data-sensitive, anything you'd want a test for, or a bundle of "trivial" edits that together shift behavior. A small feature (e.g. adding a `--json` flag) is NOT trivial — it has choices and a contract; it takes the pipeline, scaled down.

**When in doubt, it's not trivial — enter the pipeline.** The bypass is for changes whose correctness is self-evident, not for work you'd rather not process.

The always-on discipline still applies to a triaged-out change: candor, and verification-before-completion (verify the edit did what was asked before claiming done).

## Scale to the work (inside the pipeline)

A change that enters the pipeline but is small scales each stage *down* — design is a sentence, the grill stays silent (see brainstorming/grill-gate.md), the plan may be one task, red-team is skipped. Scale the ceremony, not the gates: once in the pipeline, the ✋ gates stay.
