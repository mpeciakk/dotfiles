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

### Task 4: literal commands — flow-state resolves `.` and `HEAD`, task-brief finds the plan (E4)

**Files:**
- Modify: `.claude/hooks/flow-state` (`main`, commands `set` and `task`; the worktree error hint)
- Modify: `.claude/skills/subagent-driven-development/scripts/task-brief` (argument handling)
- Modify: `.claude/skills/using-git-worktrees/SKILL.md` (Step 1 ignore check, Step 2 record), `.claude/skills/subagent-driven-development/SKILL.md` (per-task loop steps 1–2), `.claude/skills/requesting-code-review/SKILL.md` (How, step 1)
- Test: `.claude/hooks/flow-guard-test` (new section)

**Interfaces:**
- Consumes: nothing new.
- Produces: `flow-state set worktree=. branch=. base=HEAD` (resolved against `--cwd`/cwd: worktree → `git rev-parse --show-toplevel`, branch → `git branch --show-current`, base → `git rev-parse HEAD`); `flow-state task N STATUS "base=HEAD …"` (and `fixbase=HEAD`) stores the resolved SHA in the note; `task-brief N` (one argument) reads the plan from `flow-state get plan`.

- [ ] **Step 1: Write the failing tests** — append to `flow-guard-test` before the final summary line:

```bash
echo "=== literal values in flow-state and task-brief (E4) ==="
LIT=$ROOT/literal; mkrepo "$LIT" >/dev/null || fixture_fail "literal repo"
"$STATE" --cwd "$LIT" init lit >/dev/null
"$STATE" --cwd "$LIT" set stage=isolate worktree=. branch=. base=HEAD >/dev/null 2>&1
[ "$("$STATE" --cwd "$LIT" get worktree)" = "$(git -C "$LIT" rev-parse --show-toplevel)" ] \
  && report ok "worktree=. resolves to the toplevel" || report no "worktree=." "$("$STATE" --cwd "$LIT" get worktree)"
[ "$("$STATE" --cwd "$LIT" get branch)" = "$(git -C "$LIT" branch --show-current)" ] \
  && report ok "branch=. resolves to the current branch" || report no "branch=."
[ "$("$STATE" --cwd "$LIT" get base)" = "$(git -C "$LIT" rev-parse HEAD)" ] \
  && report ok "base=HEAD resolves to a SHA" || report no "base=HEAD" "$("$STATE" --cwd "$LIT" get base)"
"$STATE" --cwd "$LIT" task 1 started "base=HEAD model=sonnet" >/dev/null 2>&1
note=$("$STATE" --cwd "$LIT" get tasks | python3 -c 'import json,sys; t=json.load(sys.stdin); print(t[0].get("note","") if t else "")')
[ "$note" = "base=$(git -C "$LIT" rev-parse HEAD) model=sonnet" ] \
  && report ok "task note base=HEAD is stored resolved" || report no "task note" "$note"
"$STATE" --cwd "$LIT" task branch-review started "fixbase=HEAD" >/dev/null 2>&1
note=$("$STATE" --cwd "$LIT" get tasks | python3 -c 'import json,sys; print([t.get("note","") for t in json.load(sys.stdin) if t["n"]=="branch-review"][0])')
[ "$note" = "fixbase=$(git -C "$LIT" rev-parse HEAD)" ] \
  && report ok "task note fixbase=HEAD is stored resolved" || report no "fixbase note" "$note"
out=$("$STATE" --cwd "$LIT" set worktree=relative/path 2>&1)
case "$out" in *'worktree=.'*) report ok "relative-worktree error suggests worktree=.";;
  *) report no "relative-worktree hint" "$out";; esac
case "$out" in *'$('*) report no "hint still recommends command substitution" "$out";; *) report ok "hint has no command substitution";; esac
mkdir -p "$LIT/.flow/plans"
printf '# P\n\n## Global Constraints\n\nNone.\n\n### Task 1: one\n\nbody-one\n' > "$LIT/.flow/plans/p.md"
"$STATE" --cwd "$LIT" set plan="$LIT/.flow/plans/p.md" >/dev/null
TB=$(cd "$HERE/../skills/subagent-driven-development/scripts" && pwd)/task-brief
brief=$(cd "$LIT" && "$TB" 1 2>/dev/null)
[ -n "$brief" ] && grep -q body-one "$brief" \
  && report ok "task-brief N reads the plan from flow-state" || report no "task-brief N without a plan path" "$brief"
```

