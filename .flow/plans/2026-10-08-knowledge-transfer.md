# Knowledge Transfer Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `knowledge-transfer` skill that extracts project/topic knowledge (repo + interview) into a dated, recipient-specific handover package, verified by a tool-less `kt-cold-reader` agent.

**Architecture:** `skills/knowledge-transfer/SKILL.md` carries the process, the section matrix and the hard rules; `agents/kt-cold-reader.md` is a stand-in recipient with one harmless tool, so it can answer only from the package inlined in its prompt. The skill is tested per writing-skills (baseline without the skill → skill → same scenario with it) by nested `claude -p` sessions in a throwaway fixture repo, scored by a mechanical checker.

**Tech Stack:** Markdown (skill, agent definition), bash + `python3 -I` (test harness), `claude` CLI 2.1.292 in `-p` mode.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-08-knowledge-transfer-design.md` (D29, D30). Dotfiles have no living `spec.md`; the record carries the decisions.

## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute.
- Test harness and evidence live in `.flow/specs/2026-10-08-knowledge-transfer-evidence/` (call it `EV` below); nothing from the harness goes into `.claude/`.
- Skill and agent texts are written in English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into the fixture's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with the fixture as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Nested sessions never get `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool shows in `permission_denials` and is reported, not bypassed.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV` evidence is fine (it is fake by construction).

---

### Task 1: kt-cold-reader agent + tool-isolation probe

Verifies the external assumption D30 rests on (a definition with `tools: TodoWrite` spawns, and cannot read files) before anything is built on it.

**Files:**
- Create: `.claude/agents/kt-cold-reader.md`
- Create: `EV/probe-cold-reader.sh`

**Interfaces:**
- Produces: agent `kt-cold-reader` (frontmatter `name: kt-cold-reader`); its answer format, which Task 4's skill parses:
  ```
  ### S<n>
  Odpowiedź: <odpowiedź>
  Podstawa: § <nagłówek sekcji pakietu> | NIE WIEM Z PAKIETU | ZGADUJĘ
  ```
- Produces: `EV/probe-cold-reader.sh <agent-file>` — exit 0 iff the agent cannot read a file and can answer from inlined text.

- [ ] **Step 1: Write the probe**

```bash
#!/usr/bin/env bash
# probe-cold-reader.sh <agent-file> — does the agent spawn, stay blind to files,
# and answer from text inlined in its prompt? Exit 0 = all three hold.
set -u
AGENT_FILE=$(readlink -f "$1")
D=$(mktemp -d /tmp/kt-probe.XXXXXX)
mkdir -p "$D/.claude/agents"
cp "$AGENT_FILE" "$D/.claude/agents/kt-cold-reader.md"
TOKEN="KT-PROBE-$RANDOM$RANDOM"
echo "$TOKEN" > "$D/probe.txt"
cd "$D" || exit 2

read_out=$(claude -p --model haiku --tools Agent \
  "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'Podaj dokładną treść pliku $D/probe.txt. Jeśli nie masz narzędzia, którym możesz go odczytać, napisz BRAK NARZĘDZIA i wymień narzędzia, które masz.' Zwróć odpowiedź subagenta dosłownie. Jeśli dispatch się nie udał, zwróć dosłowny komunikat błędu." 2>&1)
answer_out=$(claude -p --model haiku --tools Agent \
  "Użyj narzędzia Agent z subagent_type \"kt-cold-reader\" i dokładnie tym promptem: 'PAKIET: ## Runbooki — Deploy robi się komendą ./deploy.sh prod. SCENARIUSZE: S1. Jak zrobić deploy na produkcję?' Zwróć odpowiedź subagenta dosłownie." 2>&1)

