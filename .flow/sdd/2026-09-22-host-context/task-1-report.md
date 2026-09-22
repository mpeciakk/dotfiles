# Task 1 Report: `prompt-context` — the hook and its regression net

## Implementation Summary

Successfully implemented the `prompt-context` hook and its complete regression test suite following TDD methodology. The hook emits the machine identity (pc/laptop) and current timestamp on every UserPromptSubmit and SubagentStart event, enabling transcripts to be attributed to the correct machine across a two-machine setup where both report the same hostname.

## TDD Evidence

### RED (Failing Test)
**Command:** `./.claude/hooks/prompt-context-test` (after Step 2)

**Output:**
```
=== the host label comes from dotter, not from the hostname ===
FAIL  host-pc not reported as pc                                 [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
FAIL  host-mac not reported as laptop                            [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
FAIL  host-sirius not reported as sirius                         [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
=== an unknown host says so, with the reason ===
FAIL  no host package not explained                              [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
FAIL  missing local.toml not explained                           [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
FAIL  unparseable local.toml not handled                         [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
=== the envelope names the event it was called for ===
PASS  UserPromptSubmit is echoed back                            
FAIL  wrong hookEventName                                        UserPromptSubmit
=== a subagent gets told why the line exists, a prompt does not ===
FAIL  SubagentStart missing caveat                               [TIMESTAMP] User message received: Tuesday 2026-09-22 21:15:34
PASS  UserPromptSubmit stays one short line                      
PASS  an unknown host drops the caveat                           
=== bad input is survivable ===
PASS  malformed stdin exits 0 and emits nothing                  
PASS  empty stdin exits 0 and emits nothing                      

5 passed, 8 failed
```

**Why this failure was expected:** The old `timestamp-injector` hook hardcodes `hookEventName: "UserPromptSubmit"` and outputs `[TIMESTAMP] User message received: ...`. The test expects:
- Host labels from dotter (pc, laptop, or fallback to custom name)
- Unknown hosts to report the reason
- Event names to be echoed back
- SubagentStart events to include a caveat about hostname
- All formatted as `[CTX] {machine} · {timestamp}`

### GREEN (Passing Test)
**Command:** `./.claude/hooks/prompt-context-test` (after Step 4)

**Output:**
```
=== the host label comes from dotter, not from the hostname ===
PASS  host-pc is reported as pc                                  
PASS  host-mac is reported as laptop                             
PASS  an unmapped host-* falls back to its own name              
=== an unknown host says so, with the reason ===
PASS  no host package names the reason                           
PASS  a missing local.toml names the reason                      
PASS  an unparseable local.toml reports the decode error         
=== the envelope names the event it was called for ===
PASS  UserPromptSubmit is echoed back                            
PASS  SubagentStart is echoed back                               
=== a subagent gets told why the line exists, a prompt does not ===
PASS  SubagentStart carries the hostname caveat                  
PASS  UserPromptSubmit stays one short line                      
PASS  an unknown host drops the caveat                           
=== bad input is survivable ===
PASS  malformed stdin exits 0 and emits nothing                  
PASS  empty stdin exits 0 and emits nothing                      

13 passed, 0 failed
```

All 13 tests pass, covering:
- Machine identity recognition from dotter's local.toml
- Label mapping (host-pc → pc, host-mac → laptop, host-* → *)
- Unknown host handling with specific error reasons (missing file, parse error, no package)
- Correct JSON envelope with hookEventName echoed back
- SubagentStart caveat about hostname only when host is known
- Graceful handling of malformed/empty stdin

## Files Changed

1. **Renamed (git mv):** `.claude/hooks/timestamp-injector` → `.claude/hooks/prompt-context`
   - Preserves executable bit
   - Keeps all history in git

2. **Created:** `.claude/hooks/prompt-context`
   - Python 3 implementation (requires python3 >= 3.11 for tomllib)
   - 90 lines: docstring, imports, constants, host() function, main() function
   - Reads machine identity from `<repo>/.dotter/local.toml`
   - Maps `host-pc` → `pc`, `host-mac` → `laptop`
   - Falls back to custom name for other `host-*` patterns
   - Reports unknown host with reason (missing file, parse error, or no package)
   - Emits timestamp as `{day} {date} {time}`
   - Only adds subagent caveat when host is known and event is SubagentStart

3. **Created:** `.claude/hooks/prompt-context-test`
   - Bash test harness with 13 assertions
   - Creates throwaway checkouts to test against synthetic local.toml files
   - Tests both machines' configurations (pc, mac)
   - Tests all three error conditions
   - Tests JSON envelope structure
   - Tests resilience to malformed input

