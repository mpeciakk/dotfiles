# Knowledge Transfer — Current State and How It Works Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `knowledge-transfer` package explains how the project works and what state it is in, with no dates or events, and it does not depend on the author's machine or on any one person.

**Architecture:**
- The harness (`EV/`) gains two scripts:
  - `check-d32.sh`, a structural checker for the D32 rules;
  - `make-config-dir.sh`, the throwaway `CLAUDE_CONFIG_DIR` that keeps the personal-level skill from shadowing the fixture copy.
- `.claude/skills/knowledge-transfer/SKILL.md` is rewritten to D32: a new premise, eleven new sections, the current-state and agnostic rules, and new Common-mistakes rows.
- One GREEN run on the existing `kolejka-sms` fixture. The RED is the already-committed `EV/team-package.md`.

**Tech Stack:** Markdown (skill), bash + `python3 -I` (harness), `claude` CLI in `-p` mode via `EV/turn.sh`.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-09-kt-current-state-design.md` (D32). Dotfiles have no living `spec.md`; the record carries the decision. D31 (`2026-10-08-kt-company-scope-design.md`) stays in force.

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

### Task 2: SKILL.md to D32

**Files:**
- Modify: `.claude/skills/knowledge-transfer/SKILL.md`
- Modify: `.claude/README.md` (one word in the `**Outside the pipeline:**` paragraph)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: the skill text Task 3 copies into its fixture. The eleven `## N. …` heading strings must match `check-d32.sh` D2 exactly. The gap-line format must match D3.

- [ ] **Step 1: Write the failing check**

```bash
S=.claude/skills/knowledge-transfer/SKILL.md
fails=0
for bad in 'dated, reader-prioritised snapshot' 'Link to the spec instead of restating it' 'two sentences and' 'Gdzie stanąłem' 'Mapa systemu' 'Pułapki i obejścia' 'whether the repo lets them recover it' 'how the user runs it' 'no run descriptions' '#5-cykl-runu'; do
  grep -qF -- "$bad" "$S" && { echo "still present: $bad"; fails=$((fails+1)); }
done
for good in '## 0. Jak czytać' '## 1. Cel i granice' '## 2. Jak to działa' '## 3. Stan projektu' '## 4. Środowisko i dostępy' '## 5. Typowe zadanie krok po kroku' '## 6. Awarie i obejścia' '## 7. Rozwój' '## 8. Kto co wie' '## 9. Luki' '## 10. Sprawdź się' \
            'Opisuje commit' 'Skutek:' 'Do czasu ustalenia:' 'Current state, not events' 'Machine- and person-agnostic' 'datę wygaśnięcia' '../../spec.md' 'docs.internal.animativ.dev' \
            'przeszło 194 z 194 testów' 'Na `pc` jest herdr 0.9.3' 'z osobistego workflow autora' 'Najpierw przeczytaj sekcję 7' 'nieznany pakietowi' 'odpowiedz `dalej`' \
            'how it was run in the past' 'when it applies and when to stop' 'no descriptions of past runs'; do
  grep -qF -- "$good" "$S" || { echo "missing: $good"; fails=$((fails+1)); }
done
[ "$(wc -l < "$S")" -lt 230 ] || { echo "too long"; fails=$((fails+1)); }
grep -qF 'packages current-state handovers' .claude/README.md || { echo "README still says dated"; fails=$((fails+1)); }
echo "fails=$fails"; [ "$fails" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails**

Expected:
- `still present:` lines for `dated, reader-prioritised snapshot`, `Link to the spec instead of restating it`, `two sentences and`, `Gdzie stanąłem`, `Mapa systemu`, `Pułapki i obejścia`, `whether the repo lets them recover it`, `how the user runs it`;
- one or more `missing: …` lines and `README still says dated`;
- a non-zero `fails=`, exit 1.

(`no run descriptions` and `#5-cykl-runu` are absent today; those two checks pass vacuously and guard the rewrite.)

