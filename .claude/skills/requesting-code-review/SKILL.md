---
name: requesting-code-review
description: Use when you want a fresh reviewer on completed work — "review my changes", "code review this", "review the branch", before merging to main, for the branch review at the end of subagent-driven-development, and for inline work that changes behaviour across modules or touches a spec decision.
---

# Requesting Code Review

A reviewer subagent with no session history judges the work, not your
reasoning about it, and your context stays free.

## 1. Bound the change

BASE is where the work began:

- a run: `~/.claude/hooks/flow-state get base`;
- a branch: `git merge-base HEAD main` (or `master`);
- inline work on main: the HEAD you noted before the first edit. Not noted:
  the parent of the change's first commit, from `git log`.

`HEAD~1` only when the change is exactly one commit. If none of these
resolves, ask where the work began.

HEAD is the last commit — or `--worktree` while the change is not all
committed: the package then runs from BASE to the working tree, untracked
files included. Size it: `git diff --shortstat BASE` (working tree) or
`git diff --shortstat BASE HEAD`.

## 2. Dispatch

`subagent_type: "branch-reviewer"`, `run_in_background: true`, then end the
turn. The prompt carries:

- what was built and the requirements (plan path, or a few lines for inline
  work);
- the living spec path and the decisions the change touches;
- BASE and HEAD (or `--worktree`);
- the verification to run (the plan's Verification section, or the command or
  scenario that shows inline work working);
- concerns implementers raised, as their own block.

## 3. Act on it

Evaluate findings with receiving-code-review before acting on them.

- **Critical or Important:** one implementer dispatch with the complete list
  (file:line each), the plan path, and the report path
  `.flow/sdd/<plan basename>/branch-review-report.md` (created if absent;
  outside a run, any path under `.flow/sdd/`). After a
  fix to a Critical finding, re-review only the fix range
  (`<pre-fix HEAD>..HEAD`): a `branch-reviewer` whose requirements are the
  findings list, not the plan.
- **Minor you keep:** fix them yourself or in the same dispatch; no re-review.
- **Minor you drop:** say which and why in one line.
- **A finding that contradicts the plan:** the user's call.

Small fixes you may make yourself — no implementer is in flight at this point.
