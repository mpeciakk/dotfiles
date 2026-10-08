## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`). The package the skill produces, scenario prompts, user-fact answers and the cold-reader's answers are Polish.
- The company knowledge base is named exactly `docs.internal.animativ.dev`.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call goes through `EV/turn.sh` unchanged. It already sets `--model sonnet`, `--output-format stream-json --verbose`, `--permission-mode acceptEdits`, the allowed tools and `--disallowedTools SendMessage ListAgents`. Never use `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`.
- Bash tool calls that run a nested session use `timeout: 600000`. A turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).
- Do not commit anything from `~/.claude/projects/` (real session transcripts). They may be read and quoted.

---

### Task 1: `stream.py questions` — what a session asked the user

**Files:**
- Modify: `EV/stream.py` (new subcommand `questions`)
- Create: `EV/questions-test.sh`

**Interfaces:**
- Consumes: `EV/stream.py` helpers `events(path)`, `blocks(event)` (existing).
- Produces: `python3 -I EV/stream.py questions <jsonl>...` prints one line per question to the user, formatted `<basename of jsonl>: <question text>`. It has two sources:
  - (a) every line containing `?` in the `result` text of each `type == "result"` event (stream-json from `claude -p`);
  - (b) every `input.questions[].question` of each `tool_use` block named `AskUserQuestion` (interactive session transcripts). Newlines inside an AskUserQuestion question are replaced by a space.

  A path that does not exist makes it exit non-zero.

This is an extractor, not a judge. Which questions are forbidden is decided by reading (Task 3), because a pattern match both flags allowed questions (secret location) and misses requests phrased without `?`.

- [ ] **Step 1: Write the failing test**

`EV/questions-test.sh`, following the pattern of `EV/stream-test.sh`:

```bash
#!/usr/bin/env bash
# questions-test.sh — stream.py questions extracts the questions a session put to the user.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-qtest.XXXXXX)
# stream-json result event (claude -p)
printf '%s\n' '{"type":"result","subtype":"success","result":"Inwentarz gotowy.\n1. Czy worker działa w tej samej jednostce co app.py?\n2. Kto nadaje dostęp SSH do sms1?\nZatwierdzasz?"}' > "$T/p.jsonl"
# interactive transcript: AskUserQuestion tool_use
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"AskUserQuestion","input":{"questions":[{"question":"Pakiet jest dla Ernesta?\n(imię odbiorcy)"},{"question":"Gdzie leży plik outbox.db?"}]}}]}}' > "$T/i.jsonl"
q=$(python3 -I "$EV/stream.py" questions "$T/p.jsonl" "$T/i.jsonl")
echo "$q" | sed 's/^/     /'
[ "$(echo "$q" | grep -c .)" -eq 5 ]; check "five questions (3 result lines with ?, 2 AskUserQuestion)" $?
echo "$q" | grep -qxF 'p.jsonl: 2. Kto nadaje dostęp SSH do sms1?'; check "result line kept whole, file prefix" $?
echo "$q" | grep -qxF 'i.jsonl: Pakiet jest dla Ernesta? (imię odbiorcy)'; check "AskUserQuestion newline folded" $?
echo "$q" | grep -q 'Inwentarz gotowy'; [ $? -ne 0 ]; check "line without ? is not a question" $?
python3 -I "$EV/stream.py" questions "$T/missing.jsonl" >/dev/null 2>&1; [ $? -ne 0 ]; check "missing file -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash EV/questions-test.sh`
Expected: `FAIL five questions …` (stream.py prints its usage error, so 0 lines), FAIL on the next two checks, `2 passed, 3 failed`, exit 1. The two passing checks are the negative ones, which hold vacuously before the subcommand exists.

- [ ] **Step 3: Implement**

Add `questions(paths)` next to `subagent_tools`, using `events()` and `blocks()`. `events()` already raises on a missing path, so do not catch that. Add a `questions` branch in `main()` and a usage line in the module docstring and in the `sys.exit` usage message.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash EV/questions-test.sh && bash EV/stream-test.sh && bash EV/check-package-test.sh`
Expected: `5 passed, 0 failed`, `6 passed, 0 failed`, `8 passed, 0 failed`.

- [ ] **Step 5: Extract the real RED questions (recorded in the report, not committed as data)**

Run `python3 -I EV/stream.py questions ~/.claude/projects/-home-m-work-edge-vibecoding/fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl` (the real KT session that motivated D31) and paste the output verbatim into the report. Expected: 16 lines, among them the router question, `Od 2026-09-28 był jakiś run?` and `…Pakiet jest dla Ernesta?`. A different count is reported as it is, not adjusted.

- [ ] **Step 6: Commit**

```bash
git add EV/stream.py EV/questions-test.sh
git commit -m "test: knowledge-transfer harness — extract the questions a session put to the user"
```

---
