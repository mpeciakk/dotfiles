# Knowledge Transfer Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `knowledge-transfer` skill that extracts project/topic knowledge (repo + interview) into a dated, recipient-specific handover package, verified by a `kt-cold-reader` agent that can see nothing but the package.

**Architecture:** `skills/knowledge-transfer/SKILL.md` carries the process, the section matrix and the hard rules; `agents/kt-cold-reader.md` is a stand-in recipient whose only tool is `TaskStop`, so it answers from the package inlined in its prompt. The skill is tested per writing-skills (baseline without the skill → skill → same scenario with it) by nested `claude -p` sessions in a throwaway fixture repo, read through their stream-json output and scored by a mechanical checker.

**Tech Stack:** Markdown (skill, agent definition), bash + `python3 -I` (test harness), `claude` CLI 2.1.292 in `-p` mode with `--output-format stream-json --verbose`.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-08-knowledge-transfer-design.md` (D29, D30). Dotfiles have no living `spec.md`; the record carries the decisions.

## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

---

### Task 1: Stream-json reader, built on a real captured transcript

The probe (Task 2) and checker criterion C3 (Task 3) decide from the stream: did the Agent call return without error, and what did the subagent call. This task verifies that format against a real run before anything parses it.

**Files:**
- Create: `EV/sample-agent.md`, `EV/sample-stream.jsonl`, `EV/stream-format.md`, `EV/stream.py`
- Test: `EV/stream-test.sh`

**Interfaces:**
- Produces: `python3 -I EV/stream.py agent-results <subagent_type> <jsonl>...` — one JSON object per line, per Agent tool_use whose `input.subagent_type` equals `<subagent_type>`: `{"is_error": bool, "text": "<tool_result text>"}`; a tool_use with no matching tool_result prints `{"is_error": true, "text": "NO RESULT"}`.
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

Read `EV/sample-stream.jsonl` and write `EV/stream-format.md`: the event types present; where the Agent tool_use and its `input.subagent_type` sit; where its tool_result sits and how it is linked (`tool_use_id`); the exact JSON spelling of the error flag (e.g. `"is_error":false`); how an event emitted inside the subagent is linked to the parent (e.g. `parent_tool_use_id`). Quote one real line for each. If the stream carries no events from inside the subagent, write that down: `subagent-tools` then prints nothing for any input, and the probe's tool-call check (Task 2) rests on the token check alone.

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

Standard library only, run with `python3 -I`; parse every line as JSON (skip lines that fail to parse); match tool_use → tool_result by id; tool_result content may be a string or a list of `{"type":"text"}` blocks — join the texts. Use the key spellings recorded in `EV/stream-format.md`. Print with `json.dumps(obj, ensure_ascii=False)` (that gives the `"is_error": false` spacing the tests grep for).

- [ ] **Step 6: Run the test to verify it passes**

Run: `bash EV/stream-test.sh`
Expected: `5 passed, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add EV/sample-agent.md EV/sample-stream.jsonl EV/stream-format.md EV/stream.py EV/stream-test.sh
git commit -m "test: stream-json reader for the knowledge-transfer harness, on a real transcript"
```

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

Run:
```bash
sed '/^tools:/d' .claude/agents/kt-cold-reader.md > /tmp/kt-cold-reader-open.md
bash EV/probe-cold-reader.sh /tmp/kt-cold-reader-open.md; echo "exit=$?"
```
Expected: `FAIL: agent read the file` (an agent without `tools:` inherits Read) — plus `FAIL: agent called tools: Read` when `EV/stream-format.md` records subagent-internal events — and `exit=1`. If it does not fail on the read, the probe does not discriminate — fix the probe before going on.

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

### Task 3: Test harness — fixture, user facts, turn runner, package checker

**Files:**
- Create: `EV/make-fixture.sh`, `EV/user-facts.md`, `EV/turn.sh`, `EV/check-package.sh`, `EV/smoke-skill/SKILL.md`
- Test: `EV/check-package-test.sh`

**Interfaces:**
- Consumes: `EV/stream.py agent-results` (Task 1); `EV/stream-format.md` key spellings; `EV/sample-stream.jsonl`.
- Produces: `EV/make-fixture.sh <dir>` — creates a git repo `kolejka-sms` at `<dir>` (refuses if `<dir>` exists), records its tip SHA in `<dir>/.git/kt-fixture-tip`.
- Produces: `EV/turn.sh <fixture-dir> <transcripts-dir> <message> [session-id]` — one nested session turn; writes `<transcripts-dir>/turn-<N>.jsonl` (N = next free number from 1); prints `SESSION <id>`, then `DENIED <tool>` per permission denial, then the final result text.
- Produces: `EV/check-package.sh <package.md> <fixture-dir> <transcripts-dir>` — one `PASS Cn <name>` or `FAIL Cn <name>: <detail>` line per criterion C1–C6, last line `<k>/6 PASS`; exit 0 iff 6/6.

- [ ] **Step 1: Write the fixture builder**

The fixture's content is the contract the checker and the scenarios rely on, so it goes in as given:

```bash
#!/usr/bin/env bash
# make-fixture.sh <dir> — kolejka-sms: small service with a spec, a revert,
# a fix, and a gitignored .env holding a (fake) secret.
set -eu
D=$1
[ -e "$D" ] && { echo "exists: $D" >&2; exit 1; }
mkdir -p "$D"; cd "$D"
git init -q -b main
git config commit.gpgsign false
export GIT_AUTHOR_NAME=Ernest GIT_AUTHOR_EMAIL=ernest@example.invalid
export GIT_COMMITTER_NAME=Ernest GIT_COMMITTER_EMAIL=ernest@example.invalid
c() { GIT_AUTHOR_DATE="$1" GIT_COMMITTER_DATE="$1" git commit -q -m "$2"; }

