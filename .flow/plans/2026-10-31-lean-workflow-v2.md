# Lean workflow v2 — plan

## Goal
Runs are implemented in the main session rather than by a fresh implementer per task. Tests are written for stated behaviour rather than through a mandatory test-first procedure. Review is capped, advisor use is narrowed, and compaction is planned. Runs stay resumable after `/clear` and in a new session.
Spec: none. This plan's Decisions are the record; `.claude/README.md` is updated to match.
Evidence: `.flow/reviews/2026-10-31-setup-review/report.md` (sections 1–4 and "Decyzje"), committed with this plan.

## Decisions
- W1 The session implements a run's tasks itself, in the run's worktree, at `stage=implement`. The guard stays active at that stage.
  - Subagents are reserved for independent read-only work in parallel, verbose output (they get the read-only contract) and review.
  - Deleted: the `implementer` agent and the `task-brief` and `sdd-workspace` scripts.
  - `stage=inline` keeps one meaning: the user moved the work onto main without a worktree.
  - Why: Anthropic's optimizing-for-cost page found that when the work is one dependent chain, "the orchestrator's model alone at lower effort came out ahead in every case measured". The best-practices page says "Handing the same task to a subagent doesn't make the answer any better". Measured here: implementer contexts peak at a median of 190–350k, and 53% of their tool output is `Read` re-reading files.
  - Rejected: implementers on Opus, because the handoff loss and the re-reads remain. One implementer per run, because one handoff is still a handoff and the docs show no gain.
- W2 The skill `subagent-driven-development` is renamed `executing-plans` and describes the session working the tasks.
  - Why: the old name routes on a pattern that no longer exists.
- W3 Tests target behaviour.
  - Each acceptance line in a plan gets one focused test.
  - Each bug that escapes to a commit gets a regression test.
  - Verification means running the real thing.
  - A timing-dependent test uses a fake clock.
  - Test-first stays the default for a bug fix and for behaviour that is easy to state as a test. It is no longer mandatory for every change.
  - Why: in cinemancer over 5 days, tests caught 2 regressions while about 49 tests were rewritten. 27 of 29 `fix` commits fixed a defect committed under a green suite. One wall-clock test caused 13 flaky incidents. The mutation score is 86.5%, and 246 of 806 tests kill everything the suite kills.
  - Rejected: dropping TDD entirely, because an escaped bug needs a failing test to prove its fix.
- W4 `branch-reviewer` stays, with these changes:
  - At most 3 rounds; after round 1 it reviews only the new diff.
  - If round 3 still has Critical findings, they go to the user.
  - It skips style and gives a confidence for each finding.
  - It does not call the advisor.
  - The session fixes findings itself.
  - Why: review found 18 of 27 bugs, but it costs the most (108M tokens attributed in 7 days). The docs warn: "A reviewer that's asked to find problems will always find *something*."
- W5 A reviewer finding that contradicts the plan: the controller rules on it if it is reversible and in scope, and logs it under `## Rulings`. Scope changes, spec decisions and anything irreversible go to the user.
  - Why: the user's decision, 31.10.2026.
- W6 `plan-red-team` stays at `effort: high`, down from `xhigh`, and does not call the advisor.
  - At the plan gate the session logs each red-team finding: did it change a Decision row, and was it about behaviour. The log goes to `.flow/reviews/red-team-log.md` in the project.
  - Why: the user kept red-team on the condition that this gets counted. On Opus 5.5, xhigh scores +1.4 pp over high at 2.5× the cost.
  - Rejected: removing red-team (the user overruled this).
- W7 The session calls the advisor only in three cases:
  - once per run, before the plan or architecture is approved;
  - when the same error returns after 2 fix attempts;
  - before an irreversible or outward-facing action.
  - Reviewer and red-team: `disallowedTools: advisor` if the frontmatter accepts it, otherwise a prose rule plus measurement.
  - Why: about 445 calls in 7 days, three quarters of them from subagents. Each call reads the whole transcript uncached at Fable rates. The coding gain is "at the edge of run-to-run noise".
