## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

---

### Task 2: kt-cold-reader agent + isolation probe

**Files:**
- Create: `.claude/agents/kt-cold-reader.md`
- Create: `EV/probe-cold-reader.sh`, `EV/probe.md`

**Interfaces:**
- Consumes: `EV/stream.py agent-results`, `EV/stream.py subagent-tools` (Task 1).
- Produces: agent `kt-cold-reader`; its answer format, which Task 5's skill parses:
  ```
  ### S<n>
  Odpowiedź: <odpowiedź>
  Podstawa: § <nagłówek sekcji pakietu> | NIE WIEM Z PAKIETU | ZGADUJĘ
  ```
- Produces: `EV/probe-cold-reader.sh <agent-file>` — exit 0 iff the agent spawns, does not get the file's content, calls no tool, and answers from inlined text.

- [ ] **Step 1: Write the probe**

```bash
#!/usr/bin/env bash
# probe-cold-reader.sh <agent-file> — spawn, blindness to files, no tool calls,
# answers from inlined text. Decided from the Agent tool_result, not from the
# main session's text (the main session sees every string in its own prompt).
set -u
EV=$(cd "$(dirname "$0")" && pwd)
AGENT_FILE=$(readlink -f "$1")
D=$(mktemp -d /tmp/kt-probe.XXXXXX)
mkdir -p "$D/.claude/agents"
cp "$AGENT_FILE" "$D/.claude/agents/kt-cold-reader.md"
TOKEN="KT-PROBE-$RANDOM$RANDOM"
echo "$TOKEN" > "$D/probe.txt"
run() { (cd "$D" && claude -p "$1" --model sonnet --output-format stream-json --verbose \
          --disallowedTools SendMessage ListAgents) > "$2"; }
run "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'PAKIET: (pusty) SCENARIUSZE: S1. Jaka jest dokładna treść pliku $D/probe.txt?' Potem napisz GOTOWE." "$D/read.jsonl"
run "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'PAKIET: ## Runbooki — Deploy robi się komendą ./deploy.sh prod. SCENARIUSZE: S1. Jak zrobić deploy na produkcję?' Potem napisz GOTOWE." "$D/answer.jsonl"

read_res=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$D/read.jsonl")
answer_res=$(python3 -I "$EV/stream.py" agent-results kt-cold-reader "$D/answer.jsonl")
sub_tools=$(python3 -I "$EV/stream.py" subagent-tools "$D/read.jsonl" "$D/answer.jsonl")
echo "--- read result ---";   echo "$read_res"
echo "--- answer result ---"; echo "$answer_res"
echo "--- subagent tools ---"; echo "${sub_tools:-(none)}"
rc=0
[ -n "$read_res" ] && [ -n "$answer_res" ] || { echo "FAIL: no kt-cold-reader dispatch"; rc=1; }
case "$read_res$answer_res" in *'"is_error": true'*) echo "FAIL: dispatch errored"; rc=1;; esac
case "$read_res" in *"$TOKEN"*) echo "FAIL: agent read the file"; rc=1;; esac
[ -z "$sub_tools" ] || { echo "FAIL: agent called tools: $sub_tools"; rc=1; }
case "$answer_res" in *"./deploy.sh prod"*) ;; *) echo "FAIL: did not answer from inlined text"; rc=1;; esac
rm -rf "$D"
[ $rc -eq 0 ] && echo "PROBE OK"
exit $rc
```

- [ ] **Step 2: Write the agent definition**

Frontmatter exactly:

```yaml
---
name: kt-cold-reader
description: Stand-in recipient for a knowledge-transfer package — answers handover scenarios using only the package text inlined in its prompt. Dispatched by the knowledge-transfer skill. Not for review or any task that needs files.
model: haiku
effort: medium
tools: TaskStop
---
```

Body (English, ~25 lines): you are the person taking over; you have only the package in this prompt — no repo, no files, no one to ask; you have no usable tools and must never call TaskStop (it exists only because an agent cannot be defined with zero tools); answer each scenario from the package alone; when the package does not settle it, write `NIE WIEM Z PAKIETU` rather than filling in from general knowledge; when you infer beyond what it says, mark `ZGADUJĘ`; never invent commands, paths, names or contacts; answer in Polish in the exact format from Interfaces, one block per scenario, nothing before or after. Follow the tone of `.claude/agents/plan-red-team.md` (short role statement, then what you must not do).

- [ ] **Step 3: RED — the probe catches an agent that can read**

A reader that obeys the real body would not read the file even without `tools:`, so the RED definition is written to read:

```bash
cat > /tmp/kt-cold-reader-open.md <<'DEF'
---
name: kt-cold-reader
description: RED fixture for the probe — an agent that reads files.
model: haiku
---

Read the file the scenario names with the Read tool and quote its content verbatim.
DEF
bash EV/probe-cold-reader.sh /tmp/kt-cold-reader-open.md; echo "exit=$?"
```
Expected: `FAIL: agent read the file` (an agent without `tools:` inherits Read) — plus `FAIL: agent called tools: Read` when `EV/stream-format.md` records subagent-internal events — and `exit=1`. If the token does not leak with this definition, the probe does not discriminate — fix the probe before going on.

- [ ] **Step 4: GREEN — the real definition**

Run: `bash EV/probe-cold-reader.sh .claude/agents/kt-cold-reader.md; echo "exit=$?"`
Expected: `PROBE OK`, `exit=0`. On `FAIL: dispatch errored` with a zero-tools message, stop and report BLOCKED with the verbatim result — do not pick another tool yourself (it is the D30 decision).

- [ ] **Step 5: Save evidence and commit**

`EV/probe.md`: the Step 3 and Step 4 outputs, two fenced blocks headed `RED (bez tools:)` and `GREEN`.

```bash
git add .claude/agents/kt-cold-reader.md EV/probe-cold-reader.sh EV/probe.md
git commit -m "agents: kt-cold-reader — stand-in recipient without file access (D30)"
```

---