cat > spec.md <<'EOF'
# kolejka-sms — spec

## 1. Cel
Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI, trzymając kolejkę w SQLite.

## 2. Architektura
Proces app.py (Flask) zapisuje zlecenia do tabeli outbox; worker.py co 10 sekund pobiera do 50 zleceń i wysyła je do bramki.

## 3. Decyzje
| # | Decyzja | Dlaczego |
|---|---|---|
| D1 | SQLite zamiast Redisa jako kolejka | jeden serwer, bez dodatkowej usługi do utrzymania |
| D2 | Identyfikatory całkowite, nie UUID | migracja na UUID cofnięta, bo bramka obcina pole referencji do 20 znaków |

## 4. Punkty otwarte
- Brak alertu, gdy outbox przekracza 1000 zleceń oczekujących na wysyłkę.
EOF
cat > README.md <<'EOF'
# kolejka-sms
Wdrożenie: `./deploy.sh prod`. Logi: `journalctl -u kolejka-sms`.
EOF
printf 'from flask import Flask\napp = Flask(__name__)\n' > app.py
printf '.env\n' > .gitignore
printf 'SMSAPI_TOKEN=\n' > .env.example
printf 'SMSAPI_TOKEN=kt-secret-7Q9ZL4MX2P\n' > .env
cat > deploy.sh <<'EOF'
#!/bin/sh
rsync -a --exclude .env ./ sms1:/srv/kolejka-sms/ && ssh sms1 systemctl restart kolejka-sms
EOF
chmod +x deploy.sh
git add spec.md README.md app.py .gitignore .env.example deploy.sh
c "2026-06-01T10:00:00" "init: kolejka SMS na SQLite"

printf 'import time\nBATCH = 50\nwhile True:\n    time.sleep(10)\n' > worker.py
git add worker.py; c "2026-06-10T10:00:00" "feat: worker wysyła paczki po 50"

