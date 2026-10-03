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

### Task 2: Cloudflare plugin per repository

**Files (outside the repo — mutagen-synced to both machines; not committed anywhere):**
- Create or modify `.claude/settings.local.json` in: `/home/m/obsidian`, `/home/m/work/kid-aid-recordings-worker`, `/home/m/work/knowledge-base`, `/home/m/projects/ernest`, `/home/m/work/justom-static`, `/home/m/work/kid-aid-website-2026`, `/home/m/projects/cloud` (7 directories — `~/work/infrastructure-cloud` from the record does not exist)

**Interfaces:**
- Consumes: Task 1's `"cloudflare@cloudflare": false` at user scope.
- Produces: nothing later tasks use.

- [ ] **Step 1: Write the failing check** — save as `.flow/sdd/2026-10-03-setup-perf-audit/cf-check.py` in the worktree:

```python
import json, os, sys
DIRS = ["/home/m/obsidian", "/home/m/work/kid-aid-recordings-worker", "/home/m/work/knowledge-base",
        "/home/m/projects/ernest", "/home/m/work/justom-static", "/home/m/work/kid-aid-website-2026",
        "/home/m/projects/cloud"]
bad = []
for d in DIRS:
    if not os.path.isdir(d):
        print(f"skip (missing): {d}"); continue
    p = os.path.join(d, ".claude", "settings.local.json")
    try:
        cfg = json.load(open(p))
    except (OSError, ValueError) as e:
        bad.append(f"{p}: {e}"); continue
    if cfg.get("enabledPlugins", {}).get("cloudflare@cloudflare") is not True:
        bad.append(f"{p}: cloudflare not enabled")
print("\n".join(bad) or "all present directories enabled")
sys.exit(1 if bad else 0)
```

- [ ] **Step 2: Run it to verify it fails**

Run (from the worktree): `python3 .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py`
Expected: exit 1, lines naming the directories without the key. Record in the report which files already exist and their **top-level key names only** — at least one holds an API key in `env`; never `cat` these files (Global Constraints).

- [ ] **Step 3: Implement** — for each existing directory, load `settings.local.json` if present (else `{}`), set `enabledPlugins["cloudflare@cloudflare"] = true` keeping every other key and value untouched, write back with 2-space indent. Before writing, copy each pre-existing file to `<file>.bak-2026-10-03` beside it.

- [ ] **Step 4: Run it to verify it passes**

Run: `python3 .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py`
Expected: `all present directories enabled`, exit 0. For each pre-existing file, compare with its backup in python: the loaded dicts differ only in `enabledPlugins["cloudflare@cloudflare"]` (print `same except enabledPlugins` — never the values). Then delete the backups.

- [ ] **Step 5: Commit** — `git add .flow/sdd/2026-10-03-setup-perf-audit/cf-check.py && git commit -m "chore: cloudflare per-repo enablement check (D11)"`.

---
