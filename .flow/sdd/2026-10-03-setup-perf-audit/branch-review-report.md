# Branch-review fixes (fixer report)

Pre-fix HEAD `ca41e99`. Worktree `/home/m/dotfiles/.claude/worktrees/feat-setup-perf-audit`,
branch `worktree-feat-setup-perf-audit`. All new tests live in a `=== branch-review fixes ===`
block at the end of `.claude/hooks/flow-guard-test`.

Covering command for every finding below: `.claude/hooks/flow-guard-test`.
RED run before the fixes: `176 passed, 5 failed` (task-brief arg drop, detached branch=.,
reviewer wording, absurd resets_at 5h, 7d dropped). After: `181 passed, 0 failed`; after
adding the two doc-text checks (findings 1, 2): `183 passed, 0 failed`.

## 1. finishing Step 1 archive commit (IMPORTANT)
Changed `.claude/skills/finishing-a-development-branch/SKILL.md`: the nested `$(basename "$(…)")`
is gone; the block is now `flow-state get plan`, `git add .flow/sdd`,
`git commit -m "docs: archive sdd reports for <plan basename>"`, plus a sentence telling the
reader to write the basename from the first command's output. Other `$(…)` lines untouched.
Test: `PASS  archive commit is two literal steps` (the check greps the HEAD version and
finds the old `archive sdd reports for $(` once, the new file zero times).

## 2. SDD step 6 fixer dispatch
`.claude/skills/subagent-driven-development/SKILL.md`: fixer dispatch now says
"with `run_in_background: true` (then end the turn, as in step 3)".
Test: `PASS  SDD fixer dispatch runs in the background` (0 matches in step 6 on HEAD, match now).

## 3. flow-context wording
`.claude/hooks/flow-context:62`: "That is the tree BASE..HEAD lives in." No assertion on the old
string existed in flow-guard-test (grep confirmed). Test added:
`PASS  reviewer context names the tree BASE..HEAD lives in` (failed before the change).

## 4. task-brief third user argument
`.../scripts/task-brief`: the post-prepend check is now `[ $# -lt 2 ] || [ $# -gt 3 ]`, so
`task-brief N OUTFILE EXTRA` (4 args after prepend) prints the usage line, rc=2, writes nothing.
Tests: `PASS  task-brief N OUTFILE EXTRA is refused with the usage line`,
`PASS  refused task-brief wrote nothing` (first one FAILED before: rc=0, wrote the default path).

## 5. flow-state detached HEAD
`.claude/hooks/flow-state` `resolve_literal`: for `key == "branch"` the error ends with
" (detached HEAD?)". Test: `PASS  branch=. on a detached HEAD says so` (failed before; message
was only "…git branch --show-current failed in …").

## 6. statusline resets_at
`.claude/hooks/statusline`: only the `→HH:MM` suffix is wrapped in
`try/except (OverflowError, OSError, ValueError)`; docstring now lists `rate_limits`.
Tests: `PASS  absurd resets_at keeps the 5h percentage` and `PASS  absurd resets_at keeps the 7d
percentage` (resets_at 1e30; both failed before, bar was blank),
`PASS  normal resets_at shows →HH:MM` (regex `→[0-9]{2}:[0-9]{2}`; passed before and after, it
guards the suffix against the try-wrap swallowing it).

## 7. development-workflow row
`.claude/skills/development-workflow/SKILL.md:95`: "/model sonnet (session only) at "go"".
Covered by `text-check.sh` ("statusline hints are session-only" family) staying green; no
dedicated test (one-word doc edit).

## 8. Grep/Read wording
`.claude/README.md:51`: "before grep/find via Bash". `.claude/agents/implementer.md:71`:
"before grep/find via Bash (Read is for text, config and non-code files)". Doc edits; text-check
scripts stay green.

## 9. Memory notes (outside the repo, not committed)
`/home/m/.claude/projects/-home-m-dotfiles/memory/plan-granularity-experiment.md`: description says
closed 2026-10-03 (kept); "How to apply" labelled "(original criterion, now settled — see
Outcome)"; Sonnet line says "Sonnet (5.5 as of the 2026-10-03 closing)".
`MEMORY.md`: one line, "closed 2026-10-03, kept: … (historical rollback pointer 0d2c8b3)".

## Full suite
```
.claude/hooks/flow-guard-test | tail -1       -> 183 passed, 0 failed
.claude/hooks/prompt-context-test | tail -1   -> 17 passed, 0 failed
bash .flow/sdd/2026-10-03-setup-perf-audit/text-check.sh    -> every line PASS (0 non-PASS lines)
bash .flow/sdd/2026-10-03-setup-perf-audit/text-check-2.sh  -> every line PASS (0 non-PASS lines)
```

## Declined
Nothing.

## Concerns
- The worktree guard refused a python heredoc that mentioned git in its text; edits were redone
  with the Edit tool (no effect on the result).
- Items 7 and 8 have no dedicated regression test (pure wording); the text-check scripts are the net.
