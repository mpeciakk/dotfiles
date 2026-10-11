## Global Constraints

- All paths below are relative to `config/quickshell/` inside the worktree; run every command from that directory.
- No Caelestia or other external shell modules. Version-less imports (`import QtQuick`, `import Quickshell`).
- **Zero magic numbers / colours in UI QML** (root `*.qml` except `Theme.qml`, `states/`, `components/`): every px, ms, colour, opacity and font size comes from `Theme`. Allowed literals: `0`, `1`, `2`, `0.5`. Enforced by `tests/no-magic.test.mjs`. A value the task needs that is not yet a token → add it to `lib/theme.js` `defaults` under `layout.<state>` (state-specific) or the matching global group, with the value from the reference doc.
- Colours in `lib/theme.js` are produced as lowercase `#aarrggbb` strings (QML `color` cannot parse CSS `rgba()`).
- `lib/*.js` files start with `.pragma library`, never `.import` other files, and export only via top-level `function` and `var` (the node loader exposes only those).
- Fonts: `Theme.fonts.ui` / `Theme.fonts.mono`, default `"JetBrainsMono Nerd Font"` for both (W5).
- Icons: only via `components/Icon.qml` (Lucide-style paths in `lib/icons.js`, stroke `Theme.sizes.iconStroke` = 1.6).
- Out of scope (W8): warm light, screen recording, `/` file search, tray. Do not add niri binds except in Task 22 (W9).
- IPC: `IpcHandler` functions need typed args/returns (`string|int|bool|real|color|void`); only typed properties are readable with `qs ipc prop get`. Instance flags go before the subcommand: `qs ipc -p <dir> call|prop get …`.
- `Region { item: x }` tracks only `x`'s own geometry — animate the item itself. Regions have no concave corners: an ear = rect minus ellipse (`intersection: Intersection.Subtract`).
- **Test mode** (`Quickshell.env("WYSPA_TEST") === "1"`, exported by `tests/smoke.sh`): island keyboard focus is always `WlrKeyboardFocus.None`, power commands only `console.info` what they would run, and the lock action only logs. Every task that adds keyboard focus, a power command or a lock path implements this guard. Never trigger power actions or the session lock from a test.
- **Config path**: `Theme.qml` reads `Quickshell.env("WYSPA_CONFIG")` if set, else `~/.config/dotfiles/config.json`. Smoke runs use a fresh temp copy of `tests/fixtures/config.json` (check files may rewrite that copy; Theme hot-reloads it). Never edit the live `~/.config/dotfiles/config.json` (it is a symlink into the main checkout).
- **Allowed log warnings** live in `tests/smoke/allowed-warnings.txt` (one ERE per line, each preceded by a `#` comment saying why). Adding a pattern requires a justification in the task report; never widen the grep in `smoke.sh`.
- The pre-rewrite code is at commit `ff1f02d` — read it with `git show ff1f02d:config/quickshell/<path>` (never `HEAD~1`).
- niri config is validated only through `tests/niri-validate.sh` (the repo's `config.kdl` includes a per-host `output.kdl` that exists only after dotter deploy).
- Screenshots (`tests/shot.sh`) capture the focused monitor of the user's live session and niri also copies each one to the clipboard — take at most the ones a task asks for.
- Commit after each task with `git add -A .` (plus `../niri` when niri files changed) and a `quickshell:` prefixed message ending in the `Co-Authored-By` trailer the controller provides.


## Group 1 — Theme (gate after Task 2)

---

### Task 5a: Island surface, morphing shape, strut, mask, focus

**Files:**
- Create: `Island.qml`, `IslandShape.qml`, `Strut.qml`, `tests/smoke/05a-surface.sh`
- Modify: `shell.qml` (per screen: `Wallpaper`, `Strut`, `Island`), `IslandState.qml` (readable `maskMode: string` = "shape"|"full" for the island on `output`, reported by Island like `contentState` in Task 6 — add `reportMask(output: string, m: string)`), `lib/theme.js` (new tokens), `config/niri/layout.kdl` (`../niri/layout.kdl` from here: delete the whole `struts { … }` block — it compensated the old Border)

Reference: §2.1–§2.3, §2.6–§2.7, §2.9, §7 R13, R20, R25; DESIGN W3.

**Interfaces:**
- Consumes: `IslandState.current/output/hidden/modal/geometryFor/close`, `Theme.*`.
- Produces: `IslandShape.qml` properties `w: real`, `h: real`, `r: real`, `ears: bool`, `fillColor: color`, `lineMode: bool`, readonly `body: Item` (an Item whose own `x/y/width/height` follow the animated shape — Regions track only an item's own geometry), readonly `animW/animH/animR/animEar: real`, default property alias `content` (a `clip: true` item of size `animW × animH`). `Island.qml`: `required property var modelData` (ShellScreen), readonly `effState: string` (`IslandState.current` if `IslandState.output === screen.name` or current is `rest`, else `rest`; the `line` override comes in Task 20), keyboard focus `WlrKeyboardFocus.Exclusive` iff `IslandState.modal && IslandState.output === screen.name && Quickshell.env("WYSPA_TEST") !== "1"`, else `None`. `Strut.qml`: `required property var modelData`, `exclusiveZone: Theme.geom.exclusive` (Task 20 makes it 0 in line mode).

- [ ] **Step 1: Write the check** — `tests/smoke/05a-surface.sh`:

```bash
expect island maskMode shape
shot surface-rest
call island open launcher
wait_ms 700
expect island maskMode full
shot surface-launcher
call island close
wait_ms 700
expect island maskMode shape
call island open toast
wait_ms 700
expect island maskMode shape
call island close
```

- [ ] **Step 2: Run** `tests/smoke.sh tests/smoke/05a-surface.sh` → FAIL (`maskMode` not found; shots show no island).
- [ ] **Step 3: Implement**
  - `Island.qml`: `PanelWindow`, `screen: modelData`, anchors all four edges, `color: "transparent"`, `exclusionMode: ExclusionMode.Ignore`, `WlrLayershell.layer: WlrLayer.Overlay`, `WlrLayershell.namespace: "wyspa"`. Shape centred horizontally at `y = 0`. `mask: Region { item: modal-on-this-screen ? fullItem : shape.body }`. A full-size `MouseArea` below the shape, enabled only when modal on this screen, calls `IslandState.close()` (R20). `Keys.onEscapePressed: IslandState.close()` on a focus scope focused while keyboard focus is Exclusive.
  - `IslandShape.qml`: `w/h/r` each with `Behavior { NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.morphMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.morphCurve } }`. Fill = ONE `Shape` (`preferredRendererType: Shape.CurveRenderer`) with one `ShapePath` following §2.3 (concave ear arcs, convex bottom corners) — no seams. The ear radius is its own animated value `animEar` = `ears ? min(Theme.geom.ear, animH - animR) : 0` (clamped, so the path stays valid during line↔rest morphs — §2.3 warns `h − r ≥ e`), animated over `Theme.motion.earFadeMs`. Fill colour `lineMode ? Theme.line : Theme.islandBg`, `ColorAnimation` `Theme.motion.bgColorMs`.
  - `Strut.qml`: `PanelWindow` anchored top/left/right, `implicitHeight: Theme.geom.exclusive`, `exclusionMode: ExclusionMode.Normal`, `exclusiveZone: Theme.geom.exclusive`, transparent, `mask: Region {}`, `WlrLayershell.layer: WlrLayer.Bottom`, namespace `wyspa-strut`.
- [ ] **Step 4: Run** `tests/smoke.sh tests/smoke/05a-surface.sh`, `node --test 'tests/*.test.mjs'`, `tests/niri-validate.sh`; Read the PNGs → rest 200×36 with ears at top centre, launcher 680×356; all PASS.
- [ ] **Step 5: Commit** — `git add -A . ../niri` — `quickshell: island surface, morphing shape, strut`
