## Global Constraints

- Labels are exactly `pc` and `laptop`. `host-pc` → `pc`, `host-mac` → `laptop`; any other `host-<name>` falls back to `<name>`.
- Host identity comes from `<repo>/.dotter/local.toml` only. Never `hostname`, `/etc/hostname`, `uname -n` or `hostnamectl` — both machines answer `ciek`.
- Unknown host is reported as `unknown (<reason>)`, never guessed and never silent.
- No state file and no transcript scanning. The line is emitted on every matching event.
- Stdlib only. The hooks in this directory take no third-party dependency.
- Hook scripts carry no file extension (`flow-context`, `flow-state`), are executable, and exit 0 on malformed input rather than raising.

---

### Task 2: Wire it into `settings.json`

**Files:**
- Modify: `.claude/settings.json` (the `UserPromptSubmit` entry added on 2026-09-21, and the `SubagentStart` entry with matcher `*`)
- Test: `.claude/hooks/prompt-context-test` (append a wiring section)

**Interfaces:**
- Consumes: the executable at `.claude/hooks/prompt-context` from Task 1, referenced from settings as `~/.claude/hooks/prompt-context`.
- Produces: nothing later tasks consume.

- [ ] **Step 1: Write the failing test**

Append to `.claude/hooks/prompt-context-test`, immediately **before** the final
`printf '\n%d passed, %d failed\n'` line:

```bash
echo "=== the hook is wired into settings.json ==="
wired() { # event matcher_substring command_substring
  python3 -c '
import json, sys
cfg = json.load(open(sys.argv[1]))
event, matcher, command = sys.argv[2], sys.argv[3], sys.argv[4]
for entry in cfg.get("hooks", {}).get(event, []):
    if matcher and matcher not in (entry.get("matcher") or ""): continue
    for hook in entry.get("hooks", []):
        if command in (hook.get("command") or ""): sys.exit(0)
sys.exit(1)' "$SETTINGS" "$1" "$2" "$3"
}

wired UserPromptSubmit "" prompt-context \
  && report ok "UserPromptSubmit runs prompt-context" \
  || report no "UserPromptSubmit does not run prompt-context"
wired SubagentStart "" prompt-context \
  && report ok "SubagentStart runs prompt-context" \
  || report no "SubagentStart does not run prompt-context"
wired SubagentStart "" flow-context \
  && report ok "SubagentStart still runs flow-context" \
  || report no "flow-context was dropped from SubagentStart"
wired SubagentStart "" cbm-subagent-reminder \
  && report ok "SubagentStart still runs cbm-subagent-reminder" \
  || report no "cbm-subagent-reminder was dropped from SubagentStart"
grep -q timestamp-injector "$SETTINGS" \
  && report no "settings.json still references the old hook name" \
  || report ok "no reference to the old hook name remains"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.claude/hooks/prompt-context-test`

Expected: FAIL on `UserPromptSubmit runs prompt-context`, `SubagentStart runs
prompt-context` and `no reference to the old hook name remains` — settings.json
still names `timestamp-injector` and `SubagentStart` has no entry for this hook.
The two assertions about `flow-context` and `cbm-subagent-reminder` pass
already; they are there to catch a later edit that overwrites the array instead
of appending to it. The Task 1 assertions all still pass.

- [ ] **Step 3: Point `UserPromptSubmit` at the new name**

In `.claude/settings.json`, inside the `UserPromptSubmit` array, change the
command:

```json
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/prompt-context",
            "timeout": 5
          }
        ]
      }
    ],
```

- [ ] **Step 4: Add it to `SubagentStart`**

In the `SubagentStart` entry with `"matcher": "*"`, append a third hook after
`cbm-subagent-reminder` — do not touch the two that are already there:

```json
    "SubagentStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/flow-context",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/cbm-subagent-reminder"
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/prompt-context",
            "timeout": 5
          }
        ]
      }
    ],
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `.claude/hooks/prompt-context-test`

Expected: PASS — `18 passed, 0 failed`, exit 0.

- [ ] **Step 6: Verify settings.json is still valid JSON**

Run:

```bash
python3 -c "import json; json.load(open('.claude/settings.json')); print('json ok')"
```

Expected: `json ok`

- [ ] **Step 7: Commit**

```bash
git add .claude/settings.json .claude/hooks/prompt-context-test
git commit -m "feat: run prompt-context on every prompt and subagent start"
```

**Expect hook errors for the rest of this run, and do not debug them.** This
worktree's `.claude/settings.json` is loaded as project settings and now names
`~/.claude/hooks/prompt-context`, which does not exist under `~/.claude/hooks`
until the branch merges and `dotter deploy` runs. Every prompt and every
subagent start will log a hook-not-found error until then. It is cosmetic, it is
expected, and it is not a regression to investigate.

---