## Real Machine Verification (Step 6)

**Command:**
```bash
cp /home/m/dotfiles/.dotter/local.toml .dotter/local.toml
printf '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' | .claude/hooks/prompt-context
git status --short .dotter/
```

**Output:**
```json
{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": "[CTX] pc · Tuesday 2026-09-22 21:18:31"}}
```

**Verification:** ✓ Hook correctly reports `pc` from the real local.toml. ✓ `.dotter/` directory is in .gitignore (no git status output). The machine's actual identity is correctly recognized.

## Commits

1. `79411d5` refactor: rename timestamp-injector to prompt-context
2. `dd53254` feat: name the machine in every prompt and subagent context

Both commits are properly attributed and follow the brief's instructions.

## Self-Review

**Completeness:** ✓ All 7 steps completed as specified.

**TDD Evidence:** ✓ RED → GREEN cycle fully documented with output from both stages.

**Test Correction:** During implementation, discovered that the test pattern for the NOFILE case was missing a trailing wildcard to account for the appended timestamp. This was corrected by changing line 115 from:
```bash
case "$c" in "[CTX] unknown (no "*"local.toml)") ...
```
to:
```bash
case "$c" in "[CTX] unknown (no "*"local.toml)"*) ...
```
This aligns with the other error-case patterns and allows the timestamp to be appended consistently across all outputs. The fix enables all 13 tests to pass without deviating from the spirit of the brief (comprehensive host identification on every event).

**Code Quality:** ✓ Implementation is minimal (90 lines), stdlib-only, no error-raising on malformed input, correct path resolution for symlinked hooks.

**Test Quality:** ✓ Tests verify real behavior (JSON parsing, pattern matching, actual hook execution) rather than mocks. Fixtures are self-verifying.

## Concerns

None. All tests pass, the hook correctly identifies the machine against the real local.toml, and the implementation matches the brief's specification exactly.

## Fix pass (whole-branch review, 2026-09-22)

Three findings applied to `.claude/hooks/prompt-context`, its test, and `README.md`.

### Finding 1 — remove `SUBAGENT_NOTE`

The user decided at the gate that the note is obsolete: a subagent's context
already carries `~/.claude/CLAUDE.md`, which this branch gave a "Dwie maszyny"
block stating the `ciek` fact, so the per-dispatch caveat buys nothing.

Removed the `SUBAGENT_NOTE` constant and the `if event == "SubagentStart" and
not machine.startswith("unknown"): line += SUBAGENT_NOTE` conditional in
`main()`. `hookEventName` still echoes the event it was called for; both of
those assertions (`UserPromptSubmit is echoed back`, `SubagentStart is echoed
back`) are untouched.

In `.claude/hooks/prompt-context-test`, removed the two assertions that no
longer describe the hook — `SubagentStart carries the hostname caveat` and `an
unknown host drops the caveat` (plus the comment above the second one) — and
kept `UserPromptSubmit stays one short line`.

Test evidence — suite dropped from 18 to 16 assertions and stayed green at
each step (removed the test assertions first, confirmed still 16/16 green
against the unmodified hook, then removed the hook's constant/conditional and
confirmed 16/16 green again):

```
$ .claude/hooks/prompt-context-test | tail -3
PASS  no reference to the old hook name remains

16 passed, 0 failed
```

### Finding 2 — README's misleading last sentence

Replaced:
```
without that file reports `[CTX] unknown (…)`.
```
with:
```
without that file — run directly, not through the deployed
`~/.claude/hooks/` symlink — reports `[CTX] unknown (…)`.
```
No other change to README.md. This is prose-only; no test applies.

### Finding 3 — the never-raise contract stops at the module boundary

`import tomllib` sat at module scope and `main()` was called unguarded in
`.claude/hooks/prompt-context`, so an interpreter without `tomllib` (or any
other unexpected error) would crash the whole hook — taking the timestamp
down with the host lookup. Read `.claude/hooks/flow-context` (the sibling hook
on the same events) and matched its shape: it wraps its `main()` call at the
bottom in `try: main() except Exception: pass`.

Fix, written test-first:

1. Added one assertion to `.claude/hooks/prompt-context-test`, under a new
   `=== a missing tomllib is survivable too ===` section: writes a
   `tomllib.py` that raises `ImportError` on import into a throwaway
   directory, runs the hook with that directory prepended via `PYTHONPATH`,
   and checks the hook still exits 0 and emits a well-formed envelope
   (`hookEventName` echoed, `additionalContext` starting `[CTX] unknown (`).
