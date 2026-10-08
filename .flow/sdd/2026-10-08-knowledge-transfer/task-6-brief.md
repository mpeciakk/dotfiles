## Global Constraints

- All paths are relative to the repo root `/home/m/dotfiles` unless absolute. `EV` below means `.flow/specs/2026-10-08-knowledge-transfer-evidence`.
- Test harness and evidence live in `EV/`; nothing from the harness goes into `.claude/`.
- Skill and agent texts are English (like every skill in `.claude/skills/`); the package the skill produces, the scenario prompts and the cold-reader's answers are Polish.
- Skills and agents under `~/.claude` are per-file symlinks into the **main checkout**, so files created in the worktree are invisible to any session. Every live test copies the files under test into a temp dir's own `.claude/agents/` / `.claude/skills/` (project level) and runs `claude -p` with that dir as cwd. Never run a nested `claude` with the dotfiles repo or the worktree as cwd: the run's flow-guard would deny its writes.
- Every nested `claude -p` call: the prompt is the first argument after `-p` (`--tools`, `--allowedTools`, `--disallowedTools` are variadic and swallow what follows them); `--model sonnet` (the production session model); `--output-format stream-json --verbose`; `--disallowedTools SendMessage ListAgents` (nested sessions load `~/.claude/CLAUDE.md`, which tells them to report facts to the vault session — fixture facts must not reach it). Never `--permission-mode bypassPermissions` or `--dangerously-skip-permissions`; a denied tool is reported, not bypassed.
- Bash tool calls that run a nested session use `timeout: 600000`; a turn that may run longer (scan + package + cold read) runs with `run_in_background: true` and is waited for.
- The fake secret `kt-secret-7Q9ZL4MX2P` exists only in fixtures; committing it inside `EV/` evidence is fine (fake by construction).

---

### Task 6: README and design record to current state

Dotfiles have no living spec; README and the design record are the state documents this change makes untrue.

**Files:**
- Modify: `.claude/README.md` (section `## The flow`, after the "Always-on discipline" paragraph)
- Modify: `.flow/specs/2026-10-08-knowledge-transfer-design.md` (section `## Do sprawdzenia w implementacji`)

- [ ] **Step 1: README**

Add one paragraph, headed `**Outside the pipeline**`: `writing-specs` bootstraps a project's living spec; `knowledge-transfer` writes a dated handover package for a successor, a support person or the user's later self, checked by the `kt-cold-reader` agent, which sees only the package; neither opens a run. Follow the paragraph style of the "Always-on discipline" paragraph above it.

- [ ] **Step 2: Design record**

Replace the body of `## Do sprawdzenia w implementacji` with the result from `EV/probe.md` (does `tools: TaskStop` spawn under Sonnet and stay blind — one sentence, with a pointer to `EV/probe.md`) and rename the heading to `## Sprawdzone w implementacji`.

- [ ] **Step 3: Verify**

Run: `grep -n 'knowledge-transfer' .claude/README.md && grep -n 'Sprawdzone w implementacji' .flow/specs/2026-10-08-knowledge-transfer-design.md && bash .flow/specs/2026-10-08-knowledge-transfer-evidence/check-package-test.sh | tail -1 && bash .flow/specs/2026-10-08-knowledge-transfer-evidence/stream-test.sh | tail -1`
Expected: one README line, one heading line, `8 passed, 0 failed`, `5 passed, 0 failed`.

- [ ] **Step 4: Commit**

```bash
git add .claude/README.md .flow/specs/2026-10-08-knowledge-transfer-design.md
git commit -m "docs: knowledge-transfer in README; D30 probe result in the design record"
```

---
