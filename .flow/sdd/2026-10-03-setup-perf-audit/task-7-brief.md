## Global Constraints

- Do not touch `config/`, `hosts/`, or `config/mimeapps.list` — unrelated user changes live there.
- Hooks and scripts stay python3/bash with the standard library only; keep each file's existing style and comment density.
- `.claude/settings.json`: valid JSON, 2-space indentation, existing key order kept where a key survives.
- `CLAUDE.md` stays Polish; skills, agents and README stay English.
- The hook test suites must end green: `/home/m/dotfiles/.claude/hooks/flow-guard-test` and `/home/m/dotfiles/.claude/hooks/prompt-context-test` (run them from the worktree path — they test the files beside them).
- Cite code in docs by path and symbol, never by line number.
- The repo is PUBLIC and run reports under `.flow/sdd/` get committed: never copy the contents of any `settings.local.json`, `.credentials*`, `~/.claude.json` or env values into a report, test, script or commit — key names only (`python3 -c 'import json,sys; print(sorted(json.load(open(sys.argv[1]))))' FILE`).
- Run commands with literal paths (no `$(…)`, no `VAR=$(…) cmd $VAR`): the harness's worktree guard refuses computed commands. Throwaway check scripts live in `.flow/sdd/2026-10-03-setup-perf-audit/` and resolve their root from their own path.
- Live config is the main checkout (`~/.claude/*` symlinks into `/home/m/dotfiles`), so nothing in the worktree takes effect until merge + `dotter deploy`; verify settings with `claude --settings <file>`.

---

### Task 7: brainstorming/writing-plans rules inline, CLAUDE.md rules 2 and 5, README, experiment note

**Files:**
- Modify: `.claude/skills/brainstorming/SKILL.md` (Checklist item 3)
- Modify: `.claude/skills/writing-plans/SKILL.md` (`## Red-Team Pass`)
- Modify: `.claude/CLAUDE.md` (rules 2 and 5 — Polish)
- Modify: `.claude/README.md` (`## Model & effort`, `## codebase-memory (cbm)`, the plan-granularity paragraph)
- Modify (outside repo, synced): `/home/m/.claude/projects/-home-m-dotfiles/memory/plan-granularity-experiment.md`, `/home/m/.claude/projects/-home-m-dotfiles/memory/MEMORY.md`

**Interfaces:**
- Consumes: Task 1 (models, hooks removed), Task 6 (model table).
- Produces: nothing code depends on.

- [ ] **Step 1: Write the failing checks** — save as `.flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh` in the worktree:

```bash
#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; M=/home/m/.claude/projects/-home-m-dotfiles/memory
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "grill rule inline in brainstorming checklist" "grep -qE '^3\. \*\*Grill gate\*\*.*recommended default and why' $R/skills/brainstorming/SKILL.md"
chk "minor-objection rule inline in writing-plans" "awk '/^## Red-Team Pass/,/^## Execution/' $R/skills/writing-plans/SKILL.md | grep -q 'verdict PROCEED'"
chk "rule 2 names grep/find via Bash" "grep -q 'grep/find' $R/CLAUDE.md && ! grep -q 'Grep/Glob/Read tylko' $R/CLAUDE.md"
chk "rule 2 names the cbm project convention" "grep -q 'home-m-projects-' $R/CLAUDE.md"
chk "rule 5 marked main-thread" "grep -q 'dotyczy głównego wątku' $R/CLAUDE.md"
chk "README: no Sonnet 5 xhigh default" "! grep -q 'Sonnet 5 · xhigh' $R/README.md"
chk "README: no Grep/Glob augmenter" "! grep -q 'PreToolUse augmenter' $R/README.md"
chk "experiment note closed" "! grep -q 'Still open' $M/plan-granularity-experiment.md && grep -q 'Haiku' $M/plan-granularity-experiment.md"
exit $f
```

- [ ] **Step 2: Run to verify it fails**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh`
Expected: FAIL on every line.

- [ ] **Step 3: Implement**
- brainstorming Checklist item 3 (the line starting `3. **Grill gate**`): state the rule inline on that line — "grill one question at a time, each with a recommended default and why" — keeping the pointer to `grill-gate.md` for the rest.
- writing-plans `## Red-Team Pass`: inline the minor-only rule from `red-team.md` — "Minor objections only, or none: verdict PROCEED; apply the list to the plan without a gate and name it in one line at the plan gate."
- CLAUDE.md rule 2 (Polish): replace "Grep/Glob/Read tylko do tekstu…" with grep/find przez Bash + Read for text, configs and non-code; add one sentence: nazwa projektu w cbm to ścieżka main checkoutu z myślnikami (np. `home-m-projects-harmonia`), także gdy pracujesz w worktree. Keep "Projekt bez indeksu → najpierw index_repository". Rule 5: append "(dotyczy głównego wątku)" to its first sentence.
- README: `## Model & effort` → session default Sonnet 5.5 · high, design/plan Opus 5.5 · high, roles as in development-workflow's table, task-reviewer Opus on named triggers; `## codebase-memory (cbm)` → drop the PreToolUse augmenter and the SubagentStart reminder sentence (the protocol lives in CLAUDE.md rule 2); plan-granularity paragraph → the middle-variant plans are kept (D25).
- Memory note: replace the "Still open" sentence with the outcome (revert criterion not met; Haiku override on the implementer accepted), keep `0d2c8b3` as a historical pointer; update its line in MEMORY.md (`— closed 2026-10-03: middle-variant plans kept`).

- [ ] **Step 4: Run to verify it passes**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh`
Expected: all PASS, exit 0.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/brainstorming/SKILL.md .claude/skills/writing-plans/SKILL.md .claude/CLAUDE.md .claude/README.md .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh
git commit -m "docs: inline grill/red-team rules, CLAUDE.md rules 2 and 5, README to current config (D20, D21, D24, D25)"
```

---