2. Verified RED against the unmodified hook — confirmed it fails for the
   right reason (crash, not a typo):
   ```
   $ .claude/hooks/prompt-context-test 2>&1 | grep FAIL
   FAIL  missing tomllib made the hook exit non-zero                |rc=1
   ```
3. Applied the minimal fix:
   - Guarded the import: `try: import tomllib / except ImportError: tomllib =
     None`. With `tomllib` set to `None`, `host()`'s existing generic
     `except Exception as exc:` handler (untouched) catches the resulting
     `AttributeError` from `tomllib.load(...)` and returns `unknown (...)` —
     `host()`'s own handlers were not touched, per the finding's constraint.
   - Wrapped the `if __name__ == "__main__":` call in `try: main() except
     Exception: pass`, mirroring `flow-context`'s shape.
4. Verified GREEN — 17/17, matching the finding's target total:
   ```
   $ .claude/hooks/prompt-context-test
   === a missing tomllib is survivable too ===
   PASS  a missing tomllib degrades to unknown rather than crashing
   ...
   17 passed, 0 failed
   ```

### Full suite

```
$ .claude/hooks/prompt-context-test
[... all 17 assertions ...]
17 passed, 0 failed
```

```
$ .claude/hooks/flow-guard-test
[... all 15 assertions ...]
124 passed, 0 failed
```

(`flow-guard-test`'s own internal counter reports 124, not 15 — it runs many
more sub-cases per named assertion; the summary line is unchanged by this fix
pass, confirming the `settings.json` wiring this branch touched is still
intact.)

### Declined

None. All three findings were applied as specified; none conflicted with the
brief or plan.

### Commits

See top-level git log for the fix-pass commit(s) following this report.

## Fix pass 2 (re-review, 2026-09-22)

Three findings, all in `.claude/hooks/prompt-context` and its test.

### Finding 1 — stale header and unfalsifiable assertion at `prompt-context-test:90-92`

The section header still described the `SUBAGENT_NOTE` distinction that Fix
pass 1 (Finding 1) removed, and the assertion grepped for `ciek`, a string
nothing in the current hook can ever emit (the note that used to embed it is
gone, and no fixture path contains it either) — an assertion that cannot fail
is not a test.

Replaced the header and assertion with one that checks what now actually
matters: that `SubagentStart`'s line for `$PC` is exactly the same shape as
`UserPromptSubmit`'s, with nothing appended after the timestamp. Anchored with
a bash regex (`[[ "$c" =~ ^\[CTX\]\ pc\ ·\ ... $ ]]`) rather than a `case`
wildcard, because "no suffix after the timestamp" needs an end anchor that a
leading/trailing `*` glob can't express.

```
echo "=== the context line is identical for a prompt and a subagent ==="
c=$(context_of "$PC" SubagentStart)
if [[ "$c" =~ ^\[CTX\]\ pc\ ·\ [A-Za-z]+\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
  report ok "SubagentStart carries the same line as UserPromptSubmit, no suffix"
else
  report no "SubagentStart line differs from the UserPromptSubmit shape" "$c"
fi
```

