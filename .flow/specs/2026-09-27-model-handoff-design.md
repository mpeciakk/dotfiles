# Model handoff: design and plan on Opus, execution on Sonnet (2026-09-27)

The dotfiles have no living `spec.md`, so this record carries the decisions as
well as the deliberation.

## Problem

Session default is Sonnet. Design and plans are where a stronger model pays
off, but switching model mid-session rebuilds the whole prompt cache (the cache
is per model), so a switch at 150K context costs a full re-read. Nothing can
switch the model automatically: hooks cannot set it, and the user forgets to.

## D1 — When to switch

**Chosen:** stages 1–2 (design, plan) on Opus 5.5 · high. At the plan gate the
user's "go" becomes `/clear` → `/model sonnet` → `go`: the fresh session starts
at ~20–30K instead of ~150K, on Sonnet, and resumes from flow-state (the
SessionStart hook injects the run). Opus effort goes medium → high in
`settings.json`, matching Sonnet's `high`.

**Rejected:**
- `model: opus` in brainstorming/writing-plans frontmatter. It lasts one turn and
  reverts on the next prompt, so a multi-turn design would flip models every
  turn — a cache rebuild each time, worse than one manual switch.
- Switching without `/clear`. One full cache rebuild of the design context, and
  the controller then carries that context through the whole run.
- Opus for the whole run. The controller mostly dispatches and adjudicates;
  agent definitions already pick the model per role.

## D2 — How the user is reminded

**Chosen:** the status line's flow row shows a hint from `stage` + `model.id`:
design on a non-Opus model → switch to Opus; plan → the /clear + /model sonnet
handoff; isolate/implement/finish on Opus → switch to Sonnet. Free (no context
tokens), visible on every render, and the statusline payload always carries the
model. Plus: `flow-context`'s session context at `stage=plan` says that "go"
means using-git-worktrees then subagent-driven-development — without it a
cleared session sees only `stage: plan` and has to rediscover the next step.

**Rejected:**
- SessionStart hook printing the hint: the `model` field is optional there, and
  the text costs context tokens in every session.
- PreModelSwitch hook warning on a large context: more code for a case the
  status line already covers. Revisit if the hint gets missed in practice.
