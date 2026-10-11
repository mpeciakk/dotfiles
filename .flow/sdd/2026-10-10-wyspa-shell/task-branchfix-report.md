# branchfix report (whole-branch review fixes)

Commit 7d8c141 `quickshell: no live reload while locked, plain-text external strings, guard precision, cleanup`.
Worktree and branch verified before the first edit. No lock was engaged, no 19-lock-preview, no niri action, no notify-send;
`qs list --all` was empty after every smoke.

## Verification
- `node --test 'tests/*.test.mjs'` (from config/quickshell): 235 tests, 235 pass, 0 fail.
- Smokes, serially, `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh`: 00-start, 04-state, 06-content, 08-notifs, 11-series,
  12-center (shot), 10-osd (shot), 21-auto: all exit 0, no unlisted WARN/ERROR; `qs list --all` = "No running instances." after each.
  (04 and 06 were issued in one tool turn; both passed.)

## Items
- A (Critical). RED: new guard in tests/lock.test.mjs ("shell.qml does not hot-reload ...") failed on `watchFiles: true`
  (`The input did not match /settings\.watchFiles\s*:\s*false\b/`). GREEN: shell.qml `settings.watchFiles: false` + one-line WHY comment;
  the guard also requires watchFiles set exactly once and a comment mentioning reload / lock / restart. Config.json overrides: Theme.qml
  reads it through its own `FileView { watchChanges: true; onFileChanged: reload() }`, independent of `settings.watchFiles`
  (verified in the code, and smoke 21-auto, which rewrites the temp config and expects Theme to follow, passes with watchFiles false).
  CLAUDE.md: deploy section says no live reload, restart after deploy, why. docs/DESIGN.md only mentions config.json hot-reload
  via FileView (lines 32, 161): still true, left alone.
- B1. tests/lock.test.mjs: new test pins `if (L.keepsLocked(root.testMode, sessionLock.locked, root.unlocking)) {` un-negated and `return;` in its body.
  Passes on the current code (it was correct); the existing guard stays. Not mutation-tested against a negated `!`; the regex has no slot for one.
- B2. tests/power.test.mjs: `/\bSocket(Server)?\b/g`; the "DANGEROUS catches each spelling" test gained `SocketServer { }` (the old regex does not match it). The planted-offender test passes.
- C3. RED: new polish guard failed ("states/Toast.qml: root.snap.summary must be PlainText"). GREEN: `textFormat: Text.PlainText` on Toast summary and body
  line, Center card summary and body. Guard covers all four Texts.
- C4. grep first: `focusWorkspace` and `dateStr` had no callers (only their definitions). Removed both. tests/power.test.mjs allowlist for services/Niri.qml
  stays (`execDetached`, `Process` still used by focusWindow and the event stream; "every entry still true" passes); only its comment no longer mentions workspace.
- C5. tests/shot.sh: `qs ipc call lock isLocked` -> `qs ipc prop get island locked` (+ messages); lock.test.mjs shot guard pins the new line,
  the `-p "$DIR"` line, and forbids `qs ipc call lock`. RED before the edit: "did not match /qs ipc prop get island locked/".
- C6. Lock.qml `const d = L.engage(`. (whitespace; existing tests)
- C7. services/AutoTheme.qml probe Image: `cache: false`; new polish guard (RED: did not match /cache:\s*false/).
- C8. tests/smoke/10-osd.sh: `wait_ms 700` before `shot osd`; 10-osd passes.
- C9. Done, small (~10 lines): `lib/island.js stranded(state, output, outputNames)` (modal and output not among the names) with a node unit test (RED: `I.stranded is not a function`),
  and a `Connections { target: Quickshell; onScreensChanged }` in IslandState.qml that calls `root.close()` when stranded. A polish source guard pins the handler.
  Not exercised live (no real unplug); smokes load it without warnings.
- C10. CLAUDE.md gotcha 9: UNVERIFIED note about the shell dying while locked and the likely recovery.

## Not done
Nothing declined. Item 9 is only verified by the unit test, the source guard and clean smoke startup, not by unplugging a monitor.

## Concerns
- `qs ipc prop get island locked` in shot.sh has no `-p`: with several instances running (e.g. a smoke plus the live shell) qs picks one; harmless (read only), and the second `-p "$DIR"` check covers the checkout's own instance.
