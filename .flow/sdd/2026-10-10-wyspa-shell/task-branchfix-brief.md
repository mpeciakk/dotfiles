# branchfix — fixes from the whole-branch review (standalone task)

Worktree: /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell, branch worktree-feat+wyspa-shell, HEAD 73c2151. Code under config/quickshell/. Read config/quickshell/CLAUDE.md first. Surgical; RED first where testable; NEVER engage a real lock (no `island lock` outside existing WYSPA_TEST smokes; no 19-lock-preview; no smokes with a lock path); never weaken a guard test, only extend.

## A. CRITICAL — hot reload while locked unlocks without PAM
`shell.qml:6` `settings.watchFiles: true` + `Lock.qml` `WlSessionLock`: upstream `WlSessionLock::onReload` takes over the old manager, the new instance starts with `locked == false` and calls `unlock()` on it, releasing the compositor lock. dotter symlinks every file of `~/.config/quickshell`, so any write/commit/merge in the repo reloads the live shell (and the idle lock fires after 300 s). Decision (controller): option (b) — set `settings.watchFiles: false` in shell.qml, with a one-line WHY comment (reload while locked releases the lock; restart the service after deploy instead). Token overrides in config.json still hot-reload through FileView — verify that this still works (grep how config.json is read; it must not depend on watchFiles; if it does, report instead of guessing). Add a node source-guard test (style of tests/lock.test.mjs) pinning `watchFiles: false` in shell.qml with the reason. Update CLAUDE.md (running section: after `dotter deploy` restart with `systemctl --user restart quickshell`; no live reload; why) and docs/DESIGN.md only if it claims hot reload (grep first; if it does, minimal correction).

## B. Guard precision (tests only)
1. tests/lock.test.mjs item-3 guard: pin the polarity — the branch in engageLock must match `/if\s*\(\s*L\.keepsLocked\(\s*root\.testMode\s*,\s*sessionLock\.locked\s*,\s*root\.unlocking\s*\)\s*\)\s*\{/` (adapt to the real text) and its body must contain `return`.
2. tests/power.test.mjs: `/\bSocket\b/` -> `/\bSocket(Server)?\b/` (check the planted-offender test still proves it).

## C. Small fixes
3. `states/Toast.qml` (~118, 127) and `states/Center.qml` (~399, 410): external notification summary/body Texts -> `textFormat: Text.PlainText` (Qt fetches `<img src=https://…>` in rich text). Extend tests/polish.test.mjs' external-strings guard to cover them.
4. Dead code orphaned by the branch: remove `services/Niri.qml` `focusWorkspace` (unguarded `sh -c`; no callers — verify with grep first) and its entry/allowlist reference in tests/power.test.mjs if the allowlist only exists for it (keep any other allowlisted items; the allowlist check "still true" must keep passing); remove unused `services/Time.qml` `dateStr` (verify no callers first).
5. `tests/shot.sh:8` queries the OLD shell's `lock` target (dead after deploy): replace with `qs ipc prop get island locked` (live shell, harmless read) and keep the pinning assertion in tests/lock.test.mjs in step.
6. `Lock.qml:~50/85` whitespace `const d =L.engage(` -> `const d = L.engage(`.
7. `services/AutoTheme.qml` probe Image: add `cache: false` (deterministic bitmap release).
8. `tests/smoke/10-osd.sh`: `wait_ms 700` before `shot osd`.
9. `IslandState.qml`: a modal state can outlive its monitor — if the output of an open modal state is unplugged, `current` stays modal with no surface. Close it when its output disappears (find how outputs are tracked; a small handler + node/smoke assertion if testable). If it needs more than ~15 lines or a new mechanism, DO NOT do it; report why.
10. CLAUDE.md gotcha 9: add, clearly marked UNVERIFIED: if the shell dies while locked the compositor keeps the blank lock and a restarted shell starts unlocked; likely recovery is restart quickshell, `qs ipc call island lock`, then authenticate (or `island unlock`); not verified live.

## Verify
`node --test 'tests/*.test.mjs'` (from config/quickshell); smokes serially via `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh`: 00-start, 04-state, 06-content, 08-notifs, 11-series, 12-center, 10-osd (one shot ok), 21-auto. `qs list --all` empty after each (~2 s); only `qs kill -p <worktree>/config/quickshell`. No niri actions, no notify-send.
Commit config/quickshell only (not .flow/): `quickshell: no live reload while locked, plain-text external strings, guard precision, cleanup` + trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Report: .flow/sdd/2026-10-10-wyspa-shell/task-branchfix-report.md (RED/GREEN per item; say which items were not done and why).