- W8 Compaction:
  - a `# Compact instructions` section in `CLAUDE.md`;
  - the SessionStart `flow-context` hook stays as it is;
  - a PostToolUse hook on `flow-state task … done` reads the last `usage` from `transcript_path` and, above 300k, tells the session to ask the user for `/clear` + "kontynuuj";
  - `autoCompactWindow: 500000` stays as the safety net;
  - a PostCompact hook appends `compact_summary` to a log;
  - `idleCompaction` stays at its default.
  - Dropped from the approved set: the test-output filter hook. In 1351 test commands in cinemancer, 96% were already piped through the agent's own `grep` and 0 matched the docs pattern. The docs example also hides the exit code, so a failing run could read as green.
  - Why: costs.md says `/clear` costs nothing, while `/compact` is itself a large request. The model cannot see its own token count; only the statusline and the transcript can.
- W9 `.flow/` layout:
  - Committed: `plans/`, `specs/`, `design/`, `probes/`, `reviews/`.
  - Ignored: `run/` (`state.json`, review diffs). `review-package` writes into the main checkout's `run/` (from `flow-state path`), never the worktree's.
  - Removed from dotfiles: the 135 tracked `sdd/` files (no history rewrite) and the orphaned `run/fix-rounds.json`.
  - Why: `sdd/` existed for implementer handoff. A worktree-local `run/` is not ignored.
- W10 Plugins `cloudflare` and `text-to-cad` are turned off globally. The user enables them per project on demand.
  - The user disables the claude.ai-synced skills in `/plugin` themselves.
- W11 Each prompt-audit hunk (`.flow/reviews/2026-10-31-setup-review/prompt-audit/`) is applied, re-derived or dropped with a reason, in the task that owns its file. Plugin findings stay flag-only.
- W12 This run follows W1. The session implements at `stage=implement` in a worktree and fixes review findings itself.
  - Before task 1, the user runs `/clear` + "kontynuuj", because the planning session is above 300k.
  - Main is tagged `workflow-v2-pre` before merge. Rollback: `git reset --hard workflow-v2-pre && dotter deploy`.

## Constraints
- A run resumes after `/clear`, after compaction and in a new session, at the first task not marked done (`flow-state` and `hooks/flow-context`).
- `flow-guard` rule 1 (one workspace) and rule 3 (no hand edits of `.flow/run/`) stay enforced at `stage=implement`.
- Dotter maps `.claude/{agents,skills,hooks}` as directories and `.claude/{CLAUDE.md,settings.json}` as files. `~/.claude/settings.json` is the live file for every session on `pc`.
- `CLAUDE.md` stays under 200 lines.
- `hooks/flow-guard-test` and `hooks/prompt-context-test` pass.

## Verification
1. All hook tests pass, including new cases:
   - at `stage=implement`, a second `EnterWorktree` is denied;
   - at `stage=implement`, an Edit of `.flow/run/state.json` is denied;
   - SubagentStart for `general-purpose` during a run carries no "only writer" or BLOCKED text;
   - the context hook fires above 300k and stays silent below it;
   - PostCompact appends a line.
2. `review-package` run in a linked worktree leaves `git status --porcelain` empty.
3. `grep -rn -E 'implementer|task-brief|sdd-workspace|\.flow/sdd|subagent-driven-development' .claude` returns no live reference. Remaining hits are listed and judged.
4. After merge on `pc`, `dotter deploy` leaves `find ~/.claude/{skills,agents,hooks} -xtype l` empty. Then `laptop`: pull and `dotter deploy`.
5. Smoke run in a scratch repo, once at the end with the user's ok:
   - a 2-task plan, then "go";
   - the session implements task 1 and the ledger records it;
   - `/clear` + "kontynuuj" resumes at task 2;
   - one branch review;
   - finish.

## Task 1: Execution skills
**Outcome:** a run is worked by the session task by task, with a ledger entry and context check per task. No skill or agent refers to the implementer handoff.
**Acceptance:**
- `executing-plans` replaces `subagent-driven-development`. It keeps the ledger, the Rulings and the push-after-first-commit rule. It records `stage=implement`.
- `agents/implementer.md`, `task-brief` and `sdd-workspace` are deleted. `review-package` moves under `requesting-code-review` and writes into the main checkout's `.flow/run/`.
- The following describe W1:
  - `development-workflow` (stage table, models, stop rules including the W8 `/clear` stop, `.flow` layout from W9);
  - `writing-plans` ("everything above the first task" no longer feeds briefs; `inline` per W1);
  - `using-git-worktrees`, `finishing-a-development-branch`;
  - `writing-specs` (`SKILL.md` and `project-claude-md.md`, whose `.flow` block lists W9);
  - `plan-red-team.md:35`;
  - `CLAUDE.md` rule 5 and `README.md`;
  - the `settings.json` permissions.
