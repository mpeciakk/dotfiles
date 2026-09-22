## Global Constraints

- Labels are exactly `pc` and `laptop`. `host-pc` → `pc`, `host-mac` → `laptop`; any other `host-<name>` falls back to `<name>`.
- Host identity comes from `<repo>/.dotter/local.toml` only. Never `hostname`, `/etc/hostname`, `uname -n` or `hostnamectl` — both machines answer `ciek`.
- Unknown host is reported as `unknown (<reason>)`, never guessed and never silent.
- No state file and no transcript scanning. The line is emitted on every matching event.
- Stdlib only. The hooks in this directory take no third-party dependency.
- Hook scripts carry no file extension (`flow-context`, `flow-state`), are executable, and exit 0 on malformed input rather than raising.

---

### Task 1: `prompt-context` — the hook and its regression net

**Files:**
- Rename: `.claude/hooks/timestamp-injector` → `.claude/hooks/prompt-context` (via `git mv`)
- Modify: `.claude/hooks/prompt-context`
- Test: `.claude/hooks/prompt-context-test` (create)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: an executable at `.claude/hooks/prompt-context` that reads a hook payload on stdin and writes `{"hookSpecificOutput": {"hookEventName": <event>, "additionalContext": "[CTX] …"}}` to stdout. Task 2 wires this path into `settings.json`. The test file gains wiring assertions in Task 2.

- [ ] **Step 1: Rename the hook, so the script under test exists**

```bash
cd "$(git rev-parse --show-toplevel)"
git mv .claude/hooks/timestamp-injector .claude/hooks/prompt-context
git commit -m "refactor: rename timestamp-injector to prompt-context"
```

The rename comes first on purpose: the test in Step 2 must fail on its
assertion about the host, not on a missing file.

- [ ] **Step 2: Write the failing test**

Create `.claude/hooks/prompt-context-test`, `chmod +x` it:

```bash
#!/usr/bin/env bash
# Regression net for the prompt-context hook. Runs the real script against
# synthetic payloads inside throwaway checkouts, because the only thing that
# distinguishes the two machines is .dotter/local.toml and it is git-ignored.
#
# Fixtures are verified before any assertion runs: a suite that cannot tell
# "the hook is broken" from "my own tooling is broken" is worse than none.
#
# Usage: prompt-context-test        (exit 0 = all green)
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
HOOK=$HERE/prompt-context
SETTINGS=$(cd "$HERE/.." && pwd)/settings.json
ROOT=${TMPDIR:-/tmp}/prompt-context-test
pass=0; fail=0

command -v python3 >/dev/null || { echo "MISSING DEPENDENCY: python3" >&2; exit 1; }
# Not python3 alone: on 3.10 `import tomllib` fails and every host assertion
# fails identically to a real regression.
python3 -c 'import tomllib' 2>/dev/null \
  || { echo "MISSING DEPENDENCY: python3 >= 3.11 (tomllib)" >&2; exit 1; }
[ -x "$HOOK" ] || { echo "FIXTURE FAILED: $HOOK is not executable" >&2; exit 1; }

report() { if [ "$1" = ok ]; then printf 'PASS  %-58s %s\n' "$2" "${3:-}"; pass=$((pass+1))
  else printf 'FAIL  %-58s %s\n' "$2" "${3:-}"; fail=$((fail+1)); fi; }

rm -rf "$ROOT"; mkdir -p "$ROOT"

# A throwaway checkout: <name>/.claude/hooks/prompt-context beside a
# <name>/.dotter/local.toml we control. The hook resolves its repo from its own
# realpath, so the copy reads the fake local.toml and nothing else.
fake() { # name packages_toml_line_or_empty
  local dir=$ROOT/$1
  mkdir -p "$dir/.claude/hooks" "$dir/.dotter"
  cp "$HOOK" "$dir/.claude/hooks/prompt-context"
  if [ -n "${2:-}" ]; then printf '%s\n' "$2" > "$dir/.dotter/local.toml"; fi
  printf '%s' "$dir/.claude/hooks/prompt-context"
}

context_of() { # script event
  printf '{"hook_event_name":"%s","prompt":"x"}' "$2" | "$1" | python3 -c '
import json, sys
try: print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])
except Exception: print("")'
}

event_of() { # script event
  printf '{"hook_event_name":"%s","prompt":"x"}' "$2" | "$1" | python3 -c '
import json, sys
try: print(json.load(sys.stdin)["hookSpecificOutput"]["hookEventName"])
except Exception: print("")'
}

echo "=== the host label comes from dotter, not from the hostname ==="
PC=$(fake pc 'packages = ["default", "host-pc"]')
c=$(context_of "$PC" UserPromptSubmit)
case "$c" in "[CTX] pc · "*) report ok "host-pc is reported as pc";; *) report no "host-pc not reported as pc" "$c";; esac

MAC=$(fake mac 'packages = ["default", "host-mac"]')
c=$(context_of "$MAC" UserPromptSubmit)
case "$c" in "[CTX] laptop · "*) report ok "host-mac is reported as laptop";; *) report no "host-mac not reported as laptop" "$c";; esac

OTHER=$(fake other 'packages = ["default", "host-sirius"]')
c=$(context_of "$OTHER" UserPromptSubmit)
case "$c" in "[CTX] sirius · "*) report ok "an unmapped host-* falls back to its own name";; *) report no "host-sirius not reported as sirius" "$c";; esac

echo "=== an unknown host says so, with the reason ==="
NOHOST=$(fake nohost 'packages = ["default"]')
c=$(context_of "$NOHOST" UserPromptSubmit)
case "$c" in "[CTX] unknown ("*"no host-* package"*) report ok "no host package names the reason";; *) report no "no host package not explained" "$c";; esac

# The three unknown reasons all embed the path, so each pattern below matches
# the part that only its own branch produces — otherwise a hook that reported
# "no local.toml" for a corrupt file would pass.
NOFILE=$(fake nofile '')
c=$(context_of "$NOFILE" UserPromptSubmit)
case "$c" in "[CTX] unknown (no "*"local.toml)") report ok "a missing local.toml names the reason";; *) report no "missing local.toml not explained" "$c";; esac

BROKEN=$(fake broken 'packages = [oops')
c=$(context_of "$BROKEN" UserPromptSubmit)
case "$c" in "[CTX] unknown ("*"local.toml: "*) report ok "an unparseable local.toml reports the decode error";; *) report no "unparseable local.toml not handled" "$c";; esac

echo "=== the envelope names the event it was called for ==="
e=$(event_of "$PC" UserPromptSubmit)
[ "$e" = UserPromptSubmit ] && report ok "UserPromptSubmit is echoed back" || report no "wrong hookEventName" "$e"
e=$(event_of "$PC" SubagentStart)
[ "$e" = SubagentStart ] && report ok "SubagentStart is echoed back" || report no "wrong hookEventName" "$e"

echo "=== a subagent gets told why the line exists, a prompt does not ==="
c=$(context_of "$PC" SubagentStart)
case "$c" in *"hostname \`ciek\`"*) report ok "SubagentStart carries the hostname caveat";; *) report no "SubagentStart missing caveat" "$c";; esac
c=$(context_of "$PC" UserPromptSubmit)
case "$c" in *ciek*) report no "UserPromptSubmit should stay short" "$c";; *) report ok "UserPromptSubmit stays one short line";; esac
# "this line is the only thing naming the machine" is false when the line names
# no machine — a subagent told that goes and guesses from the hostname.
c=$(context_of "$NOHOST" SubagentStart)
case "$c" in *"only thing"*) report no "an unknown host must not claim to name the machine" "$c";; *) report ok "an unknown host drops the caveat";; esac

echo "=== bad input is survivable ==="
out=$(printf 'not json' | "$PC"; echo "rc=$?")
case "$out" in "rc=0") report ok "malformed stdin exits 0 and emits nothing";; *) report no "malformed stdin mishandled" "$out";; esac
out=$(printf '' | "$PC"; echo "rc=$?")
case "$out" in "rc=0") report ok "empty stdin exits 0 and emits nothing";; *) report no "empty stdin mishandled" "$out";; esac

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `.claude/hooks/prompt-context-test`

Expected: **8 failed, 4 passed**, exit 1. The failures are the six host
assertions (the first reads `FAIL  host-pc is reported as pc` with the actual
line `[TIMESTAMP] User message received: …`), plus `SubagentStart is echoed
back` and `SubagentStart carries the hostname caveat` — the current script
hardcodes `"hookEventName": "UserPromptSubmit"` and has no notion of a subagent.
The four that pass are `UserPromptSubmit is echoed back`, `UserPromptSubmit
stays one short line` and the two stdin assertions.

It must NOT fail with "No such file or directory" or "is not executable": that
would mean the rename in Step 1 did not happen and the run proves nothing.

- [ ] **Step 4: Write the implementation**

Replace the whole contents of `.claude/hooks/prompt-context` with:

```python
#!/usr/bin/env python3
"""UserPromptSubmit / SubagentStart hook: which machine, and when.

Two machines run this configuration and both report hostname `ciek`, so nothing
in a session names the one it is on — and transcripts move between them, since
~/.claude/projects is mutagen-synced. dotter's per-host package is the only
discriminator: .dotter/local.toml is git-ignored and selects hosts/<name>/.

Between turns there is also no clock; a 30-second gap and a 30-hour gap look the
same. Both facts ride on one line, on every turn, because a mark that appears
only at the switch point leaves every turn around it unattributed.

The timestamp half is vendored from
https://github.com/VoxCore84/claude-code-timestamp-hook (MIT).
"""

