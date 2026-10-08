# Knowledge Transfer — Company Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The `knowledge-transfer` skill assumes a company repo handed to another Animativ employee (or the author later). It has one recipient, no profiles and no `temat` mode, and its interview never asks about company infrastructure or run history.

**Architecture:** One rewrite of `.claude/skills/knowledge-transfer/SKILL.md` (intake, interview scope, a flat section list instead of the matrix, a Sonnet cold reader, new Common-mistakes rows), plus one README line. The existing nested-session harness (`EV/`) gains a mechanical check that lists the questions a session put to the user and flags the forbidden ones. One GREEN run on a "colleague takes over" scenario proves the change.

**Tech Stack:** Markdown (skill), bash + `python3 -I` (harness), `claude` CLI in `-p` mode with `--output-format stream-json --verbose`.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-08-kt-company-scope-design.md` (D31). Dotfiles have no living `spec.md`; the record carries the decision. The earlier record `2026-10-08-knowledge-transfer-design.md` (D29, D30) is a dated journal and is not edited.

## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill texts are English (like every skill in `.claude/skills/`); the package the skill produces, scenario prompts, user-fact answers and the cold-reader's answers are Polish.
- The company knowledge base is named exactly `docs.internal.animativ.dev`.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call goes through `EV/turn.sh` unchanged (it already sets `--model sonnet`, `--output-format stream-json --verbose`, `--permission-mode acceptEdits`, the allowed tools and `--disallowedTools SendMessage ListAgents`). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).
- Do not commit anything from `~/.claude/projects/` (real session transcripts). They may be read and quoted.

---

### Task 1: Question check — which questions did a session put to the user

**Files:**
- Modify: `EV/stream.py` (new subcommand `questions`)
- Create: `EV/check-questions.sh`, `EV/check-questions-test.sh`

**Interfaces:**
- Consumes: `EV/stream.py` helpers `events(path)`, `blocks(event)` (existing).
- Produces:
  - `python3 -I EV/stream.py questions <jsonl>...` prints one line per question to the user, formatted `<basename of jsonl>: <question text>`. Sources: (a) every line containing `?` in the `result` text of each `type == "result"` event (stream-json, `claude -p`); (b) every `input.questions[].question` of each `tool_use` block named `AskUserQuestion` (interactive session transcripts). Newlines inside an AskUserQuestion question are replaced by a space.
  - `bash EV/check-questions.sh <jsonl>...` prints `FLAG <category> <line>` for each question matching a forbidden pattern, then `<n> flagged`. Exit 0 iff none were flagged. Categories: `infra`, `historia`, `odbiorca`.

The patterns are the decision, so here they are in full. Matching is case-insensitive Python `re` on the question line:

```python
FORBIDDEN = {
    "infra": r"router|\bsie(ć|ci)\b|\bVPN\b|\bDHCP\b|\bkont(o|a|em)\b|uprawnie|\bSSH\b|dostęp|password manager|menedżer\w* haseł|1Password",
    "historia": r"uruchomion|uruchamiał|uruchamiasz|odpalan|odpalał|odpalasz|był jakiś run|kiedy ostatnio",
    "odbiorca": r"\bprofil|ja-później|następc|imi(ę|enia) odbiorcy|dla kogo|kto przejmuje|pakiet jest dla",
}
```

Put the matcher in `check-questions.sh` as a `python3 -I -c` block (or a heredoc) that reads `stream.py questions` output on stdin. Do not use `grep -iE`: `\b` and case folding on Polish letters then depend on the locale.

A line from the "inventory" may be a scenario rather than a question to the user (e.g. `Gdzie szukać?`). The check lists candidates; it does not judge that. Task 3 classifies every flagged line by reading.

- [ ] **Step 1: Write the failing test**

`EV/check-questions-test.sh`, following the pattern of `EV/stream-test.sh` (`check <label> <exit-code>`, `N passed, M failed`, exit non-zero on any failure):

```bash
#!/usr/bin/env bash
# check-questions-test.sh — stream.py questions extracts questions to the user; check-questions.sh flags the forbidden ones.
set -u
EV=$(cd "$(dirname "$0")" && pwd)
pass=0; fail=0
check() { if [ "$2" -eq 0 ]; then pass=$((pass+1)); echo "ok   $1"; else fail=$((fail+1)); echo "FAIL $1"; fi; }
T=$(mktemp -d /tmp/kt-qtest.XXXXXX)
# stream-json result event (claude -p)
printf '%s\n' '{"type":"result","subtype":"success","result":"Inwentarz gotowy.\n1. Czy worker działa w tej samej jednostce co app.py?\n2. Kto nadaje dostęp SSH do sms1?\n3. Od czerwca był jakiś run?\nZatwierdzasz?"}' > "$T/p.jsonl"
# interactive transcript: AskUserQuestion tool_use
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"AskUserQuestion","input":{"questions":[{"question":"Pakiet jest dla Ernesta?\n(imię odbiorcy)"},{"question":"Gdzie leży plik outbox.db na serwerze?"}]}}]}}' > "$T/i.jsonl"
q=$(python3 -I "$EV/stream.py" questions "$T/p.jsonl" "$T/i.jsonl")
echo "$q" | sed 's/^/     /'
[ "$(echo "$q" | grep -c .)" -eq 6 ]; check "six questions extracted (4 result lines with ?, 2 AskUserQuestion)" $?
echo "$q" | grep -qF 'i.jsonl: Pakiet jest dla Ernesta? (imię odbiorcy)'; check "AskUserQuestion newline folded, file prefix" $?
echo "$q" | grep -q 'Inwentarz gotowy'; [ $? -ne 0 ]; check "lines without ? are not questions" $?
out=$(bash "$EV/check-questions.sh" "$T/p.jsonl" "$T/i.jsonl"); rc=$?
echo "$out" | sed 's/^/     /'
[ "$rc" -eq 1 ]; check "flagged questions -> exit 1" $?
echo "$out" | grep -q '^FLAG infra .*dostęp SSH'; check "infra: access/SSH flagged" $?
echo "$out" | grep -q '^FLAG historia .*był jakiś run'; check "historia: run history flagged" $?
echo "$out" | grep -q '^FLAG odbiorca .*Ernesta'; check "odbiorca: recipient name flagged" $?
echo "$out" | grep -q 'jednostce co app.py'; [ $? -ne 0 ]; check "mechanism question not flagged" $?
echo "$out" | grep -q 'outbox.db'; [ $? -ne 0 ]; check "project file location not flagged" $?
echo "$out" | grep -qx '3 flagged'; check "count line" $?
printf '%s\n' '{"type":"result","subtype":"success","result":"Czy worker restartuje się sam po restarcie serwera?"}' > "$T/clean.jsonl"
bash "$EV/check-questions.sh" "$T/clean.jsonl" >/dev/null; check "clean transcript -> exit 0" $?
rm -rf "$T"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash EV/check-questions-test.sh`
Expected: `FAIL six questions extracted …` (stream.py prints its usage error, so 0 lines) and further FAIL lines, ending `… failed` with a non-zero failed count and exit 1. Not a bash syntax error.

- [ ] **Step 3: Implement**

`stream.py`: add `questions(paths)` next to `subagent_tools`, using `events()` and `blocks()`, and a `questions` branch in `main()` plus a line in the module docstring's usage. `check-questions.sh`: header comment in the style of `EV/check-package.sh` (usage line, what exit 0 means), runs `stream.py questions "$@"` and pipes it to the Python matcher with `FORBIDDEN` above; a line matching several categories is reported once per category.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash EV/check-questions-test.sh && bash EV/stream-test.sh && bash EV/check-package-test.sh`
Expected: `11 passed, 0 failed`, `6 passed, 0 failed`, `8 passed, 0 failed`.

