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
