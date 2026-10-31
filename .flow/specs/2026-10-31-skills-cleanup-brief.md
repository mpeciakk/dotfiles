# Skills cleanup — brief for the plan

Input for writing-plans. The user approved all five items in full on
2026-10-31 (pc). The evidence is the session's count of Skill calls and
`/slash` uses in `~/.claude/projects` transcripts, from 2026-10-11 with
2026-09-01 in brackets. Bare reads of skill files were not counted.

## Items (approved)

1. **Rewrite `writing-skills`** (SKILL.md 666 lines plus 1,723 lines of
   references, 8 uses). Most of it is vendored superpowers text. Target: a
   SKILL.md of about 150 lines. Keep the frontmatter and description rules
   (they decide whether a skill triggers), the structure, and a baseline vs
   treatment test for discipline skills only. Its Iron Law ("no skill without
   a failing test first") was not followed in any recent setup change. Open
   audit flags to resolve here: slice B F1, F2, F5, F6, F7, F11
   (`.flow/reviews/2026-10-31-setup-review/unsettled-flags.md`,
   `prompt-audit/slice-b.md`). Files: `anthropic-best-practices.md` (1,150,
   vendored, no copy date), `testing-skills-with-subagents.md` (349),
   `persuasion-principles.md` (224; its counter-evidence table is measured
   data, so keep that data somewhere), `examples/CLAUDE_MD_TESTING.md` (189,
   tests a discovery mechanism that no longer exists), `render-graphs.js`,
   `graphviz-conventions.dot`.
2. **Rewrite `systematic-debugging`** (SKILL.md 322 lines plus references,
   16 uses). Target: about 120 lines, cut the way TDD was cut. Resolve slice B
   F8 (three overlapping lists) and F9 (pressure coaching, an unsourced
   statistic). References: `root-cause-tracing.md`, `defense-in-depth.md`,
   `condition-based-waiting.md` with its `.ts` example (F12: the example
   breaks its own signature; F13: an upstream header), `find-polluter.sh`.
   Decide for each one: keep, trim or delete.
3. **Merge `receiving-code-review` into `requesting-code-review` and delete
   it** (2 uses since 2026-09-01). After W4/W5, section 3 of
   requesting-code-review already holds the plan-conflict and Minor rules.
   Only "external reviewers" and "GitHub inline replies" are unique. Its
   callers: CLAUDE.md (workflow intro), development-workflow "Always on",
   README, `agents/branch-reviewer.md` (the D-M8a line), requesting-code-review
   §3.
4. **Delete `handoff`** (0 uses since 2026-10-11, 2 since 2026-09-01).
   flow-state, `/clear` and the CLAUDE.md compact instructions replaced it for
   runs.
5. **Retire the `test-driven-development` skill** (0 Skill calls since
   2026-09-01; only implementers read it, and they are gone). The essentials
   are already in CLAUDE.md "Before writing" (W3). The session's proposal for
   the plan to decide: delete `SKILL.md`, move `writing-good-tests.md` to
   `skills/executing-plans/writing-good-tests.md`, and point to it from
   executing-plans step 3 and from CLAUDE.md. Callers: CLAUDE.md lines 11 and
   15, development-workflow "Always on", README, the `writing-skills`
   background line, and the `systematic-debugging` references to TDD.

## Constraints

- `hooks/flow-guard-test` (180 checks) and `hooks/prompt-context-test` pass.
  Some checks grep skill files.
- `find ~/.claude/skills -xtype l` is empty after `dotter deploy`. dotter
  prompts about emptied directories, so answer `y`, or `rmdir` them first.
- CLAUDE.md stays under 200 lines.
- The memory note [[setup-changes-agree-direction]] is met: the user gave the
  direction.