- [ ] **Step 5: RED evidence on real transcripts (recorded, not committed as data)**

Run, and paste each output verbatim into the report:
- `bash EV/check-questions.sh ~/.claude/projects/-home-m-work-edge-vibecoding/fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl`. This is the real KT session that motivated D31. Expected: exit 1, with at least the router question (`infra`), `Od 2026-09-28 był jakiś run?` (`historia`) and `Pakiet jest dla Ernesta?` (`odbiorca`) flagged.
- `bash EV/check-questions.sh EV/green-transcripts/*.jsonl`. This is the old skill on the support scenario. Expected: exit 1, with the `SSH na sms1` question flagged as `infra`.

If either does not flag what is expected, the patterns are wrong: fix them, add the missed line as a test case in Step 1's script, and re-run Step 4.

- [ ] **Step 6: Commit**

```bash
git add EV/stream.py EV/check-questions.sh EV/check-questions-test.sh
git commit -m "test: knowledge-transfer harness — flag questions about company infra, run history, recipient"
```

---

### Task 2: SKILL.md and README to D31

**Files:**
- Modify: `.claude/skills/knowledge-transfer/SKILL.md`
- Modify: `.claude/README.md` (the `**Outside the pipeline:**` paragraph)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: the skill text Task 3 copies into its fixture. Package path `docs/kt/YYYY-MM-DD.md`.

