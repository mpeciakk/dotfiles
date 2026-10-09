## Global Constraints

- All paths are relative to the repo root unless absolute. `EV` means `.flow/specs/2026-10-08-knowledge-transfer-evidence`. In code blocks, `EV/` stands for that path: substitute it when you run or copy a command.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill texts are English, like every skill in `.claude/skills/`. The package, scenario prompts, user-fact answers and the cold-reader's answers are Polish.
- The company knowledge base is named exactly `docs.internal.animativ.dev`.
- A nested `claude -p` loads the personal-level `~/.claude/skills/knowledge-transfer` and `~/.claude/agents/kt-cold-reader.md` instead of the fixture's project-level copies (`EV/stream-format.md`, last section). Every live run therefore sets `CLAUDE_CONFIG_DIR` to a dir made by `EV/make-config-dir.sh`. The proof of what loaded is the `Base directory for this skill:` line in the Skill tool result.
- Never run a nested `claude` with the dotfiles repo or the worktree as cwd. The run's flow-guard would deny its writes.
- Every nested `claude -p` call goes through `EV/turn.sh` unchanged, prefixed with `CLAUDE_CONFIG_DIR=<dir>`. Never use `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`.
- Bash tool calls that run a nested session use `timeout: 600000`. A turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The worktree guard refuses inline multi-line shell and python. Put one-off helpers in `/tmp` (never in the repo), and run them as plain `bash /tmp/<name>.sh` commands, one per Bash call, with the worktree as cwd.
- Shell variables do not persist between Bash calls. Write fixture and config-dir paths to a file in `/tmp`, or reuse them as literals.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine.
- Do not commit anything from `~/.claude/projects/` (real session transcripts). They may be read and quoted.

---

### Task 1: Harness — `check-d32.sh` and `make-config-dir.sh`

**Files:**
- Create: `EV/check-d32.sh`, `EV/check-d32-test.sh`, `EV/make-config-dir.sh`, `EV/make-config-dir-test.sh`

**Interfaces:**
- Consumes: nothing from other tasks. `EV/team-package.md` (committed, pre-D32 package) is read by the test.
- Produces:
  - `bash EV/check-d32.sh <package.md>` prints one line per criterion and then `<k>/4 PASS`. It exits 0 iff all four criteria pass, and exits non-zero on a missing file. A passing line is `PASS <id> <name>`; a failing line is `FAIL <id> <name>: <detail>`. The criteria:
    - **D1 `daty`:** no dates in prose. Before matching, the check removes Markdown link targets (`](…)`) and backtick spans that contain `/`, so a link or path to a dated file is not a date. Three patterns count as dates (`grep -E`):
      - `\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b`;
      - `\b[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{4}\b`;
      - `\b[0-9]{1,2} (stycznia|lutego|marca|kwietnia|maja|czerwca|lipca|sierpnia|września|października|listopada|grudnia) [0-9]{4}\b`.

      On failure, the `FAIL` line is followed by every matching line, each indented with five spaces and prefixed with its line number (`     64: …`).
    - **D2 `sekcje`:** the lines starting with `## ` are exactly eleven, and the i-th starts with the i-th of `## 0. Jak czytać`, `## 1. Cel i granice`, `## 2. Jak to działa`, `## 3. Stan projektu`, `## 4. Środowisko i dostępy`, `## 5. Typowe zadanie krok po kroku`, `## 6. Awarie i obejścia`, `## 7. Rozwój`, `## 8. Kto co wie`, `## 9. Luki`, `## 10. Sprawdź się`. A prefix match allows longer headings.
    - **D3 `luki`:** a line starting with `## 9. Luki` exists. In that section (up to the next `## ` line), every item contains both `Skutek:` and `Do czasu ustalenia:`, after `**` is removed. An item is a line starting with `- ` or with a number and `. ` (`1. `), plus the lines after it that start with whitespace. A section with no non-blank lines passes. A section with text but no items fails.
    - **D4 `setup`:** no line matches `/home/|/tmp/|~/\.claude|/Users/|\bpc\b|\blaptop\b` (`grep -E`, case-sensitive). `pc` and `laptop` are the user's machine names.
  - `bash EV/make-config-dir.sh <src> <dst>` creates `<dst>` and prints its path. `<dst>` must not exist; if it does, the script exits non-zero. For every top-level entry of `<src>`, including dotfiles, the script creates a symlink `<dst>/<name>` → `<src>/<name>`. `skills/` and `agents/` are exceptions: each becomes a real directory filled with per-entry symlinks, minus `skills/knowledge-transfer` and `agents/kt-cold-reader.md`. Nothing is copied.

