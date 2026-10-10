# Lean workflow (2026-10-10)

The dotfiles have no living `spec.md`, so this record carries the decisions as
well as the deliberation. Session on `pc`, analysis in conversation with a
second opinion from Codex (three reviews pasted by the user).

## Problem

The setup was tuned for three months on cost (context size, cache reads,
review rubric) and never measured whether development got better. Evidence
gathered 2026-10-10:

- harmonia since 09-01: 598 commits, 327 (55%) touch only `.flow/`, `spec.md`
  or `docs/`; `.flow` is 5.8 MB. Plans: median 494 lines, max 2884 —
  the bulk is full test code.
- Subagents since 09-01, all projects: 807 implementers, 748 task-reviewers,
  253 fixers, 95 branch-reviewers, 108 red-teams.
- The race that mattered in harmonia (`inactive` before `session_error`,
  fixed in 2cb939b) was found by the **branch** review, not a task review.
- The critical taste-profile bug came from 347297e, a 1160-line Codex commit
  made outside any pipeline; a Claude audit on real data caught it together
  with six silently reversed spec decisions. Free work without a final
  review is not safe either.
- Before 09-27 roughly 57% of first-review Important findings were TDD
  evidence or docs drift, not code defects.
- Codex: hard routing of every change through the pipeline, the controller
  edit ban, plans that pre-write the code, and per-task review against a
  brief are method imposed on the model rather than knowledge it lacks;
  timings after the 10-03 trim (22–86 min per refactor part) show execution
  itself is not slow.

## L1 — Default is inline; a run is opened deliberately

**Chosen:** triage lives in `CLAUDE.md`. Inline when the change sits in one
domain and fits one sitting; a single decision for the user is a question
asked inline, not a reason for a run. Otherwise a run (development-workflow).
Inline work that changes behaviour across modules or touches a spec decision
gets a `branch-reviewer` before it lands on main; its BASE is the HEAD noted
before the first edit, and `review-package BASE --worktree` covers work not
yet committed.

**Rejected:** keeping `development-workflow` as the mandatory entry for every
code task (the cost the user feels); a plain "lean mode" layered on top
(user: not enough, the workflow itself needs cutting); no review at all for
inline work (347297e).

## L2 — The small lane goes

**Chosen:** one-decision changes are inline.
**Rejected:** keeping the lane — two dispatches, two gates and a worktree for
one decision cost more than they caught (user: it got in the way more than it
helped).

## L3 — Design and plan are one document with one gate

**Chosen:** brainstorming is folded into writing-plans. The plan holds the
change's decisions (chosen + rejected, one line each), tasks, and the final
verification scenario. The decision row still lands in the living spec at the
gate. Target 100–250 lines; above ~300 the plan is first cut back to what an
implementer cannot decide, and only a scope that is still too big is split. No separate
`.flow/specs/*-design.md` per run. The `/clear` + `/model` ritual between
design and execution goes.

**Rejected:** two documents and two gates (the design was shown twice);
putting general project assumptions in the plan (they belong to the living
spec — a plan that copies them grows into the size problem).

## L4 — Tasks are a domain of the change, briefs carry outcomes, not code

