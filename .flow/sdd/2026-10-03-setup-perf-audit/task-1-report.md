# Task 1 report: settings.json config package

Status: DONE_WITH_CONCERNS. Commit: `b1604f1 settings: audit config package (D2-D9, D11, D13-D16)`.
Machine: laptop. Retry of a BLOCKED dispatch; Step 1 (RED tests) was already applied and uncommitted, edits through Edit were accepted this time (no denial).

## What was implemented
- `.claude/settings.json`: all Step 3 changes (env x2, `permissions.deny`, `model`, Grep|Glob entry removed, `if` filter on the Bash flow-guard handler, `cbm-subagent-reminder` handler removed, plugin flags, `modelSettings` replaced / `effortLevel` removed, `agentPushNotifEnabled: false`, `skillOverrides` (26 keys), `deniedMcpServers`, `enableArtifact`, `autoCompactWindow`, `cleanupPeriodDays`, `promptSuggestionEnabled`). `skipWorkflowUsageWarning` not added. Key order kept for surviving keys; the new `skillOverrides` block sits right before `tui`.
- `git rm` of `cbm-code-discovery-gate` and `cbm-subagent-reminder`.
- Tests (Step 1, from the previous attempt): 3 new checks in `flow-guard-test`, `wired SubagentStart ... cbm-subagent-reminder` inverted in `prompt-context-test`.

## TDD evidence
RED (previous attempt, confirmed by the dispatcher, state verified at start of this run: settings.json at HEAD, cbm hooks present): the 4 expected failures
`FAIL  Bash flow-guard has no if filter`, `FAIL  Grep|Glob augmenter still wired`, `FAIL  cbm hook files still present`, `FAIL  cbm-subagent-reminder is still wired (removed by D13)`.
GREEN, after the edits:
```
python3 -m json.tool .claude/settings.json  -> JSON_OK
.claude/hooks/flow-guard-test      -> 141 passed, 0 failed   (baseline 138 + 3 new)
.claude/hooks/prompt-context-test  -> 17 passed, 0 failed
```

## Step 5 verification against the real CLI (claude 2.1.284)
1. Values: `model=sonnet`; `modelSettings` = `claude-sonnet-5-5` high, `claude-opus-5-5` high; both new env vars present with the brief's values (checked as booleans); `autoCompactWindow 500000`, `cleanupPeriodDays 90`, `enableArtifact False`, `promptSuggestionEnabled False`, `agentPushNotifEnabled False`, `skipWorkflowUsageWarning` absent; deny = `['ReportFindings','ShareOnboardingGuide']`; 3 denied servers; wakatime/cloudflare/cowork `False`, context7 `True`; `len(skillOverrides)==26`. All as expected.
2. Init event (`claude -p --model haiku`, with vs without `--settings`):
   - before: tools 106 incl. `ReportFindings`, `ShareOnboardingGuide`; MCP: context7, 5 cloudflare servers, codebase-memory-mcp, claude.ai Claude Docs, Microsoft 365, ClickUp, Canva; plugins claude-code-wakatime, context7, cloudflare, cowork-plugin-management, agents-md, telemetry; 62 skills.
   - after: tools 33, none of `ReportFindings`/`ShareOnboardingGuide`; MCP: context7, codebase-memory-mcp, claude.ai ClickUp (ClickUp present); plugins context7, agents-md, telemetry; 40 skills, no cloudflare:*, cowork-plugin-management:* or anthropic-skills:{cloudflare*,wrangler,workers-best-practices,google-workspace,import-memory}. Slash commands still include `init`, `code-review`, `anthropic-skills:the-humanizer` (user-invocable).
   - stderr of the after-run prints `Warning: claude.ai MCP servers blocked by enterprise policy: claude.ai Claude Docs, claude.ai Microsoft 365, claude.ai Canva`, so `deniedMcpServers` takes effect (cosmetic warning on every launch).
3. Skill listing in the transcript (`skill_listing` attachment): 61 lines before, 30 after. After: `dataviz` and `anthropic-skills:docx` listed name-only (no description); `code-review`, `simplify`, `init`, `anthropic-skills:the-humanizer` and all cloudflare/wrangler/google-workspace/import-memory entries absent. Before: all present.
4. `if` filter: with `--debug-file`, `ls` run logged `Skipping hook due to if condition "Bash(*worktree add*)" not matching`; the `git -C /tmp/if-check worktree add /tmp/if-check-wt` run logged no skip. With `--include-hook-events` the count of `PreToolUse:Bash` hook_started events was 1 for `ls` and 2 for `worktree add`. The baseline 1 is the unfiltered live `~/.claude/settings.json` handler, which `--settings` merges with (the live file is still the old one until merge + deploy). Scratch repos `/tmp/if-check*` removed; the `/tmp/sp-*.jsonl` files remain in /tmp (no secrets, init events only).

## Files changed
`.claude/settings.json`, `.claude/hooks/flow-guard-test`, `.claude/hooks/prompt-context-test`, deleted `.claude/hooks/cbm-code-discovery-gate`, `.claude/hooks/cbm-subagent-reminder`. Throwaway scripts used for parsing were deleted.

## Self-review
- Every settings.json line traces to a Step 3 bullet. Valid JSON, 2-space indent; the `deniedMcpServers` objects stay inline as written in the brief. `deny` was placed between `allow` and `defaultMode`.
- No `config/`, `hosts/`, `mimeapps.list` touched. No secrets or env values in the report.

## Concerns
1. `enableArtifact: false` could not be verified: `Artifact` is not in the init `tools` list even without `--settings` in `-p` mode, so before/after cannot differ there. The key is accepted without errors; effect is only observable in an interactive/SDK session.
2. The `if` filter evidence relies on the merge with the live settings for the baseline of 1 hook; after deploy the `ls` run should spawn 0 flow-guard processes.
3. The `modelSettings` replacement drops the previous `claude-fable-5-1` and `claude-sonnet-5` entries, as the brief specified.
4. `deniedMcpServers` prints a warning line on every CLI start (cosmetic).
