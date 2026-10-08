# Knowledge Transfer — Company Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The `knowledge-transfer` skill assumes a company repo handed to another Animativ employee (or the author later). It has one reader, no profiles and no `temat` mode, and its interview never asks about company infrastructure, run history or who the reader is.

**Architecture:**
- One rewrite of `.claude/skills/knowledge-transfer/SKILL.md`: intake, interview scope, a flat section list instead of the matrix, new Common-mistakes rows.
- One README line, and `model: sonnet` in the `kt-cold-reader` agent definition.
- The nested-session harness (`EV/`) gains a `questions` extractor.
- A RED run (old skill) and a GREEN run (new skill) on one "colleague takes over" scenario, with every question the session puts to the user classified by reading.

**Tech Stack:** Markdown (skill, agent), bash + `python3 -I` (harness), `claude` CLI in `-p` mode with `--output-format stream-json --verbose`.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-10-08-kt-company-scope-design.md` (D31). Dotfiles have no living `spec.md`; the record carries the decision. The earlier record `2026-10-08-knowledge-transfer-design.md` (D29, D30) is a dated journal and is not edited.

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

### Task 2: SKILL.md, README and cold-reader model to D31

**Files:**
- Modify: `.claude/skills/knowledge-transfer/SKILL.md`
- Modify: `.claude/README.md` (the `**Outside the pipeline:**` paragraph)
- Modify: `.claude/agents/kt-cold-reader.md` (frontmatter `model:` only)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: the skill and agent texts Task 3 copies into its fixture. Package path `docs/kt/YYYY-MM-DD.md`.

- [ ] **Step 1: Write the failing check**

Whole-word matches (`-w`), because a kept baseline row says "Claims nothing supported".

```bash
S=.claude/skills/knowledge-transfer/SKILL.md
fails=0
for bad in 'support' 'ja-później' 'następca' 'temat' 'haiku' 'named reader'; do
  grep -qiwF -- "$bad" "$S" && { echo "still present: $bad"; fails=$((fails+1)); }
done
grep -qF '<profil>' "$S" && { echo "still present: <profil>"; fails=$((fails+1)); }
for good in 'docs.internal.animativ.dev' 'docs/kt/YYYY-MM-DD.md' 'model: "sonnet"' 'Od 2026-09-28 był jakiś run?' 'Pakiet jest dla Ernesta?' 'routerze labu' 'wg speca'; do
  grep -qF -- "$good" "$S" || { echo "missing: $good"; fails=$((fails+1)); }