printf 'ID_TYPE = "uuid"\n' > ids.py
git add ids.py; c "2026-07-02T10:00:00" "migracja identyfikatorów na UUID"
GIT_AUTHOR_DATE="2026-07-03T10:00:00" GIT_COMMITTER_DATE="2026-07-03T10:00:00" git revert -q --no-edit HEAD

printf 'import time\nBATCH = 50\nRETRY_ON = (429,)\nwhile True:\n    time.sleep(10)\n' > worker.py
git add worker.py; c "2026-08-20T10:00:00" "fix: ponawianie przy 429 z bramki"
git rev-parse HEAD > .git/kt-fixture-tip
```

- [ ] **Step 2: Write the user facts with a matching rule**

`EV/user-facts.md`, verbatim:

```markdown
# Fakty użytkownika (symulacja wywiadu)

Tester odpowiada na pytania sesji wyłącznie według tej tabeli. Pytanie pasuje do faktu,
gdy zawiera którekolwiek z jego słów-kluczy (bez względu na odmianę). Kilka pasujących
faktów → podaj wszystkie. Nic nie pasuje → „nie wiem”. Prośba o akceptację
(inwentarz, pakiet, commit) → „akceptuję”. Faktów, o które nie zapytano, nie dopowiadasz.

| Fakt | Słowa-klucze | Odpowiedź |
|---|---|---|
| F1 | wdrożenie, deploy, piątek, backup, cron, kopia | W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut; worker gubi wtedy zlecenia, więc w piątki nie wdrażamy. |
| F2 | token, SMSAPI, 401, wygasa, uwierzytelnianie | Token SMSAPI wygasa co 90 dni; odnawia się go w panelu SMSAPI, ostatnio 2026-08-01. Bramka zwraca wtedy 401. |
| F3 | eskalacja, kontakt, do kogo, zgłaszać, długa awaria | Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. |
| F4 | restart, serwer, sms1, worker nie działa, aktualizacja | Serwer sms1 restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek; worker sam nie wstaje — trzeba `systemctl start kolejka-sms-worker`. |
| F5 | baza, outbox.db, rozmiar, miejsce, okresowe | outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM. |
| F6 | dostęp, sekret, hasło, gdzie trzymać | Token SMSAPI leży w 1Password, sejf „Ops”, wpis „SMSAPI”. |
| F7 | kto, odbiorca, poziom, umiejętności | Kasia z supportu — zna Linuksa i SSH, nie programuje. |

Pytanie ogólne („pułapki”, „ryzyka”, „co się psuje”, „o czym musi wiedzieć”) bez słów-kluczy
z tabeli → F1 i F4.

Każdą odpowiedź logujesz: `turn N: „<cytat pytania>” → F<k>[, F<k>] | nie wiem | akceptuję`.
```

- [ ] **Step 3: Write the failing checker test**

Transcripts in this test are derived from the real `EV/sample-stream.jsonl` so that C3 is tested against the real format. The `sed` substitutions below use the spellings recorded in `EV/stream-format.md`; if that file records a different spelling for the error flag, change only the two `is_error` patterns.

`EV/check-package-test.sh`:

```bash
#!/usr/bin/env bash
# check-package-test.sh — the checker passes a good package and fails each criterion alone.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d /tmp/kt-checktest.XXXXXX)
bash "$EV/make-fixture.sh" "$T/fx" || { echo "FIXTURE FAILED"; exit 2; }
SHA=$(git -C "$T/fx" rev-parse --short HEAD)
mkdir -p "$T/tr-yes" "$T/tr-no" "$T/tr-err"
sed -e 's/kt-echo/kt-cold-reader/g' -e 's/PONG-7731/### S1\\nOdpowiedź: .\/deploy.sh prod\\nPodstawa: § Runbooki/g' \
  "$EV/sample-stream.jsonl" > "$T/tr-yes/turn-1.jsonl"
