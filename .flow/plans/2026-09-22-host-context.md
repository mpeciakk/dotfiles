# Host Identity in Session Context — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every user turn and every dispatched subagent carries the name of the machine the session is running on, so a transcript that moves between the two hosts stays attributable.

**Architecture:** The existing `timestamp-injector` hook is renamed to `prompt-context` and grows a host lookup. It reads dotter's per-host package from `<repo>/.dotter/local.toml` — the only thing that differs between the machines, since both report hostname `ciek` — and emits one line as `hookSpecificOutput.additionalContext` on `UserPromptSubmit` and on `SubagentStart`. No state file, no change detection: the mark is on every turn.

**Tech Stack:** Python 3.14 stdlib (`tomllib`, `json`, `datetime`), bash test harness in the style of `.claude/hooks/flow-guard-test`, dotter for deployment.

**Spec:** none — this repo has a README.md and no living `spec.md`. Writing one is its own job (`writing-specs`), out of scope here.

**Design record:** `/home/m/dotfiles/.flow/specs/2026-09-22-host-context-design.md`

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

NOFILE=$(fake nofile '')
c=$(context_of "$NOFILE" UserPromptSubmit)
case "$c" in "[CTX] unknown ("*local.toml*) report ok "a missing local.toml names the reason";; *) report no "missing local.toml not explained" "$c";; esac

BROKEN=$(fake broken 'packages = [oops')
c=$(context_of "$BROKEN" UserPromptSubmit)
case "$c" in "[CTX] unknown ("*) report ok "an unparseable local.toml reports unknown";; *) report no "unparseable local.toml not handled" "$c";; esac

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

Expected: FAIL on the host assertions — the first is
`FAIL  host-pc is reported as pc` with the actual line
`[TIMESTAMP] User message received: …`, because the script still emits the old
text and knows nothing about hosts. It must NOT fail with "No such file or
directory" or "is not executable": that would mean the rename in Step 1 did not
happen and the run proves nothing. The `hookEventName` and malformed-input
assertions pass already.

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
    """The machine's label, or `unknown (<reason>)`. Never a guess."""
    try:
        with open(LOCAL_TOML, "rb") as handle:
            packages = tomllib.load(handle).get("packages", [])
    except FileNotFoundError:
        return f"unknown (no {LOCAL_TOML})"
    except (tomllib.TOMLDecodeError, OSError) as exc:
        return f"unknown ({LOCAL_TOML}: {exc})"

    for package in packages:
        if package.startswith("host-"):
            return LABELS.get(package, package[len("host-"):])
    return f"unknown ({LOCAL_TOML} selects no host-* package)"


def main():
    try:
        event = json.load(sys.stdin).get("hook_event_name") or "UserPromptSubmit"
    except Exception:
        sys.exit(0)

    line = f"[CTX] {host()} · {datetime.now():%A %Y-%m-%d %H:%M:%S}"
    if event == "SubagentStart":
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

Expected: PASS — `12 passed, 0 failed`, exit 0.

- [ ] **Step 6: Verify the real machine reports itself correctly**

Run:

```bash
printf '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' | .claude/hooks/prompt-context
```

Expected: a line containing `[CTX] pc · ` — this task runs in a worktree, whose
`.dotter/local.toml` does not exist (it is git-ignored), so if the output says
`unknown (…)` run the same command against the main checkout's copy at
`/home/m/dotfiles/.claude/hooks/prompt-context` and report both results. Both
outcomes are expected behaviour, not a failure; record which one you saw.

- [ ] **Step 7: Commit**

```bash
git add .claude/hooks/prompt-context .claude/hooks/prompt-context-test
git commit -m "feat: name the machine in every prompt and subagent context"
```

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

Expected: PASS — `17 passed, 0 failed`, exit 0.

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

---

### Task 3: Tell the reader there are two machines

