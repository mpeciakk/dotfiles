# Claude Code — workflow & skills

A personal, trimmed adaptation of [obra/superpowers](https://github.com/obra/superpowers):
inline work by default, a planned run for changes that need one, always-on
discipline (candor, verification).

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
| 3 | Implement — the session works each task (a domain of the change) in the worktree | `executing-plans` | — |
| 4 | Review — spec state sections first, then the whole branch: tests, real verification, spec | `requesting-code-review` | — |
| 5 | Finish — suite unless the review's run still holds, merge | `finishing-a-development-branch` | ✋ merge / PR / keep / discard |

Run state lives in `flow-state`, so "kontynuuj" in a fresh session resumes at
the first task not done. `.flow/` commits `plans/`, `specs/`, `design/`,
`probes/` and `reviews/`; `run/` (run state, review packages) is ignored.

**Always-on discipline:** `test-driven-development`, `systematic-debugging`,
`receiving-code-review`. `CLAUDE.md` → "Rules" holds the code rules (from
[karpathy-guidelines](https://github.com/multica-ai/andrej-karpathy-skills) and
[ponytail](https://github.com/dietrichgebert/ponytail)), candor, and response
shape (from [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd)).

**Outside the flow:** `writing-specs` establishes a project's living spec;
`knowledge-transfer` packages handovers, reviewed by the `kt-cold-reader`
agent.

## Model & effort

Roles carry their model in `agents/`: branch-reviewer **Opus 5.5 · high**,
plan-red-team **Opus 5.5 · high**, kt-cold-reader **Sonnet 5.5 · medium**. The
session runs on the model you start it with and implements the tasks itself.

Why it looks like this: `.flow/specs/2026-10-10-lean-workflow-design.md`
(rollback tag `workflow-v1`), then `.flow/plans/2026-10-31-lean-workflow-v2.md`
(rollback tag `workflow-v2-pre`).

## Code navigation

Grep and Read by range. The codebase-memory graph and the Haiku `explorer` agent
were removed on 2026-10-25: two weeks of transcripts showed no graph query and two
explorer calls (`.flow/specs/2026-10-25-lean-workflow-measurement/report.md`).

## How this differs from obra/superpowers

- **Inline by default** — a run is opened deliberately, not for every change.
- **One plan document, one design gate**; tasks are domains with outcomes and
  acceptance criteria, not pre-written code.
- **No per-task review** — one stronger branch review that runs the tests and
  the change's real verification and checks spec decisions.
- **Grep-based caller check in the branch review**, **candor ruleset**,
  **red-team pre-mortem**.

## Testing

Discipline skills are pressure-tested per
`skills/writing-skills/testing-skills-with-subagents.md` (baseline vs treatment,
manual read). The flow is smoke-tested end-to-end mechanically before use.