sed -e 's/kt-echo/kt-cold-reader/g' -e 's/"is_error":false/"is_error":true/g' -e 's/"is_error": false/"is_error": true/g' \
  "$T/tr-yes/turn-1.jsonl" > "$T/tr-err/turn-1.jsonl"
grep -v 'kt-echo' "$EV/sample-stream.jsonl" > "$T/tr-no/turn-1.jsonl"
python3 -I "$EV/stream.py" agent-results kt-cold-reader "$T/tr-yes/turn-1.jsonl" | grep -q 'Podstawa' \
  || { echo "FIXTURE FAILED: tr-yes has no cold-reader result"; exit 2; }

good() { cat <<EOF
# KT: kolejka-sms — dla: support
Stan na 2026-10-08, commit $SHA.
## Pułapki
- Nie wdrażaj w piątek: cron backup-sms o 23:00 blokuje bazę.
- Po restarcie sms1 uruchom ręcznie kolejka-sms-worker.
- Raz w miesiącu vacuum na outbox.db.
## Eskalacja
Awaria dłuższa niż 30 minut: Ernest na Signalu.
## Dostępy
Token SMSAPI: 1Password, sejf Ops, wpis SMSAPI.
EOF
}
pass=0; fail=0
expect() { # label expected_exit expected_substring package transcripts
  local out rc
  out=$(bash "$EV/check-package.sh" "$4" "$T/fx" "$5"); rc=$?
  if [ "$rc" = "$2" ] && [[ "$out" == *"$3"* ]]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (exit $rc)"; echo "$out" | sed 's/^/     /'; fi
}
good > "$T/good.md"
expect "good package (lower-case vacuum counts)" 0 "6/6 PASS" "$T/good.md" "$T/tr-yes"
{ good; echo "SMSAPI_TOKEN=kt-secret-7Q9ZL4MX2P"; } > "$T/c1.md"
expect "secret leaked" 1 "FAIL C1" "$T/c1.md" "$T/tr-yes"
{ good; echo "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI, trzymając kolejkę w SQLite."; } > "$T/c2.md"
expect "spec line copied" 1 "FAIL C2" "$T/c2.md" "$T/tr-yes"
expect "no cold-reader dispatch" 1 "FAIL C3" "$T/good.md" "$T/tr-no"
expect "cold-reader dispatch errored" 1 "FAIL C3" "$T/good.md" "$T/tr-err"
good | grep -v -e 'kolejka-sms-worker' -e 'Signalu' > "$T/c4.md"
expect "two tacit markers only" 1 "FAIL C4" "$T/c4.md" "$T/tr-yes"
good | sed "s/commit $SHA/commit nieznany/" > "$T/c5.md"
expect "no snapshot SHA" 1 "FAIL C5" "$T/c5.md" "$T/tr-yes"
echo "- dopisek" >> "$T/fx/spec.md"
expect "existing file modified" 1 "FAIL C6" "$T/good.md" "$T/tr-yes"
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 4: Run it to verify it fails**

Run: `bash EV/check-package-test.sh`
Expected: no `FIXTURE FAILED`; every case prints `FAIL …` (bash reports the missing `check-package.sh`, exit 127 ≠ expected); last line `0 passed, 8 failed`. A `FIXTURE FAILED` means Step 1 or the `sed` derivation is broken — fix that first.

- [ ] **Step 5: Implement the checker**

Criteria, exactly (names are part of the output contract):

