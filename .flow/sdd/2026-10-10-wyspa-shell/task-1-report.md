# Task 1 report — Clean slate + test harness

Status: DONE (with one concern, below). Commit: 8f6d7ff "quickshell: clean slate for Wyspa + node/smoke test harness".

## Implemented
- Deleted `modules/`, `components/`, `services/{Colours,Appearance,Config,Vpn}.qml` (git rm -> 49 files changed, 3652 deletions). Kept services Apps, Audio, Battery, Menus, Network, Niri, Notifs, Players, Time, `menus/`, `assets/`, `docs/`.
- Rewrote `shell.qml` (empty ShellRoot, `settings.watchFiles: true`).
- Created (verbatim from brief): `tests/qmljs.mjs`, `tests/no-magic.test.mjs`, `tests/smoke.sh`, `tests/shot.sh`, `tests/niri-validate.sh` (all three scripts chmod +x), `tests/smoke/00-start.sh`, `tests/smoke/allowed-warnings.txt`, `tests/fixtures/config.json`.
- No changes to smoke.sh's log pattern were needed (see Step 7 evidence).

## TDD evidence
RED (guard test written first, run against the old tree):
```
$ node --test 'tests/*.test.mjs'
✖ UI QML takes colours, sizes and times only from Theme
  AssertionError: Expected values to be strictly deep-equal:
  + [ 'components/Drawer.qml:74: number 4: return Math.max(4, ...', 'components/Drawer.qml:82: number 0.001: ...',
  +   'components/Glyph.qml:8: number 18: property int size: 18', 'components/Icon.qml:5: number 16: ...', ... ]
ℹ pass 0 / fail 1
```
Expected: old UI is full of px/ms/colour literals; test fails on the offender list, not on an error.

GREEN (after deleting old UI):
```
$ node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/00-start.sh
✔ UI QML takes colours, sizes and times only from Theme
ℹ tests 1 / pass 1 / fail 0
exit=0
```

## Step 7 — runner probes
1. `Component.onCompleted: console.warn("probe")` in ShellRoot:
```
$ tests/smoke.sh tests/smoke/00-start.sh
FAIL: instance logged:
  WARN qml: probe          (ANSI colour codes around WARN in real output)
exit=1
```
Caught; the `\b(WARN|ERROR|FATAL|CRIT)` pattern matches the real `qs log` format as is (levels are coloured but the word boundary still matches).
2. `console.error("probe-err")`: `ERROR qml: probe-err`, exit=1 — caught.
3. Probe removed (shell.qml restored; committed version has no probe).
4. Unbound variable check file (`echo $NOPE`):
```
$ tests/smoke.sh /tmp/unbound-check.sh
/tmp/unbound-check.sh: line 1: NOPE: unbound variable
exit=1
$ qs list --all | grep -E 'Config path|Instance'
Instance lp8papmt:
  Config path: /home/m/.config/quickshell/shell.qml      <- only the user's own shell; none for this worktree
$ ls /tmp/wyspa-config.*   -> No such file (temp config removed by the trap)
```
EXIT trap cleaned up the instance and the temp config copy.
5. `tests/niri-validate.sh` -> "config is valid", exit 0.

The user's running shell (lp8papmt) was untouched throughout: every `qs kill`/`qs ipc` carried `-p <config dir>`.

## Files changed
config/quickshell: shell.qml (M), tests/{qmljs.mjs,no-magic.test.mjs,smoke.sh,shot.sh,niri-validate.sh,smoke/00-start.sh,smoke/allowed-warnings.txt,fixtures/config.json} (A), plus the deletions above.

## Self-review
- All brief items done; allowed-warnings.txt has a justification comment per pattern; no extra patterns added.
- No leftover references to the deleted services in the kept files (grep on services/ and menus/ was empty before deletion).
- Stray temp files are only in /tmp (/tmp/shell.qml.bak, /tmp/unbound-check.sh); not in the repo.

## Concerns
- `tests/shot.sh` (verbatim from brief) runs `qs ipc call lock isLocked` WITHOUT `-p`, i.e. it queries the user's live old shell (read-only call, intended as lock detection). With two instances running, qs may report ambiguity -> `|| true` -> empty -> treated as unlocked. So the lock guard is effectively inert while both shells run, and this one call is the only place the harness touches the user's instance. I did not run shot.sh (no screenshot was required by this task) and did not change it. Worth revisiting once the old shell is gone (it then queries the new one, which has no `lock` target until the lock task).
- The Write/Bash environment refused long compound commands in the worktree, so files were written individually; no impact on content.
