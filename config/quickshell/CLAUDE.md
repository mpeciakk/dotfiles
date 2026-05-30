# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Quickshell](https://quickshell.org) desktop shell configuration, written in QML (Qt Quick). Quickshell renders Wayland desktop UI (bars, widgets, popups) from declarative QML and exposes system integration types (clocks, IPC, Hyprland, and more).

This directory is the source for `~/.config/quickshell`. The `dotter` setup in the parent `dotfiles` repo symlinks it there (`.dotter/global.toml`: `"config/quickshell" = "~/.config/quickshell"`), so edits here go straight to the deployed config.

## Running

- `qs` (alias for `quickshell`) runs the `default` config, `~/.config/quickshell/shell.qml`.
- `qs -p .` runs by path from this directory without the symlink.
- `shell.qml` sets `settings.watchFiles: true`, so a running instance hot-reloads on save. There is no build step.
- For LSP, `qmlls` reads this tree via `.qmlls.ini`. The empty `.qmlls.ini` marks the project root.

## Structure

Three directories split the tree by role: `services/` (singletons), `components/` (reusable primitives), `modules/` (feature UI). `shell.qml` stays at the root because Quickshell loads it and nothing else. Cross-directory references use directory imports — from inside `modules/`, that means `import "../components"` and `import "../services"`; from the root, `import "modules"`.

