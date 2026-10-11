# polishA — Task 20 follow-up + doc imprecisions (standalone task, not in plan)

Worktree: /home/m/dotfiles/.claude/worktrees/feat+wyspa-shell, branch worktree-feat+wyspa-shell. Code under config/quickshell/.

## 1. WYSPA_TEST guard on Fullscreen detection (REQUIRED)
Problem: `services/Fullscreen.qml` reads real niri/toplevel state. On pc a fullscreen window (a steam game, a 2560x1440 window on the focused output) puts the smoke instance in line mode, so every smoke that reads rest content or shoots fails/shoots the line (06-content, 09-rest, 05a contentState, shot checks).
Do: in test mode (same `WYSPA_TEST` mechanism the other services/components use — find the idiom with `grep -rn WYSPA_TEST config/quickshell --include=*.qml`) `Fullscreen.outputs` must be `[]` (real detection off). `tests/smoke/20-line.sh` (and anything else relying on real fullscreen state) must be independent of the real fullscreen state: drop any BASE baseline against real outputs; drive line mode only through the existing IPC (see what 20-line.sh uses: `lineOn` etc.). Keep real detection unchanged outside test mode. Add a proof of the guard (smoke assertion, or a source-grep node test in the style of tests/lock.test.mjs only if no runtime way exists).

## 2. maskMode "line" value (REQUIRED)
Island.qml / IslandState.qml expose a test-readable `maskMode` (check the real name). Safety rule from Task 20: in line mode only the 400x28 top-centre zone is input; modal states take the full mask. Make it report `full` when modal here, `line` when line mode wanted, else `shape` (adapt to actual names) and add smoke assertions (20-line.sh): in line mode `maskMode` is `line`; after leaving line mode it is `shape`; with a modal state opened via IPC (launcher is fine — NOT lock, NOT power perform) it is `full`.

## 3. Docs imprecisions in config/quickshell/CLAUDE.md and docs/DESIGN.md (text only)
- CLAUDE.md ~line 100: tests/niri-validate.sh validates against `hosts/pc/niri-output.kdl` (the pc host's output config) on every machine — say so instead of "this host's output.kdl".
- CLAUDE.md ~112 and DESIGN.md ~259: the blur region (`blurShape`, `BackgroundEffect.blurRegion`) lives in `Island.qml`, not `IslandShape.qml`; move the phrase to the Island.qml row; IslandShape.qml has path, shadow and inner glow.
- CLAUDE.md ~99: tests/shot.sh crops around the island (by targetW/targetH), not "the focused monitor".
- CLAUDE.md gotcha 10 (fullscreen/line mode): say the Fullscreen service is disabled under WYSPA_TEST so smokes are independent of real fullscreen windows; add one line on the maskMode values.

## Verify
`node --test 'tests/*.test.mjs'`; then `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh tests/smoke/<x>.sh` for: 20-line, 06-content, 02, 04, 08, 11-series, 21. No shot-containing smoke except 20-line if it already has a shot (budget: at most 1 live shot total). A fullscreen window currently exists on the focused output: 06-content and 20-line MUST pass despite it — that is the proof. Confirm `qs list --all` shows nothing after each run (~2 s wait); only `qs kill -p <worktree>/config/quickshell`. Never run 19-lock-preview, never `island lock`, no niri actions, no notify-send.

Commit: stage `config/quickshell` only (not .flow/), message `quickshell: smokes independent of real fullscreen windows, maskMode line, doc fixes` + trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
Report: .flow/sdd/2026-10-10-wyspa-shell/task-polishA-report.md (RED/GREEN evidence for the guard and maskMode assertions).
