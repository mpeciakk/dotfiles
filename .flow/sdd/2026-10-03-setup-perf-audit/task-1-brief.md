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

### Task 1: settings.json — the config package, verified against the real CLI

**Files:**
- Modify: `.claude/settings.json`
- Delete: `.claude/hooks/cbm-code-discovery-gate`, `.claude/hooks/cbm-subagent-reminder`
- Test: `.claude/hooks/flow-guard-test` (section `=== settings.json wiring ===`), `.claude/hooks/prompt-context-test` (wiring block at its end)

**Interfaces:**
- Consumes: nothing.
- Produces: the settings every later task assumes; `PreToolUse` Bash entry carries `"if": "Bash(*worktree add*)"`.

- [ ] **Step 1: Write the failing tests**

Only structural wiring goes into the suite — values such as `model` or `modelSettings` are rewritten by the CLI itself (`/model`, `/effort`, the first Workflow approval) and would make the suite flap; they are checked once in Step 5. In `flow-guard-test`, at the end of the `=== settings.json wiring ===` section (after the `statusLine points at the flow status line` check), append:

```bash
setting 'any(h.get("if") == "Bash(*worktree add*)" for e in cfg["hooks"]["PreToolUse"] if e.get("matcher") == "Bash" for h in e["hooks"])' \
  && report ok "flow-guard on Bash only spawns for worktree add" || report no "Bash flow-guard has no if filter"
setting 'not any("Grep" in (e.get("matcher") or "") for e in cfg["hooks"]["PreToolUse"])' \
  && report ok "dead Grep|Glob augmenter removed" || report no "Grep|Glob augmenter still wired"
[ ! -e "$HERE/cbm-code-discovery-gate" ] && [ ! -e "$HERE/cbm-subagent-reminder" ] \
  && report ok "removed cbm hook files are gone" || report no "cbm hook files still present"
```

In `prompt-context-test`, replace the `wired SubagentStart "" cbm-subagent-reminder` check (3 lines) with:

```bash
wired SubagentStart "" cbm-subagent-reminder \
  && report no "cbm-subagent-reminder is still wired (removed by D13)" \
  || report ok "cbm-subagent-reminder is no longer wired"
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.claude/hooks/flow-guard-test | grep -E '^FAIL'; .claude/hooks/prompt-context-test | grep -E '^FAIL'`
Expected: `FAIL  Bash flow-guard has no if filter`, `FAIL  Grep|Glob augmenter still wired`, `FAIL  cbm hook files still present` and `FAIL  cbm-subagent-reminder is still wired (removed by D13)` — assertion failures, not a harness crash.

- [ ] **Step 3: Implement**

Edit `.claude/settings.json`. The worktree is cut from HEAD, which has no `model`, `agentPushNotifEnabled` or `skipWorkflowUsageWarning` keys (those exist only as uncommitted edits in the laptop main checkout) — so below "add" means add:
- `env`: add `"CLAUDE_CODE_FORK_SUBAGENT": "0"` and `"CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS": "1"`.
- `permissions`: add `"deny": ["ReportFindings", "ShareOnboardingGuide"]` after `allow`.
- Add `"model": "sonnet"` right after `permissions`.
- `hooks.PreToolUse`: delete the `Grep|Glob` entry; on the `Bash` entry's flow-guard handler add `"if": "Bash(*worktree add*)"`. `hooks.SubagentStart`: delete the `cbm-subagent-reminder` handler (keep `flow-context` and `prompt-context`).
- `enabledPlugins`: `"claude-code-wakatime@wakatime": false`, `"cloudflare@cloudflare": false`, add `"cowork-plugin-management@synced": false`; others unchanged.
- Replace `"effortLevel"` and `"modelSettings"` with `"modelSettings": {"claude-sonnet-5-5": {"effortLevel": "high"}, "claude-opus-5-5": {"effortLevel": "high"}}`.
- Add `"agentPushNotifEnabled": false` (an explicit false blocks server-side hydration); do not add `skipWorkflowUsageWarning`.
- Add, before `"tui"`:

```json
  "skillOverrides": {
    "anthropic-skills:cloudflare": "off",
    "anthropic-skills:cloudflare-email-service": "off",
    "anthropic-skills:cloudflare-one": "off",
    "anthropic-skills:workers-best-practices": "off",
    "anthropic-skills:wrangler": "off",
    "anthropic-skills:google-workspace": "off",
    "anthropic-skills:import-memory": "off",
    "anthropic-skills:the-humanizer": "user-invocable-only",
    "anthropic-skills:docs": "name-only",
    "anthropic-skills:pdf": "name-only",
    "anthropic-skills:docx": "name-only",
    "anthropic-skills:pptx": "name-only",
    "anthropic-skills:xlsx": "name-only",
    "dataviz": "name-only",
    "update-config": "name-only",
    "artifact-capabilities": "name-only",
    "artifact-diagramming": "name-only",
    "artifact-design": "name-only",
    "schedule": "name-only",
    "loop": "name-only",
    "code-review": "user-invocable-only",
    "simplify": "user-invocable-only",
    "security-review": "user-invocable-only",
    "keybindings-help": "user-invocable-only",
    "fewer-permission-prompts": "user-invocable-only",
    "init": "user-invocable-only"
  },
  "deniedMcpServers": [
    {"serverName": "claude.ai Claude Docs"},
    {"serverName": "claude.ai Canva"},
    {"serverName": "claude.ai Microsoft 365"}
  ],
  "enableArtifact": false,
  "autoCompactWindow": 500000,
  "cleanupPeriodDays": 90,
  "promptSuggestionEnabled": false,
```

Then `git rm .claude/hooks/cbm-code-discovery-gate .claude/hooks/cbm-subagent-reminder`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m json.tool .claude/settings.json >/dev/null && .claude/hooks/flow-guard-test | tail -1 && .claude/hooks/prompt-context-test | tail -1`
Expected: both suites print `N passed, 0 failed`.

- [ ] **Step 5: Verify values and knobs against the real CLI (external dependency)**

Several keys are undocumented or documented as enterprise-only (`deniedMcpServers`), and the `if` filter gates the one-workspace guard — check them deterministically, not by asking a model. Use the literal worktree path printed by `~/.claude/hooks/flow-state get worktree` (written `<WT>` below).

1. Values: `python3 -c 'import json; c=json.load(open("<WT>/.claude/settings.json")); print(c["model"], c["modelSettings"], c["env"], c["autoCompactWindow"], c["cleanupPeriodDays"], c["enableArtifact"], c["promptSuggestionEnabled"], c["agentPushNotifEnabled"], "skipWorkflowUsageWarning" in c, c["permissions"]["deny"], c["deniedMcpServers"], c["enabledPlugins"], len(c["skillOverrides"]))'` — expect `sonnet`, both 5.5 keys at high, the two new env vars, `500000 90 False False False False`, the deny list, three denied servers, cloudflare/wakatime/cowork `false`, `26`.
2. Init event: from `/tmp`, `claude -p --model haiku --settings <WT>/.claude/settings.json --output-format stream-json --verbose 'reply ok' > /tmp/sp-after.jsonl`, and the same without `--settings` into `/tmp/sp-before.jsonl`. From each file's `{"type":"system","subtype":"init"}` event list `tools`, `mcp_servers`, `plugins`, `skills`. Expected after: no `Artifact`, `ReportFindings`, `ShareOnboardingGuide`; no `claude.ai Claude Docs`/`Canva`/`Microsoft 365` server; ClickUp present; no cloudflare plugin, MCP server or skills; no wakatime or cowork plugin; `init`/`code-review` still user-invocable. The before file shows them.
3. Skill listing as the model sees it: in the transcript of the after-run (`~/.claude/projects/-tmp/<session>.jsonl`, newest file), the skill-listing attachment has no `anthropic-skills:cloudflare`, `wrangler`, `google-workspace`, `import-memory`; `dataviz` and `anthropic-skills:docx` appear without a description; `code-review`, `init`, `anthropic-skills:the-humanizer` are absent.
4. The `if` filter: in a scratch repo (`git init /tmp/if-check && git -C /tmp/if-check commit --allow-empty -m x`), run `claude -p --model haiku --settings <WT>/.claude/settings.json --debug 'run the shell command: ls'` and `… 'run the shell command: git -C /tmp/if-check worktree add /tmp/if-check-wt'`; the debug output shows the flow-guard hook skipped (`Skipping hook due to if condition`) for `ls` and executed for `git … worktree add`. Remove `/tmp/if-check*` afterwards.

Paste the relevant lines (names only, no env values) into the report. If a knob did not take effect, report DONE_WITH_CONCERNS naming the key — do not invent a substitute.

- [ ] **Step 6: Commit**

```bash
git add .claude/settings.json .claude/hooks/flow-guard-test .claude/hooks/prompt-context-test
git commit -m "settings: audit config package (D2-D9, D11, D13-D16)"
```

---
