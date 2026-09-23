# Claude Code — workflow & skills

A personal, trimmed adaptation of [obra/superpowers](https://github.com/obra/superpowers):
a set of **process skills** that drive every code change through an explicit,
gated pipeline, plus always-on discipline (candor, verification) and a
codebase-memory navigation layer.

## The flow

Every code task starts at the **`development-workflow`** skill, which **triages** first:

- **Trivial mechanical change** (config value, style token, typo, `.gitignore` /
  dependency entry, version bump) → done directly, no pipeline. Candor +
  verification still apply.
- **Everything else** → the gated pipeline (✋ = you decide):

| # | Stage | Skill | Gate |
|---|-------|-------|------|
| 1 | Understand + design | `brainstorming` (grill-gate embedded) | ✋ approve design (the written record is shown again at the plan gate) |
| 2 | Plan | `writing-plans` (+ red-team pre-mortem on non-trivial plans) | ✋ approve plan + written design ("go") |
| 3 | Isolate | `using-git-worktrees` | — |
| 4 | Implement | `subagent-driven-development` — fresh subagent per task, strict TDD, per-task review (spec + quality), fix loop, final whole-branch review | — |
| 5 | Finish | `finishing-a-development-branch` | ✋ merge / PR / discard |

Artifacts: specs → `.flow/specs/`, plans → `.flow/plans/`, execution scratch → `.flow/sdd/`.

**Always-on discipline** (fires on trigger, any stage): `test-driven-development`,
`systematic-debugging` (independent failures investigated in parallel),
`receiving-code-review`. Candor (anti-sycophancy) and code discipline
(Karpathy-style) live always-on in `CLAUDE.md`.

## Model & effort

Session default **Sonnet 5 · xhigh**; inline stages escalate to **Opus 5.5 ·
xhigh** only for a genuinely hard case. Dispatched roles carry their model in
`agents/`: implementer **Sonnet 5 · high**, overridden to **Haiku 4.5** for
small, surgical or paste-ready tasks (decision code stays on Sonnet); fixer and
task-reviewer **Sonnet 5 · high**
(Opus 5.5 override for non-trivial / security / concurrency diffs),
branch-reviewer **Opus 5.5 · high**, plan-red-team **Opus 5.5 · xhigh**. Full
table in `development-workflow`.

Plans fix the contract — interfaces, full tests, exact values — and carry
implementation code only where it is a decision; this is an experiment against
the full-code plans of `0d2c8b3`, see
`.flow/specs/2026-09-23-plan-granularity-design.md`.

## codebase-memory (cbm)

Code navigation uses the [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
graph **before** Grep/Read (`search_graph`, `trace_path`, `get_code_snippet`,
`get_architecture`), wired into brainstorming, planning, the implementer/reviewer
prompts, and debugging. The protocol itself lives in `CLAUDE.md` rule 2 (loaded
every session and after compaction); a PreToolUse augmenter adds graph context to
Grep/Glob and a SubagentStart hook reminds subagents. The graph indexes the main checkout, not worktrees,
so `finishing` re-indexes after merge.

## How this differs from obra/superpowers

- **Entry map + triage** — `development-workflow` routes every task and lets
  genuinely trivial changes skip the pipeline (upstream runs the design gate for
  *everything*).
- **Trimmed** — removed domain/agent skills; dropped `executing-plans` (always
  subagent-driven); deduplicated Red Flags / examples across skills.
- **One per-task reviewer, two verdicts** (spec + quality) instead of two passes.
- **cbm navigation layer** wired into every stage (not upstream).
- **Candor ruleset** (always-on, anti-sycophancy *and* anti-over-correction) +
  **red-team plan pre-mortem** subagent.
- **Concrete per-stage model/effort policy**.
- **Localized** — `CLAUDE.md` and discipline notes in Polish.

## Testing

Discipline skills are pressure-tested per
`skills/writing-skills/testing-skills-with-subagents.md` (baseline vs treatment,
manual read). The flow is smoke-tested end-to-end mechanically before use.
