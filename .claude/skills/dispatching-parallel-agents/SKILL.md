---
name: dispatching-parallel-agents
description: Use when 2+ independent read-only investigations (exploration, review, research, root-cause analysis across separate subsystems) can run at once instead of one after another
---

# Dispatching Parallel Agents

Parallel dispatch is for agents that **read**: exploring unfamiliar code,
reviewing along different dimensions, researching options, diagnosing
independent failures. Issue all the dispatches in one response and they run
concurrently; one per response runs them in series.

## Never parallelize writers

Two agents editing and committing in the same working tree collide on the index
and the lock, and the "independent" fixes arrive as a conflicted mess. One
writer per working tree — implementation stays sequential
(subagent-driven-development dispatches one implementer at a time).

If you catch yourself wanting parallel writers, the tractable version is
parallel *investigation* followed by one sequential fix pass: each agent
reports root cause and a proposed patch, you order the changes and dispatch
the writes one at a time.

## What each agent needs

- **One domain** — a single test file, subsystem, or question. "Fix all the
  tests" gets lost; "diagnose the 3 failures in agent-tool-abort.test.ts"
  does not.
- **The evidence inline** — error messages, failing test names, symptoms. An
  agent that has to rediscover the symptom spends its context on that.
- **Read-only scope, stated** — "investigate and report; do not edit files."
- **A named deliverable** — root cause, the specific lines involved, and the
  minimal change they recommend.

## When one agent beats several

Related failures (fixing one may fix the rest), anything needing whole-system
state to understand, and exploratory work where you do not yet know what is
broken. Split by domain only once you know the domains are separate.

## After they return

Read each report, check whether the proposals conflict with each other, then
sequence the resulting work. Agents can make correlated mistakes, so spot-check
the reasoning rather than trusting the summaries wholesale.