- [ ] **Step 1: Write the failing check**

```bash
S=.claude/skills/knowledge-transfer/SKILL.md
fails=0
for bad in 'support' 'ja-później' 'następca' 'temat' 'haiku' '<profil>'; do
  grep -qiF -- "$bad" "$S" && { echo "still present: $bad"; fails=$((fails+1)); }
done
for good in 'docs.internal.animativ.dev' 'docs/kt/YYYY-MM-DD.md' 'model: "sonnet"' 'Od 2026-09-28 był jakiś run?' 'Pakiet jest dla Ernesta?' 'routerze labu'; do
  grep -qF -- "$good" "$S" || { echo "missing: $good"; fails=$((fails+1)); }
done
[ "$(wc -l < "$S")" -lt 200 ] || { echo "too long"; fails=$((fails+1)); }
grep -qF 'support person' .claude/README.md && { echo "README still names support"; fails=$((fails+1)); }
echo "fails=$fails"; [ "$fails" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails**

Expected: `still present: support`, `still present: ja-później`, `still present: temat`, `missing: docs.internal.animativ.dev` and the other missing lines, `README still names support`, a non-zero `fails=`, exit 1.

- [ ] **Step 3: Rewrite the skill**

Keep the file's section order and style: Boundary, Intake, Process, the section list, Cold read, Hard rules, Common mistakes. Make exactly these changes:

1. **Frontmatter `description`**, exactly:
   ```
   description: Use when another Animativ employee — or the user, months later — is taking over a company project and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
   ```
2. **Opening paragraph:** add the premise. Every KT covers a company (Animativ) repo. The reader is another employee of the same company, or the author months later. They know the company's infrastructure and have the company knowledge base, `docs.internal.animativ.dev`. The package is written for that reader, not for a named person.
3. **Boundary:** keep. Remove the `temat`/`~/obsidian` content wherever it appears.
4. **Intake:** two fields, asked together in one message only if missing: **Goal** (what the reader must be able to do afterwards) and **Extra materials** (optional). No profile, no mode, no recipient name.
5. **Process:**
   - Step 2 scan: drop "(`projekt` mode only)".
   - Step 5 writes `docs/kt/YYYY-MM-DD.md`, by the section list.
   - Step 4 interview: keep "gaps only" and the hypothesis rule. Add a **never ask** list:
     - company infrastructure: network, router, VPN, accounts, permissions, SSH/server access, the password manager. The package carries one line pointing to `docs.internal.animativ.dev` instead.
     - run history: when something was last run, whether it has been run, how the user runs it. The package describes the mechanism as the code has it. Where the spec says what was or was not verified, the package quotes it as the spec's claim ("wg speca …") and does not confirm it. A spec–code contradiction goes to "Luki" without a question.
     - the recipient: no name, no profile, no skill level.
   - What the interview still asks: traps and workarounds that are not in the code, who knows what, the project's own external dependencies, and where a secret the repo names is kept (location only).
6. **Replace the section matrix** with one list (Polish headings, in this order). Keep the bullets under it about linking the spec instead of restating it, and about every claim tracing to the repo, the user or a "Luki" line. Drop the `ja-później` bullet and the `temat` bullet. The list:
   ```
   0. Jak czytać, stan na (data, SHA)
   1. Co to robi (dwa zdania i link do speca)
   2. Mapa systemu (linki do speca i kodu)
   3. Uruchomienie i zmiany (build, test, release; runbooki jako linki)
   4. Decyzje i dlaczego (linki do rekordów)
   5. Dług i otwarte ryzyka
   6. Gdzie stanąłem, jak odtworzyć środowisko
   7. Pułapki i obejścia (z objawami)
   8. Kto co wie
   9. Dostępy projektu: gdzie, nigdy jakie; infrastruktura firmowa: docs.internal.animativ.dev
   10. Sprawdź się: scenariusze z odpowiedziami
   11. Luki
   ```
7. **Cold read:** always `model: "sonnet"`. Remove the haiku/profile split. Everything else unchanged.
8. **Hard rules:** "plain language for `support`" goes. Polish per `polszczyzna` stays.
9. **Common mistakes:** change the intro line. The rows come from the skill-less baseline run (`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`) and from the first real KT run (edge-vibecoding, 2026-10-08). Keep the six baseline rows. Add these three rows, quotes verbatim:

   | Mistake | Counter |
   |---|---|
   | Asked about company infrastructure: „Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?” (the answer: „po prostu router w biurze”) | Company infrastructure is in `docs.internal.animativ.dev`. One line in the package points there; never ask. |
   | Asked about run history: „Od 2026-09-28 był jakiś run?” | Describe the mechanism as the code has it. A spec's claim about what was verified is quoted as the spec's claim. |
   | Asked who the reader is: „Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?” | The reader is a company employee or the author later; no name, no profile. |

README: in the `**Outside the pipeline:**` paragraph, replace `for a successor, support person,\nor the user's future self` with `for another employee or the user's future self`. Re-wrap the paragraph to the same width and leave the rest of it unchanged.

- [ ] **Step 4: Run the check to verify it passes**

Run the Step 1 block again. Expected: `fails=0`, exit 0. Also `head -4 .claude/skills/knowledge-transfer/SKILL.md` shows the new description verbatim.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/knowledge-transfer/SKILL.md .claude/README.md
git commit -m "skills: knowledge-transfer — company repo, one reader, no infra or run-history questions (D31)"
```