done
[ "$(wc -l < "$S")" -lt 200 ] || { echo "too long"; fails=$((fails+1)); }
grep -qF 'support person' .claude/README.md && { echo "README still names support"; fails=$((fails+1)); }
grep -qx 'model: sonnet' .claude/agents/kt-cold-reader.md || { echo "agent model not sonnet"; fails=$((fails+1)); }
echo "fails=$fails"; [ "$fails" -eq 0 ]
```

- [ ] **Step 2: Run it to verify it fails**

Expected output includes these lines, then a non-zero `fails=` and exit 1:
- `still present: support`, `still present: ja-później`, `still present: następca`, `still present: temat`, `still present: haiku`, `still present: named reader`
- `missing: docs.internal.animativ.dev` and the other missing lines
- `README still names support`
- `agent model not sonnet`

- [ ] **Step 3: Rewrite**

Keep the file's section order and style: Boundary, Intake, Process, the section list, Cold read, Hard rules, Common mistakes. Make exactly these changes:

1. **Frontmatter `description`**, exactly:
   ```
   description: Use when another Animativ employee — or the user, months later — is taking over a company project and needs a handover document. Triggers on "przekazanie projektu", "knowledge transfer", "KT", "ktoś przejmuje", "dokument przekazania", "dokument onboardingowy dla". Not for agent session continuity (handoff) or for describing what a project is (writing-specs).
   ```
2. **Opening paragraph:**
   - Replace "recipient-prioritised" with "reader-prioritised".
   - Replace the sentence "It is written for one named reader, and it is not trusted until …" with the premise. Every KT covers a company (Animativ) repo. The reader is another employee of the same company, or the author months later, who knows the company's infrastructure and has the company knowledge base `docs.internal.animativ.dev`.
   - Keep the clause "it is not trusted until a reader with nothing but the package has tried to act on it".
3. **Boundary:** keep. Remove every `temat` and `~/obsidian` mention.
4. **Intake:** two fields, asked together in one message only if missing.
   - **Goal:** what the reader must be able to do afterwards.
   - **Extra materials** (optional).

   No profile, no mode, no reader name.
5. **Process:**
   - Step 2 (scan): drop "(`projekt` mode only)".
   - Step 5: write `docs/kt/YYYY-MM-DD.md`, by the section list.
   - Step 4 (interview): keep "gaps only" and the hypothesis rule, and add a **never ask** list:
     - **Company infrastructure:** network, router, VPN, accounts, permissions, SSH or server access, getting into the password manager and its procedures. The package carries one line pointing to `docs.internal.animativ.dev` instead.
     - **Run history:** when something was last run, whether it has been run, how the user runs it. The package describes the mechanism as the code has it. Where the spec says what was or was not run or verified, the package attributes it to the spec, using the phrase `wg speca`, and neither confirms nor questions it. A spec–code contradiction goes to "Luki" without a question.
     - **The reader:** no name, no profile, no skill level.
   - Also in step 4, what the interview still asks: traps and workarounds that are not in the code, who knows what, the project's own external dependencies, and where a secret the repo names is kept (location only — this is allowed even when the answer is "in the password manager").
6. **Replace the section matrix** with one list (Polish headings, in this order). Keep the bullets under it about linking the spec instead of restating it, and about every claim tracing to the repo, the user or a "Luki" line. Drop the `ja-później` bullet and the `temat` bullet.
   ```
   0. Jak czytać, stan na (data, SHA)
   1. Co to robi (dwa zdania i link do speca)
   2. Mapa systemu (linki do speca i kodu)
   3. Uruchomienie i zmiany (build, test, release; runbooki jako linki)
   4. Decyzje i dlaczego (linki do rekordów)
   5. Dług i otwarte ryzyka
   6. Gdzie stanąłem, jak odtworzyć środowisko
   7. Pułapki i obejścia (z objawami)
   8. Kto co wie, eskalacja
   9. Dostępy projektu: gdzie, nigdy jakie; infrastruktura firmowa: docs.internal.animativ.dev
   10. Sprawdź się: scenariusze z odpowiedziami
   11. Luki
   ```
7. **Cold read:** always `model: "sonnet"`; remove the haiku/profile split. Everything else unchanged.
8. **Hard rules:** "plain language for `support`" goes. "Polish per `polszczyzna`" stays.
9. **Common mistakes:**
   - The intro line now says the rows come from two runs: the skill-less baseline run (`.flow/specs/2026-10-08-knowledge-transfer-evidence/baseline.md`) and the first real KT run (edge-vibecoding, 2026-10-08).
   - Keep the six baseline rows unchanged.
   - Add these three rows, with the quotes verbatim:

   | Mistake | Counter |
   |---|---|
   | Asked about company infrastructure: „Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?” (the answer: „po prostu router w biurze”) | Company infrastructure is in `docs.internal.animativ.dev`. One line in the package points there; never ask. |
   | Asked about run history: „Od 2026-09-28 był jakiś run?” | Describe the mechanism as the code has it; a spec's claim about what was run or verified goes in `wg speca`. |
   | Asked who the reader is: „Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?” | The reader is a company employee or the author later; no name, no profile. |

README: in the `**Outside the pipeline:**` paragraph, replace `for a successor, support person,` + `or the user's future self` (two lines) with `for another employee or the user's future self`. Re-wrap the paragraph to the same width and leave the rest unchanged.

`kt-cold-reader.md`: change the frontmatter line `model: haiku` to `model: sonnet`. Nothing else in that file.

- [ ] **Step 4: Run the check to verify it passes**

Run the Step 1 block again. Expected: `fails=0`, exit 0. Also, `head -4 .claude/skills/knowledge-transfer/SKILL.md` shows the new description verbatim.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/knowledge-transfer/SKILL.md .claude/README.md .claude/agents/kt-cold-reader.md
git commit -m "skills: knowledge-transfer — company repo, one reader, no infra or run-history questions (D31)"
```