- [ ] **Step 1: Write the failing tests**

`EV/check-d32-test.sh`, in the style of `EV/check-package-test.sh`:

```bash
#!/usr/bin/env bash
# check-d32-test.sh — check-d32.sh passes a D32-shaped package and fails each criterion alone.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-d32test.XXXXXX)
cat > "$T/good.md" <<'EOF'
# Przekazanie projektu kolejka-sms

## 0. Jak czytać
Opisuje commit abc1234. Wersja 0.9.1, serwer 10.100.100.205.

## 1. Cel i granice
Usługa kolejkuje SMS-y i wysyła je przez bramkę.

## 2. Jak to działa
Worker czyta outbox.db i wysyła zlecenia.

## 3. Stan projektu
Działa produkcyjnie. Wg speca ponawianie 429 jest niesprawdzone na produkcji.

## 4. Środowisko i dostępy
Infrastruktura firmowa: docs.internal.animativ.dev.

## 5. Typowe zadanie krok po kroku
1. Na serwerze: `systemctl status kolejka-sms-worker`.

## 6. Awarie i obejścia
- Worker nie wstaje po restarcie serwera.

## 7. Rozwój
Testy: `pytest`.
Decyzje: [rekord](../../.flow/specs/2026-10-08-x-design.md), poprzednie KT: `docs/kt/2026-10-08.md`.

## 8. Kto co wie
Projekt zna tylko autor.

## 9. Luki
- **Kontakt do SMSAPI.** **Skutek:** brak eskalacji u dostawcy.
  Do czasu ustalenia: zgłoszenia przez panel SMSAPI.

## 10. Sprawdź się
1. Worker nie działa po restarcie. Co robisz?
EOF
run() { bash "$EV/check-d32.sh" "$1" > "$T/out" 2>&1; echo $?; }
r=$(run "$T/good.md"); sed 's/^/     /' "$T/out"
[ "$r" -eq 0 ] && grep -qx '4/4 PASS' "$T/out"; check "good package -> 4/4, exit 0" $?
variant() { # variant <name> <the one criterion expected to fail> <sed script>
  sed -e "$3" "$T/good.md" > "$T/$1.md"
  r=$(run "$T/$1.md")
  [ "$r" -ne 0 ] && grep -q "^FAIL $2 " "$T/out" && [ "$(grep -c '^FAIL ' "$T/out")" -eq 1 ]
  check "$1 -> only $2 fails" $?
}
variant iso-date         D1 's/^Działa produkcyjnie\./Działa produkcyjnie. Token odnowiono 2026-08-01./'
variant dot-date         D1 's/^Działa produkcyjnie\./Działa produkcyjnie od 1.08.2026./'
variant worded-date      D1 's/^Działa produkcyjnie\./Działa produkcyjnie od 1 sierpnia 2026./'
variant order            D2 's/^## 2\. Jak to działa/## 2. Stan projektu/; s/^## 3\. Stan projektu/## 3. Jak to działa/'
variant missing-heading  D2 '/^## 7\. Rozwój/d'
variant gap-no-meanwhile D3 's/Do czasu ustalenia: /Potem: /'
variant gap-no-impact    D3 's/Skutek:/Wpływ:/'
variant gap-numbered     D3 's/^- \*\*Kontakt/1. **Kontakt/; s/Skutek:/Wpływ:/'
variant gap-prose        D3 '/^  Do czasu/d; /^- \*\*Kontakt/c\Brak kontaktu do SMSAPI.'
variant home-path        D4 's/^Testy: `pytest`\./Testy: `pytest` w \/home\/m\/kolejka./'
variant tmp-path         D4 's/^Testy: `pytest`\./Testy: `pytest` w \/tmp\/kt-team.x\/fx./'
variant machine-name     D4 's/^Testy: `pytest`\./Testy: `pytest`, na pc herdr 0.9.3./'
r=$(run "$EV/team-package.md"); sed 's/^/     /' "$T/out"
[ "$r" -ne 0 ] && grep -q '^FAIL D1 ' "$T/out" && grep -q '^FAIL D2 ' "$T/out" && grep -qF 'Ostatnio odnowiono go 2026-08-01' "$T/out"
check "pre-D32 package (team-package.md) fails D1 and D2, D1 lists every dated line" $?
r=$(run "$T/missing.md"); [ "$r" -ne 0 ]; check "missing file -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

`EV/make-config-dir-test.sh`:

```bash
#!/usr/bin/env bash
# make-config-dir-test.sh — the throwaway config dir links everything but the skill and agent under test.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-cfgtest.XXXXXX)
S=$T/src
mkdir -p "$S/skills/knowledge-transfer" "$S/skills/other" "$S/agents" "$S/projects"
echo secret > "$S/.credentials.json"; echo '{}' > "$S/settings.json"
echo old > "$S/skills/knowledge-transfer/SKILL.md"; echo x > "$S/skills/other/SKILL.md"
echo old > "$S/agents/kt-cold-reader.md"; echo x > "$S/agents/implementer.md"
D=$(bash "$EV/make-config-dir.sh" "$S" "$T/dst"); echo "     $D"
[ "$D" = "$T/dst" ]; check "prints the destination" $?
[ -L "$T/dst/.credentials.json" ] && [ "$(readlink "$T/dst/.credentials.json")" = "$S/.credentials.json" ]; check "credentials linked, not copied" $?
[ -L "$T/dst/settings.json" ] && [ -L "$T/dst/projects" ]; check "other top-level entries linked" $?
[ -d "$T/dst/skills" ] && [ ! -L "$T/dst/skills" ] && [ -d "$T/dst/agents" ] && [ ! -L "$T/dst/agents" ]; check "skills/ and agents/ are real dirs" $?
[ -L "$T/dst/skills/other" ] && [ -L "$T/dst/agents/implementer.md" ]; check "other skills and agents linked" $?
[ -d "$T/dst/skills" ] && [ ! -e "$T/dst/skills/knowledge-transfer" ] && [ ! -e "$T/dst/agents/kt-cold-reader.md" ]; check "skill and agent under test omitted" $?
bash "$EV/make-config-dir.sh" "$S" "$T/dst" >/dev/null 2>&1; [ $? -ne 0 ]; check "existing destination -> non-zero exit" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash EV/check-d32-test.sh`
Expected: `1 passed, 14 failed`, exit 1. Only the missing-file check passes, and it passes vacuously because the script does not exist yet.

Run: `bash EV/make-config-dir-test.sh`
Expected: `1 passed, 6 failed`, exit 1. Only the existing-destination check passes, vacuously.

- [ ] **Step 3: Implement**

`check-d32.sh`: follow the structure and output style of `EV/check-package.sh`: the `ok`/`bad` helpers, one block per criterion and the final `k/N PASS` line. D3's section parsing may use `python3 -I` inline in the script, as `EV/turn.sh` does.

`make-config-dir.sh`: plain bash with `ln -s` per entry. Iterate including dotfiles, e.g. with `shopt -s dotglob nullglob`. Fail with a message on stderr when `<dst>` exists.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash EV/check-d32-test.sh && bash EV/make-config-dir-test.sh && bash EV/check-package-test.sh && bash EV/stream-test.sh && bash EV/questions-test.sh`
Expected, in order: `15 passed, 0 failed`, `7 passed, 0 failed`, `8 passed, 0 failed`, `6 passed, 0 failed`, `5 passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add EV/check-d32.sh EV/check-d32-test.sh EV/make-config-dir.sh EV/make-config-dir-test.sh
git commit -m "test: knowledge-transfer harness — D32 structure checker and throwaway config dir"
```

---
