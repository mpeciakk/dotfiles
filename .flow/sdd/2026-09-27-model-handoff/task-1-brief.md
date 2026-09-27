## Global Constraints

- Hooks stay python3 standard library only; a hook must never raise (existing `try/except` wrappers stay).
- `bash .claude/hooks/flow-guard-test | tail -1` must end `N passed, 0 failed`; the baseline is `124 passed, 0 failed`.
- All paths below are relative to the repo root `/home/m/dotfiles`.

---

### Task 1: Status line model hint

**Files:**
- Modify: `.claude/hooks/statusline` (`flow_line`, `main`; new `model_hint`)
- Test: `.claude/hooks/flow-guard-test` (new section after `=== status line task counter ===`)

**Interfaces:**
- Produces: `model_hint(stage, payload) -> str | None` in `statusline`; `flow_line(state, payload)` (gains a second parameter).

- [ ] **Step 1: Write the failing test**

Insert before the `=== context reflects the real vocabulary ===` section:

```bash
echo "=== status line model hint ==="
sl_model() { # cwd model_id -> status line output
  python3 -c '
import json, sys
m = {"id": sys.argv[2], "display_name": "X"} if sys.argv[2] else {}
print(json.dumps({"workspace": {"current_dir": sys.argv[1], "project_dir": sys.argv[1]},
                  "model": m}))' "$1" "$2" | "$SL" | tail -1; }
HNT=$ROOT/hint; mkrepo "$HNT" >/dev/null || fixture_fail "hint repo"
"$STATE" --cwd "$HNT" init hinting >/dev/null
# stage=implement is refused without a recorded plan and workspace.
"$STATE" --cwd "$HNT" set plan="$HNT/p.md" worktree="$HNT" >/dev/null || fixture_fail "hint run fields"
hint_case() { # stage model_id expected_substring_or_NONE label
  "$STATE" --cwd "$HNT" set stage="$1" >/dev/null || fixture_fail "could not set stage=$1"
  local line; line=$(sl_model "$HNT" "$2")
  case "$line" in *hinting*) ;; *) fixture_fail "flow line missing for stage=$1: $line";; esac
  if [ "$3" = NONE ]; then
    case "$line" in *"/model"*) report no "$4" "$line";; *) report ok "$4";; esac
  else
    case "$line" in *"$3"*) report ok "$4";; *) report no "$4" "$line";; esac
  fi
}
hint_case design claude-sonnet-5 "⚠ /model opus" "design on Sonnet: asks for Opus"
hint_case design "claude-opus-5-5[1m]" NONE "design on Opus: no hint"
hint_case plan "claude-opus-5-5[1m]" "go → /clear · /model sonnet · go" "plan on Opus: shows the handoff"
hint_case plan claude-sonnet-5 NONE "plan on Sonnet: no hint"
hint_case implement claude-opus-5-5 "⚠ /clear · /model sonnet" "implement on Opus: asks for Sonnet"
hint_case isolate claude-opus-5-5 "⚠ /clear · /model sonnet" "isolate on Opus: asks for Sonnet"
hint_case finish claude-opus-5-5 "⚠ /clear · /model sonnet" "finish on Opus: asks for Sonnet"
hint_case implement claude-sonnet-5 NONE "implement on Sonnet: no hint"
hint_case inline claude-opus-5-5 NONE "inline: no hint"
hint_case design "" NONE "no model in payload: no hint"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash .claude/hooks/flow-guard-test | grep -E 'FAIL|passed'`
Expected: FAIL on the four "asks for"/"shows the handoff" cases (the line lacks the hint); the NONE cases pass; no `FIXTURE FAILED`.

- [ ] **Step 3: Implement**

Add to `statusline` and append the hint as the last element of `bits` in `flow_line`. `flow_line` takes `payload` as a second argument; `main` passes it. This mapping is the decision (D2), so it goes in as given:

```python
OPUS_STAGES = {"design"}
SONNET_STAGES = {"isolate", "implement", "finish"}


def model_hint(stage, payload):
    """What to switch to, if this stage wants a different model (design D2)."""
    model = (payload.get("model") or {}).get("id") or ""
    if not model:
        return None
    opus = "opus" in model.lower()
    if stage in OPUS_STAGES and not opus:
        return f"{YELLOW}⚠ /model opus{RESET}"
    if stage == "plan" and opus:
        return f"{CYAN}go → /clear · /model sonnet · go{RESET}"
    if stage in SONNET_STAGES and opus:
        return f"{YELLOW}⚠ /clear · /model sonnet{RESET}"
    return None
```

Also update the module docstring's example so the flow row shows a hint, e.g.
`flow  json-export · plan · 0/5 tasks · go → /clear · /model sonnet · go`.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash .claude/hooks/flow-guard-test | tail -1`
Expected: `134 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add .claude/hooks/statusline .claude/hooks/flow-guard-test
git commit -m "statusline: hint the model switch the run's stage wants"
```
