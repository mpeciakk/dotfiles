# Task 1 report

Status: DONE_WITH_CONCERNS. Commit 67671d5 "test: stream-json reader for the knowledge-transfer harness, on a real transcript". EV = `.flow/specs/2026-10-08-knowledge-transfer-evidence`.

## Implemented
- `EV/sample-agent.md` (verbatim), `EV/sample-stream.jsonl` (real capture, 20 lines, contains PONG-7731; Agent call with `tools: TaskStop` spawned fine, no BLOCKED), `EV/stream-format.md`, `EV/stream.py`, `EV/stream-test.sh` (verbatim from brief).
- Capture ran in /tmp/kt-sample.f1JEJF, not the worktree. An extra capture with an unknown subagent_type (/tmp/kt-capture-script/err-stream.jsonl, not committed) gave the real error spelling, quoted in stream-format.md.

## Findings that shaped stream.py
1. Report location: tool_result holds only boilerplate. Report is in `system/task_notification.handback_report.text` (linked by `tool_use_id` to the Agent tool_use id); also in the tool_result event's `tool_use_result.handbackReport.text` and in the subagent's `SubagentHandback` tool_use. stream.py uses task_notification, falls back to tool_result content (error case).
2. Error flag: successful tool_result has NO `is_error` key (the only `"is_error":false` in the file is on the final `result` event). Error tool_result: `"is_error":true` in the block, `content` is a plain string.
3. Subagent events: `parent_tool_use_id` == Agent tool_use id (null at top level), plus `agent_id`, `subagent_type`.
4. DEVIATION: the stream DOES contain one tool_use inside the subagent: `SubagentHandback` (harness-injected hand-back tool; the subagent's `tools:` list does not matter). Brief's test requires `subagent-tools` to print nothing for kt-echo, so `subagent-tools` excludes `SubagentHandback`. Documented in stream-format.md.

## TDD evidence
RED: `bash EV/stream-test.sh` before stream.py existed:
```
python3: can't open file '.../stream.py': [Errno 2] No such file or directory
FAIL exactly one kt-echo result
FAIL result is not an error
FAIL result carries the subagent text
ok   other subagent_type: no output
ok   kt-echo called no tools
2 passed, 3 failed
```
Expected exactly as brief step 4 (missing script, two vacuous passes).
GREEN: after stream.py:
```
     {"is_error": false, "text": "PONG-7731"}
ok x5
5 passed, 0 failed
```
Extra manual check on the error capture: `agent-results kt-nonexistent err-stream.jsonl` prints `{"is_error": true, "text": "Agent type 'kt-nonexistent' not found. ..."}`.

## Self-review
Standard library only, `python3 -I`, unparsable lines skipped, content string or text-block list handled, NO RESULT path implemented (not exercised by a test; the brief's tests don't cover it).

## Concerns
- `SubagentHandback` exclusion (finding 4) is a judgment call; Task 2/3 should know `task_progress.usage.tool_uses` counts the hand-back too, so it must not be used as a "no tool calls" signal.
- `stream-test.sh` "kt-echo called no tools" only proves the exclusion works for the hand-back; a subagent calling a real tool would print its name (inferred from the code, not captured).
- Capture prints a "claude.ai MCP servers blocked by enterprise policy" warning on stderr; irrelevant to the stream.