| # | Name | PASS when |
|---|---|---|
| C1 | `sekret` | the package does not contain `kt-secret-7Q9ZL4MX2P` |
| C2 | `bez kopii speca` | no line of `<fixture>/spec.md` that is ≥ 50 characters after trimming whitespace occurs verbatim (fixed-string) in the package; FAIL detail names the first copied line |
| C3 | `cold-reader` | `python3 -I EV/stream.py agent-results kt-cold-reader <transcripts-dir>/*.jsonl` prints at least one line with `"is_error": false` whose text contains `Podstawa:` |
| C4 | `wiedza ukryta` | at least 3 of the 5 strings `backup-sms`, `90 dni`, `Signal`, `kolejka-sms-worker`, `VACUUM` occur in the package, case-insensitive (`grep -iF`); FAIL detail lists the found count |
| C5 | `snapshot` | the package contains some short SHA from `git -C <fixture> log --format=%h` |
| C6 | `bez zmian w istniejących plikach` | `git -C <fixture> diff --name-only --diff-filter=MDR $(cat <fixture>/.git/kt-fixture-tip)` is empty (added files are fine; any modified, deleted or renamed tracked file — spec.md included — fails); FAIL detail lists the files |

Plain bash with `grep -F`/`grep -E`; follow the output style of `EV/check-package-test.sh` (`ok`/`FAIL` lines, counter at the end).

- [ ] **Step 6: Run the checker test to verify it passes**

Run: `bash EV/check-package-test.sh`
Expected: `8 passed, 0 failed`, exit 0.

- [ ] **Step 7: Write the turn runner and smoke it end to end**

`EV/turn.sh`: resolve both path arguments with `readlink -f` first, then `cd <fixture-dir>` and run

```
claude -p "<message>" [--resume <session-id>] --model sonnet --output-format stream-json --verbose \
  --permission-mode acceptEdits \
  --allowedTools Read Grep Glob Write Edit Agent Skill "Bash(git *)" "Bash(ls *)" "Bash(wc *)" "Bash(cat *)" "Bash(head *)" "Bash(date *)" "Bash(mkdir *)" \
  --disallowedTools SendMessage ListAgents
```

with stdout to `<transcripts-dir>/turn-<N>.jsonl`; then parse the last line (`"type":"result"`) with `python3 -I` and print `SESSION <session_id>`, one `DENIED <tool_name>` per entry of `permission_denials`, then `result`. Follow `EV/probe-cold-reader.sh` for structure (`set -u`, positional args, no globals).

`EV/smoke-skill/SKILL.md`:

```markdown
---
name: kt-smoke
description: Use when the user says "kt-smoke". Test fixture for the knowledge-transfer harness.
---

Reply with exactly `SMOKE-SKILL-4412`.
```

Smoke run (Bash `timeout: 600000`):
```bash
F=$(mktemp -d /tmp/kt-smoke.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p "$F/.claude/skills/kt-smoke" "$F/.claude/agents"
cp EV/smoke-skill/SKILL.md "$F/.claude/skills/kt-smoke/"
cp EV/sample-agent.md "$F/.claude/agents/kt-echo.md"
printf '.claude/\n' >> "$F/.git/info/exclude"
TR=$(mktemp -d /tmp/kt-smoke-tr.XXXXXX)
bash EV/turn.sh "$F" "$TR" "kt-smoke"
# take <id> from the SESSION line above
bash EV/turn.sh "$F" "$TR" 'Użyj narzędzia Agent z subagent_type "kt-echo" i promptem "Odpowiedz zgodnie z instrukcją." Zwróć jego odpowiedź.' <id>
python3 -I EV/stream.py agent-results kt-echo "$TR"/turn-2.jsonl
```
Expected: turn 1 prints `SMOKE-SKILL-4412`, turn 2 a `SESSION` line with the same id, the last command a line with `"is_error": false` and `PONG-7731`; no `DENIED` line anywhere. Any `DENIED Skill` or `DENIED Agent` is a harness failure — fix `turn.sh`, never treat it as a skill failure later.

- [ ] **Step 8: Commit**

```bash
git add EV/make-fixture.sh EV/user-facts.md EV/turn.sh EV/check-package.sh EV/check-package-test.sh EV/smoke-skill
git commit -m "test: knowledge-transfer harness — fixture, user facts, turn runner, checker"
```

---