- [ ] **Step 2: Run to verify it fails**

Run: `.claude/hooks/flow-guard-test | grep -E 'resolves|stored resolved|worktree=\.|substitution|reads the plan'`
Expected: FAIL on each (today `worktree=.` dies with "worktree must be absolute", `branch=.` stores a literal dot, `task-brief 1` prints its usage).

- [ ] **Step 3: Implement**
- `flow-state` `set`: before validation, map literal values — `worktree=.` → toplevel of the effective cwd (use the module's `git(cwd, "rev-parse", "--show-toplevel")`), `branch=.` → `git(cwd, "branch", "--show-current")`, `base=HEAD` → `git(cwd, "rev-parse", "HEAD")`; die with a clear message if git fails. Relative-worktree error hint becomes: ``worktree must be absolute — the hooks compare realpaths: use `worktree=.` from inside the worktree``.
- `flow-state` `task`: in the note, replace a `base=HEAD` or `fixbase=HEAD` token with the resolved full SHA from the effective cwd.
- `task-brief`: accept `task-brief N [OUTFILE]` when the first argument is all digits — then `plan=$(<.claude>/hooks/flow-state get plan)` where the hooks dir is resolved from the script's realpath (`readlink -f "$0"` → `scripts` → `subagent-driven-development` → `skills` → `.claude`); keep the existing `PLAN N [OUTFILE]` form. Update the usage line and header comment.
- using-git-worktrees Step 1: move the ignore check **before** `EnterWorktree`, run in the main checkout as literal commands: `mkdir -p .claude/worktrees && git check-ignore -q .claude/worktrees || { echo '.claude/worktrees/' >> .gitignore && git add .gitignore && git commit -m "chore: ignore worktrees"; }` (the directory exists, so check-ignore answers correctly; the commit lands on HEAD before the branch is cut). Drop the `MAIN=$(…)` block and the paragraph about running the check after creation.
- using-git-worktrees Step 2: `~/.claude/hooks/flow-state set stage=isolate worktree=. branch=. base=HEAD`.
- SDD per-task loop step 1: `~/.claude/skills/subagent-driven-development/scripts/task-brief N` (prints the brief path); step 2: `~/.claude/hooks/flow-state task N started "base=HEAD model=<haiku|sonnet>"`, then read the base back with `~/.claude/hooks/flow-state get tasks` when the reviewer needs it.
- requesting-code-review step 1: `~/.claude/hooks/flow-state get base` and `git rev-parse HEAD` as two separate literal commands; fall back to `git merge-base HEAD main` as its own command; pass the printed SHAs on. Step 4 (the fix range): `flow-state task branch-review started "fixbase=$(git rev-parse --short HEAD)"` becomes `~/.claude/hooks/flow-state task branch-review started "fixbase=HEAD"`.
- Add to the Step 1 tests: `grep -qE '\$\(' "$SK/using-git-worktrees/SKILL.md" "$SK/requesting-code-review/SKILL.md" && report no "skills still prescribe \$(…) commands" || report ok "worktree/review skills prescribe literal commands"` (with `SK=$(cd "$HERE/../skills" && pwd)` if not yet defined in that section); in SDD check only the per-task loop: `awk '/^## The per-task loop/,/^## Implementer status/' "$SK/subagent-driven-development/SKILL.md" | grep -q '\$(' && report no "SDD loop still uses \$(…)" || report ok "SDD loop is literal"`.

- [ ] **Step 4: Run to verify it passes**

Run: `.claude/hooks/flow-guard-test | tail -1`
Expected: `N passed, 0 failed` (all earlier sections still green, including the fixture's absolute-path `set`).

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/flow-state .claude/hooks/flow-guard-test .claude/skills/subagent-driven-development .claude/skills/using-git-worktrees/SKILL.md .claude/skills/requesting-code-review/SKILL.md
git commit -m "flow: literal workspace commands the worktree guard accepts (D17)"
```

---
