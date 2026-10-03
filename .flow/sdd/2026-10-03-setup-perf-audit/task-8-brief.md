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

### Task 8: `bin/claude-baseline` — the before/after measurement

**Files:**
- Modify: `bin/claude-baseline` (committed verbatim with the plan from the audit's `baseline.py`; this task edits it in place)

**Interfaces:**
- Consumes: nothing.
- Produces: `claude-baseline [FROM=YYYY-MM-DD] [TO=YYYY-MM-DD]` — read-only report on `~/.claude/projects` (first-request size by machine/kind, cache share, compactions).

- [ ] **Step 1: Write the failing check**

Run: `grep -q 'lastModelUsage' bin/claude-baseline`
Expected: exit 1 (the analysis rules are not in the header yet).

- [ ] **Step 2: Implement** — extend its docstring (keep it Polish, like the file) with the analysis rules (F7): output tokens of subagents since 2.1.280 are ~3× under-reported in transcripts — use `~/.claude.json` `lastModelUsage` / cost state for output; window by entry `timestamp`, never file mtime; machine from the `[CTX]` line, else version; keep accounts apart if more than one shows up. Keep the `LAP`/`PC` version sets (they are the host fallback) and add a comment above them that they need updating when either machine upgrades.

- [ ] **Step 3: Run to verify it works**

Run: `bin/claude-baseline 2026-09-27 2026-10-03`
Expected: prints first-request medians for main/sub by machine (laptop main ~49K, pc main ~51K on this window) and a compaction count; exit 0.

- [ ] **Step 4: Commit**

```bash
git add bin/claude-baseline
git commit -m "bin: claude-baseline analysis rules (D28)"
```

---

No living-spec sync task: the dotfiles have no `spec.md`; README (Task 7) is the state document.

Before the finish merge (laptop main checkout): it carries uncommitted edits to `.claude/settings.json` that Task 1 supersedes, which would make `git merge` refuse — run `git -C /home/m/dotfiles checkout -- .claude/settings.json` (that one path only; never `stash` or `checkout .`, which would sweep the user's `config/` and `hosts/` edits).

After merge (by the user, both machines, not part of execution): on pc `git -C ~/dotfiles checkout .claude/settings.json` before `pull` (D1); `dotter deploy` on both machines (removes the deleted hooks' symlinks, links `bin/claude-baseline`); then the manual items from the design record — mutagen force-poll (D26), cbm watcher off in `~/obsidian` and `~/work/knowledge-base` (D27), pc Cloudflare skill copies (A7).