---

### Task 3: GREEN run — a colleague takes over

**Files:**
- Create: `EV/scenario-team.md`, `EV/user-facts-team.md`, `EV/team.md`, `EV/team-package.md`, `EV/team-transcripts/turn-*.jsonl`
- Modify (only in a refactor round): `.claude/skills/knowledge-transfer/SKILL.md`

**Interfaces:**
- Consumes: `EV/check-questions.sh` (Task 1); SKILL.md (Task 2); `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh` (existing, unchanged); `.claude/agents/kt-cold-reader.md` (unchanged).

- [ ] **Step 1: Write the scenario and the user facts**

`EV/scenario-team.md`, verbatim (the message is everything below the heading line):

```markdown
# Scenariusz: przejmuje kolega z zespołu (wiadomość pierwszej tury)
Od poniedziałku projekt kolejka-sms (to repo) przejmuje kolega z mojego zespołu. Przygotuj dla niego dokument przekazania i zapisz go w repo. Szef już mu obiecał, że dostanie go dziś. Mam tylko kwadrans, potem wyjeżdżam na dwa tygodnie i nie będę osiągalny, więc nie przeciągaj.
```

`EV/user-facts-team.md`: copy `EV/user-facts.md` and change only the fact table, as follows. F1–F5 stay unchanged. F6 keywords become `sekret, hasło, gdzie trzymać` (answer unchanged). F7 is replaced. F8 and F9 are added:

```markdown
| F7 | kto, odbiorca, poziom, umiejętności, imię | Kolega z mojego zespołu, programista Pythona; zna naszą infrastrukturę. |
| F8 | router, sieć, VPN, konto, uprawnienia, SSH, dostęp, 1Password | To jest opisane w firmowej bazie wiedzy. |
| F9 | uruchamiane, odpalane, był run, kiedy ostatnio, sprawdzone | Opisz to, co jest w repo. |
```

- [ ] **Step 2: Run the scenario with the skill**

Bash `timeout: 600000` per turn:
```bash
F=$(mktemp -d /tmp/kt-team.XXXXXX)/fx; bash EV/make-fixture.sh "$F"
mkdir -p "$F/.claude/skills/knowledge-transfer" "$F/.claude/agents" EV/team-transcripts
cp .claude/skills/knowledge-transfer/SKILL.md "$F/.claude/skills/knowledge-transfer/"
cp .claude/agents/kt-cold-reader.md "$F/.claude/agents/"
printf '.claude/\n' >> "$F/.git/info/exclude"
bash EV/turn.sh "$F" EV/team-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

User simulation: while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, strictly by the table and rules in `EV/user-facts-team.md`. Answer only what was asked ("Faktów, o które nie zapytano, nie dopowiadasz"). Log each answer in that file's format. Stop when the session reports done, or after 8 turns in total. A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure: stop and report BLOCKED. Other denials are recorded and ignored.

- [ ] **Step 3: Score it**

Copy the package (`$F/docs/kt/*.md`) to `EV/team-package.md`, then run:
- `bash EV/check-package.sh EV/team-package.md "$F" EV/team-transcripts`. Expected: `6/6 PASS`.
- `bash EV/check-questions.sh EV/team-transcripts/*.jsonl`. Classify every `FLAG` line by reading the turn it came from. It is either a question put to the user (a **skill failure**) or an inventory scenario or package line that only contains a `?` (a false positive; quote it and say why).

Also check by reading:
- The package path is `docs/kt/YYYY-MM-DD.md`.
- Section 9 points to `docs.internal.animativ.dev` and does not describe SSH or 1Password access procedures.
- The session stopped at the inventory gate before its first Write.
- The cold-reader dispatch used `model: "sonnet"`. Find the `Agent` tool_use input in the transcript.

GREEN means: checker 6/6, zero flagged questions to the user, and every reading check holds.

- [ ] **Step 4: Refactor if needed**

On any failure, quote the session's words that show it, add the counter to SKILL.md, and re-run Steps 2–3 on a fresh fixture with transcript dir `EV/team-transcripts-r<N>` and package `EV/team-package-r<N>.md`. At most 2 refactor runs. If it is still failing, report BLOCKED with the checker output, the flagged lines and the quotes. Do not tune the skill to the fixture's specific facts.

- [ ] **Step 5: Record and commit**

`EV/team.md`, in the style of `EV/green.md`, must contain:
- a run table (fixture, tip, session id, transcripts, package, skill text);
- both checkers' output verbatim, with the FLAG classification;
- the answer log;
- the turn count and gate observations;
- refactor rounds, with the quotes that drove them.

It must also contain these two notes:
- RED for this change is the real edge-vibecoding session. Task 1's Step 5 output shows it flagged; quote it from the Task 1 report.
- C4 depends on the session asking about traps. A narrower interview that still reaches 3 of 5 markers is the expected result. A miss is reported, not explained away.

```bash
git add EV/scenario-team.md EV/user-facts-team.md EV/team.md EV/team-package*.md EV/team-transcripts* .claude/skills/knowledge-transfer/SKILL.md
git commit -m "test: knowledge-transfer GREEN on the colleague scenario (D31)"
```

---

No living spec to sync: dotfiles have none. README is updated in Task 2, and the design records are dated journals.

## After merge (finish stage, not a task)

`SKILL.md` is an existing file, so its symlink already points into the main checkout and the merge makes it live; no `dotter deploy` is needed. Start a new session, then redo the edge-vibecoding KT with the new skill. That is the real-world check D31 names.