- [ ] **Step 3: Rewrite**

Keep the file's section order and style: frontmatter, opening, Boundary, Intake, Process, Sections, Cold read, Hard rules, Common mistakes. Keep the frontmatter unchanged. Make exactly these changes:

1. **Opening paragraph.** Replace its first sentence ("A KT package is a dated, reader-prioritised snapshot …") with: "A KT package is one document from which a company colleague understands how the project works and what state it is in, and can do the goal set at intake. It explains at a flat level, in its own words, and links into the spec and the code for depth; the spec stays the source of truth." Keep the rest of the paragraph: Animativ repo, the reader, `docs.internal.animativ.dev`, "not trusted until …".
2. **Boundary table**, KT row: replace the "Holds" cell with "how the project works and its current state, at one commit, readable by anyone in the company". Keep the two bullets under the table.
3. **Intake**, Goal: append "It drives section 5 and the practical tasks in section 10."
4. **Process step 3** (Inventory): replace the priority formula "cost of not knowing × whether the repo lets them recover it" with "how much the goal depends on it × how hard it is to get right without the package".
5. **Process step 4**:
   - "Still asked": add "the steps of the typical task (section 5) that the repo does not describe, and for each workaround, when it applies and when to stop".
   - "Never ask", the **Run history** bullet: replace its first sentence with "When or whether something was run, and how it was run in the past. The procedure of the typical task and where each step runs may be asked; how to get access there goes to `docs.internal.animativ.dev`." Keep the rest of that bullet ("The package describes the mechanism …" to the end). The other two "Never ask" bullets stay as they are.
