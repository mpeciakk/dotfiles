# Task 4 report — literal commands (E4)

Status: DONE. Commit c89c204 `flow: literal workspace commands the worktree guard accepts (D17)`.

## Implemented
- `flow-state`: `LITERALS` + `resolve_literal` (`worktree=.` -> toplevel, `branch=.` -> current branch, `base=HEAD` -> SHA, via the module's `git(cwd, ...)`; dies with a clear message when git fails). `set` resolves before validation. `task` rewrites `base=HEAD` / `fixbase=HEAD` tokens inside the note (regex over the joined note, because callers pass the whole note as one argument). Relative-worktree hint now: ``use `worktree=.` from inside the worktree``. Usage docstring documents the literals.
- `task-brief`: first argument all digits -> `task-brief N [OUTFILE]`, plan from `<.claude>/hooks/flow-state get plan` (dir found from `readlink -f "$0"`, four dirnames up); `PLAN N [OUTFILE]` unchanged. Usage line and header comment updated; clear error when no plan is recorded.
- using-git-worktrees: ignore check moved before `EnterWorktree` as one literal command run in the main checkout, `MAIN=$(…)` block and "run after creation" paragraph dropped; Step 2 is `flow-state set stage=isolate worktree=. branch=. base=HEAD`.
- SDD per-task loop: step 1 `task-brief N`; step 2 `task N started "base=HEAD model=<haiku|sonnet>"` + read-back via `get tasks` (matched by content; steps are renumbered by task 3).
- requesting-code-review: step 1 two literal commands + `git merge-base HEAD main` fallback; the fix-range step uses `flow-state task branch-review started "fixbase=HEAD"`.

## TDD evidence
RED (`.claude/hooks/flow-guard-test`, new section appended first): `153 passed, 10 failed`. Failures: `worktree=.`, `branch=.`, `base=HEAD` (stored literal / refused), `task note` (stored `base=HEAD model=sonnet`), `fixbase note`, `relative-worktree hint` and `hint still recommends command substitution` (old message with `$(...)`), `task-brief N without a plan path` (usage), `skills still prescribe $(…)`, `SDD loop still uses $(…)`. Each is the missing feature, not a test error.

An intermediate GREEN attempt gave `162 passed, 1 failed` (`task note`): my first implementation split on argv tokens, but the note arrives as one argument. Fixed by regex over the joined note.

GREEN: `.claude/hooks/flow-guard-test` -> `163 passed, 0 failed` (rc=0); `.claude/hooks/prompt-context-test` -> `17 passed, 0 failed`. Also checked by hand: `task-brief` with no args prints usage rc=2; `task-brief PLAN 4 /tmp/x.md` still works.

## Files changed
`.claude/hooks/flow-state`, `.claude/hooks/flow-guard-test`, `.claude/skills/subagent-driven-development/SKILL.md`, `.claude/skills/subagent-driven-development/scripts/task-brief`, `.claude/skills/using-git-worktrees/SKILL.md`, `.claude/skills/requesting-code-review/SKILL.md`.

## Self-review
- The `fixbase=` slice is now regex-based; `(?<!\w)` keeps `base=HEAD` from matching inside `fixbase=HEAD`, and `(?!\w)` avoids `base=HEADER`.
- `resolve_literal` in `task` is only invoked when a token matches, so notes without literals never touch git.
- `task-brief` ambiguity: a plan path that is all digits would be read as a task number; not a real case.

## Concerns
- Heads-up: the worktree guard here refuses Bash commands that pipe python text mentioning git, so test/code edits were made with Edit rather than scripted.
- The `.claude/skills/subagent-driven-development/SKILL.md` line 58 `plan="$PLAN"` stays (variable, not command substitution); the brief did not ask to change it.
- Per-task reports under `.flow/sdd/` are untracked and not included in the commit (as with tasks 1-3).
