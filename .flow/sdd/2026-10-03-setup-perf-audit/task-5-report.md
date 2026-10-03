# Task 5 report: status line limits and absolute context; cheaper hook starts

Commit: dd78bcc "statusline: limits and absolute context, no dollars; lazy traceback (D13, D22)"

## Implemented
- `statusline` `context_segment`: int `total_input_tokens` renders `ctx <colour>NNNK` (green <150000, yellow <300000, red otherwise); falls back to the percentage rendering.
- `statusline` `cost_segment`: dollar part removed, lines added/removed kept.
- `statusline` new `limits_segment(payload)`: `5h` then `7d`, colour green <70 / yellow <90 / red; 5h gets `→HH:MM` (local time from `resets_at`); None when neither present. Wired into `main` after `context_segment`.
- `statusline` `git()`: `env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"}`.
- `statusline` imports `datetime` (needed for `resets_at`); docstring example line updated (it still showed `$0.42`).
- `prompt-context`: `import traceback` moved into the `except` block.

## TDD evidence
RED (test block appended first, code untouched):
`.claude/hooks/flow-guard-test | grep -E '^FAIL'` -> 8 FAIL, `166 passed, 8 failed`:
dollars still shown, absolute context, context colour (green), context yellow, 5h limit, 7d limit, GIT_OPTIONAL_LOCKS, prompt-context eager traceback import. The three fallback checks (lines kept, no limits without rate_limits, percent fallback) passed already, as the brief predicted. Failures were for the right reason (output showed `ctx 40%  $3.21`, no limit segments).

GREEN after implementation:
- `.claude/hooks/flow-guard-test | tail -1` -> `174 passed, 0 failed`
- `.claude/hooks/prompt-context-test | tail -1` -> `17 passed, 0 failed`

## Files changed
`.claude/hooks/statusline`, `.claude/hooks/prompt-context`, `.claude/hooks/flow-guard-test`

## Self-review
Matches the brief's Interfaces and Step 3. Only change beyond the listed bullets: the `datetime` import and the docstring example, both direct consequences.

## Concerns
- `limits_segment` does not guard `datetime.fromtimestamp` against an absurd `resets_at` (OverflowError/ValueError); `main`'s outer handler would then print an empty line. Claude Code sends epoch seconds, so left as the brief specifies.
- `total_input_tokens` of `bool` type counts as int in Python; irrelevant for the real payload.
