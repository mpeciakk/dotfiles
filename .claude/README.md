# Claude Code — workflow & skills

A personal, trimmed adaptation of [obra/superpowers](https://github.com/obra/superpowers):
inline work by default, a planned run for changes that need one, always-on
discipline (candor, verification) and a codebase-memory navigation layer.

## The flow

**Default: inline.** Read what the change needs, make the smallest sensible
change, verify it. Inline work that changes behaviour across modules or
touches a spec decision gets a `branch-reviewer` before it lands on main.

**A run** (`development-workflow`) when the change spans several domains or
needs more than one sitting; a single decision for you is a question inline,
not a run (✋ = you decide):

| # | Stage | Skill | Gate |
|---|-------|-------|------|
| 1 | Plan — decisions + tasks in one document | `writing-plans` (+ red-team for 2+ tasks) | ✋ "go" |
| 2 | Isolate | `using-git-worktrees` | — |
| 3 | Implement — one implementer per task (a domain of the change), in the background | `subagent-driven-development` | — |
| 4 | Review — spec state sections first, then the whole branch: tests, real verification, spec | `requesting-code-review` | — |
| 5 | Finish — suite unless the review's run still holds, merge | `finishing-a-development-branch` | ✋ merge / PR / keep / discard |

Run state lives in `flow-state`, so "kontynuuj" in a fresh session resumes at
the first task not done. Plans → `.flow/plans/`; `.flow/sdd/` is scratch.

**Always-on discipline:** `test-driven-development`, `systematic-debugging`,
`receiving-code-review`. Candor, code discipline (Karpathy-style) and response
shape (adapted from [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd))
live in `CLAUDE.md`.

**Outside the flow:** `writing-specs` establishes a project's living spec;
`knowledge-transfer` packages handovers, reviewed by the `kt-cold-reader`
agent.

## Model & effort

Roles carry their model in `agents/`: implementer **Sonnet 5.5 · high**,
branch-reviewer **Opus 5.5 · high**, plan-red-team **Opus 5.5 · xhigh**. The
session runs on the model you start it with.

Why it looks like this: `.flow/specs/2026-10-10-lean-workflow-design.md`
(rollback tag `workflow-v1`).

## codebase-memory (cbm)

Code navigation uses the [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
graph **before** grep/find via Bash (`search_graph`, `trace_path`, `get_code_snippet`,
`get_architecture`), wired into planning, the implementer/reviewer
prompts, and debugging. The protocol itself lives in `CLAUDE.md` rule 2 (loaded
every session and after compaction). The graph indexes the main checkout, not
worktrees, so `finishing` re-indexes after merge.

## How this differs from obra/superpowers

- **Inline by default** — a run is opened deliberately, not for every change.
- **One plan document, one design gate**; tasks are domains with outcomes and
  acceptance criteria, not pre-written code.
- **No per-task review** — one stronger branch review that runs the tests and
  the change's real verification and checks spec decisions.
- **cbm navigation layer**, **candor ruleset**, **red-team pre-mortem**.
- **Localized** — `CLAUDE.md` and discipline notes in Polish.

## Testing

Discipline skills are pressure-tested per
`skills/writing-skills/testing-skills-with-subagents.md` (baseline vs treatment,
manual read). The flow is smoke-tested end-to-end mechanically before use.