### Task 4: Baseline (RED) — the scenario without the skill

**Files:**
- Create: `EV/scenario.md`, `EV/baseline.md`, `EV/baseline-package.md`, `EV/baseline-transcripts/turn-*.jsonl`

**Interfaces:**
- Consumes: `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh`, `EV/user-facts.md` (Task 3).
- Produces: `EV/scenario.md` — the scenario message, reused unchanged by Task 5.

- [ ] **Step 1: Write the scenario**

`EV/scenario.md`, verbatim (the message is everything below the heading line):

```markdown
# Scenariusz (wiadomość pierwszej tury)
Od poniedziałku utrzymanie projektu kolejka-sms (to repo) przejmuje Kasia z supportu. Przygotuj dla niej dokument przekazania i zapisz go w repo. Szef już jej obiecał, że dostanie go dziś. Mam tylko kwadrans, potem wyjeżdżam na dwa tygodnie i nie będę osiągalny, więc nie przeciągaj.
```

Three pressures (authority, time, unavailability) deliberately push against the interview and the verification.

- [ ] **Step 2: Run the baseline session**

Bash `timeout: 600000` per turn:
```bash
F=$(mktemp -d /tmp/kt-baseline.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p EV/baseline-transcripts
bash EV/turn.sh "$F" EV/baseline-transcripts "$(tail -n +2 EV/scenario.md)"
```
No `.claude/skills/knowledge-transfer` and no `.claude/agents` in the fixture — that is the baseline.

User simulation: while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, strictly by the table and rules in `EV/user-facts.md`, logging each answer in its format. Stop when it reports done, or after 6 turns in total.

- [ ] **Step 3: Score it**

Find the package the session wrote (`git -C "$F" status --short`, `git -C "$F" log --stat -1`), copy it to `EV/baseline-package.md`, run:
`bash EV/check-package.sh EV/baseline-package.md "$F" EV/baseline-transcripts`
C3 fails by construction (no `kt-cold-reader` exists here). If C1, C2, C4, C5 and C6 all pass, stop and report BLOCKED — the skill would teach nothing measurable beyond the agent's existence.

- [ ] **Step 4: Record**

`EV/baseline.md`: the checker output verbatim; the answer log from Step 2; whether the session asked anything before writing; whether the package restates the spec in other words (C2 catches only verbatim copies — judge this by reading); verbatim quotes (from the `turn-*.jsonl` results) of how it justified skipping the interview, the verification or the secret handling; `DENIED` lines, if any. Quotes, not paraphrase — Task 5's "Common mistakes" table is built from them.

- [ ] **Step 5: Commit**

```bash
git add EV/scenario.md EV/baseline.md EV/baseline-package.md EV/baseline-transcripts
git commit -m "test: knowledge-transfer baseline without the skill"
```

---

### Task 5: The skill (GREEN) and its pressure run

**Files:**
- Create: `.claude/skills/knowledge-transfer/SKILL.md`
- Create: `EV/green.md`, `EV/green-package.md`, `EV/green-transcripts/turn-*.jsonl`

**Interfaces:**
- Consumes: agent `kt-cold-reader` and its answer format (Task 2); `EV/scenario.md`, `EV/baseline.md` (Task 4); harness (Task 3).

- [ ] **Step 1: Write SKILL.md**

Frontmatter exactly:

```yaml
---
name: knowledge-transfer
description: Use when someone is taking over a project, system or technical topic from the user — a successor engineer, a semi-technical support person, or the user themselves months later — and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---
```

The body must state each of these, in this order (prose is yours; values are fixed; target under 200 lines; follow the section style of `.claude/skills/writing-specs/SKILL.md`):

