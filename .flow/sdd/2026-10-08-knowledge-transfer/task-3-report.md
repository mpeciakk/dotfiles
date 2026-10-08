# Task 3 report — test harness

Status: DONE_WITH_CONCERNS. Commit e9f8efe `test: knowledge-transfer harness — fixture, user facts, turn runner, checker`.

## Implemented
In `.flow/specs/2026-10-08-knowledge-transfer-evidence/` (EV): `make-fixture.sh`, `user-facts.md` (verbatim), `turn.sh`, `check-package.sh`, `check-package-test.sh`, `smoke-skill/SKILL.md`.

Deviations from the brief:
1. `make-fixture.sh`: `git revert -q --no-edit HEAD` -> `git revert --no-edit HEAD >/dev/null`. This git rejects `-q` for `revert` (printed usage, `FIXTURE FAILED`). Only change to the given fixture.
2. `check-package-test.sh`: `tr-err` derived by injecting `"is_error":true,` after `"type":"tool_result",` (brief's second option; `stream-format.md` says a successful tool_result carries no flag, sample has only one `is_error` hit, on the `result` event). Added two extra guards: tr-err really yields `"is_error": true` from stream.py, tr-no really has no cold-reader dispatch.

## TDD evidence
RED (`bash EV/check-package-test.sh`, after fixture + test existed, checker absent): no `FIXTURE FAILED`; each of 8 cases `FAIL ... (exit 127)` with `check-package.sh: No such file or directory`; `0 passed, 8 failed`. Expected: the checker did not exist. (An earlier run printed `FIXTURE FAILED` with git revert usage — the `-q` bug above, fixed first.)

GREEN (after writing `check-package.sh`): 8 ok lines, `8 passed, 0 failed`, exit 0; re-run before commit identical, output pristine.

## Smoke (nested claude, cwd = temp fixture, timeout 600000)
- turn 1 `kt-smoke` -> `SESSION 35b510d4-...` / `SMOKE-SKILL-4412`
- turn 2 (Agent kt-echo, same id) -> `SESSION` same id / `PONG-7731`; `stream.py agent-results kt-echo turn-2.jsonl` -> `{"is_error": false, "text": "[Subagent hand-back] ... PONG-7731 ..."}`
- turn 3 -> `42c8bd3 fix: ponawianie przy 429 z bramki`
- No `DENIED` line anywhere; `Bash(git *)` syntax worked, no switch to `:*` needed. Temp dirs removed.

## Self-review
Checker output contract matches (PASS/FAIL Cn name, `<k>/6 PASS`, exit 0 iff 6/6). C2 trims whitespace in pure bash and reports the first copied line. C6 uses `git diff` against the tip file so working-tree edits count.

## Concerns
1. In the smoke's turn 2 (resumed session) the stream had NO `handback_report` in `task_notification` (only `summary`), so `stream.py` fell back to tool_result content, which is a framed text: `[Subagent hand-back] The text below is the final report ... PONG-7731\nagentId: ...<usage>...`. The sample capture (non-resumed) had `handback_report.text`. Substring checks (`Podstawa:`, `PONG-7731`) still work, but anything doing exact/prefix matching on `agent-results` text must tolerate the frame. `usage.tool_uses` was 0 here vs 1 in the sample, further confirming it is not a stable signal.
2. `claude` prints `Warning: claude.ai MCP servers blocked by enterprise policy ...` to stderr on every turn; harmless noise from `turn.sh` (not suppressed, to avoid hiding real errors).
3. `turn.sh` and the checker are not themselves unit-tested beyond the smoke / checker test (as specified).
