# polishB1 — UI polish of deferred Minors (standalone task, not in plan)

Worktree: /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell, branch worktree-feat+wyspa-shell. Code under config/quickshell/. Read CLAUDE.md there first (idioms, traps). Surgical changes only: each item below, nothing else; no refactors. Each item gets a node test or a smoke assertion where it is testable (RED first); where it is not testable without a real pointer/keyboard, say so in the report and verify by reading + the existing smokes.

## Launcher (states/Launcher.qml, IslandState.qml)
1. `IslandState.launcherResult` keeps the last selected label after close (clipboard preview readable via IPC): reset it when the launcher closes (Launcher `onActiveChanged` else-branch or equivalent).
2. Rows rebuild (Niri.windowList change / menu re-list) resets the ListView to the top without re-scrolling: `positionViewAtIndex(selected, ListView.Contain)` on rows change.
3. `launcherMenu(id)` sets `launcherMenuRequest` before `request(launcher)`: a refused open leaves it pending. Set it only when the request is granted (true).
4. Description/sublabel `Text` items show external strings (app_id, comments, menu sublabels): set `textFormat: Text.PlainText`.
5. Empty menu command runs `sh -c ''`: guard it (skip when command is empty; the old launcher had `if item.command`).

## OSD (IslandState.qml)
6. Old-shell regression: a default-sink change (BT/USB connect) flashes the OSD. In IslandState's Audio Connections: on default sink change reset `osdReady` and restart the gate timer (see how the existing startup gate works and reuse it — same mechanism, no new one). A smoke or node-testable path if one exists; otherwise justify.

## Toast (states/Toast.qml)
7. `+N` chip vanishes instantly at close (series resets while the layer fades: more = -1): keep the last non-negative value while the layer fades out.
8. Empty body renders "Wyspa · ": render the app/summary without the dangling separator when the body is empty.
9. App icon `Image` has no `sourceSize` (niri's screenshot notification carries a full-res PNG): set `sourceSize` to the icon box size (use the existing Theme token for the icon size, no magic literal). Keep the Image synchronous — NEVER `asynchronous` (qsimage must load inside the handler).

## Center (states/Center.qml)
10. The centre drops image-path hints too (image://icon/...), contrary to the spec: exclude only `image://qsimage/` URLs (they dangle after the Notification is destroyed), keep the rest.

## Verify
`node --test 'tests/*.test.mjs'`; smokes via `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh` for every smoke touching the changed areas: 08-notifs, 11-series, 12-center, 15-launcher*, 04-state, 06-content (check which exist with ls tests/smoke). Shot-containing smokes: run at most 3 live shots total. A fullscreen window may exist on the focused output; smokes no longer depend on it (Fullscreen is off under WYSPA_TEST). `qs list --all` must be empty after each run (~2 s); only `qs kill -p <worktree>/config/quickshell`. Never run 19-lock-preview, never `island lock`, no niri actions, no notify-send (the smokes inject via IPC).
Commit: stage `config/quickshell` only (not .flow/), message `quickshell: polish launcher, osd sink gate, toast, centre image hints` + trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`. Report with RED/GREEN evidence per item (or why not testable): .flow/sdd/2026-10-10-wyspa-shell/task-polishB1-report.md
