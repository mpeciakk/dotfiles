# Red-team log

One row per red-team finding, filled at the plan gate. "Changed D" = the finding
changed a Decision row; "Behaviour" = it was about how the result behaves (not wording or process).

| date | plan | finding | severity | changed D | behaviour |
|---|---|---|---|---|---|
| 2026-10-31 | lean-workflow-v2 | S1 `stage=inline` turns flow-guard off | serious | W1, W12 | yes |
| 2026-10-31 | lean-workflow-v2 | S2 writer contract makes allowed subagents BLOCKED | serious | W1 (task 2 acceptance) | yes |
| 2026-10-31 | lean-workflow-v2 | S3 review diff in un-ignored worktree `.flow/run/` | serious | W9 | yes |
| 2026-10-31 | lean-workflow-v2 | S4 uncommitted live settings.json on main breaks merge | serious | W12 (gate step) | yes |
| 2026-10-31 | lean-workflow-v2 | S5 model cannot see its context size | serious | W8 | yes |
| 2026-10-31 | lean-workflow-v2 | S6 test-output filter never fires / hides exit code | serious | W8 (item dropped) | yes |
| 2026-10-31 | lean-workflow-v2 | S7 audit hunks and writing-specs owned by no task | serious | — (tasks) | no |
| 2026-10-31 | lean-workflow-v2 | S8 red-team counting condition not carried | serious | W6 | no |
| 2026-10-31 | lean-workflow-v2 | S9 prose "no advisor" loses to harness | serious | W7 | yes |
| 2026-10-31 | skills-cleanup | S1 eval cannot tell old from new; fallback breaks Verification | serious | D8 | yes |
| 2026-10-31 | skills-cleanup | S2 D9 drops W3 test-first default | serious | D9 | yes |
| 2026-10-31 | skills-cleanup | S3 D10 drops order of work, scope, pushback rules | serious | D10 | yes |
| 2026-10-31 | skills-cleanup | S4 "No root cause" retry contradicts D3 | serious | D3 | yes |
| 2026-10-31 | skills-cleanup | S5 Task 5 trigger vs process-summary undefined | serious | no | yes |
| 2026-10-31 | skills-cleanup | M1 D5 link has no URL, misses Claude Code frontmatter | minor | D5 | no |
| 2026-10-31 | skills-cleanup | M2 waitForEvent defined only in deleted .ts | minor | no | yes |
| 2026-10-31 | skills-cleanup | M3 counter-evidence table carries stale rows | minor | D5 | no |
| 2026-10-31 | skills-cleanup | M4 unsettled-flags.md goes stale | minor | no | no |
| 2026-10-31 | skills-cleanup | M5 laptop deploy and rollback tag missing | minor | no | no |
