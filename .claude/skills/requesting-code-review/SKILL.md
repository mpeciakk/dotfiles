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
BASE_SHA=$(~/.claude/hooks/flow-state get base)          # the run records it
[ -n "$BASE_SHA" ] || BASE_SHA=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
HEAD_SHA=$(git rev-parse HEAD)
```

If both fall through — a repo whose default branch is `trunk` or `develop` —
ask the user which branch this work forked from rather than packaging an empty
or oversized range.

**2. Package the diff as a file**, so it never enters your context and the
reviewer reads it in one call:

```bash
PKG=$(~/.claude/skills/subagent-driven-development/scripts/review-package "$BASE_SHA" "$HEAD_SHA")
```

**3. Dispatch** `subagent_type: "branch-reviewer"`. Its role, model and read-only
tool set live in `~/.claude/agents/branch-reviewer.md`, so your prompt carries
only: what was built, the requirements (plan or spec path), BASE and HEAD, the
diff-package path, and the run's deferred Minor findings **as their own block** —
mixed into the requirements, a reviewer reads them as things the branch was
supposed to deliver and reports each unfixed one as a spec gap.

Then end the turn and wait for the notification — not for a wakeup you schedule
yourself. A branch review runs for minutes; polling it re-reads your whole
context every few minutes for nothing.

**4. Act on it.**

- *Before any fixer.* Record the pre-fix HEAD so a compaction cannot lose it:
  `flow-state task branch-review started "fixbase=$(git rev-parse --short HEAD)"`.
  Outside a run, note it in your reply.
- *Critical or Important present.* Those findings, plus any Minor you decide to
  keep, go to ONE fix subagent with the complete list. Package it with
  `review-package <fixbase> HEAD`. The re-review covers only the fix range
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