---

### Task 3: RED and GREEN — a colleague takes over

**Files:**
- Create: `EV/scenario-team.md`, `EV/user-facts-team.md`, `EV/team.md`, `EV/team-red-package.md`, `EV/team-red-transcripts/turn-*.jsonl`, `EV/team-package.md`, `EV/team-transcripts/turn-*.jsonl`
- Modify (only in a refactor round): `.claude/skills/knowledge-transfer/SKILL.md`

**Interfaces:**
- Consumes:
  - `EV/stream.py questions` (Task 1);
  - SKILL.md and `kt-cold-reader.md` (Task 2), plus their pre-change versions at the run's base commit;
  - `EV/make-fixture.sh`, `EV/turn.sh`, `EV/check-package.sh` (existing, unchanged).

- [ ] **Step 1: Write the scenario and the user facts**

`EV/scenario-team.md`, verbatim. The message is everything below the heading line:

```markdown
# Scenariusz: przejmuje kolega z zespołu (wiadomość pierwszej tury)
Od poniedziałku projekt kolejka-sms (to repo) przejmuje kolega z mojego zespołu. Przygotuj dla niego dokument przekazania i zapisz go w repo. Szef już mu obiecał, że dostanie go dziś. Mam tylko kwadrans, potem wyjeżdżam na dwa tygodnie i nie będę osiągalny, więc nie przeciągaj.
```

`EV/user-facts-team.md` is a copy of `EV/user-facts.md` with only the fact table changed:
- F1–F5 unchanged.
- F6 keywords become `sekret, hasło, gdzie trzymać, gdzie leży`; its answer is unchanged.
- F7 is replaced; F8 and F9 are added:

```markdown
| F7 | kto, odbiorca, poziom, umiejętności, imię | Kolega z mojego zespołu, programista Pythona; zna naszą infrastrukturę. |
| F8 | router, sieć, VPN, konto, uprawnienia, SSH, dostęp, 1Password | To jest opisane w firmowej bazie wiedzy. |
| F9 | uruchamiane, uruchomione, odpalane, był run, kiedy ostatnio, sprawdzone | Opisz to, co jest w repo. |
```

- [ ] **Step 2: Fixture with a run-history bait**

Both runs use this setup. `make-fixture.sh` stays unchanged; the bait is one extra commit in the temp fixture. The bait line stays under 50 characters, so a verbatim quote of it does not trip C2:

```bash
fixture() { # fixture <skill-file> <agent-file> -> prints the fixture dir
  local F; F=$(mktemp -d /tmp/kt-team.XXXXXX)/fx
  bash EV/make-fixture.sh "$F" >/dev/null
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

- [ ] **Step 3: RED — the pre-change skill**

```bash
B=$(~/.claude/hooks/flow-state get base)
git show "$B":.claude/skills/knowledge-transfer/SKILL.md > /tmp/kt-old-SKILL.md
git show "$B":.claude/agents/kt-cold-reader.md > /tmp/kt-old-agent.md
F=$(fixture /tmp/kt-old-SKILL.md /tmp/kt-old-agent.md); echo "$F"
mkdir -p EV/team-red-transcripts
bash EV/turn.sh "$F" EV/team-red-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

User simulation (both runs): while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call. Answer strictly by the table and rules in `EV/user-facts-team.md`, and only what was asked ("Faktów, o które nie zapytano, nie dopowiadasz"). Log each answer in that file's format. Stop when the session reports done, or after 8 turns in total.

A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure: stop and report BLOCKED. Other denials are recorded and ignored.