**Chosen:** a task is one domain of this change with a checkable result and a
clean resume point (e.g. "session core: status contract + events, session
tests green"). The plan gives outcome, acceptance criteria, area and context;
the implementer writes the tests. Exact values stay in the plan only when they
are the user's decision (public names, formats, external API shapes). Default
implementer model is Sonnet 5.5; the Haiku override for paste-ready briefs
goes with paste-ready briefs.

**Rejected:** 2–5 minute steps and full test code in the plan (needed for
weaker implementers; with Claude 5.5 models it freezes untested code into the
plan and is what makes plans 500–2900 lines).

## L5 — Subagent per task and run state stay

**Chosen:** one implementer per task in the background, run state and ledger
via `flow-state` so "kontynuuj" resumes. Reason (user): the main session stays
small enough to talk to without compaction, and less cached context per
message is lower usage. Worktree stays the default.

## L6 — Per-task review and the fixer go; the branch review gets stronger

**Chosen:** no task-reviewer and no fixer agent. The branch reviewer runs the
suite and the plan's verification scenario, checks the spec decisions the
branch touches and the state sections updated before it, and looks at seams
between tasks. One reviewer per branch: parallel reviewers would share the
package path and the test workspace. Fixes go to one implementer dispatch with
the full finding list; Critical fixes get a focused re-review of the fix range.

The suite runs where it adds information: an implementer runs it once per code
task (with no per-task review it is the only regression check between tasks),
the branch reviewer once on the final code. Docs-only work gets a content and
link check instead; a fix range gets the tests of its area; finish reuses the
reviewer's run while HEAD has not moved; after a fast-forward merge nothing
reruns.

**Rejected:** a single full-suite run per branch (Codex/Astra) — a regression
from task 1 would surface only after the last task, far from the code that
made it.

**Rejected:** keeping per-task review on an Opus trigger list (most of its
output was process compliance; the finding that mattered came from the branch
review).

## L7 — The controller may edit; one writer still holds

**Chosen:** `flow-guard` drops the controller edit ban and the fix-round
counter. It keeps the wakeup-polling denial, the second-worktree denial and
the run-state file protection. The controller edits only when no implementer
is in flight (spec sync at finish, one-line fixes).

## L8 — Red-team stays

**Chosen:** default for plans with two tasks or more (user: it found real gaps
every time). It now attacks decisions, sequencing and acceptance criteria, not
test code.

## L9 — `.flow/sdd` is scratch

**Chosen:** briefs and reports are ignored and die with the worktree. The
record of a run is the plan, the spec and the commits. `sdd-workspace` adds
`/.flow/sdd/` to `info/exclude`, so projects that track an older `.gitignore`
there do not show scratch as untracked.

## Measuring it

Rollback: tag `workflow-v1` on main before the merge. Check after two weeks of
use: `fix` commits to freshly merged code within 7 days, time from "go" to
ready to integrate (branch review green) with time spent waiting on the user
counted separately, the user's interventions during a run.

## After the Astra review (same day)

A review of the first draft (Codex, Astra 6) found five gaps, all fixed in L1,
L3, L6, L9 and the measurement above: inline review could not see uncommitted
work or commits on main; scratch stayed visible in older projects; the suite
ran up to four times; parallel reviewers shared a workspace; the spec's state
sections were updated after the only review. Its point on the suite was taken
in part (see L6).

## L10 — cbm where grep is worse; a Haiku explorer for broad questions

Measured on transcripts since 09-01: 212 cbm calls against ~25k grep/find
searches (0–3% by role; implementers 4 calls in 155 harmonia transcripts).
Per call a targeted grep returned less (median 1.0k chars, 0.3 s) than
`search_graph` (3.2k, 1.7 s); `trace_path` (0.4k) beats the rounds of greps a
caller search takes. The token sink is whole-file Reads of code (median 6.7k).

**Chosen:** grep and Read by default, code files read by range when not
edited; cbm `trace_path` for callers and blast radius (planning, the branch
reviewer for every changed public interface), `get_architecture` when
planning. A read-only `explorer` agent on Haiku answers broad "where / how is
X handled" questions for the main session with file:line only.

**Rejected:** a hook enforcing cbm (process on top of a tool that is not
cheaper per call); the explorer for implementers (a dispatch costs tens of
seconds against a 0.3 s grep, and branch-new code is not in the graph); the
built-in `Explore` agent (ran on Sonnet here).

## Cutover (after the wyspa-shell run is closed)

- Tag `workflow-v1`, merge, then `dotter deploy`: dotter links files one by
  one, so new files need a deploy and removed ones leave dangling links —
  `~/.claude/agents/{task-reviewer,fixer}.md`,
  `~/.claude/skills/brainstorming/*`.
- Memory `plan-granularity-experiment.md` ("kept: middle-variant plans")
  becomes false; update it.
- Tell the vault session (CLAUDE.md cross-session rule): pointer to this file.