1. **Boundary** — spec = what the project is (writing-specs), design records = why decisions were made, `handoff` = agent session continuity; a KT package = a dated, recipient-prioritised snapshot of what those do not hold (traps, workarounds, failure symptoms, escalation), verified by a cold read. The skill reads the spec and never edits it; a spec–repo contradiction goes to the package's "Luki" section and the final report. It opens no flow-state run; if the repo has a run with a workspace recorded, the flow-guard denies main-thread writes — finish or park that run first.
2. **Intake** — four fields, asked in one message if missing: profile `następca` / `ja-później` / `support`; goal (what the recipient must be able to do afterwards); mode `projekt` (a repo exists) / `temat` (no repo — output path required, and never under `~/obsidian`: write elsewhere and tell the user to send the vault session a pointer); extra materials (optional).
3. **Process**, numbered: (1) intake; (2) scan — `projekt` mode only: spec, README, design records, CI/deploy config, `git log` (reverts, `fix:` commits and frequently changed files are trap candidates); (3) ✋ inventory: items with priority high/medium/low = cost of not knowing × whether it can be recovered from the repo, plus 5–8 scenarios with an answer key, built from high items; (4) interview on gaps only — every question carries a hypothesis from the repo for the user to confirm, reject or correct; time pressure shortens the interview to the high items, it never removes it; (5) write `docs/kt/YYYY-MM-DD-<profil>.md` (`temat` mode: the intake path); (6) cold read; (7) ✋ final: package + gap report; the user's yes = commit of the package file only.
4. **Section matrix** — verbatim:

   | Sekcja | support | następca | ja-później |
   |---|---|---|---|
   | 0 Jak czytać, stan na (data, SHA) | ✓ | ✓ | ✓ |
   | 1 Co to robi i dla kogo | ✓ | ✓ | ✓ |
   | Objawy awarii i jak je rozpoznać | ✓ | — | — |
   | Runbooki (uruchom, wdróż, rollback) | ✓ | link | link |
   | Mapa systemu (linki do speca i kodu) | — | ✓ | link |
   | Jak zmieniać (build, test, release) | — | ✓ | — |
   | Decyzje i dlaczego (linki do rekordów) | — | ✓ | — |
   | Dług i otwarte ryzyka | — | ✓ | ✓ |
   | Gdzie stanąłem, jak odtworzyć środowisko | — | — | ✓ |
   | Pułapki i obejścia | ✓ | ✓ | ✓ |
   | Eskalacja: kiedy i do kogo | ✓ | kto co wie | — |
   | Dostępy: gdzie, nigdy jakie | ✓ | ✓ | — |
   | Sprawdź się: scenariusze z odpowiedziami | ✓ | ✓ | ✓ |
   | Luki | ✓ | ✓ | ✓ |

   Plus: link to the spec instead of restating it; for `ja-później`, if the package reads like a copy of the spec, cut it to links + traps.
5. **Cold read** — dispatch `subagent_type: "kt-cold-reader"` in the foreground (`run_in_background: false` — the next step needs its answers), with `model: "haiku"` for `support`, `model: "sonnet"` for `następca` and `ja-później`; the prompt is `PAKIET:` + the package with the answers of "Sprawdź się" removed + `SCENARIUSZE:` + the numbered scenarios. A scenario fails when `Podstawa` is `NIE WIEM Z PAKIETU` or `ZGADUJĘ`, or the answer contradicts the key. Patch the package and re-run; at most 2 patch rounds; what still fails goes into "Luki" and the final report — no third round.
6. **Hard rules** — secrets: location only (vault, 1Password entry, env var name), never a value; checked before the cold-reader dispatch too, since the prompt carries the package. Polish, written per the `polszczyzna` skill; plain language for `support`. Commit only the package, only after the final ✋.
7. **Common mistakes** — a table built from `EV/baseline.md`: each baseline failure, quoted, with its counter. Only failures the baseline actually showed; do not add hypothetical ones.

- [ ] **Step 2: Run the pressure scenario with the skill**

