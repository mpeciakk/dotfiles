## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

---

### Task 1: Stream-json reader, built on a real captured transcript

The probe (Task 2) and checker criterion C3 (Task 3) decide from the stream: did the Agent call return without error, and what did the subagent call. This task verifies that format against a real run before anything parses it.

**Files:**
- Create: `EV/sample-agent.md`, `EV/sample-stream.jsonl`, `EV/stream-format.md`, `EV/stream.py`
- Test: `EV/stream-test.sh`

**Interfaces:**
- Produces: `python3 -I EV/stream.py agent-results <subagent_type> <jsonl>...` — one JSON object per line, per Agent tool_use whose `input.subagent_type` equals `<subagent_type>`: `{"is_error": bool, "text": "<the subagent's report>"}` — the report wherever the stream carries it: the `tool_result` content, or a separate hand-back message linked to that dispatch (in interactive sessions here the `tool_result` holds only boilerplate and the report arrives as a hand-back; `-p` may differ); a tool_use with no matching tool_result prints `{"is_error": true, "text": "NO RESULT"}`.
- Produces: `python3 -I EV/stream.py subagent-tools <jsonl>...` — one tool name per line, for every tool_use emitted *inside* a subagent (an event linked to a parent tool_use), in stream order.
- Produces: `EV/stream-format.md` — the exact key spellings Task 3's test substitutes on (how a tool_result marks an error, how a subagent event is linked to its parent).

- [ ] **Step 1: Capture a real transcript**

`EV/sample-agent.md`:

```markdown
---
name: kt-echo
description: Test fixture for the knowledge-transfer harness. Replies with a fixed string.
model: haiku
tools: TaskStop
---

Reply with exactly `PONG-7731` and nothing else. Never call any tool.
```

```bash
D=$(mktemp -d /tmp/kt-sample.XXXXXX); mkdir -p "$D/.claude/agents"
cp EV/sample-agent.md "$D/.claude/agents/kt-echo.md"
(cd "$D" && claude -p 'Użyj narzędzia Agent z subagent_type "kt-echo" i promptem "Odpowiedz zgodnie z instrukcją." Potem napisz GOTOWE.' \
  --model sonnet --output-format stream-json --verbose --disallowedTools SendMessage ListAgents) > EV/sample-stream.jsonl
grep -c . EV/sample-stream.jsonl; grep -o 'PONG-7731' EV/sample-stream.jsonl | head -1
```
Expected: a non-empty file containing `PONG-7731`. If the Agent call failed (e.g. zero tools), stop and report BLOCKED with the error line — D30 depends on `tools: TaskStop` spawning.

- [ ] **Step 2: Record the format**

Read `EV/sample-stream.jsonl` and write `EV/stream-format.md`: the event types present; where the Agent tool_use and its `input.subagent_type` sit; where its tool_result sits and how it is linked (`tool_use_id`); the exact JSON spelling of the error flag (e.g. `"is_error":false`); how an event emitted inside the subagent is linked to the parent (e.g. `parent_tool_use_id`). Where the subagent's report text actually is — in the `tool_result`, or in a separate hand-back event (and how that event is linked to the dispatch). Whether a successful `tool_result` carries an error flag at all. Quote one real line for each. If the stream carries no events from inside the subagent, write that down: `subagent-tools` then prints nothing for any input, and the probe's tool-call check (Task 2) rests on the token check alone.

- [ ] **Step 3: Write the failing test**

`EV/stream-test.sh`:

```bash
#!/usr/bin/env bash
# stream-test.sh — stream.py reads the real captured transcript correctly.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { # label condition-exit-code
  if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi
}
out=$(python3 -I "$EV/stream.py" agent-results kt-echo "$EV/sample-stream.jsonl")
echo "$out" | sed 's/^/     /'
[ "$(echo "$out" | grep -c .)" -eq 1 ]; check "exactly one kt-echo result" $?
echo "$out" | grep -q '"is_error": false'; check "result is not an error" $?
echo "$out" | grep -q 'PONG-7731'; check "result carries the subagent text" $?
none=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$EV/sample-stream.jsonl")
[ -z "$none" ]; check "other subagent_type: no output" $?
tools=$(python3 -I "$EV/stream.py" subagent-tools "$EV/sample-stream.jsonl")
[ -z "$tools" ]; check "kt-echo called no tools" $?
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 4: Run it to verify it fails**

Run: `bash EV/stream-test.sh`
Expected: `FAIL exactly one kt-echo result`, `FAIL result is not an error`, `FAIL result carries the subagent text` (python reports the missing `stream.py`, output is empty); the two "no output" checks pass vacuously; last line `2 passed, 3 failed`.

- [ ] **Step 5: Implement `stream.py`**

Standard library only, run with `python3 -I`; parse every line as JSON (skip lines that fail to parse); match tool_use → tool_result by id; tool_result content may be a string or a list of `{"type":"text"}` blocks — join the texts. Use the key spellings and the report location recorded in `EV/stream-format.md`; absent error flag = `false`. Print with `json.dumps(obj, ensure_ascii=False)` (that gives the `"is_error": false` spacing the tests grep for).

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash EV/stream-test.sh`
Expected: `5 passed, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add EV/sample-agent.md EV/sample-stream.jsonl EV/stream-format.md EV/stream.py EV/stream-test.sh
git commit -m "test: stream-json reader for the knowledge-transfer harness, on a real transcript"
```

---
