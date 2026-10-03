# Task 6 report

Commit: 72c3626 "skills: background dispatch, named Opus triggers, Sonnet 5.5 table, /clear at run end (D5, D16, D19, D23, D24)"

## Implemented
- SDD: step 3 dispatches with `run_in_background: true` and ends the turn; "runs Sonnet 5.5"; step 5 (reviewer) background + named Opus triggers (auth/secrets/untrusted input; concurrency/lock order; migration/storage format; public API contract; ~400 changed lines; docs/spec-sync stay Sonnet; re-review keeps model; ledger note `model=opus reason=<trigger>`); "Pass `model:` only to override" paragraph mirrors the triggers; task-reviewer table row dropped the Global Constraints paste; orphan `plan="$PLAN"` changed to `plan=<absolute plan path>` (controller's extra instruction).
- requesting-code-review: dispatch step says `run_in_background: true`.
- development-workflow: Sonnet 5 -> 5.5 (modelSettings key `claude-sonnet-5-5`), task-reviewer row, Explore row deleted, session-only wording for `/model opus` / `/model sonnet`, new Triage paragraph (~120K, `/clear`).
- finishing: closing line tells the user to `/clear`.
- task-reviewer.md: brief already carries Global Constraints.
- red-team.md: `run_in_background: true`.
- statusline: `model_hint` strings gain ` (session only)`; docstring example now `ctx 412K`, `5h 40%`, hint with (session only). Task 5 had already dropped `$0.42`.
- flow-guard-test: five `hint_case` expected strings updated.

## TDD evidence
RED: `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh` before any edit: 14/14 `FAIL` lines (every check), exit 1. Expected: none of the text existed.
GREEN: same command after edits: 14/14 `PASS`.
Suites: `.claude/hooks/flow-guard-test | tail -1` -> `174 passed, 0 failed`; `.claude/hooks/prompt-context-test | tail -2` -> `17 passed, 0 failed`.

## Files changed
.claude/agents/task-reviewer.md, .claude/hooks/flow-guard-test, .claude/hooks/statusline, .claude/skills/{development-workflow,finishing-a-development-branch,requesting-code-review,subagent-driven-development}/SKILL.md, .claude/skills/writing-plans/red-team.md, .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh (new).

## Self-review
- Docstring: the code renders `5h 40% →16:20  7d 12%` (reset time arrow is real behavior for five_hour), so I kept the arrow rather than show a string the code never emits; the brief's literal `5h 40%  7d 12%` differs only by that arrow.
- Brief and report files from tasks 1-6 remain untracked, as before.

## Concerns
- `.claude/skills/writing-plans/SKILL.md` line 278 announces "To execute: /clear, /model sonnet, then 'go'." — same session-only issue, outside this task's file list, left alone.
- `.claude/skills/prompt-master/*` still says "Sonnet 5" (model-landscape text, unrelated; left alone).
- The statusline hint lines are longer now; not checked against narrow terminals.

## Fix round 1
Finding 1 (Important): SDD step 5 did not say which ledger call records `model=opus reason=<trigger>`; step 2 forbids a second `task N` call (drops `base=`).
- Change: `.claude/skills/subagent-driven-development/SKILL.md` step 5 now says to record the choice "in the `done` note of step 7, never a second `started` call (it would drop `base=`): `model=opus reason=<trigger>`" (token text unchanged). Step 7 shows the note after an Opus review: `"<base7>..<head7>, review clean, model=opus reason=<trigger>"`. The Example block shows a Sonnet review, so it stays correct as is.
- Test: new check 15 in `.flow/sdd/2026-10-03-setup-perf-audit/text-check.sh` ("reviewer model recorded on done, never a second started call").
- RED: `bash text-check.sh | tail -2` before the edit -> `FAIL reviewer model recorded on done, never a second started call`.
- GREEN: same command after -> 15/15 `PASS`.
- Suites: `flow-guard-test | tail -1` -> `174 passed, 0 failed`; `prompt-context-test | tail -2` -> `17 passed, 0 failed`.
- Minor findings untouched (go to the ledger).
