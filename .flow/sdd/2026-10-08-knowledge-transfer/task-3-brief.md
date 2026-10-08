## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

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

Transcripts in this test are derived from the real `EV/sample-stream.jsonl` so that C3 is tested against the real format. The `sed` substitutions below use the spellings recorded in `EV/stream-format.md`. If that file records a different spelling for the error flag, change only the two `is_error` patterns; if a successful `tool_result` carries no error flag at all, derive `tr-err` by injecting `"is_error":true,` right after `"type":"tool_result",` instead of flipping. The `FIXTURE FAILED` guards catch a derivation that does not take.

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
bash EV/turn.sh "$F" "$TR" 'Uruchom git log --oneline -1 i podaj jego wynik.' <id>
```
Expected: turn 1 prints `SMOKE-SKILL-4412`, turn 2 a `SESSION` line with the same id, the `stream.py` command a line with `"is_error": false` and `PONG-7731`, turn 3 the line `… fix: ponawianie przy 429 z bramki`; no `DENIED` line anywhere. A `DENIED Bash` on turn 3 means the rule syntax is wrong: switch every `"Bash(x *)"` to the `"Bash(x:*)"` form and re-run the smoke. Any `DENIED Skill` or `DENIED Agent` is a harness failure — fix `turn.sh`, never treat it as a skill failure later.

- [ ] **Step 8: Commit**

```bash
git add EV/make-fixture.sh EV/user-facts.md EV/turn.sh EV/check-package.sh EV/check-package-test.sh EV/smoke-skill
git commit -m "test: knowledge-transfer harness — fixture, user facts, turn runner, checker"
```

---