- `shell.qml`: entry point, the `ShellRoot`. Quickshell loads this file and no other. Imports `"modules"`, instantiates one `Bar` and one `Border` per screen, plus a single `LauncherPanel`.
- `modules/Bar.qml`: vertical left `PanelWindow` (layer-shell bar), one per screen via `Variants { model: Quickshell.screens }` in `shell.qml`. Takes `modelData` and binds it to `screen`. Hosts `Workspaces` (top), and at the bottom the `Tray` above a stacked HH/MM clock. Owns the tray-menu `Drawer` that slides out of the bar (anchored by screen y).
- `modules/Workspaces.qml`: niri workspace chips for one output (`output: bar.screen.name`). Click focuses the workspace via `Niri.focusWorkspace`.
- `modules/Tray.qml`: system tray `Row` over `SystemTray.items` (`Quickshell.Services.SystemTray`). Left click `activate()`s, right click emits `requestMenu(handle, x)`, which `Bar.qml` routes into the `Drawer` as a notch dropdown. Items use `StateLayer` for hover/press feedback.
- `modules/TrayMenu.qml`: renders a `SystemTrayItem.menu` handle (`QsMenuOpener.children` → `QsMenuEntry`) as clickable rows; lives inside a modal `Drawer`.
- `modules/Notifications.qml`: stack of auto-expiring notification cards over `Notifs.list` (click a card to dismiss). `modules/NotificationPanel.qml` hosts it as a non-modal `Drawer` (`edge: "top-right"`) — a corner notch out of the top-right, shoulders blending into both borders, growing downward as cards arrive — a single instance on the primary screen, shown while `Notifs.count > 0`, keeping the springy notch open/close animation.
- `modules/Border.qml`: rounded "screen border" frame for one output (caelestia's border without the SDF plugin). Three thin click-through strut `PanelWindow`s reserve `Config.border.thickness` on top/right/bottom (`ExclusionMode.Normal` + explicit `exclusiveZone`; the left is already reserved by the vertical bar) so tiled windows inset. A separate full-screen, click-through (`mask: Region {}`), `WlrLayer.Bottom` overlay fills the border region with `Colours.base` and rounds the inner corners — a single `Shape`/`ShapePath` with `fillRule: ShapePath.OddEvenFill` (outer screen rectangle + inner rounded-rect subpath = a hole the desktop shows through). Geometry renderer (not `CurveRenderer`) for the hole, MSAA layer for smooth corners.
- `modules/Launcher.qml`: app launcher content — a search `TextInput` over a `ListView` of `Apps.query` results. ↑/↓ move, Enter launches, Esc closes; the field drives the list (`keyNavigationEnabled: false`). `modules/LauncherPanel.qml` wraps it in a keyboard-focused (`OnDemand`) modal `Drawer` (`edge: "bottom"`, horizontally centred) on the primary screen and exposes an `IpcHandler` (`target: "launcher"`, functions `toggle`/`open`/`close`). It's a single global instance (in `shell.qml`), not per-monitor, so there's one IPC target and one keyboard grab. Toggle from a niri keybind: `qs ipc call launcher toggle`.
- `components/Drawer.qml`: **the notch popup pattern — every dropdown/drawer must use this.** A full-screen, transparent layer-shell `PanelWindow` (`ExclusionMode.Ignore` so it overlaps the bar instead of being shoved aside) that slides a panel out to the right of the vertical bar. The panel is a single QML `Shape`, one variant per `edge`: `"top"` is the original; `"bottom"` mirrors it in Y; `"left"` (default) rotates 90° CCW (out of the vertical bar); `"right"` mirrors that in X; `"top-right"` is a corner notch (flush top + right edges, concave shoulders at top-left and bottom-right, convex bottom-left). `top`/`bottom` are positioned along the screen by `anchorX`, `left`/`right` by `anchorY`, `top-right` pins to the corner. `align` places along the cross-axis: `"center"` (default) on the anchor, `"start"` pins the near side (top/left) at it, `"end"` the far side (bottom/right). The panel sits flush with the *inner* edge of its surface, offset from the screen edge by `barSize`, so the concave shoulders flare past it onto the desktop and stay visible — `barSize` defaults to the bar width, so popups emerging from the border (launcher, notifications) set it to `Config.border.thickness`. `modal: true` (default) grabs the screen and closes on click-away (menus); `modal: false` masks input to the panel so the rest stays click-through (passive popups). Drive it with `open()`/`close()` or bind `shown`.
- `components/StateLayer.qml`: reusable hover/press highlight (`MouseArea` + translucent rounded overlay) with a Material-style ripple that expands from the press point. Inherits its parent's `radius`.
- `components/StateButton.qml`: clickable rounded surface — a `Rectangle` with a `StateLayer` baked in (ripple on top) and a `clicked(event)` signal. The interactive primitive behind tray icons, workspace chips, menu rows and notification cards; put content as children.
- `components/Icon.qml`: square `Image` preset (`PreserveAspectFit`, crisp `sourceSize`). Set `size` and `source`.
- `components/Anim.qml` / `components/CAnim.qml`: `NumberAnimation` / `ColorAnimation` presets bound to the motion tokens. Set `curve` to any `Appearance.anim.curves.*` array and override `duration`.
- `services/`: QML singletons (`pragma Singleton`). Reactive state — `Time.qml` (wraps `SystemClock`), `Notifs.qml` (a `NotificationServer` daemon exposing `list`), `Niri.qml` (reads `niri msg --json event-stream` via a `Process`/`SplitParser`), `Apps.qml` (indexes `DesktopEntries.applications` with a self-contained JS fuzzy `query`). Tokens — `Colours.qml` (Catppuccin Mocha palette), `Appearance.qml` (motion: durations + bezier curves), `Config.qml` (layout/sizing/behaviour tunables). Singletons are not global; a consumer must `import "services"` (or `"../services"` from `modules/`) before referencing the type, e.g. `Time.timeStr`.
  - `Niri.qml` keeps `workspaces` as a *structural* list (changes only on add/remove/rename) and tracks live focus/active/urgent state in separate id-keyed maps (`focusedId`, `activeByOutput`, `urgentIds`). This is deliberate: workspace chip delegates stay alive across focus switches, so flipping focus animates the existing chips instead of rebuilding them.

## Conventions

- **Notch popups:** all dropdowns/drawers slide out to the right of the vertical left bar as a rounded "notch" via `components/Drawer.qml` (concave shoulders blending into the bar). Caelestia gets this from a C++ `Caelestia.Blobs` SDF plugin; we deliberately reproduce it in pure QML `Shape` instead. Match this style for any new popup.
- **Tokens, not literals:** colours come from `Colours.*` (Catppuccin Mocha), sizes/spacing/timeouts from `Config.*`, motion from `Appearance.anim.*`. Don't reintroduce inline hex or magic numbers — add a token instead.
- **Animations:** use `Anim`/`CAnim` with `Appearance.anim` tokens, never hand-rolled `NumberAnimation` durations. These mirror caelestia's Material 3 "expressive" motion (reproduced as bezier arrays, not the C++ plugin). Pick `spatial` curves (they overshoot) for movement/size/open-close, `effects` curves for opacity/colour, `emphasized`/`standard` for neutral transitions. Positioners (`Row`/`Column`) get `add`/`move` transitions so children pop in and slide on reflow.

## Dependencies / gotchas

- QML modules rely on Quickshell's auto-discovery and version-less imports (`import Quickshell`, `import QtQuick`).
- Keep everything self-contained in this config dir. Do not import or depend on Caelestia (or any other external shell) modules/configs. Existing `Caelestia.*` imports should be replaced with local equivalents.
- Only one process can own `org.freedesktop.Notifications`. `Notifs.qml` won't receive notifications while another daemon (e.g. `swaync`) is running; stop the other daemon and Quickshell takes over automatically.

## References

- Quickshell types: https://quickshell.org/docs/v0.3.0/types/
- Qt Quick QML module: https://doc.qt.io/qt-6/qtquick-qmlmodule.html
- Caelestia shell, for examples, setups, and visuals only (do not depend on its modules or configs): https://github.com/caelestia-dots/shell
