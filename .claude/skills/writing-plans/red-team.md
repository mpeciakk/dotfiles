# Red-Team Pass

A fresh subagent whose only job is to make the strongest possible case that the
plan is **wrong**, dispatched after self-review and before the user approves the
plan for execution.

**Why a fresh subagent:** the agent that wrote the plan has conversational
investment in it — it wants the plan to be good because it made it. A subagent
with no session history and an adversarial brief has no such pull, so it is
structurally harder for it to rubber-stamp. This is the anti-sycophancy lever
that a prompt alone can't provide.

## When to run

Run it **once per plan**, at the plan gate — never per task, never per decision.
It is a plan-level pre-mortem, not a running commentary on every choice.

**Skip it** when the plan is trivial: a single task, a pure-transcription plan
(the task text already contains the complete code), or a mechanical change any
competent engineer would build identically. A full pre-mortem on a one-line
change is noise. Run it when a multi-task plan makes real design or sequencing
choices; when in doubt on such a plan, run it.

## Dispatch

Dispatch a `general-purpose` subagent with the template below. Pin it to a
strong model (Opus 5) — a critic weaker than the planner tends to miss the
subtle structural problems.

```
Subagent (general-purpose):
  description: "Red-team an implementation plan"
  model: opus
  prompt: |
    You are a skeptical senior engineer doing a pre-mortem. Assume this plan
    ships as written and fails. Your job is to make the strongest possible case
    for WHY it fails — before a line of code is written.

    ## Scope

    Read-only. Do not edit the plan, the spec, or any file in the repository,
    and do not run tests or builds. Read the plan and the spec, read code only
    to check a specific claim, and report. Your final message IS the report.

    ## The Plan
    [PLAN_PATH]

    ## The Spec It Implements
    [SPEC_PATH]

    ## Attack surface — look hard for:
    - Hidden assumptions the plan treats as settled but aren't
    - Missing tasks: spec requirements no task covers
    - Wrong sequencing: task N depends on something task N+2 produces
    - Unhandled failure modes, edge cases, and error paths
    - Scope creep: tasks that build more than the spec asks for
    - Wrong abstraction or boundary — a seam drawn in the wrong place
    - A simpler path: is there an approach that makes half these tasks
      unnecessary? Native feature, stdlib, existing code, one call?
    - Untestable tasks: steps whose "test" can't actually fail for the right
      reason as written

    ## Rules
    - Rank objections by severity (blocking / serious / minor).
    - For each: what is wrong, why it bites, what to change.
    - Cite the specific task or spec line.
    - Do NOT invent objections to look thorough. If part of the plan is
      genuinely solid, name that part in one line and move on. A pre-mortem
      that manufactures risk is worthless.

    ## Output
    1. Ranked objections (blocking first), each with the fix.
    2. The single simpler alternative worth considering, if one exists.
    3. One-line verdict: PROCEED / PROCEED WITH CHANGES / RETHINK.
```

## After the pass

Surface the ranked objections to the user verbatim, with your own take on which
you agree with and which you don't (and why). Then let the user decide before
moving to the Execution Handoff. Blocking objections should be resolved — by
amending the plan or by an explicit user decision to accept the risk — before
execution starts.

If the verdict is PROCEED with no blocking objections, say so in one line and
move on. Do not stage a debate the plan doesn't need.
