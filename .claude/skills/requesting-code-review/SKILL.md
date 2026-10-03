---
name: requesting-code-review
description: Use when you want a fresh reviewer on completed work — "review my changes", "code review this", "review the branch", before merging to main, or for the whole-branch review at the end of subagent-driven-development. Per-task review inside a plan run is the task-reviewer agent, not this skill.
---

# Requesting Code Review

Dispatch a reviewer subagent to catch issues before they cascade. It gets
precisely crafted context — never your session history — so it judges the work
product rather than your thought process, and your own context stays free for
the work.

This template is for the **whole-branch review** at the end of
subagent-driven-development, and for ad-hoc reviews. Per-*task* review has its
own reviewer (`subagent_type: "task-reviewer"`).

Request one after a major feature, before merging to main, and when a fresh
perspective would help: stuck on something, about to refactor, just fixed a
subtle bug.

## How

**1. Bound the diff.** BASE is where the work under review began — the branch
fork point, or the commit you recorded before starting. Never `HEAD~1`: it
silently drops all but the last commit of multi-commit work.

```bash
~/.claude/hooks/flow-state get base      # the run records it
git rev-parse HEAD
```

If `get base` prints nothing, fall back to the fork point, as its own command:
`git merge-base HEAD main` (or `master`). Pass the printed SHAs on as BASE and
HEAD. If both fall through — a repo whose default branch is `trunk` or
`develop` — ask the user which branch this work forked from rather than
packaging an empty or oversized range.

**2. Dispatch** `subagent_type: "branch-reviewer"`. Its role, model and read-only
tool set live in `~/.claude/agents/branch-reviewer.md`, and it builds the diff
package itself, so your prompt carries only: what was built, the requirements
(plan or spec path), BASE and HEAD, and the run's deferred Minor findings **as
their own block** —
mixed into the requirements, a reviewer reads them as things the branch was
supposed to deliver and reports each unfixed one as a spec gap.

Dispatch with `run_in_background: true` (with `CLAUDE_CODE_FORK_SUBAGENT=0` the
parameter is back, and a foreground dispatch would block the session), then end
the turn and wait for the task notification — not for a wakeup you schedule
yourself. A branch review runs for minutes; polling it re-reads your whole
context every few minutes for nothing.

**3. Act on it.**

- *Before any fixer.* Record the pre-fix HEAD so a compaction cannot lose it:
  `~/.claude/hooks/flow-state task branch-review started "fixbase=HEAD"`.
  Outside a run, note it in your reply.
- *Critical or Important present.* Those findings, plus any Minor you decide to
  keep, go to ONE fix subagent with the complete list. Dispatch the re-review
  with BASE = the fix base and HEAD. The re-review covers only the fix range
  (`<fixbase>..HEAD`). It is a `task-reviewer` whose brief is the finding list,
  handed the fixer's report. That agent already has the re-review semantics. A
  branch-reviewer given a two-commit diff would report every planned
  requirement as missing. A second Needs fixes goes to the user — there is no
  second fix round. The fixer writes its evidence to
  `.flow/sdd/<run>/branch-review-report.md`.
- *Kept Minor findings only.* One fixer whose report shows the full suite
  green, with no re-review.
- *Minor findings you do not keep.* Record them; do not drop them silently.
- *Why.* 34 of 147 historical fixers ran after a branch review, and a
  full-branch re-review re-reads work that was already approved task by task.

If the reviewer is wrong, push back with the code or test that proves it —
but never pre-empt a finding by telling the reviewer what not to flag.