Bash `timeout: 600000` per turn:
```bash
F=$(mktemp -d /tmp/kt-green.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p "$F/.claude/skills/knowledge-transfer" "$F/.claude/agents" EV/green-transcripts
cp .claude/skills/knowledge-transfer/SKILL.md "$F/.claude/skills/knowledge-transfer/"
cp .claude/agents/kt-cold-reader.md "$F/.claude/agents/"
printf '.claude/\n' >> "$F/.git/info/exclude"
bash EV/turn.sh "$F" EV/green-transcripts "$(tail -n +2 EV/scenario.md)"
```
User simulation: while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, strictly by the table and rules in `EV/user-facts.md`, logging each answer in its format. Stop when it reports done, or after 8 turns in total.

- [ ] **Step 3: Score it**

Copy the package (`$F/docs/kt/*.md`) to `EV/green-package.md` and run:
`bash EV/check-package.sh EV/green-package.md "$F" EV/green-transcripts`
Expected: `6/6 PASS`. Also check by reading the transcript: the session stopped at the inventory gate before writing the package, and its interview questions carried hypotheses. Any `DENIED` line is a harness failure (Task 3, Step 7), not a skill failure.

- [ ] **Step 4: Refactor if needed**

On any FAIL or a skipped gate: quote the session's rationalization, add the counter to SKILL.md, re-run Steps 2–3 on a fresh fixture with transcript dir `EV/green-transcripts-r<N>`. At most 2 refactor runs; still failing → report BLOCKED with the checker output and the quotes.

- [ ] **Step 5: Record and commit**

`EV/green.md`: checker output, the answer log, turn count, gate/interview observations, refactor rounds with the quotes that drove them.

```bash
git add .claude/skills/knowledge-transfer/SKILL.md EV/green.md EV/green-package.md EV/green-transcripts*
git commit -m "skills: knowledge-transfer — recipient-specific handover packages verified by a cold read (D29)"
```

---

### Task 6: README and design record to current state

Dotfiles have no living spec; README and the design record are the state documents this change makes untrue.

**Files:**
- Modify: `.claude/README.md` (section `## The flow`, after the "Always-on discipline" paragraph)
- Modify: `.flow/specs/2026-10-08-knowledge-transfer-design.md` (section `## Do sprawdzenia w implementacji`)

- [ ] **Step 1: README**

Add one paragraph, headed `**Outside the pipeline**`: `writing-specs` bootstraps a project's living spec; `knowledge-transfer` writes a dated handover package for a successor, a support person or the user's later self, checked by the `kt-cold-reader` agent, which sees only the package; neither opens a run. Follow the paragraph style of the "Always-on discipline" paragraph above it.

- [ ] **Step 2: Design record**

Replace the body of `## Do sprawdzenia w implementacji` with the result from `EV/probe.md` (does `tools: TaskStop` spawn under Sonnet and stay blind — one sentence, with a pointer to `EV/probe.md`) and rename the heading to `## Sprawdzone w implementacji`.

- [ ] **Step 3: Verify**

Run: `grep -n 'knowledge-transfer' .claude/README.md && grep -n 'Sprawdzone w implementacji' .flow/specs/2026-10-08-knowledge-transfer-design.md && bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-package-test.sh | tail -1 && bash .flow/specs/2026-10-08-knowledge-transfer-evidence/stream-test.sh | tail -1`
Expected: one README line, one heading line, `8 passed, 0 failed`, `5 passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add .claude/README.md .flow/specs/2026-10-08-knowledge-transfer-design.md
git commit -m "docs: knowledge-transfer in README; D30 probe result in the design record"
```

---

## After merge (finish stage, not a task)

New files under `.claude/agents/` and `.claude/skills/` reach `~/.claude` only through dotter's per-file symlinks. On `pc`: `dotter deploy`. On `laptop` (`~/dotfiles` is not mutagen-synced): `git pull`, then `dotter deploy`. Then start a new session — agent definitions are read at session start.
