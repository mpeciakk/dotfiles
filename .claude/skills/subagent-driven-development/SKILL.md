---
name: subagent-driven-development
description: Use when executing an approved plan task by task — one fresh implementer subagent per task, then one whole-branch review. Triggers on "go", "execute the plan", "next task", "kontynuuj", and on resuming a run after compaction.
---

# Subagent-Driven Development

Execute an approved plan one task at a time: a fresh implementer per task,
then one review of the whole branch.

## Your role

You coordinate. Implementers write the task code, so your context stays small
enough to talk in for the whole run. You may edit yourself — a spec section, a
one-line fix, a finding cheaper to fix than to explain — but only while no
implementer is in flight: one writer per working tree. Commit what you changed
before the next dispatch; an implementer stops on changes it did not make.

**After a dispatch, the turn ends.** The harness wakes you with a
`<task-notification>`. Do not poll with `ScheduleWakeup` or `ListAgents`.

## Before Task 1

1. A workspace with a green baseline: using-git-worktrees. Ledger entry `0:
   done` means it is already there.
2. `~/.claude/hooks/flow-state set stage=implement plan=<absolute plan path>`.
3. Resuming: `flow-state show`. Tasks marked done are done — start at the
   first one that is not.

## Per task

1. **Brief:** `~/.claude/skills/subagent-driven-development/scripts/task-brief N`
   prints the brief's path — the task's text plus everything above the first
   task in the plan.
2. **Record:** `~/.claude/hooks/flow-state task N started`.
3. **Dispatch** `subagent_type: "implementer"`, `run_in_background: true`.
   The prompt carries: task number and name; worktree and branch (`flow-state
   get worktree` / `get branch`); the brief path; the report path (brief name
   with `report` for `brief`); anything from earlier tasks the brief cannot
   know. Never session history, never the whole plan.
4. **Read the status:**
   - **DONE** — the reply names commits and a passing test run. Check the
     commits exist (`git log`), then record:
     `flow-state task N done "<base7>..<head7>"`. Next task.
   - **DONE_WITH_CONCERNS** — read them. A correctness or scope concern gets
     resolved before the next task; an observation goes to the branch review.
   - **NEEDS_CONTEXT** — supply it, re-dispatch.
   - **BLOCKED** — change something first: more context, a smaller slice,
     Opus, or the user if the plan itself is wrong.
   - **Plan conflict** — the implementer shows the plan is wrong.
     - Reversible and inside the plan's scope (a name, an approach, an edge
       case the plan got wrong): rule on it yourself. Append
       `- Task N: <ruling> — <why> — <cost if wrong>` to a `## Rulings`
       section at the end of the plan's copy in the worktree
       (`<worktree>/.flow/plans/<plan basename>`, not the main-checkout path
       `flow-state get plan` returns), commit it on the branch, carry on, and tell later
       implementers what it changes for them. The user sees every ruling at
       finish.
     - It changes the scope or a spec decision, or is irreversible (data,
       external side effects, security): the user's call. Show the plan line
       and the evidence.

Do not check in between tasks. Stop only for BLOCKED you cannot resolve,
ambiguity the plan does not settle, or the end of the plan.

## After the last task

1. **Spec state.** Bring the living spec up to date (`flow-state get spec`).
   The decision rows went in at the plan gate; the sections describing state —
   architecture, data model, API, documented behaviour — change now, for every
   section this branch made untrue. You hold the whole change and no
   implementer is in flight: edit them yourself, cite code by path and symbol,
   commit on the branch. Nothing touched the spec's claims: say so in one line.
2. **Branch review:** requesting-code-review. Pass it the plan path, `base`
   from the run state, HEAD, the spec sections you updated, and any concerns
   implementers raised. Act on it per that skill, then record:

```bash
~/.claude/hooks/flow-state task branch-review done "<base7>..<head7>"
```

Then finishing-a-development-branch.

## Never

- Two writers in one tree — you included, while an implementer runs.
- `isolation: "worktree"` on a writer: its commits never reach this branch.
- Re-dispatch a task the ledger marks done.
- Skip the branch review.
