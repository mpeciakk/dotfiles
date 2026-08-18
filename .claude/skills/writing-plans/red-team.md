# Red-Team Pass

A fresh subagent whose only job is to make the strongest possible case that the
plan is **wrong**, dispatched after self-review and before the user approves the
plan for execution.

**Why a fresh subagent:** the agent that wrote the plan has conversational
investment in it — it wants the plan to be good because it made it. A subagent
with no session history and an adversarial brief has no such pull, so it is
structurally harder for it to rubber-stamp. This is the anti-sycophancy lever a
prompt alone cannot provide. Its read-only tool set is part of that: an
adversary that can edit the plan it was asked to attack will helpfully "fix" it
instead of reporting it, and you will approve a plan that already moved.

## When to run

Run it **once per plan**, at the plan gate — never per task, never per decision.
It is a plan-level pre-mortem, not a running commentary on every choice.

**Skip it** when the plan is trivial: a single task, a pure-transcription plan
(the task text already contains the complete code), or a mechanical change any
competent engineer would build identically. A full pre-mortem on a one-line
change is noise. Run it when a multi-task plan makes real design or sequencing
choices; when in doubt on such a plan, run it.

## Dispatch

`subagent_type: "plan-red-team"`. Its brief, model and read-only tool set live in
`~/.claude/agents/plan-red-team.md`; your prompt carries only the plan path and
the spec path. Pass paths, never the plan text — the whole point is that the diff
stays out of your context.

## After the pass

Surface the ranked objections to the user verbatim, with your own take on which
you agree with and which you do not, and why. Then let the user decide before
moving to the Execution Handoff. Blocking objections get resolved — by amending
the plan or by an explicit user decision to accept the risk — before execution
starts.

If the verdict is PROCEED with no blocking objections, say so in one line and
move on. Do not stage a debate the plan does not need.