import json
import os
import sys
import tomllib
from datetime import datetime

# This file is reached through a dotter symlink in ~/.claude/hooks; realpath
# lands on <repo>/.claude/hooks/prompt-context, three levels under the checkout
# that owns local.toml. Resolving it this way keeps the repo's path out of the
# code and lets the test run a copy inside a throwaway tree.
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
LOCAL_TOML = os.path.join(REPO, ".dotter", "local.toml")

LABELS = {"host-pc": "pc", "host-mac": "laptop"}

SUBAGENT_NOTE = (
    " — machine identity: both machines report hostname `ciek`, so this line is "
    "the only thing naming the one you are on."
)


def host():
    """The machine's label, or `unknown (<reason>)`. Never a guess, never raises.

    A crash here would take the timestamp down with it, so the catch-all stays:
    `packages = [1]` is valid TOML and would otherwise raise AttributeError past
    every specific handler below.
    """
    try:
        with open(LOCAL_TOML, "rb") as handle:
            packages = tomllib.load(handle).get("packages", [])
        for package in packages:
            if package.startswith("host-"):
                return LABELS.get(package, package[len("host-"):])
    except FileNotFoundError:
        return f"unknown (no {LOCAL_TOML})"
    except Exception as exc:
        return f"unknown ({LOCAL_TOML}: {exc})"
    return f"unknown ({LOCAL_TOML} selects no host-* package)"


def main():
    try:
        event = json.load(sys.stdin).get("hook_event_name") or "UserPromptSubmit"
    except Exception:
        sys.exit(0)

    machine = host()
    line = f"[CTX] {machine} · {datetime.now():%A %Y-%m-%d %H:%M:%S}"
    if event == "SubagentStart" and not machine.startswith("unknown"):
        line += SUBAGENT_NOTE

    json.dump({"hookSpecificOutput": {
        "hookEventName": event,
        "additionalContext": line,
    }}, sys.stdout)


if __name__ == "__main__":
    main()
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `.claude/hooks/prompt-context-test`

Expected: PASS — `13 passed, 0 failed`, exit 0.

- [ ] **Step 6: Verify against this machine's real `local.toml`, not a fixture**

Every host assertion above runs against synthetic TOML written by the plan
author. If the real file's shape differed, all of them pass and the hook still
reports `unknown` on both machines forever. This step is the only one that
touches the real file, so it must be able to fail.

`.dotter/local.toml` is git-ignored, so it does not exist in this worktree and
cannot be committed from it. Copy the machine's own:

```bash
cp /home/m/dotfiles/.dotter/local.toml .dotter/local.toml
printf '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' | .claude/hooks/prompt-context
git status --short .dotter/
```

Expected: the hook's output starts with `[CTX] pc · `, and `git status` prints
nothing for `.dotter/` (the copy is ignored). **Any other host label, or
`unknown (…)`, fails this task** — report it as BLOCKED with the real file's
contents rather than adjusting the fixtures to match.

- [ ] **Step 7: Commit**

```bash
git add .claude/hooks/prompt-context .claude/hooks/prompt-context-test
git commit -m "feat: name the machine in every prompt and subagent context"
```

---
