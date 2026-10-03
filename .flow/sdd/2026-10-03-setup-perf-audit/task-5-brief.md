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

### Task 5: status line limits and absolute context; cheaper hook starts

**Files:**
- Modify: `.claude/hooks/statusline` (`context_segment`, `cost_segment`, new `limits_segment`, `git`, `main`)
- Modify: `.claude/hooks/prompt-context` (module imports)
- Test: `.claude/hooks/flow-guard-test` (section `=== status line ===`)

**Interfaces:**
- Consumes: statusLine payload fields verified in the 2.1.284 bundle: `context_window.total_input_tokens` (int, current prompt size = input + cache creation + cache read), `rate_limits.five_hour` / `rate_limits.seven_day` each `{used_percentage: number, resets_at: epoch seconds}`, either may be absent or null.
- Produces: `limits_segment(payload) -> str | None`.

- [ ] **Step 1: Write the failing tests** — append to the `=== status line ===` section of `flow-guard-test`, after `status line survives junk input`:

```bash
sl_rl() { python3 -c '
import json, sys
print(json.dumps({"workspace": {"current_dir": sys.argv[1], "project_dir": sys.argv[1]},
  "model": {"display_name": "Sonnet 5.5"},
  "context_window": {"used_percentage": 40, "total_input_tokens": int(sys.argv[2])},
  "rate_limits": {"five_hour": {"used_percentage": float(sys.argv[3]), "resets_at": 1790000000},
                  "seven_day": {"used_percentage": 12.0, "resets_at": 1790500000}},
  "cost": {"total_cost_usd": 3.21, "total_lines_added": 9, "total_lines_removed": 2}}))' "$@"; }
line=$(sl_rl "$COLD" 412000 93 | "$SL" | head -1)
case "$line" in *'$'*) report no "status line still shows dollars" "$line";; *) report ok "no dollar amount on a subscription";; esac
case "$line" in *"+9"*) report ok "lines added/removed kept";; *) report no "lines counter dropped" "$line";; esac
case "$line" in *$'\033[31m412K'*) report ok "context in absolute tokens, red at >=300K";; *) report no "absolute context" "$line";; esac
line=$(sl_rl "$COLD" 100000 20 | "$SL" | head -1)
case "$line" in *$'\033[32m100K'*) report ok "context green under 150K";; *) report no "context colour" "$line";; esac
line=$(sl_rl "$COLD" 200000 93 | "$SL" | head -1)
case "$line" in *$'\033[33m200K'*) report ok "context yellow under 300K";; *) report no "context yellow" "$line";; esac
case "$line" in *"5h "$'\033[31m93%'*) report ok "5h limit red at >=90%";; *) report no "5h limit" "$line";; esac
case "$line" in *"7d "$'\033[32m12%'*) report ok "7d limit shown";; *) report no "7d limit" "$line";; esac
line=$(sl_payload "$COLD" | "$SL" | head -1)
case "$line" in *"5h"*) report no "limits shown without rate_limits" "$line";; *) report ok "no limits segment without rate_limits";; esac
case "$line" in *"ctx "*"42%"*) report ok "falls back to percent without total_input_tokens";; *) report no "context fallback" "$line";; esac
grep -q 'GIT_OPTIONAL_LOCKS' "$SL" && report ok "status line git takes no optional locks" || report no "GIT_OPTIONAL_LOCKS"
grep -qE '^import traceback' "$HERE/prompt-context" && report no "prompt-context imports traceback eagerly" || report ok "traceback imported lazily"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'dollar|absolute|green under|yellow under|limit|GIT_OPTIONAL|traceback'`
Expected: FAIL on dollars, absolute context, colours, limits, GIT_OPTIONAL_LOCKS and traceback; the two fallback checks may already pass.

- [ ] **Step 3: Implement**
- `context_segment`: if `total_input_tokens` is an int, render `ctx {colour}{round(n/1000)}K{RESET}` with GREEN < 150000, YELLOW < 300000, else RED; otherwise keep today's percentage rendering.
- `cost_segment`: drop the dollar part; keep lines added/removed.
- `limits_segment(payload)`: for `five_hour` then `seven_day` (labels `5h`, `7d`) with a numeric `used_percentage`: `f"{label} {colour}{int(p)}%{RESET}"`, colour GREEN < 70, YELLOW < 90, else RED; after the 5h value append `f" {DIM}→{HH:MM}{RESET}"` from `resets_at` in local time when present; join the two with two spaces; `None` when neither is present. Add it to `main`'s segment tuple after `context_segment`.
- `git()`: pass `env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"}` to `subprocess.run`.
- `prompt-context`: remove the module-level `import traceback`; import it inside the `except` block that prints the traceback.

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1 && .claude/hooks/prompt-context-test | tail -1`
Expected: both `N passed, 0 failed`.

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/statusline .claude/hooks/prompt-context .claude/hooks/flow-guard-test
git commit -m "statusline: limits and absolute context, no dollars; lazy traceback (D13, D22)"
```

---
