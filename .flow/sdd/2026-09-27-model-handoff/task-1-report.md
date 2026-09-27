# Task 1 report: Status line model hint

## What was implemented

- `.claude/hooks/statusline`: added `OPUS_STAGES`/`SONNET_STAGES` constants and
  `model_hint(stage, payload)`, exactly as given in the brief. `flow_line` now
  takes `payload` as a second parameter, computes `hint = model_hint(stage, payload)`
  and appends it as the last element of `bits` when non-empty. `main` now calls
  `flow_line(run_state(cwd), payload)`. Updated the module docstring's example
  flow row to show a hint (`flow  json-export · plan · 0/5 tasks · go → /clear · /model sonnet · go`).
- `.claude/hooks/flow-guard-test`: inserted the `=== status line model hint ===`
  section verbatim from the brief, directly before `=== context reflects the
  real vocabulary ===`.

Both changes are verbatim from the brief (Step 3's code block and Step 1's
test block) — no deviation.

## TDD evidence

**RED** — `bash .claude/hooks/flow-guard-test | grep -E 'FAIL|passed'` (test
inserted, `statusline` not yet modified):

```
FAIL  design on Sonnet: asks for Opus
FAIL  plan on Opus: shows the handoff
FAIL  implement on Opus: asks for Sonnet
FAIL  isolate on Opus: asks for Sonnet
FAIL  finish on Opus: asks for Sonnet
129 passed, 5 failed
```

This matches the brief's expectation exactly: the four "asks for"/"shows the
handoff" cases fail (the hint doesn't exist yet — `flow_line` ignores model
entirely), the NONE cases pass (there's no `/model` text to find because there
is no hint at all yet), and there is no `FIXTURE FAILED` line, confirming the
test harness itself (state fixture, stage transitions) is sound before the
implementation exists.

**GREEN** — `bash .claude/hooks/flow-guard-test | tail -1` (after implementing
`model_hint` and wiring it into `flow_line`/`main`):

```
134 passed, 0 failed
```

Also confirmed no `FAIL`/`FIXTURE FAILED` lines anywhere in the full run.

## Files changed

- `.claude/hooks/statusline`
- `.claude/hooks/flow-guard-test`

## Self-review

- Diff reviewed with `git diff` before committing: every changed line traces
  directly to the brief (new constants, new function, `flow_line` signature
  change, `main` call-site update, docstring example, new test section). No
  unrelated formatting or refactor.
- Full suite re-run after implementation: `134 passed, 0 failed`, matching the
  brief's expected count and the baseline delta (124 → 134, i.e. the 10 new
  `hint_case` assertions).
- Checked `flow-state` supports `set stage=...` transitions used by the test
  fixture (`design` → `plan` → `implement`/`isolate`/`finish`/`inline`) and
  that `set plan=... worktree=...` satisfies the `stage=implement` guard in
  `check_order` — no fixture hacks were needed.

## Concerns

None. Output is pristine (no stray warnings), scope matches the brief
exactly, and the implementation is copied verbatim from the brief's D2
decision code rather than reinterpreted.
