---
name: subagent-driven-development
description: Use when executing an approved implementation plan task by task — one fresh implementer subagent per task, with a review between tasks. Triggers on "go", "execute the plan", "implement the plan", "next task", and on resuming a plan run after compaction. Applies whether the tasks are independent or sequential.
---

# Subagent-Driven Development

Execute an approved plan one task at a time: a fresh implementer subagent per
task, a review after each (spec compliance + code quality), a fix loop, then
one broad whole-branch review.

## Your role: controller, not implementer

**You do not write the code.** You construct exactly the context each subagent
needs and adjudicate what comes back. A fresh implementer working from a task
brief beats a controller carrying six tasks of history — and your context,
spent on edits, is no longer available for the cross-task decisions only you
can make. Once the run records a workspace, a PreToolUse hook denies Edit/Write
from the main thread; that is the rule, not an obstacle to route around — and
routing around it through Bash (`cat > file`, `sed -i`) trades a visible
handoff for an invisible one.

**One implementer at a time.** Two agents writing in one working tree fight
over the index and the lock. Parallel dispatch is for read-only agents only.

**Progress lives in the state file.** Compaction has made controllers
re-dispatch entire completed task sequences — the most expensive failure
observed in real sessions. After each clean review:

```bash
~/.claude/hooks/flow-state task N done "<base7>..<head7>, review clean"
```

At skill start, read `~/.claude/hooks/flow-state show`: tasks marked complete
are done. Resume at the first task that is not. After compaction, trust the
state file and `git log` over your recollection.

## Before Task 1

1. Ensure an isolated workspace with a clean baseline — invoke
   using-git-worktrees, and confirm `worktree`, `branch` and `base` are
   recorded. A ledger entry `0: complete` noting a green baseline means setup and
   the suite are already done; the `worktree` field alone does not, since it is
   recorded one step before the suite runs.
2. `~/.claude/hooks/flow-state set stage=implement plan="$PLAN"` — pass the plan
   path even when writing-plans already recorded it; a plan the user handed you
   was never recorded, and `implement` without one is refused.
   **Check your tree first:** if `git rev-parse --show-toplevel` is not the
   recorded `worktree`, re-enter it (`EnterWorktree` with `path`) before
   anything else. Every script below resolves against your cwd, so a resumed
   session sitting in the main checkout would brief, commit and review the
   wrong tree.
3. Read the plan; note its Global Constraints and the interfaces tasks share.
4. The ledger is the progress record — `flow-state task N ...` per task, shown
   live on the status line. If a todo tool is available in this session, mirror
   the plan into it as well; there is no reliable built-in one, so nothing
   depends on it.
5. **Pre-flight scan.** Read the plan once for tasks that contradict each other
   or the Global Constraints. Present what you find as one batched question,
   each finding beside the plan text, before execution starts — not one
   interrupt per discovery. If it is clean, proceed without comment.

## The per-task loop

1. **Brief.** The scripts live in this skill's directory, so call them by
   absolute path — your cwd is the worktree:

   ```bash
   SDD=~/.claude/skills/subagent-driven-development/scripts
   PLAN=$(~/.claude/hooks/flow-state get plan)
   BRIEF=$($SDD/task-brief "$PLAN" N)     # stdout is the path, nothing else
   ```

   The brief carries the task's full text plus the plan's Global Constraints,
   and it is the single source of requirements — exact values, magic strings,
   signatures and test cases live there and nowhere else.
2. **Record the base** before dispatching, in the ledger — a compaction between
   dispatch and review would otherwise lose it, and `HEAD~1` silently drops all
   but the last commit of a multi-commit task:

   ```bash
   BASE=$(git rev-parse HEAD)
   ~/.claude/hooks/flow-state task N started "base=$BASE"
   ```
3. **Dispatch the implementer** — `subagent_type: "implementer"`. See Dispatching
   below for what the prompt carries.
4. **Handle the status** (below).
5. **Review package.** `PKG=$($SDD/review-package "$BASE" HEAD)` writes the
   commit list, stat summary, and full diff with context to one file and prints
   its path. The diff never enters your context; the reviewer reads one file.
   If it exits with "no commits in BASE..HEAD", the implementer's commits are
   not in this tree — find them before reviewing rather than shipping an empty
   diff to a reviewer who will approve it.
6. **Dispatch the task reviewer** — `subagent_type: "task-reviewer"`, with
   `model: "opus"` for a non-trivial, security- or concurrency-touching diff.
   After a fix, re-package the same range (`BASE..HEAD`, not just the fix
   commits) so the re-review judges the task, not the patch.
7. **Fix loop.** Critical and Important findings go to ONE `fixer` dispatch with
   the complete list — per-finding fixers each rebuild context and re-run suites,
   which in a real session cost more than all its tasks combined. Its report
   must contain the covering tests, the command and the output before you
   re-dispatch the review. Minor findings go into the ledger note and get handed
   to the final review to triage.
8. **Record it.** `flow-state task N done ...`, mark the todo done, move on
   — without checking in. The approved plan is the instruction. Stop only for
   BLOCKED you cannot resolve, ambiguity the plan does not settle, or the end
   of the plan.

