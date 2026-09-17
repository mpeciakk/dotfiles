---
name: finishing-a-development-branch
description: Use when implementation is done and you need to wrap up a branch or worktree — merge, open a PR, keep it, or discard. Also when the final suite has not been run yet.
---

# Finishing a Development Branch

Verify tests → detect the workspace → present options → execute → clean up.

**Do not record `stage=finish` yet.** That stands the implement-phase guards
down, and a red suite in Step 1 is exactly when they should still be up and
fixes should still go to implementers. The stage gets recorded in Step 5, once
the user has picked what to do.

## Step 1 — tests green, on the real suite

Run the project's full suite. If anything fails, report the failures and stop:
merging red code or opening a failing PR costs more than the delay.

Then one question, which no test answers: **does the project's living spec still
describe reality?** `~/.claude/hooks/flow-state get spec` names it. Skim the
sections this branch touched. If one now describes the old behaviour, fix it
before the merge — you are the last person who holds the whole change in mind,
and this is the last moment the fix is cheap. Nothing enforces it; it is the step
most easily skipped and the one whose absence you feel weeks later.

**Archive the run's sdd reports before anything can delete them.** Task briefs,
implementer reports and reviewer verdicts live in `.flow/sdd/` — real prose that
does not exist anywhere else, unlike the diff packages there (`*.diff`), which
`git log`/`git diff` regenerate on demand and stay ignored. Commit the rest now,
while the worktree is still whole:

```bash
git add .flow/sdd
git commit -m "docs: archive sdd reports for $(basename "$(~/.claude/hooks/flow-state get plan)" .md)"
```

No-op if there is nothing to add. Skipping this is exactly how a real run lost
ten rounds of review findings: the reports sat gitignored inside the worktree,
and `git worktree remove --force` at Step 6 deleted them along with everything
else — the only things that survived were the living spec and whatever
conclusions got stuffed into code comments instead, which is not what comments
are for.

## Step 2 — what kind of workspace is this?

```bash
git rev-parse --git-dir --git-common-dir --show-toplevel
git branch --show-current
```

| State | Menu | Cleanup path |
|---|---|---|
| git-dir == git-common-dir (normal checkout) | 4 options | nothing to remove |
| worktree under `.claude/worktrees/` (created by `EnterWorktree`) | 4 options | `ExitWorktree` |
| worktree under `.worktrees/` or `worktrees/` (created by git) | 4 options | `git worktree remove` |
| worktree elsewhere, or detached HEAD | 3 options (no local merge) | leave it; the host owns it |

## Step 3 — base branch

`git merge-base HEAD main` (or `master`). If neither resolves, ask: "This
branch split from main — correct?"

## Step 4 — present the options, without commentary

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

Detached HEAD drops option 1 and offers: push as a new branch and open a PR /
keep as-is / discard.

## Step 5 — execute

Record the stage now — the merge itself must not be denied:

```bash
~/.claude/hooks/flow-state set stage=finish
```

**1. Merge locally.** Merge before removing anything — a failed merge with the
worktree already gone is unrecoverable work.

Check where you actually are first: `git rev-parse --show-toplevel` against
the recorded `worktree` (`flow-state get worktree`). Still inside a worktree
`EnterWorktree` created (Step 2's second row) → exit it before touching the
main checkout: `ExitWorktree` with `action: "keep"`, not `"remove"` — the
merge has not happened yet, and removing the branch now would make it
unrecoverable. A real run hit this directly: Bash from inside that session is
confined to the worktree, and a git operation aimed at the shared main
checkout was refused until the session left ("the isolation guard blocks git
operations on the shared checkout from inside the worktree — correctly"). A
worktree the session only `cd`'d into (Step 2's third row) carries no such
confinement — skip this if that's what you're in.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git checkout <base-branch> && git pull
git merge <feature-branch>
<test command>                     # verify the merged result, not just the branch
codebase-memory-mcp cli index_repository --repo-path "$MAIN_ROOT"
```

The reindex matters because the worktree's changes were never indexed while
isolated, so later work would query a stale graph. Then clean up the workspace
(Step 6) — the branch is still checked out in the worktree until it is gone, so
the order is merge, then remove the workspace, then deal with the branch.

**2. Push and open a PR.** `git push -u origin <feature-branch>`, then open the
PR. Keep the worktree: the user needs it to act on review feedback.

**3. Keep as-is.** Report the branch and worktree path. Change nothing.

**4. Discard.** List exactly what disappears — branch, commits, worktree path —
and require the user to type `discard`. Then clean up the workspace (Step 6).

## Step 6 — clean up the workspace

Only for options 1 and 4; options 2 and 3 always keep the worktree.

**Created by `EnterWorktree` (under `.claude/worktrees/`):** check where you are
first — `git rev-parse --show-toplevel` against the recorded `worktree`.

- **Still inside it** (discard, option 4 — nothing needed the main checkout):
  call `ExitWorktree` with `action: "remove"`. It deletes the worktree **and
  its branch**, and returns the session to its original directory — no
  separate `git branch -d` afterwards; running one errors with "branch not
  found".
- **Already back in the main checkout** (merge, option 1 — Step 5 required
  exiting with `action: "keep"` first to reach it): you already left this
  worktree once. Do not call `ExitWorktree` again expecting it to still track
  what you exited — fall straight to the git-based path below, using the
  worktree path you recorded before you left.

Two things the direct-removal call above will do that the naive reading does
not expect:

- It **refuses** to remove a worktree holding uncommitted files or commits not
  on the original branch, and returns the list. After a discard the user
  confirmed by typing `discard`, that leftover is scratch: re-invoke with
  `discard_changes: true`. Answering the refusal with `action: "keep"` instead
  leaves the worktree alive *and* blocks the branch delete — the
  lost-workspace failure, recreated at the last step.
- It only knows worktrees **it created in this session**. Two more states it
  cannot remove: a resumed run (it reports no active worktree session and
  changes nothing), and a worktree you re-entered with `path` — the tool's own
  contract says it will not remove that one. In every state where it does not
  apply, the removal is yours to do: the git path below. Do not report cleanup
  as done because the tool exited cleanly.

**Created by git, or from an earlier session (under `.worktrees/`,
`worktrees/`, `.claude/worktrees/`):** `cd` to the main root first. Removing a
worktree from inside it succeeds and leaves the session in a deleted directory,
after which every git call fails with "Unable to read current working
directory" — the recovery is another `cd`, but you will be debugging it blind.

```bash
git worktree remove --force "$WORKTREE_PATH"
git worktree prune
git branch -d <feature-branch>        # -D for a confirmed discard
```

`--force` is needed because test runs leave untracked artifacts, and by this
point they are scratch: the merge is verified or the discard is confirmed.

**Anywhere else:** the host environment owns it. Leave it alone.

Finally, end the run: `~/.claude/hooks/flow-state clear`.

## Never

- Record `stage=finish` before the user has picked an option — it disarms the
  guards, and a red suite is when they matter most.
- Offer options before the suite is green, or merge without re-running tests on
  the merged result.
- Remove a worktree before the merge succeeded, or remove one you did not
  create.
- Remove a worktree before `.flow/sdd` is committed (Step 1) — `--force`
  deletes it right along with the untracked test artifacts it is meant for.
- Delete the branch before removing the worktree that has it checked out.
- Discard without typed confirmation, or force-push unless asked.