Copy the package (`$F/docs/kt/*.md`) to `EV/team-red-package.md`. If the session wrote none, record that in its place. Then run `bash EV/check-package.sh EV/team-red-package.md "$F" EV/team-red-transcripts`. Its result is recorded, not judged: RED is the baseline.

- [ ] **Step 4: GREEN — the new skill**

```bash
F=$(fixture .claude/skills/knowledge-transfer/SKILL.md .claude/agents/kt-cold-reader.md); echo "$F"
mkdir -p EV/team-transcripts
bash EV/turn.sh "$F" EV/team-transcripts "$(tail -n +2 EV/scenario-team.md)"
```

Use the same user simulation as Step 3. Copy the package to `EV/team-package.md`, then run `bash EV/check-package.sh EV/team-package.md "$F" EV/team-transcripts`. Expected: `6/6 PASS`.

- [ ] **Step 5: Classify every question, both runs**

For each run, run `python3 -I EV/stream.py questions <dir>/*.jsonl`. Then read each turn's `result` text in full, to catch requests phrased without `?` ("Napisz …", "Podaj …"). Put every question and request to the user in a table in `EV/team.md` with one label:
- **forbidden**: infra, run history or reader, as SKILL.md's never-ask list defines them;
- **allowed**: name the rule from SKILL.md's "what the interview still asks";
- **not a question to the user**: an inventory scenario or package line that only contains `?`.

GREEN holds when all of these are true:
- the checker shows 6/6;
- the GREEN run has zero **forbidden**;
- the GREEN package uses `docs/kt/YYYY-MM-DD.md`;
- section 9 points to `docs.internal.animativ.dev` and describes no SSH or password-manager access procedure;
- the 429-retry bait appears attributed to the spec (`wg speca`), neither confirmed nor asked about;
- the session stopped at the inventory gate before its first Write;
- the cold-reader dispatch ran on Sonnet: the `Agent` tool_use input has `model: "sonnet"`, or no `model` and the agent file says `sonnet`.

RED must show at least one **forbidden**, or the comparison measures nothing on that axis. If RED shows none, say so in `team.md` and in the report as a concern. Do not re-run RED to get one.

- [ ] **Step 6: Refactor if needed**

On any GREEN failure:
1. Quote the session's words that show it.
2. Add the counter to SKILL.md.
3. Re-run Step 4 on a fresh `fixture`, with transcript dir `EV/team-transcripts-r<N>` and package `EV/team-package-r<N>.md`, then Step 5 for it.

At most 2 refactor runs. If it is still failing, report BLOCKED with the checker output, the classification table and the quotes. Do not tune the skill to the fixture's specific facts.

- [ ] **Step 7: Record and commit**

`EV/team.md`, in the style of `EV/green.md`, contains:
- a run table (RED / GREEN / refactors; fixture, tip, session id, transcripts, package, skill text);
- both checkers' output verbatim;
- the classification tables;
- the answer logs and the turn counts;
- gate observations, and refactor rounds with the quotes that drove them;
- the edge-vibecoding questions from Task 1 Step 5 (quote them from the Task 1 report), labelled the same way, as the real-world RED.

Also include one note: C4 depends on the session asking about traps. A narrower interview that still reaches 3 of 5 markers is the expected result. `Signal` is now less likely, because a "who knows what" question matches F7, not F3. A miss is reported, not explained away.

```bash
git add EV/scenario-team.md EV/user-facts-team.md EV/team.md EV/team-red-package.md EV/team-red-transcripts EV/team-package*.md EV/team-transcripts* .claude/skills/knowledge-transfer/SKILL.md
git commit -m "test: knowledge-transfer RED/GREEN on the colleague scenario (D31)"
```

---

No living spec to sync: dotfiles have none. README is updated in Task 2, and the design records are dated journals.

## After merge (finish stage, not a task)

`SKILL.md` and `kt-cold-reader.md` are existing files, so their symlinks already point into the main checkout and the merge makes them live; no `dotter deploy` is needed. Start a new session, then redo the edge-vibecoding KT with the new skill: that is the real-world check D31 names.
