# Task 22 report: niri binds, CLAUDE.md, spec state

Status: DONE_WITH_CONCERNS (06-content fails here because of a fullscreen window, see Concerns).

## Implemented
- `config/niri/bindings.kdl`: three binds retargeted, nothing else activated:
  - `Mod+Space` -> `qs ipc call island toggle launcher`
  - `Mod+Shift+V` -> `qs ipc call island launcherMenu clipboard`
  - `Mod+L` -> `qs ipc call island lock`
  - commented block of the future binds (control, center, media, power, hide, brightness keys) after them.
  - Checked against the real `IpcHandler` in `IslandState.qml`: `toggle(s: string)`, `launcherMenu(id: string)`, `lock()` exist with those types; `clipboard` is a `Menus` id.
- `config/quickshell/CLAUDE.md` (new): what it is, dotter, running, tests, structure (real files from `ls`), conventions, IPC tables for `island` / `theme` / `notifs` (functions and props taken from the three `IpcHandler`s), niri binds + blur rule, 11 gotchas one line each.
  - Dotter: `.dotter/global.toml` maps the directory `config/quickshell` -> `~/.config/quickshell`; the live dir shows real directories with per-file symlinks (e.g. `CLAUDE.md -> /home/m/dotfiles/config/quickshell/CLAUDE.md`), so "file by file, new files need `dotter deploy`" is true.
  - Gotcha 10: `grep -n WYSPA_TEST services/Fullscreen.qml` finds nothing, so it is written as a known gap.
  - Gotcha 5 lists `Niri`, `Apps`, `Fullscreen`, `AutoTheme` (the four `shell.qml` references; `Notifs` is referenced via `IslandState`, so it was dropped from the list after review).
- `config/quickshell/docs/DESIGN.md` section 7 rewritten in Polish to the real files; sections 1-6 and 8 untouched (headings checked).
- `README.md`: only the "Lock `unlock` IPC" note: path `config/quickshell/IslandState.qml`, call `qs ipc call island unlock`.
- No QML/JS touched.

## Verification (TDD exception: config + docs, no production code; no RED invented)
- `tests/niri-validate.sh` -> "config is valid", exit 0.
- `node --test 'tests/*.test.mjs'` -> 204 tests, 204 pass, 0 fail.
- Smokes (`QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh ...`), non-shot ones only (`grep -L '^\s*shot\b'`); `qs list --all` -> "No running instances." after each run:

| Smoke | Result |
|---|---|
| 00-start | pass (exit 0) |
| 02-theme | pass |
| 04-state | pass |
| 06-content | FAIL: 2x `island.contentState expected 'rest' got 'line'` |
| 08-notifs | pass |
| 11-series | pass |
| 21-auto | pass |

- Not run (contain `shot` calls, per the dispatch): 05a, 05b, 09, 10, 11-toast, 12, 15, 16, 17, 18, 20; 19-lock-preview excluded.
- 06-content cause: `niri msg -j windows` (sizes only, no titles) shows a focused window of 2560x1440 = the output's full logical size, so a fullscreen window is on the focused output. The test instance's `Fullscreen` service sees it and puts the island in line mode (`contentState` = `line`). The launcher steps of the same smoke pass. Environmental, linked to the known gap in gotcha 10, not a regression. Re-run when nothing is fullscreen.

## Files changed
`README.md`, `config/niri/bindings.kdl`, `config/quickshell/CLAUDE.md` (new), `config/quickshell/docs/DESIGN.md`.

## Self-review
- Every IPC function/prop in CLAUDE.md compared with `IslandState.qml` lines 198-253, `Theme.qml` 143-158, `services/Notifs.qml` 82-102.
- `.flow/` not staged; `git status` clean apart from it.

## Concerns
- 06-content fails on this machine while a fullscreen window is on the focused output (above). `services/Fullscreen.qml` has no `WYSPA_TEST` guard; fixing it needs a code change, out of scope here.
- Gotchas 3, 6, 7, 9 and the `pam_faillock` defaults come from the dispatch and were not re-verified by me (no lock was exercised).
- CLAUDE.md is English (like the code comments); DESIGN section 7 is Polish.