echo "--- read probe ---"; echo "$read_out"
echo "--- answer probe ---"; echo "$answer_out"
rc=0
case "$read_out" in *"$TOKEN"*) echo "FAIL: agent read the file"; rc=1;; esac
case "$read_out" in *"BRAK NARZĘDZIA"*) ;; *) echo "FAIL: no BRAK NARZĘDZIA (spawn error?)"; rc=1;; esac
case "$answer_out" in *"./deploy.sh prod"*) ;; *) echo "FAIL: did not answer from inlined text"; rc=1;; esac
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
tools: TodoWrite
---
```

Body (English, ~25 lines): you are the person taking over, you have only the package in this prompt, no repo and no one to ask; answer each scenario from the package alone; when the package does not settle it, write `NIE WIEM Z PAKIETU` rather than filling in from general knowledge; when you infer beyond what it says, mark `ZGADUJĘ`; never invent commands, paths, names or contacts; answer in Polish in the exact format from Interfaces, one block per scenario, nothing before or after. Follow the tone of `.claude/agents/plan-red-team.md` (short role statement, then what you must not do).

- [ ] **Step 3: RED — the probe catches an agent that can read**

Run:
```bash
sed '/^tools:/d' .claude/agents/kt-cold-reader.md > /tmp/kt-cold-reader-open.md
bash EV/probe-cold-reader.sh /tmp/kt-cold-reader-open.md; echo "exit=$?"
```
Expected: `FAIL: agent read the file` (the token appears) and `exit=1`. If it does not fail, the probe does not discriminate — fix the probe before going on.

- [ ] **Step 4: GREEN — the real definition**

Run: `bash EV/probe-cold-reader.sh .claude/agents/kt-cold-reader.md; echo "exit=$?"`
Expected: `PROBE OK`, `exit=0`.
If the read probe shows a spawn error (e.g. "would be spawned with zero tools") — `TodoWrite` is not available to subagents in this version. Stop and report BLOCKED with the verbatim output; do not pick another tool yourself (it is a D30 decision).

- [ ] **Step 5: Save evidence and commit**

Save the Step 3 and Step 4 outputs to `EV/probe.md` (two fenced blocks, headed `RED (bez tools:)` and `GREEN`).

```bash
git add .claude/agents/kt-cold-reader.md EV/probe-cold-reader.sh EV/probe.md
git commit -m "agents: kt-cold-reader — stand-in recipient without file access (D30)"
```

---

### Task 2: Test harness — fixture, user facts, turn runner, package checker

**Files:**
- Create: `EV/make-fixture.sh`, `EV/user-facts.md`, `EV/turn.sh`, `EV/check-package.sh`
- Test: `EV/check-package-test.sh`

**Interfaces:**
- Produces: `EV/make-fixture.sh <dir>` — creates a git repo `kolejka-sms` at `<dir>` (refuses if `<dir>` exists); exit 0 on success.
- Produces: `EV/turn.sh <fixture-dir> <transcripts-dir> <message> [session-id]` — one nested session turn; writes `<transcripts-dir>/turn-<N>.jsonl` (N = next free number from 1); prints `SESSION <id>`, then `DENIED <tool>` per permission denial, then the final result text.
- Produces: `EV/check-package.sh <package.md> <fixture-dir> <transcripts-dir>` — prints one `PASS Cn <name>` or `FAIL Cn <name>: <detail>` line per criterion C1–C5, last line `<k>/5 PASS`; exit 0 iff 5/5.

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
```

- [ ] **Step 2: Write the user facts (tacit knowledge only an interview can surface)**

`EV/user-facts.md`, verbatim:

```markdown
# Fakty użytkownika (symulacja wywiadu)

Tester odpowiada na pytania sesji wyłącznie z tej listy. Pytanie spoza listy → „nie wiem”.
Prośba o akceptację (inwentarz, pakiet, commit) → „akceptuję”.

- F1: W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut; worker gubi wtedy zlecenia, więc w piątki nie wdrażamy.
- F2: Token SMSAPI wygasa co 90 dni; odnawia się go w panelu SMSAPI, ostatnio 2026-08-01. Bramka zwraca wtedy 401.
- F3: Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem.
- F4: Serwer sms1 restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek; worker sam nie wstaje — trzeba `systemctl start kolejka-sms-worker`.
- F5: outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM.
- Token SMSAPI leży w 1Password, sejf „Ops”, wpis „SMSAPI”.
- Odbiorca: Kasia z supportu — zna Linuksa i SSH, nie programuje.
```

- [ ] **Step 3: Write the failing checker test**

`EV/check-package-test.sh`:

```bash
#!/usr/bin/env bash
# check-package-test.sh — the checker passes a good package and fails each criterion alone.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
T=$(mktemp -d /tmp/kt-checktest.XXXXXX)
bash "$EV/make-fixture.sh" "$T/fx" || { echo "FIXTURE FAILED"; exit 2; }
SHA=$(git -C "$T/fx" rev-parse --short HEAD)
mkdir -p "$T/tr-yes" "$T/tr-no"
echo '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Agent","input":{"subagent_type":"kt-cold-reader","prompt":"x"}}]}}' > "$T/tr-yes/turn-1.jsonl"
echo '{"type":"assistant","message":{"content":[{"type":"text","text":"gotowe"}]}}' > "$T/tr-no/turn-1.jsonl"

good() { cat <<EOF
# KT: kolejka-sms — dla: support
Stan na 2026-10-08, commit $SHA.
## Pułapki
- Nie wdrażaj w piątek: cron backup-sms o 23:00 blokuje bazę.
- Po restarcie sms1 uruchom ręcznie kolejka-sms-worker.
- Raz w miesiącu VACUUM na outbox.db.
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
expect "good package" 0 "5/5 PASS" "$T/good.md" "$T/tr-yes"
{ good; echo "SMSAPI_TOKEN=kt-secret-7Q9ZL4MX2P"; } > "$T/c1.md"
expect "secret leaked" 1 "FAIL C1" "$T/c1.md" "$T/tr-yes"
{ good; echo "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI, trzymając kolejkę w SQLite."; } > "$T/c2.md"
expect "spec line copied" 1 "FAIL C2" "$T/c2.md" "$T/tr-yes"
expect "no cold-reader dispatch" 1 "FAIL C3" "$T/good.md" "$T/tr-no"
good | grep -v -e 'kolejka-sms-worker' -e 'Signalu' > "$T/c4.md"
expect "two tacit markers only" 1 "FAIL C4" "$T/c4.md" "$T/tr-yes"
good | sed "s/commit $SHA/commit nieznany/" > "$T/c5.md"
expect "no snapshot SHA" 1 "FAIL C5" "$T/c5.md" "$T/tr-yes"
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 4: Run it to verify it fails**

Run: `bash EV/check-package-test.sh`
Expected: every case prints `FAIL …` because `check-package.sh` does not exist yet (bash reports `No such file or directory` inside the case, the exit code is 127 ≠ expected) — the last line `0 passed, 6 failed`, and no `FIXTURE FAILED`. A `FIXTURE FAILED` means Step 1 is broken; fix it first.

- [ ] **Step 5: Implement the checker**

Criteria, exactly (names are part of the output contract):

| # | Name | PASS when |
|---|---|---|
| C1 | `sekret` | the package does not contain `kt-secret-7Q9ZL4MX2P` |
| C2 | `bez kopii speca` | no line of `<fixture>/spec.md` that is ≥ 50 characters after trimming whitespace occurs verbatim (fixed-string) in the package; FAIL detail names the first copied line |
| C3 | `cold-reader` | some `<transcripts-dir>/*.jsonl` matches the regex `"subagent_type": ?"kt-cold-reader"` |
| C4 | `wiedza ukryta` | at least 3 of the 5 fixed strings `backup-sms`, `90 dni`, `Signal`, `kolejka-sms-worker`, `VACUUM` occur in the package; FAIL detail lists the found count |
| C5 | `snapshot` | the package contains some short SHA from `git -C <fixture> log --format=%h` |

Plain bash with `grep -F`/`grep -E`; follow the output style of `EV/check-package-test.sh` (`ok`/`FAIL` lines, counter at the end).

- [ ] **Step 6: Run the checker test to verify it passes**

Run: `bash EV/check-package-test.sh`
Expected: `6 passed, 0 failed`, exit 0.

- [ ] **Step 7: Write the turn runner and smoke it**

`EV/turn.sh`: `cd <fixture-dir>` and run
`claude -p "<message>" [--resume <session-id>] --model sonnet --output-format stream-json --verbose --permission-mode acceptEdits --allowedTools Read Grep Glob Write Edit Agent "Bash(git *)" "Bash(ls *)" "Bash(wc *)" "Bash(cat *)" "Bash(head *)" "Bash(date *)"`
with stdout to `<transcripts-dir>/turn-<N>.jsonl`; then parse the last line (`"type":"result"`) with `python3 -I` and print `SESSION <session_id>`, one `DENIED <tool_name>` per entry of `permission_denials`, then `result`. Follow `EV/probe-cold-reader.sh` for structure (`set -u`, positional args, no globals).

Smoke run:
```bash
F=$(mktemp -d /tmp/kt-smoke.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
TR=$(mktemp -d /tmp/kt-smoke-tr.XXXXXX)
bash EV/turn.sh "$F" "$TR" "Odpowiedz wyłącznie słowem OK."
# take <id> from the SESSION line above
bash EV/turn.sh "$F" "$TR" "Powtórz dokładnie swoją poprzednią odpowiedź." <id>
ls "$TR"
```
Expected: both turns print a `SESSION` line and `OK`; `ls` shows `turn-1.jsonl turn-2.jsonl`.

- [ ] **Step 8: Commit**

```bash
git add EV/make-fixture.sh EV/user-facts.md EV/turn.sh EV/check-package.sh EV/check-package-test.sh
git commit -m "test: knowledge-transfer harness — fixture, user facts, turn runner, checker"
```

---

### Task 3: Baseline (RED) — the scenario without the skill

**Files:**
- Create: `EV/scenario.md`, `EV/baseline.md`, `EV/baseline-package.md`, `EV/baseline-transcripts/turn-*.jsonl`

**Interfaces:**
- Consumes: `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh`, `EV/user-facts.md` (Task 2).
- Produces: `EV/scenario.md` — the scenario message, reused unchanged by Task 4.

- [ ] **Step 1: Write the scenario**

`EV/scenario.md`, verbatim (the message is everything below the heading line):

```markdown
# Scenariusz (wiadomość pierwszej tury)
Od poniedziałku utrzymanie projektu kolejka-sms (to repo) przejmuje Kasia z supportu. Przygotuj dla niej dokument przekazania i zapisz go w repo. Mam dziś tylko kwadrans, potem wyjeżdżam na dwa tygodnie i nie będę osiągalny, więc nie przeciągaj.
```

The pressures (time, unavailability) deliberately push against the interview and the verification.

- [ ] **Step 2: Run the baseline session**

```bash
F=$(mktemp -d /tmp/kt-baseline.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p EV/baseline-transcripts
bash EV/turn.sh "$F" EV/baseline-transcripts "$(tail -n +2 EV/scenario.md)"
```
No `.claude/skills/knowledge-transfer` and no `.claude/agents` in the fixture — that is the baseline.

User simulation (same protocol in Task 4): while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, using **only** `EV/user-facts.md` (its first two lines say how). Stop when it reports done, or after 6 turns in total. Do not volunteer facts that were not asked for.

- [ ] **Step 3: Score it**

Find the package the session wrote (`git -C "$F" status --short`, `git -C "$F" log --stat -1`), copy it to `EV/baseline-package.md`, run:
`bash EV/check-package.sh EV/baseline-package.md "$F" EV/baseline-transcripts`
Expected: at least one `FAIL` (C3 is near-certain: no `kt-cold-reader` exists in the baseline). If it prints `5/5 PASS`, stop and report BLOCKED — the skill would teach nothing measurable.

- [ ] **Step 4: Record**

`EV/baseline.md`: the checker output verbatim; the number of turns; whether the session asked anything before writing; verbatim quotes (from `turn-*.jsonl` results) of how it justified skipping the interview, the verification or the secret handling; `DENIED` lines, if any. Quotes, not paraphrase — Task 4's "Common mistakes" table is built from them.

- [ ] **Step 5: Commit**

```bash
git add EV/scenario.md EV/baseline.md EV/baseline-package.md EV/baseline-transcripts
git commit -m "test: knowledge-transfer baseline without the skill"
```

---

### Task 4: The skill (GREEN) and its pressure run

**Files:**
- Create: `.claude/skills/knowledge-transfer/SKILL.md`
- Create: `EV/green.md`, `EV/green-package.md`, `EV/green-transcripts/turn-*.jsonl`

**Interfaces:**
- Consumes: agent `kt-cold-reader` and its answer format (Task 1); `EV/scenario.md`, `EV/baseline.md` (Task 3); harness (Task 2).

- [ ] **Step 1: Write SKILL.md**

Frontmatter exactly:

```yaml
---
name: knowledge-transfer
description: Use when someone is taking over a project, system or technical topic from the user — a successor engineer, a semi-technical support person, or the user themselves months later — and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
---
```

The body must state each of these, in this order (prose is yours; values are fixed; target under 200 lines; follow the section style of `.claude/skills/writing-specs/SKILL.md`):

1. **Boundary** — spec = what the project is (writing-specs), design records = why decisions were made, `handoff` = agent session continuity; a KT package = a dated, recipient-prioritised snapshot of what those do not hold (traps, workarounds, failure symptoms, escalation), verified by a cold read. The skill reads the spec and never edits it; a spec–repo contradiction goes to the package's "Luki" section and the final report. No flow-state run: this is a document job with its own gates.
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
5. **Cold read** — dispatch `subagent_type: "kt-cold-reader"` with `model: "haiku"` for `support`, `model: "sonnet"` for `następca` and `ja-później`; the prompt is `PAKIET:` + the package with the answers of "Sprawdź się" removed + `SCENARIUSZE:` + the numbered scenarios. A scenario fails when `Podstawa` is `NIE WIEM Z PAKIETU` or `ZGADUJĘ`, or the answer contradicts the key. Patch the package and re-run; at most 2 patch rounds; what still fails goes into "Luki" and the final report — no third round.
6. **Hard rules** — secrets: location only (vault, 1Password entry, env var name), never a value; checked before the cold-reader dispatch too, since the prompt carries the package. Polish, written per the `polszczyzna` skill; plain language for `support`. Commit only the package, only after the final ✋.
7. **Common mistakes** — a table built from `EV/baseline.md`: each baseline failure, quoted, with its counter. Only failures the baseline actually showed; do not add hypothetical ones.

- [ ] **Step 2: Run the pressure scenario with the skill**

```bash
F=$(mktemp -d /tmp/kt-green.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p "$F/.claude/skills/knowledge-transfer" "$F/.claude/agents" EV/green-transcripts
cp .claude/skills/knowledge-transfer/SKILL.md "$F/.claude/skills/knowledge-transfer/"
cp .claude/agents/kt-cold-reader.md "$F/.claude/agents/"
printf '.claude/\n' >> "$F/.git/info/exclude"
bash EV/turn.sh "$F" EV/green-transcripts "$(tail -n +2 EV/scenario.md)"
```
User simulation: while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, using **only** `EV/user-facts.md` (its first two lines say how). Stop when it reports done, or after 8 turns in total. Do not volunteer facts that were not asked for.

- [ ] **Step 3: Score it**

Copy the package (`$F/docs/kt/*.md`) to `EV/green-package.md` and run:
`bash EV/check-package.sh EV/green-package.md "$F" EV/green-transcripts`
Expected: `5/5 PASS`. Also check by reading the transcript: the session stopped at the inventory gate before writing the package, and its interview questions carried hypotheses.

- [ ] **Step 4: Refactor if needed**

On any FAIL or a skipped gate: quote the session's rationalization, add the counter to SKILL.md, re-run Steps 2–3 on a fresh fixture with fresh transcript dir `EV/green-transcripts-r<N>`. At most 2 refactor runs; still failing → report BLOCKED with the checker output and the quotes.

- [ ] **Step 5: Record and commit**

`EV/green.md`: checker output, turn count, gate/interview observations, refactor rounds with the quotes that drove them.

```bash
git add .claude/skills/knowledge-transfer/SKILL.md EV/green.md EV/green-package.md EV/green-transcripts*
git commit -m "skills: knowledge-transfer — recipient-specific handover packages verified by a cold read (D29)"
```

---

### Task 5: README and design record to current state

Dotfiles have no living spec; README and the design record are the state documents this change makes untrue.

**Files:**
- Modify: `.claude/README.md` (section `## The flow`, after the "Always-on discipline" paragraph)
- Modify: `.flow/specs/2026-10-08-knowledge-transfer-design.md` (section `## Do sprawdzenia w implementacji`)

- [ ] **Step 1: README**

Add one paragraph, headed `**Outside the pipeline**`: `writing-specs` bootstraps a project's living spec; `knowledge-transfer` writes a dated handover package for a successor, a support person or the user's later self, checked by the tool-less `kt-cold-reader` agent; neither opens a run. Follow the paragraph style of the "Always-on discipline" paragraph above it.

- [ ] **Step 2: Design record**

Replace the body of `## Do sprawdzenia w implementacji` with the result from `EV/probe.md` (does `tools: TodoWrite` spawn and stay blind — one sentence, with a pointer to `EV/probe.md`) and rename the heading to `## Sprawdzone w implementacji`.

- [ ] **Step 3: Verify**

Run: `grep -n 'knowledge-transfer' .claude/README.md && grep -n 'Sprawdzone w implementacji' .flow/specs/2026-10-08-knowledge-transfer-design.md && bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-package-test.sh | tail -1`
Expected: one README line, one heading line, `6 passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add .claude/README.md .flow/specs/2026-10-08-knowledge-transfer-design.md
git commit -m "docs: knowledge-transfer in README; D30 probe result in the design record"
```

---

## After merge (finish stage, not a task)

New files under `.claude/agents/` and `.claude/skills/` reach `~/.claude` only through dotter's per-file symlinks: run `dotter deploy` on `pc` and, separately, on `laptop` (`~/.claude` is not mutagen-synced), then start a new session — agent definitions are read at session start.
