# polishB2 — lock/autotheme/guard/smoke polish (standalone task, not in plan)

Worktree: /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell, branch worktree-feat+wyspa-shell. Code under config/quickshell/. Read CLAUDE.md there first. Surgical: each item below, nothing else. RED first where testable. SAFETY: this touches the lock and the guard tests. NEVER engage a real lock: the session lock is only reachable through `engageLock()` which is test-mode guarded; never run 19-lock-preview.sh; never `island lock` outside WYSPA_TEST smokes that already exist (check 17/18/19-series smokes: do not run any smoke whose script contains `lock` unless it is a pure node test). Weakening any guard test is forbidden — only extend.

## Lock (Lock.qml, lib/lock.js, states/LockCard.qml)
1. `L.idle()` with `island.lock.timeoutDefault` 0 (or any non-positive) returns enabled true timeout 0 = locks right after startup. Treat a non-positive timeout as disabled (node test in tests/lock.test.mjs).
2. The error ring returns when the field is emptied after typing; the reference (docs/prototypes, section 4.5 of docs/DESIGN.md) says typing clears the error. Fix so an error is cleared by the first typed character and does not return when the field is emptied (pure logic where possible, node test).
3. A lock request during the reverse morph (unlocking animation) is silently dropped — an idle-lock/Zablokuj request lost means the session stays unlocked. Make a request that arrives while the reverse morph runs engage after it ends (or cancel the reverse cleanly), via the same `engageLock()` choke point. Read Lock.qml carefully first; if the fix requires a non-trivial redesign, STOP and report what you found instead of guessing (report is allowed to say "not done, reason").

## AutoTheme (services/AutoTheme.qml)
4. The SystemClock is always on: enable it only when modeSource is sun (Time.qml already has a minute SystemClock — reuse its signal if simpler; no new timers).
5. The probe Image keeps a decoded ~33 MB bitmap for the shell lifetime: store the `sourceSize` on Ready and clear `source` (release the bitmap) once the quantizer has sampled.

## Guard hardening (tests/power.test.mjs, tests/lock.test.mjs, tests/qmljs.mjs)
6. The no-dangerous-calls guard scans QML only: also scan lib/*.js.
7. `quit` regex is case-sensitive: make it case-insensitive. Add `Socket` and `openUrlExternally` to the DANGEROUS list (check the existing list structure; allowlist entries stay explicit).
8. Duplicated helpers (strip / qmlFiles / functionSpan) in lock.test.mjs and power.test.mjs: move into tests/qmljs.mjs and import from both. Behaviour of the tests unchanged (all existing assertions still run; the callers-pin of PowerActions stays exactly `["Lock.qml", "states/Power.qml"]`).

## Smokes / harness
9. Audit EVERY `tests/smoke/*.sh`: a `shot` line must be the LAST line (niri's screenshot posts a notification; the test instance is the daemon, so a later expect sees `toast`; gotcha 7). Known broken: 10-osd.sh (`current expected 'rest' got 'toast'` after `shot osd`). Move shot lines last in all; if a script needs assertions after the shot, split them before it. No other behaviour changes.
10. `09-rest.sh` asserts absolute `notifs unread 2`: make it baseline-relative (read the value before, assert +N).
11. `tests/shot.sh` only asks the instance at $DIR (the lock check uses a bare `qs ipc call lock isLocked` — the old shell). Make the lock guard query the instance for $DIR (`qs ipc -p "$DIR" call island ...` form; check what prop exists, e.g. `locked`) — verify with a harmless read, do not take shots to test it beyond what step 9 needs.

## Verify
`node --test 'tests/*.test.mjs'`. Smokes (`QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh`): 04-state, 06-content, 08-notifs, 09-rest, 21-auto, 20-line (one shot); do NOT run smokes containing `lock` or 19-*; do not run other shot-containing smokes except to verify item 9 (budget: 3 live shots total; item 9 can otherwise be verified by reading the order of lines and a /tmp copy without the shot). `qs list --all` empty after each run (~2 s); only `qs kill -p <worktree>/config/quickshell`. No niri actions, no notify-send.
Commit: stage `config/quickshell` only (not .flow/), message `quickshell: lock idle and error-ring fixes, autotheme idle, guard hardening, shot-last smokes` + trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Report with RED/GREEN per item (or why not): .flow/sdd/2026-10-10-wyspa-shell/task-polishB2-report.md
