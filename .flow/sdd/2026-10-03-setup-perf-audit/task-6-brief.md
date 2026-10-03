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

### Task 6: pipeline skill text — background dispatch, Opus triggers, model table, run boundaries

**Files:**
- Modify: `.claude/skills/subagent-driven-development/SKILL.md` (Dispatching / per-task loop step 3 and the reviewer step; "Pass `model:` only to override" paragraph; the "Your prompt supplies" table row for task-reviewer)
- Modify: `.claude/skills/requesting-code-review/SKILL.md` (the dispatch step)
- Modify: `.claude/skills/development-workflow/SKILL.md` (`## Model & effort per stage`, `## Triage`)
- Modify: `.claude/skills/finishing-a-development-branch/SKILL.md` (the closing "Finally, end the run" line)
- Modify: `.claude/agents/task-reviewer.md` (section "What you are given")
- Modify: `.claude/skills/writing-plans/red-team.md` (`## Dispatch`)
- Modify: `.claude/hooks/statusline` (`model_hint`), test `.claude/hooks/flow-guard-test` (`hint_case` lines)

**Interfaces:**
- Consumes: Task 3's renumbered SDD loop and reviewer prompt contents.
- Produces: nothing code depends on.

- [ ] **Step 1: Write the failing checks** — save as `.flow/sdd/2026-10-03-setup-perf-audit/text-check.sh` in the worktree:

```bash
#!/usr/bin/env bash
R=$(cd "$(dirname "$0")/../../.." && pwd)/.claude; S=$R/skills; A=$R/agents
f=0; chk() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; f=1; fi; }
chk "SDD dispatches in background" "grep -q 'run_in_background: true' $S/subagent-driven-development/SKILL.md"
chk "review skill dispatches in background" "grep -q 'run_in_background: true' $S/requesting-code-review/SKILL.md"
chk "Opus triggers named" "grep -q 'auth' $S/subagent-driven-development/SKILL.md && grep -q '400 changed lines' $S/subagent-driven-development/SKILL.md"
chk "no vague non-trivial trigger" "! grep -q 'non-trivial, security- or concurrency-touching' $S/subagent-driven-development/SKILL.md"
chk "Explore row gone" "! grep -q 'Read-only exploration' $S/development-workflow/SKILL.md"
chk "model table says Sonnet 5.5" "grep -q 'Sonnet 5.5' $S/development-workflow/SKILL.md && ! grep -q 'Sonnet 5 ·' $S/development-workflow/SKILL.md"
chk "triage asks for /clear after a finished run" "grep -q '120K' $S/development-workflow/SKILL.md"
chk "finishing ends with /clear" "grep -q '/clear' $S/finishing-a-development-branch/SKILL.md"
chk "no second Global Constraints paste (SDD)" "! grep -q 'Global Constraints copied verbatim' $S/subagent-driven-development/SKILL.md"
chk "reviewer reads constraints from the brief" "grep -q 'brief already carries' $A/task-reviewer.md"
chk "red-team dispatched in background" "grep -q 'run_in_background: true' $S/writing-plans/red-team.md"
chk "model switches are session-only" "grep -q 'session only' $S/development-workflow/SKILL.md && ! grep -qE 'answers with .?/clear.?, .?/model sonnet.?, then' $S/development-workflow/SKILL.md"
chk "no stale 'runs Sonnet 5;'" "! grep -q 'runs Sonnet 5;' $S/subagent-driven-development/SKILL.md"
chk "statusline hints are session-only" "grep -q 'session only' $R/hooks/statusline"
exit $f
```

- [ ] **Step 2: Run to verify it fails**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh`
Expected: FAIL on every line.

- [ ] **Step 3: Implement**
- SDD and requesting-code-review: every dispatch instruction says "dispatch with `run_in_background: true`, then end the turn and wait for the task notification" (with `CLAUDE_CODE_FORK_SUBAGENT=0` the parameter is back and a foreground dispatch would block the session).
- SDD reviewer step: replace "with `model: "opus"` for a non-trivial, security- or concurrency-touching diff" with: `model: "opus"` when the diff touches auth, secrets or untrusted input; concurrency or lock order; a data migration or storage format; a public API contract — or exceeds ~400 changed lines; docs/spec-sync diffs stay on Sonnet; a re-review keeps the first review's model. Record it in the ledger note: `model=opus reason=<trigger>`. Mirror the trigger list in the "Pass `model:` only to override" paragraph.
- development-workflow `## Model & effort per stage`: "Sonnet 5" → "Sonnet 5.5" throughout (session default Sonnet 5.5 · high via `modelSettings` keyed `claude-sonnet-5-5`); task-reviewer row → "Sonnet 5.5 · high (Opus 5.5 on the named triggers in subagent-driven-development)"; delete the `Read-only exploration (Explore)` row.
- development-workflow `## Triage`: add a paragraph before "Small, with one decision": "**A finished run still in context.** If this conversation already carried a run through finish and the context is above ~120K, ask for `/clear` (or a handoff) before opening the next run — every request of the new run would otherwise re-read the old one."
- finishing: the closing line becomes "Finally, end the run: `~/.claude/hooks/flow-state clear` — and tell the user the next step is `/clear` before the next change."
- Model switches are session-only (the CLI's `/model` otherwise writes the pick into the tracked `settings.json`): development-workflow's "the user answers with `/clear`, `/model sonnet`, then `go`" becomes "the user answers with `/clear`, `/model sonnet` choosing *session only* in the picker (or a fresh `claude`, whose committed default is Sonnet), then `go`"; the Opus switch for stages 1–2 likewise names `/model opus` (session only) or `claude --model opus`. `statusline` `model_hint`: every `/model X` hint gains ` (session only)` (e.g. `⚠ /model opus (session only)`, `go → /clear · /model sonnet (session only) · go`); update the matching expected strings in the `hint_case` lines of `flow-guard-test`.
- red-team.md `## Dispatch`: add "dispatch with `run_in_background: true`" before "Then end the turn".
- SDD step 3: "The definition runs Sonnet 5;" → "The definition runs Sonnet 5.5;". Statusline module docstring example: drop `$0.42`, show `ctx 412K` and a `5h 40%  7d 12%` limits segment.
- SDD "Your prompt supplies" table, task-reviewer row: drop "and the plan's Global Constraints copied verbatim"; task-reviewer.md "What you are given": the brief already carries the plan's Global Constraints — name only the ones the diff touches.

- [ ] **Step 4: Run to verify it passes**

Run (from the worktree): `bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh && .claude/hooks/flow-guard-test | tail -1`
Expected: all PASS, exit 0; suite `0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills .claude/agents/task-reviewer.md .claude/hooks/statusline .claude/hooks/flow-guard-test .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh
git commit -m "skills: background dispatch, named Opus triggers, Sonnet 5.5 table, /clear at run end (D5, D16, D19, D23, D24)"
```

---
