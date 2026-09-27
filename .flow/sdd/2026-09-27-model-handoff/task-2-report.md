# Task 2 report — Handoff text: flow-context and skills

## Workspace check
`git rev-parse --show-toplevel` → `/home/m/dotfiles/.claude/worktrees/feat+model-handoff`
`git branch --show-current` → `worktree-feat+model-handoff`
Both matched the dispatch before any edit.

## What I implemented
1. `.claude/hooks/flow-context` (`session_context`): when `state.get("stage") == "plan"`,
   appends the line `The plan awaits the user's "go". On go: using-git-worktrees, then
   subagent-driven-development — do not re-plan.` before the final "Trust this…" line.
2. `.claude/hooks/flow-guard-test`: added the two new assertions to the
   `=== context reflects the real vocabulary ===` section (verbatim from the brief),
   checking the handoff line appears at `stage=plan` and does not leak into `stage=implement`.
3. `.claude/skills/development-workflow/SKILL.md` — `## Model & effort per stage`:
   replaced the first paragraph (session default Sonnet 5 · high; stages 1–2 on
   Opus 5.5 · high; plan-gate handoff via `/clear`, `/model sonnet`, `go`; one-sentence
   why on prompt-cache-per-model) and replaced the first table row with the two rows
   the brief specified (`Brainstorm / grill / planning (inline)` and `Controller from
   "go" on, debugging (inline)`). Rest of the table (dispatched roles) left untouched.
4. `.claude/skills/writing-plans/SKILL.md` — `## Execution Handoff`: changed the
   Announce line's ending from `Say 'go' to execute.` to
   `To execute: /clear, /model sonnet, then 'go'.`

**Skipped per dispatch instructions:** `.claude/settings.json` — the controller applies
`modelSettings.claude-opus-5-5.effortLevel: medium → high` after merge; I did not touch
it in the worktree or the main checkout.

## TDD evidence

RED — added the two assertions from the brief to `flow-guard-test`, then ran:
```
$ bash .claude/hooks/flow-guard-test 2>&1 | grep -E "FAIL|passed"
FAIL  stage=plan context lacks the go handoff                      An open pipeline run exists in this repository (development-workflow).
135 passed, 1 failed
```
Expected and correct: `session_context` did not yet emit the go-handoff line at
`stage=plan`, so the first new assertion failed on the real payload (not an import/
collection error) while the second (`stage=implement` case) already passed, matching
the brief's "Expected" note exactly.

GREEN — after adding the `stage == "plan"` branch to `session_context`:
```
$ bash .claude/hooks/flow-guard-test 2>&1 | grep -E "FAIL|passed"
136 passed, 0 failed
```

Final full-suite run after all edits (skill text does not affect the suite, but reran
to confirm nothing regressed):
```
$ bash .claude/hooks/flow-guard-test 2>&1 | tail -1
136 passed, 0 failed
```
Output is pristine — no stray warnings.

## Files changed
- `.claude/hooks/flow-context`
- `.claude/hooks/flow-guard-test`
- `.claude/skills/development-workflow/SKILL.md`
- `.claude/skills/writing-plans/SKILL.md`

Commit `f2104f0`: "handoff: go means /clear + /model sonnet; cleared session knows what go starts"
(only these four files staged; verified `git status --short` before commit showed no
unrelated changes beyond the pre-existing untracked `.flow/sdd/2026-09-27-model-handoff/`
brief/report directory).

## Self-review
- Diffed all three text edits against the brief's exact wording — verbatim match on
  the flow-context string, the development-workflow paragraph/table row, and the
  writing-plans Announce line.
- Confirmed the dispatched roles table below the edited row is otherwise unchanged
  (`implementer`, `fixer`, `task-reviewer`, `branch-reviewer`, `plan-red-team`,
  `Explore`, `Finish` rows untouched).
- Confirmed `git rev-parse --show-toplevel` still resolves to the worktree after
  committing.
- Did not touch `.claude/settings.json` anywhere, in either checkout.

## Concerns
None. Scope was fully mechanical text/doc changes plus one small hook branch, all
specified verbatim in the brief.

## Branch-review fixes