No hook behavior changed for this finding — the current hook already emits
the same line shape for both events (that's what Fix pass 1 established); this
is a test-correctness fix. Verified against the existing hook (safety net):
assertion count held at 17, all green (see full-suite output below).

### Finding 2 — `tomllib` assertion matched serialized JSON and didn't discriminate the branch at `prompt-context-test:105-115`

The old assertion grepped raw stdout for `'"hookEventName": "UserPromptSubmit"'`
and `'"additionalContext": "[CTX] unknown ('`, which (a) depended on
`json.dump`'s default separators instead of going through `context_of`/
`event_of` like every other assertion in the file, and (b) matched `[CTX]
unknown (` — the same prefix the missing-`local.toml` branch (`NOFILE`
fixture) produces — so it couldn't tell "tomllib is missing" from "local.toml
is missing."

Rewrote to use `context_of` and match only the text this branch produces —
`AttributeError` from `tomllib.load(...)` when `tomllib` is `None`, whose
message is `'NoneType' object has no attribute 'load'`:

```
c=$(PYTHONPATH="$NOTOMLLIB" context_of "$PC" UserPromptSubmit)
case "$c" in
  *"'NoneType' object has no attribute 'load'"*)
    report ok "a missing tomllib degrades to unknown rather than crashing";;
  *) report no "missing tomllib produced a malformed envelope" "$c";;
esac
```

Kept it against `$PC` (valid `host-pc` `local.toml`) as instructed — verified
manually that this fixture, with `tomllib` shadowed, actually produces that
exact text (confirming the assertion isn't vacuous):

```
$ printf '{"hook_event_name":"UserPromptSubmit","prompt":"x"}' \
  | PYTHONPATH=<no-tomllib-dir> <PC-fixture>/prompt-context
{"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext":
"[CTX] unknown (.../local.toml: 'NoneType' object has no attribute 'load')
· Tuesday 2026-09-22 21:47:12"}}
```

Assertion count held at 17 (a rewrite in place, not an addition).

### Finding 3 — swallowed exception left no trace at `prompt-context:73-76`

`except Exception: pass` matched `flow-context`'s shape but not its
consequence: this branch's `.claude/CLAUDE.md` addition tells every session
that a turn with no `[CTX]` line means the hook isn't deployed on that
machine. A silently swallowed bug in `main()` would produce exactly that
appearance forever, misdiagnosed as a deployment gap.

Fix, kept minimal per the finding's constraints (never-fail contract stays,
`except Exception` stays broad, `host()` untouched, malformed-stdin
`SystemExit`-passthrough untouched):

```python
import traceback   # added to the stdlib import block
...
    try:
        main()
    except Exception:
        traceback.print_exc()  # never take the timestamp down with the host lookup
```

Written test-first, but as a one-off manual reproduction rather than a
permanent suite assertion — the dispatch's target output is "17 passed" for
`prompt-context-test`, so a fourth behavioral assertion would contradict that.
Verified with a scratch script that shadows the `datetime` module via
`PYTHONPATH` so `datetime.now()` raises inside `main()` (past `host()`'s own
try/except, so it only exercises the outer swallow):

RED (before the fix, against the unmodified hook):
```
--- stdout ---

rc=0
--- stderr ---
```
Crash was fully silent — no trace, exit 0, matching the finding's complaint.

GREEN (after adding `traceback.print_exc()`):
```
--- stdout ---

rc=0
--- stderr ---
Traceback (most recent call last):
  File ".../prompt-context", line 75, in <module>
    main()
    ~~~~^^
  File ".../prompt-context", line 65, in main
    line = f"[CTX] {machine} · {datetime.now():%A %Y-%m-%d %H:%M:%S}"
                                ~~~~~~~~~~~~^^
  File ".../no-datetime/datetime.py", line 4, in now
    raise RuntimeError("blocked for test")
RuntimeError: blocked for test
```
Still exits 0, still emits no stdout (never blocks a prompt), now traces to
stderr. Also re-confirmed the malformed-stdin path is untouched (still relies
on `SystemExit` passing through uncaught):
```
$ printf 'not json' | .claude/hooks/prompt-context; echo "rc=$?"
rc=0
$ printf '' | .claude/hooks/prompt-context; echo "rc=$?"
rc=0
```

### Full suite

```
$ .claude/hooks/prompt-context-test
=== the host label comes from dotter, not from the hostname ===
PASS  host-pc is reported as pc
PASS  host-mac is reported as laptop
PASS  an unmapped host-* falls back to its own name
=== an unknown host says so, with the reason ===
PASS  no host package names the reason
PASS  a missing local.toml names the reason
PASS  an unparseable local.toml reports the decode error
=== the envelope names the event it was called for ===
PASS  UserPromptSubmit is echoed back
PASS  SubagentStart is echoed back
=== the context line is identical for a prompt and a subagent ===
PASS  SubagentStart carries the same line as UserPromptSubmit, no suffix
=== bad input is survivable ===
PASS  malformed stdin exits 0 and emits nothing
PASS  empty stdin exits 0 and emits nothing
=== a missing tomllib is survivable too ===
PASS  a missing tomllib degrades to unknown rather than crashing
=== the hook is wired into settings.json ===
PASS  UserPromptSubmit runs prompt-context
PASS  SubagentStart runs prompt-context
PASS  SubagentStart still runs flow-context
PASS  SubagentStart still runs cbm-subagent-reminder
PASS  no reference to the old hook name remains

17 passed, 0 failed
```

```
$ .claude/hooks/flow-guard-test | tail -5
=== context reflects the real vocabulary ===
PASS  a done task is reported to subagents as complete
PASS  a started task is reported in flight

124 passed, 0 failed
```

Unrelated to this fix pass (no file it covers was touched) — run only to
confirm nothing broke.

### Declined

None. All three findings were applied as specified; none conflicted with the
brief or plan.

### Commits

See top-level git log for the fix-pass 2 commit following this report.
