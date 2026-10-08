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
