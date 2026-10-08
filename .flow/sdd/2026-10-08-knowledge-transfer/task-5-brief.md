## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

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
User simulation: while the session's last result asks a question or asks for approval, answer with one `turn.sh … <session-id>` call, strictly by the table and rules in `EV/user-facts.md`, logging each answer in its format. Stop when it reports done, or after 8 turns in total. A `DENIED Skill`, `DENIED Agent`, `DENIED Write` or `DENIED Edit` is a harness failure — stop and fix `turn.sh`; other denials are recorded and ignored.

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
