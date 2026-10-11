# Wyspa — the Quickshell desktop shell

One morphing island at the top of every screen: rest, OSD, toast, notification centre, launcher, control panel,
media, power menu, session lock. Design source of truth: `docs/DESIGN.md` (Polish); the HTML prototypes are in
`docs/prototypes/`. Quickshell 0.3.2, Qt 6.12, niri.

Dotter deploys `config/quickshell` into `~/.config/quickshell` file by file (symlinks per file, directories are real).
A new file in the repo is not visible to the running shell until `dotter deploy`. After deploying:
`systemctl --user restart quickshell`. There is no live reload of the QML (`shell.qml` sets `settings.watchFiles: false`):
a reload while the session is locked would release the lock without PAM (the new instance starts unlocked and unlocks
the old one), and dotter symlinks make every write in the repo a reload. Only `config.json` is watched (a `FileView`).

## Running

- `qs -p . -d` — this checkout as its own detached instance (from this directory); `qs -p .` stays in the foreground.
- `qs log -p .` — its log. `qs list --all` — what runs. `qs kill -p <dir>` — stop that instance; never a bare `qs kill`
  (it would kill the live shell).
- Config: `~/.config/dotfiles/config.json` (key `island` overrides tokens, hot-reloaded); `WYSPA_CONFIG` points elsewhere.

## Tests

- `node --test 'tests/*.test.mjs'` — pure logic (`lib/*.js` through `tests/qmljs.mjs`) and source-grep guards.
- `tests/smoke.sh tests/smoke/<x>.sh` — starts a test instance (`WYSPA_TEST=1`, temp config copy), runs the check file
  (`call`, `expect`, `wait_ms`, `shot`), fails on any logged WARN/ERROR not listed in `tests/smoke/allowed-warnings.txt`,
  always kills the instance. Run it as `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh …` (a crash otherwise leaves an
  orphan reporter process).