Workspace check: `git rev-parse --show-toplevel` → this worktree,
`git branch --show-current` → `worktree-feat+model-handoff`. Both matched before
any edit. `git status --short` showed no changes I did not make (only the
pre-existing untracked `.flow/sdd/2026-09-27-model-handoff/`).

### Finding 1 — `flow-context:94-98` handoff line, and the statusline hint, must gate on `plan` being set

Both sites keyed only on `stage == "plan"`, so a session compacted mid-planning
(stage=plan recorded, no plan file yet — per development-workflow:28 and
writing-plans:20) would be wrongly told "do not re-plan", and the status line
would show the `/clear · /model sonnet · go` handoff before there was anything
to hand off.

**RED** — added the negative cases first and confirmed they failed for the
right reason (existing code showing the handoff/hint with no plan set):
```
$ bash .claude/hooks/flow-guard-test 2>&1 | grep -E "FAIL|passed"
FAIL  plan on Opus, no plan written yet: no handoff hint           flow  hinting · plan · go → /clear · /model sonnet · go
FAIL  handoff line shown before a plan is written
136 passed, 2 failed
```

**Fix:**
- `.claude/hooks/flow-context` `session_context`: gate changed from
  `if state.get("stage") == "plan"` to
  `if state.get("stage") == "plan" and state.get("plan")`.
- `.claude/hooks/statusline` `model_hint`: signature changed to
  `model_hint(stage, payload, has_plan)`; the plan-stage branch changed from
  `if stage == "plan" and opus` to `if stage == "plan" and opus and has_plan`.
  The one call site in `flow_line` now passes
  `model_hint(stage, payload, bool(state.get("plan")))`.
- `.claude/hooks/flow-guard-test`: in `=== status line model hint ===`, added
  a clear/negative-case/restore around the existing plan+Opus case (clears
  `plan=`, asserts `NONE`, restores `plan="$HNT/p.md"`). In
  `=== context reflects the real vocabulary ===`, split the old single
  `stage=plan` assertion into: a negative case with no plan set (asserts the
  handoff line is absent), then `set plan=...`, then the original positive
  assertion (handoff line present) before moving on to `stage=implement`.

**GREEN:**
```
$ bash .claude/hooks/flow-guard-test 2>&1 | grep -E "FAIL|passed"
138 passed, 0 failed
```

### Finding 2 — `development-workflow/SKILL.md` dropped the hard-debug escalation path

The table row for "Controller from 'go' on, debugging (inline)" read only
`Sonnet 5 · high`, losing the only documented escalation to Opus for a hard
inline debug. This is a doc-only wording fix (no behaviour, no test to write
per the fixer brief) — verified by re-reading the row against the resolution's
exact wording.

**Fix:** row now reads:
```
| Controller from "go" on, debugging (inline) | session | Sonnet 5 · high (Opus 5.5 · high for a genuinely hard debug) |
```

### Finding 3 — `statusline:12` docstring example missing `no workspace`

The two-line example in the module docstring showed the stage=plan flow line
without the `no workspace` segment, but the real line inserts it (branch/no
workspace comes right before the hint in `flow_line`'s bit order).

Verified against real output — built a throwaway repo with stage=plan, a
5-task plan recorded, no worktree, and an Opus model in the payload, and ran
the real `statusline` binary:
```
$ bash /tmp/.../scratchpad/verify_docstring.sh
flow  json-export · plan · 0/5 tasks · no workspace · go → /clear · /model sonnet · go
```
(colours stripped above; raw output had ANSI codes around each segment,
confirmed identical structure).

**Fix:** docstring example line changed from
`flow  json-export · plan · 0/5 tasks · go → /clear · /model sonnet · go` to
`flow  json-export · plan · 0/5 tasks · no workspace · go → /clear · /model sonnet · go`.

### Full suite

```
$ bash .claude/hooks/flow-guard-test 2>&1 | tail -1
138 passed, 0 failed
```
Output pristine, no stray warnings. (Baseline before this fix pass was
136 passed, 0 failed — the two new negative-case tests account for the +2.)

### Declined

None. All three findings applied as resolved by the controller.

### Files changed (this pass)
- `.claude/hooks/flow-context`
- `.claude/hooks/statusline`
- `.claude/hooks/flow-guard-test`
- `.claude/skills/development-workflow/SKILL.md`