6. **Sections**: replace the numbered list and both bullets under it with:
   - one fenced block with exactly these eleven lines:
     ```
     ## 0. Jak czytać
     ## 1. Cel i granice
     ## 2. Jak to działa
     ## 3. Stan projektu
     ## 4. Środowisko i dostępy
     ## 5. Typowe zadanie krok po kroku
     ## 6. Awarie i obejścia
     ## 7. Rozwój
     ## 8. Kto co wie
     ## 9. Luki
     ## 10. Sprawdź się
     ```
   - the sentence "Use these headings verbatim; `###` subheadings are free." and one bullet per section:
     - **0:** the line `Opisuje commit <short SHA>.`, the goal from intake, and which sections to read for which need: taking over operation, developing, diagnosing a failure.
     - **1:** what goes in, what comes out, what the project does not do. Two to five sentences.
     - **2:** the parts and how a typical run flows through them, in its own words, one level deep. Each part links to its spec section or file. A reader who stops here knows how the project works.
     - **3:** version, what works, debt and open risks, in the present tense. A spec claim that something is unverified is stated as state, with `wg speca` and no date.
     - **4:** what the reader needs installed or at hand. Project secrets: where, never what. Company infrastructure: one line pointing to `docs.internal.animativ.dev`.
     - **5:** one typical task from start to finish, chosen from the intake goal. Each step names where it runs (for example the operator's machine, a server, a device console) and how success looks.
     - **6:** symptom → cause → workaround. Each workaround says when it applies and when to stop instead.
     - **7:** one worked example of a typical change: which files, which tests, when a run on real hardware or a real environment is needed, how a change is released. Decisions as links to the spec's decision records.
     - **8:** who knows what, and escalation.
     - **9:** blockers first. Each item has the form `- **<gap>.** Skutek: <what the reader cannot do>. Do czasu ustalenia: <what to do meanwhile>.`
     - **10:** 5–8 scenarios with an answer key (the cold read runs on them), then 2–3 practical tasks derived from the goal, without answers.
   - then these rule bullets:
     - **Current state, not events.** Apart from the commit line, the package holds no dates, no test-run results, no descriptions of past runs and no "last time" statements. Write a recurring deadline as its rule and where to check it, not as a date: „token wygasa co 90 dni; datę wygaśnięcia pokazuje panel SMSAPI”.
     - **Machine- and person-agnostic.** The package has no names of the author's machines, no home or `/tmp` paths, no local tool versions, no author's personal tooling as context, and no addressee. Facts about people as project state are fine: „projekt zna tylko autor”.
     - **Explain, don't copy.** Write in your own words, one level deep, and link for depth. A copied spec sentence is still a mistake.
     - **Links are relative Markdown links**, for example `[spec, sekcja 5](../../spec.md)`. Link to a heading only with its real anchor, taken from the heading as it stands in the file.
     - Keep the existing bullet "Every claim traces to the repo, to something the user said, or to an explicit line in "Luki" …" unchanged.
7. **Cold read**: add one line: "The practical tasks of section 10 are not sent as scenarios." Everything else stays unchanged.
8. **Hard rules**: unchanged.
9. **Common mistakes**:
   - The intro line names three runs: the skill-less baseline run (`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`), the first real KT run (edge-vibecoding, D31) and the second real KT run (edge-vibecoding, D32).
   - In the "Restated the spec" row, replace only the Counter cell with: "Explain in your own words, one level deep, and link to the spec; never copy its sentences. A line-level copy check misses a near-verbatim paraphrase, so check by reading."
   - In the "No pinned repo state" row, replace the Counter cell with: "Section 0: `Opisuje commit <short SHA>.` — the one pin in the package."
   - Keep every other existing row unchanged.
   - Add these six rows, with the quotes verbatim:

   | Mistake | Counter |
   |---|---|
   | Wrote events with dates: „2026-10-08 na `9c09e78` przeszło 194 z 194 testów”, „Wg speca pełne e2e z reflashem 2026-09-28 zakończyło się akceptacją A2 na płytce pod adresem 10.100.100.205” | Current state only; the commit line in section 0 is the one pin. |
   | Tied the package to the author's setup: „Na `pc` jest herdr 0.9.3”, „`.flow/` (…) to archiwum uzasadnień z osobistego workflow autora — nie musisz go kontynuować” | Machine- and person-agnostic: no author machines, paths, local versions or personal tooling. |
   | Sent the reader to the exceptions first: „Najpierw przeczytaj sekcję 7 (pułapki), potem 3 i 6.” | Normal flow first: how it works, then a typical task, then failures. |
   | Left „Co to robi” at two sentences plus a link, and the map as a table of file paths | Section 2 explains how a typical run flows through the parts; a reader who stops there knows how the project works. |
   | Listed a gap with no consequence: „**Kontakt do SoMLabs** — nieznany pakietowi.” | Each gap: `Skutek:` and `Do czasu ustalenia:`; blockers first. |
   | Gave a workaround with no condition: „Porównaj MAC-i interfejsów przewodowych z sondą i odpowiedz `dalej`.” | Each workaround says when it applies and when to stop instead. |

README: in the `**Outside the pipeline:**` paragraph, replace `packages dated handovers` with `packages current-state handovers`. Re-wrap the paragraph to the same width and leave the rest unchanged.

- [ ] **Step 4: Run the check to verify it passes**

Run the Step 1 block again. Expected: `fails=0`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/knowledge-transfer/SKILL.md .claude/README.md
git commit -m "skills: knowledge-transfer — how it works and current state, machine-agnostic (D32)"
```

---

### Task 3: GREEN on the colleague scenario

**Files:**
- Create: `EV/d32.md`, `EV/d32-package.md`, `EV/d32-transcripts/turn-*.jsonl`
- Modify (only in a refactor round): `.claude/skills/knowledge-transfer/SKILL.md`

**Interfaces:**
- Consumes:
  - `EV/check-d32.sh` and `EV/make-config-dir.sh` (Task 1);
  - SKILL.md (Task 2);
  - `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh`, `EV/stream.py questions`, `EV/scenario-team.md`, `EV/user-facts-team.md` (existing, unchanged);
  - `EV/team-package.md`, the pre-D32 package that serves as RED.

- [ ] **Step 1: RED, recorded from the committed package**

Run: `bash EV/check-d32.sh EV/team-package.md`
Expected: non-zero exit, with `FAIL D1` and `FAIL D2` among the lines. Keep the output verbatim for `d32.md`.

Then the real-world RED, read-only:

Run: `bash EV/check-d32.sh /home/m/work/edge-vibecoding/docs/kt/2026-10-08.md`
Expected: non-zero exit, with `FAIL D1`, `FAIL D2` and `FAIL D4` (`Na `pc` jest herdr 0.9.3`). Keep the output verbatim for `d32.md`. Do not edit or commit anything in that repo.

- [ ] **Step 2: Fixture and config dir**

The fixture is the one D31's runs used, including the run-history bait commit. Put this function in a `/tmp` helper script (the guard refuses inline multi-line shell):

```bash
fixture() { # fixture <skill-file> <agent-file> -> prints the fixture dir
  local F; F=$(mktemp -d /tmp/kt-d32.XXXXXX)/fx
  bash EV/make-fixture.sh "$F" >/dev/null || return 1
  printf -- '- Ponawiania 429 nie uruchamiano na produkcji.\n' >> "$F/spec.md"
  git -C "$F" add spec.md
  GIT_AUTHOR_DATE=2026-08-21T10:00:00 GIT_COMMITTER_DATE=2026-08-21T10:00:00 \
    git -C "$F" -c user.name=Ernest -c user.email=ernest@example.invalid commit -q -m "spec: ponawianie 429 do sprawdzenia"
  git -C "$F" rev-parse HEAD > "$F/.git/kt-fixture-tip"
  mkdir -p "$F/.claude/skills/knowledge-transfer" "$F/.claude/agents"
  cp "$1" "$F/.claude/skills/knowledge-transfer/SKILL.md"
  cp "$2" "$F/.claude/agents/kt-cold-reader.md"
  printf '.claude/\n' >> "$F/.git/info/exclude"
  echo "$F"
}
```

Make the config dir once: `C=$(bash EV/make-config-dir.sh ~/.claude "$(mktemp -u /tmp/kt-config.XXXXXX)")`.

- [ ] **Step 3: Sanity turn, on its own fixture**

Make a second fixture with `fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md`, with its transcripts in a `/tmp` dir (not committed). Run one turn:

`CLAUDE_CONFIG_DIR=$C bash EV/turn.sh <sanity-fixture> <tmp-transcripts> "Wywołaj skill knowledge-transfer, a potem odpowiedz tylko: OK"`

It passes when the turn answers and the transcript contains `Base directory for this skill: <sanity-fixture>/.claude/skills/knowledge-transfer`. If auth fails or the base directory is `~/.claude/...`, stop and report BLOCKED with the line. Do not copy credentials or loosen permissions.

- [ ] **Step 4: GREEN run**

```bash
F=$(fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md); echo "$F"
mkdir -p EV/d32-transcripts
CLAUDE_CONFIG_DIR=$C bash EV/turn.sh "$F" EV/d32-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

User simulation: while the session's last result asks a question or asks for approval, answer with one `CLAUDE_CONFIG_DIR=$C bash EV/turn.sh "$F" EV/d32-transcripts "<answer>" <session-id>` call. Answer strictly by the table and rules in `EV/user-facts-team.md`, and only what was asked. Log each answer in that file's format. Stop when the session reports done, or after 8 turns in total. F2's answer carries the date `2026-08-01`. That is deliberate: the package must not repeat it (D1).

A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure: stop and report BLOCKED. Other denials are recorded and ignored.

Copy the package (`$F/docs/kt/*.md`) to `EV/d32-package.md`. Then run:
- `bash EV/check-package.sh EV/d32-package.md "$F" EV/d32-transcripts`
- `bash EV/check-d32.sh EV/d32-package.md`

- [ ] **Step 5: GREEN conditions**

GREEN holds when all of these are true:
- `check-package.sh` shows `6/6 PASS`;
- `check-d32.sh` shows `4/4 PASS`;
- the turn-1 Skill result has `Base directory for this skill: $F/.claude/skills/knowledge-transfer`;
- the session stopped at the inventory gate before its first Write;
- zero **forbidden** questions by SKILL.md's never-ask list. Classify every question and request to the user by reading: run `python3 -I EV/stream.py questions EV/d32-transcripts/*.jsonl`, then read each turn's full `result` text, as `EV/team.md` did. A question about the typical task's procedure or where a step runs is **allowed** (rule: "steps of the typical task"); a question about when, whether or how something was run in the past is **forbidden**;
- by reading, section 2: the fixture's code is a skeleton and the flow lives only in its spec §2 (`app.py` writes orders to the `outbox` table; `worker.py` takes up to 50 every 10 seconds and sends them to the gateway). Section 2 passes when it explains that flow in its own words, links the spec, **and** says the code does not implement it, pointing to "Luki". It fails if it is a list of files only (as in the RED) or if it presents the flow as implemented. Quote the section in `d32.md`;
- by reading, section 6: every "when it applies" and "when to stop" condition traces to the repo, to a user answer, or to a "Luki" item. An untraceable condition is a fabrication and fails GREEN;
- by reading: no statement ties the package to the author's machine or to one person beyond project facts; the 90-day token is a rule plus where to check it, not a date.

- [ ] **Step 6: Refactor if needed**

On any GREEN failure:
1. Quote the session's words that show it.
2. Add the counter to SKILL.md.
3. Re-run Step 4 on a fresh `fixture`, with transcript dir `EV/d32-transcripts-r<N>` and package `EV/d32-package-r<N>.md`, then Step 5 for it.

At most 2 refactor runs. If it is still failing, report BLOCKED with both checkers' output, the classification table and the quotes. Do not tune the skill to the fixture's specific facts.

- [ ] **Step 7: Record and commit**

`EV/d32.md`, in the style of `EV/team.md`, contains:
- a run table (RED / sanity / GREEN / refactors; fixture, tip, session id, transcripts, package, skill text);
- RED's and the real-world RED's `check-d32.sh` output, and GREEN's output from both checkers, verbatim;
- a short "What this fixture does not exercise" note: the machine-agnostic rule (neither the fixture nor its RED has the failure; only the real-world RED shows it), and "how it works" on real code (the fixture's code is a skeleton). Both are left to the after-merge edge-vibecoding run;
- the sanity turn's base-directory line;
- the question classification table, the answer log and the turn count;
- gate observations, the section 2 quote, and refactor rounds with the quotes that drove them.

Before cleanup, check that `$C/.credentials.json` is still a symlink (`[ -L … ]`) and record the result in `d32.md`. Then remove the `/tmp` fixtures and the config dir (`rm -rf`).

```bash
git add EV/d32.md EV/d32-package*.md EV/d32-transcripts* .claude/skills/knowledge-transfer/SKILL.md
git commit -m "test: knowledge-transfer D32 GREEN on the colleague scenario"
```

---

No living spec to sync: dotfiles have none. `.claude/README.md`'s one stale word ("dated") is fixed in Task 2.

## After merge (finish stage, not a task)

`SKILL.md` is an existing file, so its symlink already points into the main checkout and the merge makes it live. Then redo the edge-vibecoding KT with the new skill in a new session: that is the real check D32 names. It passes when:
- `bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-d32.sh <new package>` shows `4/4 PASS`;
- by reading, section 2 explains the run cycle (roles, phases, gates) in its own words, so a reader understands it without the repo;
- the package has no `pc`, no locally installed herdr version and no `.flow` personal-workflow context;
- every section 6 condition traces to the repo, the user or "Luki".

On a failure, report it to the user with the checker output and quotes. The user decides between fixing forward and reverting the merge.