- `tests/shot.sh <name>` — crop around the island (by `targetW` / `targetH`) to `/tmp/wyspa-shots/<name>.png` (real screenshot of the live session).
- `tests/niri-validate.sh` — validates `config/niri/*.kdl` with `hosts/pc/niri-output.kdl` (the `pc` host's output config) on every machine; run it after editing niri files.
- Smokes with a `shot` line take real screenshots; `19-lock-preview.sh` shows the lock card in a plain window.
  Never call `island lock` from a test.

## Structure

| Path | What it is |
|---|---|
| `shell.qml` | `ShellRoot`: `Lock`, and per screen `Wallpaper`, `Strut`, `Island`; references the lazy singletons |
| `Theme.qml` | singleton: tokens (`lib/theme.js`) merged with the host config, mode, glass level, IPC `theme` |
| `IslandState.qml` | singleton: state machine, timers, OSD, line mode, launcher/lock hooks, IPC `island` |
| `Island.qml` | per-screen full-screen panel; input mask = the shape (full in modal states, hover zone (plus the body while it grows) in line mode); blur region (`blurShape`, `BackgroundEffect.blurRegion`) |
| `IslandShape.qml` | the silhouette: one path with ears, shadow, inner glow |
| `IslandContent.qml` | one layer per state (`sources`), cross-fade |
| `Strut.qml` | empty window that holds the exclusive zone (36 px, 0 in line mode) |
| `Wallpaper.qml` | wallpaper per screen |
| `Lock.qml`, `LockPreview.qml` | `WlSessionLock` + PAM; the preview shows the card without locking |
| `lib/` | pure JS (`.pragma library`): `theme`, `island`, `niri`, `fullscreen`, `notifs`, `power`, `lock`, `slider`, `fuzzy`, `calc`, `icons`, `autotheme` |
| `states/` | `Rest`, `Osd`, `Toast`, `Center`, `Launcher`, `Control`, `Media`, `Power`, `PowerDone`, `LockCard` |
| `components/` | `Icon`, `MiniPlayer`, `PowerActions` |
| `services/` | `Niri`, `Fullscreen`, `Apps`, `Menus`, `Notifs`, `Audio`, `Brightness`, `Network`, `Battery`, `Players`, `Time`, `AutoTheme` |
| `menus/` | launcher action-menu scripts (`cliphist.sh`, `vpn.sh`) |
| `assets/pam.d/` | PAM service for the lock |

## Conventions

- Theme-only literals: every px, ms, colour, opacity and font size in UI QML (root `*.qml` except `Theme.qml`,
  `states/`, `components/`) comes from `Theme`. Allowed literals: `0`, `1`, `2`, `0.5`. `tests/no-magic.test.mjs` fails on
  anything else. A value that is not a token yet goes into `lib/theme.js` `defaults` (`layout.<state>` or a global group).
- Colours in `lib/theme.js` are lowercase `#aarrggbb` (QML `color` cannot parse CSS `rgba()`).
- `lib/*.js`: `.pragma library`, no imports, only top-level `function` / `var`.
- Icons only through `components/Icon.qml` (paths in `lib/icons.js`).
- Adding a state: (1) geometry row in `lib/theme.js` (`geom`), (2) `lib/island.js` `PRIORITY` (and `MODAL` if it takes
  the keyboard), (3) `IslandContent.sources` entry, (4) `states/X.qml`. Then a smoke in `tests/smoke/`.
- Test mode is decided in ONE place per side effect (`PowerActions.perform()`, `Lock.engageLock()`, the per-component
  `testMode` guard) and pinned by source-grep tests (`tests/power.test.mjs`, `tests/lock.test.mjs`). Never weaken them.

## IPC

Typed args and returns only. Instance flag before the subcommand: `qs ipc -p <dir> call <target> <fn> [args]`,
`qs ipc -p <dir> prop get <target> <prop>`. Only typed `readonly property` values are readable.

### `island` (`IslandState.qml`)

| Function | Does |
|---|---|
| `open(s: string)` | go to state `s` if its priority allows it (`rest` closes) |
| `toggle(s: string)` | close when already in `s`, else `open(s)` |
| `close()` | back to `rest` |
| `hide()` | toggle the hidden line mode on all screens |
| `launcherSetQuery(q: string)` | set the launcher query (tests) |
| `launcherMenu(id: string)` | open the launcher on action menu `id` (`clipboard`, `vpn`) |
| `lock()` | ask for the session lock (test mode: log only) |
| `unlock()` | recovery hatch: drop the session lock without PAM |

States: `rest`, `media`, `osd`, `toast`, `control`, `power`, `center`, `powerDone`, `launcher` (`lib/island.js` `PRIORITY`).

| Property | Type | Meaning |
|---|---|---|
| `current`, `output` | string | current state, output it is on |
| `hidden`, `locked` | bool | user-hidden line mode, session lock engaged |
| `maskMode`, `lineOn`, `contentState` | string | input mask mode of the current output, outputs in line mode (comma list), state whose content is shown |
| `restLoaded` | bool | rest content loaded on the focused output (test) |
| `targetW`, `targetH` | int | geometry of `current` (`tests/shot.sh` crops by it) |
| `launcherQuery`, `launcherMode`, `launcherResult` | string | launcher state (tests) |
| `launcherCount` | int | rows in the launcher list |
| `powerLabel` | string | label shown by `powerDone` |

### `theme` (`Theme.qml`)

| Function / property | Meaning |
|---|---|
| `setMode(m: string)` | `dark` / `light` override |
| `setLevel(l: string)` | glass level override: `subtelne`, `mocne`, `ciekłe` |
| `mode`, `level` (string) | resolved mode and glass level |
| `fg`, `islandBg` (color) | resolved colours (tests read them to check a theme change) |

### `notifs` (`services/Notifs.qml`)

| Function / property | Meaning |
|---|---|
| `inject(app, summary, body: string)` | push a notification into history without D-Bus (tests) |
| `dnd(on: bool)` | do-not-disturb |
| `clear()` | clear the history |
| `count`, `unread`, `series` (int), `dndOn` (bool) | history size, unread badge, toast series, DND state |

Several of these properties exist only for tests (`restLoaded`, `contentState`, `maskMode`, `lineOn`, `target*`, `launcher*`).

## niri binds

`config/niri/bindings.kdl`: `Mod+Space` → `island toggle launcher`, `Mod+Shift+V` → `island launcherMenu clipboard`,
`Mod+L` → `island lock`. The other binds (control, centre, media, power, hide, brightness keys) are commented there
with their conflicts. Blur: the shell sets the blur region itself (`ext-background-effect`); the `layer-rule`
for `namespace="^wyspa$"` in `config/niri/window_rules.kdl` has `xray false` and `saturation`, deliberately no `blur true`.

## Gotchas

1. `Region { item: x }` tracks only `x`'s own geometry: animate the item itself. No concave corners in a Region: an ear
   is a rect minus an ellipse (`intersection: Intersection.Subtract`).
2. IPC: typed args/returns only; instance flags before the subcommand (`qs ipc -p <dir> call …`).
3. Quickshell 0.3.2 parses `on<Capital>…` property and `Behavior` names as signal handlers and segfaults
   (hence `Theme.onAccentFade`, not `onAccent`).
4. Files in `states/` and `components/` need `import ".."` to see the root singletons. `Icon` from `states/`:
   `import "../components" as Components` (unqualified fails on Qt 6.12). `import Quickshell.Networking` shadows the
   `Network` service: import it `as QsNetworking`.
5. Lazy singletons (`Niri`, `Apps`, `Fullscreen`, `AutoTheme`) run only when referenced: keep them referenced
   from `shell.qml`. `ToplevelManager` fills lazily.
6. Notification `image://qsimage` URLs die with the `Notification` object (not tracked): stored snapshots drop only those (`storedSource()`) and keep file-path and `image://icon` images, else `appIcon`.
   The toast reads the image synchronously inside the handler, never `asynchronous`.
7. niri posts its own notification for every screenshot and the test instance is the daemon: take the shot last (the
   `shot` line is the last line of a smoke and nothing is asserted after the first one; `tests/smoke.test.mjs` pins it),
   or assert relative values. `tests/shot.sh` removes the stale image and waits for the new one.
8. Smokes: `QS_DISABLE_CRASH_HANDLER=1 tests/smoke.sh …`. `WYSPA_TEST=1` sets keyboard focus to None and turns every
   side effect (power commands, lock, `sh -c`, `wl-copy`, player / volume / brightness controls, app launch,
   `focusWindow`) into a log line.
9. The lock: recovery is `qs ipc -p <dir> call island unlock` (from a TTY first
   `export XDG_RUNTIME_DIR=/run/user/1000`). `loginctl unlock-session` does NOT work. `pam_faillock` defaults: deny=3,
   unlock after 600 s. UNVERIFIED (not tried live): if the shell dies while locked, the compositor keeps the blank lock
   and a restarted shell starts unlocked; the likely recovery is `systemctl --user restart quickshell`, then
   `qs ipc call island lock` and authenticate (or `island unlock`).
10. A fullscreen window on an output puts its island in line mode. `services/Fullscreen.qml` is disabled under
    `WYSPA_TEST` (`outputs` is `[]`), so smokes are independent of real fullscreen windows; they reach line mode only
    through IPC `hide`. `maskMode`: `full` in a modal state, `line` while the line is wanted (input is the 400x28 hover
    zone, plus the body while it grows), else `shape`.
11. Test-only readable props (`restLoaded`, `contentState`, `maskMode`, …) are there for smokes; do not build features on them.
