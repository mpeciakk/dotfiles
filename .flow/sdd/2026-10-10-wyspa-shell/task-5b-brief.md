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

### Task 5b: Island material — blur region, shadow, ring, gloss + niri rule

**Files:**
- Create: `tests/smoke/05b-material.sh`
- Modify: `Island.qml`, `IslandShape.qml`, `lib/theme.js` (`sizes.sheenGlow 30`, shadow padding token). The niri side is already on main (commit before the run: `layer-rule` for `^wyspa$` with `xray false`, `saturation 2.0`, and `blur { passes 3; offset 5; }`) — do not touch niri files here.

Reference: §2.4, §2.5, §2a, §7 R2, R11, R13, R16, R23; DESIGN W1, W2.

**Interfaces:**
- Consumes: `IslandShape.body/animW/animH/animR/animEar/lineMode`, `Theme` material keys.
- Produces: nothing new for later tasks (visual only).

- [ ] **Step 1: Write the check** — `tests/smoke/05b-material.sh`:

```bash
call island open control
wait_ms 700
shot material-glass
printf '{"wallpaper":"~/.config/dotfiles/wp2.jpg","lock":{"timeout":0},"island":{"glass":false}}' > "$CFG"
wait_ms 900
shot material-solid
call island close
```

- [ ] **Step 2: Run**; Read both PNGs → RED: flat fill, no gloss/ring/shadow; identical shots.
- [ ] **Step 3: Implement**
  - Blur (W1): `BackgroundEffect.blurRegion` (from `Quickshell.Wayland`) set **only** when `Theme.glass && !lineMode`, else `null`. Region = `Region { Region { item: body; bottomLeftRadius: animR; bottomRightRadius: animR } <left ear> <right ear> }`, ear = `Region { x: body.x - e; y: 0; width: e; height: e }` followed by `Region { shape: RegionShape.Ellipse; intersection: Intersection.Subtract; x: body.x - 2*e; y: 0; width: 2*e; height: 2*e }` (mirror for the right), `e = animEar`; no ear regions when `animEar` is 0.
  - Shadow (W2): drawn only *outside* the shape — `MultiEffect` with `shadowEnabled`, `shadowColor: Theme.shadowColor`, `shadowVerticalOffset: Theme.shadowY`, `blurMax: Theme.shadowBlur`, `shadowBlur: 1`, applied to an opaque copy of the path and masked with `maskEnabled + maskInverted` by the same path, so the translucent interior is not darkened. The effect's source item is sized to the shape bounds plus `Theme.shadowBlur + Theme.shadowY` padding — never the full-screen window (a 3840×2160 FBO per morph frame on DP-2).
  - Ring (R13): a `Rectangle` the size of `body`, `color: "transparent"`, `border.color: Theme.ring`, `border.width: Theme.sizes.ringWidth`, bottom radii `animR`.
  - Gloss (§2a, R23): above content, clipped to body, `opacity: Theme.sheen`: vertical `Gradient` stops `0 → Theme.sheenTop`, `0.45 → Theme.sheenMid`, `1 → transparent`; 1 px outline `Theme.sheenOutline`; 1 px bottom-edge highlight `Theme.sheenEdge` following the bottom radius; inner glow `Theme.sheenGlow` with blur radius `Theme.sizes.sheenGlow`. Ring, gloss and shadow hidden when `lineMode` (R16).
- [ ] **Step 4: Run** `tests/smoke.sh tests/smoke/05b-material.sh`, `node --test 'tests/*.test.mjs'`; Read PNGs → glass shot: translucent fill, gloss gradient brighter at the top, 1 px ring, soft shadow outside only (no dark halo inside); solid shot: opaque fill, no gloss, and the area around the island NOT blurred. All PASS.
- [ ] **Step 5: Commit** — `git add -A .` — `quickshell: island glass material`