After the last task, run the whole-branch review — requesting-code-review owns
how to bound the diff and which template to fill; pass it the Minor findings you
accumulated. Skip it in one case only: a single-task run on development-workflow's
small lane (the run slug starts with `small/`), where the task review already
covered the entire branch. Two tasks or more, or any doubt: run it. Then record that the gate ran, because a compaction after the last
task otherwise leaves a state that looks finished when the branch was never
reviewed:

```bash
~/.claude/hooks/flow-state task branch-review done "<base7>..<head7>, findings triaged"
```

Then finishing-a-development-branch.

## Implementer status

**DONE** → generate the review package and review.

**DONE_WITH_CONCERNS** → read the concerns first. Correctness or scope
concerns get resolved before review; observations ("this file is getting
large") are noted and review proceeds.

**NEEDS_CONTEXT** → supply what was missing and re-dispatch.

**BLOCKED** → change something before retrying: more context, a stronger
model, a smaller slice of the task, or escalate to the user if the plan itself
is wrong. Never force the same model to retry unchanged, and never quietly
fix it yourself — that is the context pollution this skill avoids.

**⚠️ Cannot verify from diff** (from the reviewer) → requirements living in
unchanged code or spanning tasks. They do not block the rest of the review,
but you resolve each one before marking the task complete; you hold the
cross-task context the reviewer lacks. A confirmed gap is a failed spec review:
back to the implementer, then re-review.

**A finding that conflicts with what the plan mandates** → the user's call.
Present the finding and the plan text, ask which governs. Do not dismiss the
finding, and do not dispatch a fix that contradicts the plan.

## Dispatching

The roles live in `~/.claude/agents/` — `implementer`, `task-reviewer`, `fixer`,
`branch-reviewer`. Each definition carries its own system prompt, model, effort,
and tool restrictions, so you do not paste a role description into a prompt: the
reviewers cannot edit files at all (the harness withholds Edit/Write from them),
and the implementer and fixer get the test-driven-development skill preloaded.
Pass `model:` only to override a definition's default — e.g. `opus` for a
task-reviewer on a hard diff, or for one genuinely hard implementer task.

Your prompt supplies only what varies per dispatch:

| Role | The prompt carries |
|---|---|
| `implementer` | task number and name; the **worktree and branch** (`flow-state get worktree` / `get branch` — never `pwd`, which lies on a resumed session); the brief path; the report path; one line on where this task fits; interfaces and decisions from earlier tasks the brief cannot know; your resolution of any ambiguity you noticed |
| `task-reviewer` | brief path, implementer report path, diff-package path, BASE and HEAD, and the plan's Global Constraints copied verbatim |
| `fixer` | the worktree and branch; the verbatim finding list with file:line each; the brief path; the existing report path to append to |
| `branch-reviewer` | what was built, the requirements, the whole-branch diff-package path, and the run's deferred Minor findings as their own block |

If `flow-state get worktree` prints nothing, stop: the run has no workspace and
using-git-worktrees has not run. Do not dispatch into a workspace nobody recorded.

Never pass `isolation: "worktree"` to a writer. That hands it a *different*
working tree, and its commits never reach the branch you are building. The guard
denies it, but the dispatch is yours to get right.

### Hygiene

Everything you paste into a dispatch — and everything a subagent prints back —
stays in your context for the rest of the session and is re-read every turn. So
hand artifacts over as files:

- **The report file** is named after the brief (`task-N-brief.md` →
  `task-N-report.md`). Detail goes there; the subagent returns status, commits, a
  one-line test summary, and concerns. Fix dispatches append to the same file.
- **Never paste session history.** A real dispatch reached 42k characters of
  which 99% was accumulated prior-task summaries. A fresh subagent needs its
  task, the interfaces it touches, and the constraints. Nothing else. Pull exact
  signatures with cbm `get_code_snippet`/`search_graph` rather than reading files
  into your own context to quote them.
- **Never pre-judge a reviewer's findings.** If your prompt contains "do not
  flag", "at most Minor", or "the plan chose", stop — you are buying yourself out
  of a review loop. Let the reviewer raise it and adjudicate afterwards.

## Example

```
Task 2: Recovery modes
[task-brief → dispatch implementer (Sonnet 5) with brief + report paths + interfaces]
Implementer: DONE, added verify/repair modes, 8/8 passing, 2 commits.
[review-package a1b2c3d..e4f5g6h → dispatch task reviewer (Opus 5)]
Reviewer: Spec ❌ missing progress reporting; extra --json flag. Important: magic number 100.
[ONE fix subagent with all three findings]
Fixer: removed --json, added progress reporting, extracted PROGRESS_INTERVAL, 8/8 passing.
[re-review] Spec ✅, quality Approved.
[flow-state task 2 done "a1b2c3d..9f8e7d6, review clean"]
```

## Never

- Skip the task review, or accept a report missing either verdict.
- Move to the next task with unfixed Critical/Important findings, or skip the
  re-review after a fix.
- Dispatch a reviewer without a diff file, or hand a subagent the whole plan
  instead of its brief.
- Let implementer self-review stand in for review.
- Re-dispatch a task the state ledger already marks complete.
