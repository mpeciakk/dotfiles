---
name: executing-plans
description: Use when executing an approved plan task by task, or resuming a run ("go", "execute the plan", "next task", "kontynuuj", after /clear or compaction).
---

# Executing Plans

Work an approved plan one task at a time, yourself, in the run's worktree;
then one review of the whole branch.

## Your role

You write the task code. A subagent handed the same task loses what you know
and re-reads the files you already read; it does not build it better.
Subagents are for independent read-only work in parallel, output you only need
the gist of, and review. None of them writes in this tree.

## Before Task 1

1. A workspace with a green baseline: using-git-worktrees. Ledger entry `0:
   done` means it is already there.
2. `~/.claude/hooks/flow-state set stage=implement`.
3. Resuming: `flow-state show` and `git log` over recollection. Tasks marked
   done are done — start at the first one that is not. If your cwd is not the
   recorded worktree, `EnterWorktree` with `path` first.

## Per task

1. **Record:** `~/.claude/hooks/flow-state task N started`.
2. **Read** the task — Outcome, Acceptance, Area, Context — and everything
   above the first task in the plan: its Decisions and Constraints bind every
   task. Then the Area's code, by range.
3. **Build** it in the task's Area. Tests per CLAUDE.md "Before writing" and
   [writing-good-tests.md](writing-good-tests.md);
   anything unexpected per systematic-debugging.
4. **Verify:** the task's tests and the project suite, run, output shown.
5. **Commit** on the branch, then record the range from `git log`:
   `flow-state task N done "<base7>..<head7>"`. After the run's first done,
   if the repo has a remote, `git push -u origin <branch>`: a lost worktree
   takes unpushed branch commits with it, and nothing can recover them.
6. **Context check.** A hook on `flow-state task … done` reports when the
   session is above 300k tokens. When it does, stop and ask the user for
   `/clear`, then "kontynuuj": the ledger resumes the run at the next task, and
   `/clear` costs nothing where a compaction is itself a large request.

Then the next task, without checking in.

**Plan conflict** — the task shows the plan is wrong:

- Reversible and inside the plan's scope (a name, an approach, an edge case
  the plan got wrong): rule on it yourself. Append `- Task N: <ruling> —
  <why> — <cost if wrong>` to a `## Rulings` section at the end of the plan's
  copy in the worktree (`<worktree>/.flow/plans/<plan basename>`, not the
  main-checkout path `flow-state get plan` returns) and commit it with the
  task. The user sees every ruling at finish.
- It changes the scope or a spec decision, or is irreversible (data, external
  side effects, security): the user's call. Show the plan line and the
  evidence.

Stop only for a conflict that is the user's call, a blocker you cannot
resolve (`flow-state task N blocked "<why>"`, then the user), the context
check, or the end of the plan.

## After the last task

1. **Spec state.** Bring the living spec up to date (`flow-state get spec`).
   The decision rows went in at the plan gate; the sections describing state —
   architecture, data model, API, documented behaviour — change now, for every
   section this branch made untrue. Cite code by path and symbol, commit on
   the branch. Nothing touched the spec's claims: say so in one line.
2. **Branch review:** requesting-code-review. Pass it the plan path, `base`
   from the run state, HEAD, and the spec sections you updated. Act on it per
   that skill — each round goes into the ledger — then record the review
   closed:

```bash
~/.claude/hooks/flow-state task branch-review done "<base7>..<head7>"
```

Then finishing-a-development-branch.

## Never

- Let a subagent write in the run's tree.
- Redo a task the ledger marks done.
- Skip the branch review.
