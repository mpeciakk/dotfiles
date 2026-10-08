# stream-json format, observed

Source: `sample-stream.jsonl`, a real capture (2026-10-08, `claude -p ... --model sonnet --output-format stream-json --verbose`, one Agent call to the project-level agent `kt-echo` with `tools: TaskStop`). The Agent call spawned fine. One extra capture (not stored) with an unknown `subagent_type` gave the error spelling below. One JSON object per line, 20 lines.

## Event types present (`type` / `subtype`)

`system/hook_started`, `system/hook_response`, `system/init`, `assistant`, `system/task_started`, `user`, `rate_limit_event`, `system/task_progress`, `system/task_updated`, `system/task_notification`, `system/thinking_tokens`, `result/success`.

## Agent tool_use and its subagent_type

An `assistant` event whose `message.content[]` holds a block `type":"tool_use"`, `"name":"Agent"`; `input.subagent_type` is inside `input`:

```
{"type":"tool_use","id":"toolu_01T8TRFqwaRr8XKznUJvBpBR","name":"Agent","input":{"description":"Echo test fixture","subagent_type":"kt-echo","prompt":"Odpowiedz zgodnie z instrukcją.","run_in_background":false},"caller":{"type":"direct"}}
```

## Agent tool_result and the link

A `user` event with `parent_tool_use_id: null` whose `message.content[]` holds a `tool_result` block; the link is `tool_use_id` == the Agent tool_use `id`:

```
{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_01T8TRFqwaRr8XKznUJvBpBR","type":"tool_result","content":[{"type":"text","text":"  This agent's report was delivered to you as a message from \"a63aa983e49cd97b4\" (its SubagentHandback call). Read it there; it is not repeated here.\n  \nagentId: a63aa983e49cd97b4 (use SendMessage ...)\n<usage>subagent_tokens: 7010\ntool_uses: 1\nduration_ms: 9713</usage>"}]}]},"parent_tool_use_id":null, ...}
```

`content` is a list of `{"type":"text","text":...}` blocks here; in the error case below it is a plain string. Both forms occur.

## Error flag

A successful `tool_result` carries NO error flag at all (absent = not an error). Verified: `grep -o '"is_error":[a-z]*' sample-stream.jsonl` finds a single hit, on the final `result` event (session-level, not a tool_result). An errored tool_result spells it `"is_error":true` inside the tool_result block (capture with `subagent_type` "kt-nonexistent"):

```
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"Agent type 'kt-nonexistent' not found. Available agents: branch-reviewer, claude, ...","is_error":true,"tool_use_id":"toolu_01XDXN1N5i9ayD5vAJLfnFRU"}]},"parent_tool_use_id":null, ...}
```

In that case no `task_*` events follow; the text of the error is the `content` string.

## Where the subagent's report is

NOT in the tool_result (it holds only boilerplate: "This agent's report was delivered to you as a message ... Read it there"). The report travels as a hand-back, in three places, all carrying the same text `PONG-7731`:

1. `system/task_notification`, linked to the dispatch by `tool_use_id` == the Agent tool_use `id`; the report is `handback_report.text` (`"handback":"send"`):

```
{"type":"system","subtype":"task_notification","task_id":"a63aa983e49cd97b4","run_id":"0muztvuvh-7bc5883e","tool_use_id":"toolu_01T8TRFqwaRr8XKznUJvBpBR","status":"completed",...,"handback":"send","handback_report":{"text":"PONG-7731"},...}
```

2. The Agent tool_result event's top-level `tool_use_result.handbackReport.text` (same event as the boilerplate tool_result above; also `tool_use_result.agentId`, `agentType`).
3. The subagent's own `SubagentHandback` tool_use, `input.message` (see next section).

`stream.py` reads place 1 (fallback: the tool_result content, which is what an error or an inline-report run would carry).

## Events emitted inside the subagent

Linked by `parent_tool_use_id` == the Agent tool_use `id` (non-null; top-level events have `null`). Such events also carry `agent_id`, `subagent_type`, `task_description`. Both `assistant` (tool_use) and `user` (tool_result, prompt) events appear. The subagent's one tool call, a real line:

```
{"type":"assistant","message":{"model":"claude-haiku-4-5-20251001",...,"content":[{"type":"tool_use","id":"toolu_011W3QsHyjcqErW78Wk1eDBr","name":"SubagentHandback","input":{"message":"PONG-7731"},"caller":{"type":"direct"}}],...},"parent_tool_use_id":"toolu_01T8TRFqwaRr8XKznUJvBpBR","agent_id":"a63aa983e49cd97b4",...,"subagent_type":"kt-echo","task_description":"Echo test fixture"}
```

`SubagentHandback` is a harness-injected tool: every subagent calls it once to deliver its report, whatever its `tools:` list says (`kt-echo` has only `TaskStop` and was told to call nothing). It is the hand-back mechanism, not a tool the subagent chose to call, so `stream.py subagent-tools` does not list it. Without that exclusion `subagent-tools` would print `SubagentHandback` for every run and Task 2/3 checks "the subagent called no tool" could never pass. For `kt-echo` `subagent-tools` therefore prints nothing.

`system/task_progress` also reports `"last_tool_name":"SubagentHandback"` and `usage.tool_uses` (counts the hand-back too: `1` for kt-echo).

## Which skill or agent loads in a nested run

In a nested `claude -p` run, a personal-level skill or agent of the same name in `~/.claude` is loaded instead of the fixture's project-level copy. A test of a skill that also exists personally needs a throwaway `CLAUDE_CONFIG_DIR` omitting it (see `team.md`, "Harness deviation"). The proof of what loaded is the `Base directory for this skill:` line in the Skill tool result.
