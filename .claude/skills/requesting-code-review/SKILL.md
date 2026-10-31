---
name: requesting-code-review
description: Use when you want a fresh reviewer on completed work — "review my changes", "code review this", "review the branch", before merging to main, for the branch review at the end of executing-plans, and for inline work that changes behaviour across modules or touches a spec decision.
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
  scenario that shows inline work working).

## 3. Act on it

Evaluate findings with receiving-code-review before acting on them.

**At most 3 rounds.** Round 1 reviews the whole change; a later round reviews
only the new diff. In a run, record each round once its fixes are committed —
a round marked done with findings still open is lost on `/clear`:
`flow-state task branch-review-<n> done "<fix range>"`. Critical findings
still open after round 3 go to the user, with the reviewer's case and what
you tried — no fourth round.

- **Critical or Important:** fix them yourself and commit. After a fix to a
  Critical finding, the next round re-reviews only the fix range (`<pre-fix HEAD>..HEAD`, or the same
  BASE with `--worktree` while inline work is uncommitted): a
  `branch-reviewer` whose requirements are the findings list, not the plan.
- **Minor you keep:** fix them with the rest; no re-review.
- **Minor you drop:** say which and why in one line.
- **Declined to judge:** rule on each line — in scope (treat it as a finding)
  or not (one line why).
- **A finding that contradicts the plan:** as a plan conflict in
  executing-plans — a reversible in-scope ruling is yours,
  logged under `## Rulings` in the plan's branch copy; scope, a spec decision or anything irreversible
  is the user's call.