- Slice-A hunks D-H2, D-M6, D-M7 and D-M9, and the CLAUDE.md hunks touching rule 5, are each applied, re-derived or dropped with a reason.
**Area:** `.claude/skills/{executing-plans,subagent-driven-development,development-workflow,writing-plans,using-git-worktrees,finishing-a-development-branch,requesting-code-review,writing-specs}/`, `.claude/agents/{implementer,plan-red-team}.md`, `.claude/settings.json` (permissions), `.claude/CLAUDE.md`, `.claude/README.md`.
**Context:** `skills/subagent-driven-development/SKILL.md` (logic to keep), `prompt-audit/slice-a.md`.

## Task 2: Hooks
**Outcome:** the hooks fit W1, W8 and W9.
**Acceptance:**
- `flow-context` gives every SubagentStart during a run the read-only location contract.
- `flow-guard` polling names drop `implementer`.
- New PostToolUse context-check hook and PostCompact log hook, both registered in `settings.json` with `if:` filters.
- Verification 1 cases pass.
- `.flow/sdd/` and `.flow/run/fix-rounds.json` are removed.
**Area:** `.claude/hooks/`, `.claude/settings.json` (hooks), `.flow/sdd/`, `.flow/run/fix-rounds.json`.
**Context:** hooks.md (PostToolUse `if`, `transcript_path`, PostCompact `compact_summary`); `hooks/statusline:91-96` for reading usage.

## Task 3: Testing, review, red-team, advisor
**Outcome:** W3–W7 are in force.
**Acceptance:**
- `test-driven-development` describes W3.
- `writing-plans` asks for behaviours with one test each, plus the W6 red-team log step at the gate.
- `branch-reviewer` gives a confidence per finding, skips style and leaves out tests of impossible cases.
- `requesting-code-review` holds the 3-round cap, records rounds in the ledger (`flow-state task branch-review-<n> done`), and says what happens after round 3.
- `receiving-code-review` agrees with W5.
- `plan-red-team` runs at `effort: high`.
- `CLAUDE.md` holds the W7 rule in at most 4 lines, and its "Before writing" agrees with W3.
- `disallowedTools: advisor` is tested: a dispatched reviewer lists its tools. If the entry has no effect, the fallback is a prose line.
- Slice-A hunks D-M8a/b, D-M1, D-M2a/b and D-M3 are each applied, re-derived or dropped with a reason.
**Area:** `.claude/skills/{test-driven-development,writing-plans,requesting-code-review,receiving-code-review}/`, `.claude/agents/{branch-reviewer,plan-red-team}.md`, `.claude/CLAUDE.md`.
**Context:** report section 1; `prompt-audit/slice-a.md`, `slice-b.md` (TDD flag).

## Task 4: Context, plugins, `.flow` conventions
**Outcome:** W8 (CLAUDE.md part) and W10 are in force.
**Acceptance:**
- `CLAUDE.md` has a `# Compact instructions` section. It keeps the `flow-state` path, the plan and current task, the uncommitted diff, unresolved errors and the session's decisions, and drops exploration output.
- `enabledPlugins` has `cloudflare` and `text-to-cad` set to false.
**Area:** `.claude/CLAUDE.md`, `.claude/settings.json` (enabledPlugins).
**Context:** costs.md, "Add custom compaction instructions".

## Task 5: Remaining prompt-audit hunks
**Outcome:** audit findings are applied to the untouched files.
**Acceptance:**
- Hunks for `systematic-debugging`, `writing-skills`, `writing-plans/grill-gate.md`, `prompt-master` and `knowledge-transfer` are applied or re-derived; each one skipped is listed with a reason.
- Unsettled flagged conflicts are listed for the user.
- The README model/effort table matches the agent files.
**Area:** the skills above, `.claude/README.md`.
**Context:** `prompt-audit/slice-{a,b,c}.md`.