**Files:**
- Modify: `.claude/CLAUDE.md` (insert between the cross-session block ending `…zgłosisz następnym razem.` and the line `Dyscyplina kodu (Karpathy — zawsze; …`)
- Modify: `README.md` (section `## Per-host hardware`, after the third bullet, before `To add a machine:`)

**Interfaces:**
- Consumes: the label vocabulary (`pc`, `laptop`) and the hook name from Tasks 1–2.
- Produces: nothing.

No test: this task changes prose only. It is verified by reading the diff and by
the two `grep` checks in Step 4.

- [ ] **Step 1: Add the section to `.claude/CLAUDE.md`**

Insert this block, with one blank line before and after, immediately after the
line `w repo, zgłosisz następnym razem.` and before `Dyscyplina kodu (Karpathy`:

```markdown
Dwie maszyny — `pc` (desktop) i `laptop` (MacBook Air M2, Asahi):
- Oba systemy raportują hostname `ciek`, tego samego usera i ten sam prompt.
  Maszyny NIE wnioskujesz z hostname'a, promptu ani ścieżek — mówi ją wyłącznie
  linia `[CTX] <host>` wstrzykiwana przez hook `prompt-context` przy każdej
  wiadomości i przy starcie każdego subagenta.
- `~/projects`, `~/work`, `~/obsidian` i `~/.claude/projects` są
  synchronizowane mutagenem przez `sirius`. Wspólne jest **drzewo robocze, nie
  historia gita** (`~/work` ma `Ignore VCS`): każda maszyna ma tam własną
  historię. Nie mergujesz i nie rebase'ujesz historii między hostami — raz
  zjadło to 23 commity.
- Zapisując fakt zależny od maszyny (spec, notatka, commit, raport), nazywasz ją
  `pc` albo `laptop`. „Na tej maszynie" i „na `ciek`" są niejednoznaczne i były
  już źródłem siedmiu poprawek naraz.
```

- [ ] **Step 2: Add the line to `README.md`**

In `## Per-host hardware`, after the `hosts/pc/herdr-mirror-hosts.toml` bullet
and before the paragraph starting `To add a machine:`, add:

```markdown
`.dotter/local.toml` is also read by `.claude/hooks/prompt-context`, which names
the machine in every Claude Code session — both hosts report hostname `ciek`, so
the selected `host-*` package is the only thing that tells them apart. A checkout
without that file reports `[CTX] unknown (…)`.
```

- [ ] **Step 3: Run the hook's test suite once more**

Run: `.claude/hooks/prompt-context-test`

Expected: PASS — `17 passed, 0 failed`. Nothing in this task should have
affected it; a failure here means Step 1 or 2 edited the wrong file.

- [ ] **Step 4: Verify both edits landed where intended**

Run:

```bash
grep -c 'prompt-context' .claude/CLAUDE.md README.md
grep -n 'Dwie maszyny' .claude/CLAUDE.md
```

Expected: `.claude/CLAUDE.md:1` and `README.md:1` from the first command, and a
single `Dwie maszyny` line from the second, positioned before the
`Dyscyplina kodu` block.

- [ ] **Step 5: Commit**

```bash
git add .claude/CLAUDE.md README.md
git commit -m "docs: record that this configuration runs on two machines"
```

---

## After the merge — not a task

The hooks under `~/.claude/hooks/` are dotter symlinks into the **main
checkout**, so nothing in this branch changes the running configuration until it
merges. Once it does, `dotter deploy` has to run before the new hook is live,
and `settings.json` will point at `prompt-context` while the deployed tree still
has `timestamp-injector`:

```bash
cd ~/dotfiles && dotter deploy
ls -l ~/.claude/hooks/prompt-context          # must be a symlink into the repo
ls ~/.claude/hooks/timestamp-injector         # must be gone
printf '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' | ~/.claude/hooks/prompt-context
```

The window between merge and deploy is a hook that fails to start; Claude Code
reports that as a hook error and carries on, so it is noisy, not dangerous.
