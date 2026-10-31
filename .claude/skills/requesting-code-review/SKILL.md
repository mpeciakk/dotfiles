---
name: requesting-code-review
description: Use when you want a fresh reviewer on completed work — "review my changes", "code review this", "review the branch", before merging to main, for the branch review at the end of executing-plans, and for inline work that changes behaviour across modules or touches a spec decision. Also when acting on review feedback — from the branch reviewer, the user or a PR — before implementing it, especially when a finding seems unclear or wrong.
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

Findings are claims to verify, not orders. Tone is CLAUDE.md's Candor; this
section is how to process them — from branch-reviewer, the user, or an
external or PR reviewer alike.

- **Read all of it first.** If any item is unclear, implement nothing yet and
  ask about the unclear ones: items are often related, and a partial
  understanding gives a partial, wrong fix.
- **Verify each against the code:** does the problem exist here, is the fix
  right for this stack and these callers, is there a reason for the current
  form? A reviewer subagent read a diff; you hold the cross-task context it
  lacks. A suggestion from the user is where agreeing without checking is
  most tempting. Cannot verify: say what you would need ("I can't verify this
  without X — investigate, ask, or proceed?").
- **Scope is not the reviewer's to grant.** "Implement this properly" for
  something nothing calls → grep its callers; unused, propose removing it.
- **Push back** with the code or test that proves it when the suggestion
  breaks existing behaviour, adds an unused feature, is wrong for this stack,
  or conflicts with a decision the user made. An architectural or scope
  change goes to the user, with both sides.
- **Order of work:** unclear items, then blockers (breakage, security), then
  simple fixes, then complex ones. Work the whole list, then run the suite
  once and commit.
- **Reply** to a correct finding with "Fixed — <what, where>" or just the
  fix; to your own wrong pushback with "Checked X — it does Y. Fixing." On
  GitHub, reply to an inline comment in its thread
  (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
  top-level PR comment.

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
