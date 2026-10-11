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

### Task 1: Clean slate + test harness

**Files:**
- Delete: `modules/` (all), `components/` (all), `services/Colours.qml`, `services/Appearance.qml`, `services/Config.qml`, `services/Vpn.qml` (only the deleted VPN indicator used it; the VPN launcher menu uses `menus/vpn.sh`), `shell.qml` contents (rewritten)
- Keep untouched: `services/{Apps,Audio,Battery,Menus,Network,Niri,Notifs,Players,Time}.qml`, `menus/`, `assets/pam.d/passwd`, `docs/`
- Create: `shell.qml`, `tests/qmljs.mjs`, `tests/no-magic.test.mjs`, `tests/smoke.sh`, `tests/shot.sh`, `tests/niri-validate.sh`, `tests/smoke/00-start.sh`, `tests/smoke/allowed-warnings.txt`, `tests/fixtures/config.json`

**Interfaces:**
- Produces: `load(rel: string, extra?: object) → vm context` and `plain(x) → JSON-roundtripped x` from `tests/qmljs.mjs`; `tests/smoke.sh <check-file>` providing `call <target> <fn> [args…]`, `expect <target> <prop> <value>`, `wait_ms <n>`, `shot <name>`, `$DIR`, `$CFG` (the temp config copy) to the sourced check file; `tests/shot.sh <name>` → prints `/tmp/wyspa-shots/<name>.png`; `tests/niri-validate.sh` → exit 0 iff niri accepts the repo's niri config.

- [ ] **Step 1: Write the guard test** — `tests/no-magic.test.mjs`:

```js
import { test } from "node:test";
import assert from "node:assert/strict";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const ALLOWED = new Set(["0", "1", "2", "0.5"]);

function uiFiles() {
    const files = readdirSync(root).filter(f => f.endsWith(".qml") && f !== "Theme.qml");
    for (const d of ["states", "components", "modules"]) {
        const p = join(root, d);
        if (existsSync(p))
            for (const f of readdirSync(p))
                if (f.endsWith(".qml")) files.push(join(d, f));
    }
    return files;
}

const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/\/\/.*$/gm, "");

test("UI QML takes colours, sizes and times only from Theme", () => {
    const offenders = [];
    for (const f of uiFiles()) {
        strip(readFileSync(join(root, f), "utf8")).split("\n").forEach((line, i) => {
            if (/^\s*import\s/.test(line)) return;
            if (/#[0-9a-fA-F]{3,8}\b|rgba?\(|Qt\.rgba|Qt\.hsla/.test(line))
                offenders.push(`${f}:${i + 1}: colour literal: ${line.trim()}`);
            const code = line.replace(/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`/g, '""');
            for (const m of code.matchAll(/(?<![\w.$#])\d+(?:\.\d+)?(?![\w.])/g))
                if (!ALLOWED.has(m[0])) offenders.push(`${f}:${i + 1}: number ${m[0]}: ${line.trim()}`);
        });
    }
    assert.deepEqual(offenders, []);
});
```

- [ ] **Step 2: Run it against the old tree** — `node --test 'tests/*.test.mjs'`
  Expected: FAIL — the assertion lists offenders in `modules/*.qml` / `components/*.qml` (old UI has literals).

- [ ] **Step 3: Write the loader** — `tests/qmljs.mjs`:

```js
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

// Loads a QML JS library (`.pragma library`) into a fresh context. Top-level
// `function`s and `var`s become properties of the returned context.
export function load(rel, extra = {}) {
    const file = join(root, rel);
    const src = readFileSync(file, "utf8").replace(/^\s*\.pragma\s+library\s*$/m, "");
    const ctx = vm.createContext({ console, ...extra });
    vm.runInContext(src, ctx, { filename: file });
    return ctx;
}

// Objects from the vm context have a foreign prototype; normalise before deepStrictEqual.
export const plain = x => JSON.parse(JSON.stringify(x));
```

- [ ] **Step 4: Write the smoke runner** — `tests/smoke.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Usage: tests/smoke.sh <check-file>
# Starts this config as its own quickshell instance in test mode, sources the
# check file (call / expect / wait_ms / shot, $DIR, $CFG), fails on any logged
# warning or error not listed in tests/smoke/allowed-warnings.txt, and always
# kills the instance.
set -uo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0
export WYSPA_TEST=1 QSG_RENDER_LOOP=threaded
CFG="$(mktemp /tmp/wyspa-config.XXXXXX.json)"
cp "$DIR/tests/fixtures/config.json" "$CFG"
export WYSPA_CONFIG="$CFG"
trap 'qs kill -p "$DIR" >/dev/null 2>&1; rm -f "$CFG"' EXIT

call() { qs ipc -p "$DIR" call "$@" >/dev/null 2>&1 || { echo "FAIL: call $*"; FAILED=1; }; }
expect() {
    local got
    got="$(qs ipc -p "$DIR" prop get "$1" "$2" 2>&1)"
    if [ "$got" == "$3" ]; then echo "ok: $1.$2 = $3"; else echo "FAIL: $1.$2 expected '$3' got '$got'"; FAILED=1; fi
}
wait_ms() { sleep "$(awk "BEGIN{print $1/1000}")"; }
shot() { "$DIR/tests/shot.sh" "$1" || FAILED=1; }

qs kill -p "$DIR" >/dev/null 2>&1
qs -p "$DIR" -d >/dev/null 2>&1
sleep 2
# shellcheck source=/dev/null
source "$1"
LOG="$(qs log -p "$DIR" 2>&1)"
BAD="$(printf '%s\n' "$LOG" | grep -E '\b(WARN|ERROR|FATAL|CRIT)' | grep -v -E -f <(grep -v -E '^\s*(#|$)' "$DIR/tests/smoke/allowed-warnings.txt") || true)"
if [ -n "$BAD" ]; then echo "FAIL: instance logged:"; echo "$BAD"; FAILED=1; fi
exit $FAILED
```

  `tests/smoke/allowed-warnings.txt` (environment noise on `pc`, not shell bugs):

```
# IPC property change signals are reported as warnings by qs ipc.
Signal detected
# Quickshell.Networking without NetworkManager (pc has none running).
Could not find an available backend
# Quickshell.Bluetooth without BlueZ (pc has none running).
Failed to create DBusObjectManagerInterface for "org\.bluez"
# The user's running shell owns org.freedesktop.Notifications during development.
Could not register notification server
# Themed icon names absent from the icon theme (menu rows, some apps).
Could not load icon
# No xdg-desktop-portal host registration for this instance.
Failed to register with host portal
```

  (When the notification server warning turns out to be two lines in Task 8, add the second line's exact text there, with a comment.)

  `tests/fixtures/config.json`:

```json
{
  "wallpaper": "~/.config/dotfiles/wp2.jpg",
  "lock": { "timeout": 0 }
}
```

- [ ] **Step 5: Write the screenshot and niri helpers** — `tests/shot.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Usage: tests/shot.sh <name> — crop around the island on the focused monitor.
# niri also copies the screenshot to the clipboard. Refuses while the user's
# session is locked (the old shell's lock target answers "true").
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(qs ipc call lock isLocked 2>/dev/null || true)" == "true" ]; then echo "shot: session locked — ask the user to unlock"; exit 1; fi
mkdir -p /tmp/wyspa-shots
RAW="/tmp/wyspa-shots/$1-full.png"
W="$(qs ipc -p "$DIR" prop get island targetW 2>/dev/null || echo 800)"
H="$(qs ipc -p "$DIR" prop get island targetH 2>/dev/null || echo 500)"
[[ "$W" =~ ^[0-9]+$ ]] || W=800
[[ "$H" =~ ^[0-9]+$ ]] || H=500
SCALE="$(niri msg -j focused-output | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["logical"]["scale"])')"
niri msg action screenshot-screen --show-pointer false --path "$RAW" >/dev/null
sleep 0.5
python3 -I - "$RAW" "/tmp/wyspa-shots/$1.png" "$W" "$H" "$SCALE" <<'PY'
import sys
from PIL import Image
raw, out, w, h, scale = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), float(sys.argv[5])
im = Image.open(raw); iw, ih = im.size
cw = min(iw, int((w + 200) * scale)); ch = min(ih, int((h + 120) * scale))
im.crop(((iw - cw) // 2, 0, (iw + cw) // 2, ch)).save(out)
PY
echo "/tmp/wyspa-shots/$1.png"
```

  `tests/niri-validate.sh` (chmod +x):

```bash
#!/usr/bin/env bash
# Validates the repo's niri config with this host's output.kdl in place.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$REPO"/config/niri/*.kdl "$TMP"/
cp "$REPO/hosts/pc/niri-output.kdl" "$TMP/output.kdl"
niri validate -c "$TMP/config.kdl"
```

- [ ] **Step 6: Delete the old UI and write the empty shell** — remove the files listed above; `shell.qml`:

```qml
import QtQuick
import Quickshell

ShellRoot {
    settings.watchFiles: true
}
```

`tests/smoke/00-start.sh` (a check file is plain bash sourced by the runner):

```bash
# The config starts and logs nothing bad (the runner checks the log).
true
```

- [ ] **Step 7: Verify the runner really catches warnings and cleans up** — temporarily add `Component.onCompleted: console.warn("probe")` to `ShellRoot`, run `tests/smoke.sh tests/smoke/00-start.sh`.
  Expected: exit 1 and the `probe` line printed under "FAIL: instance logged:". If the probe is not caught, look at the real `qs log -p .` output and fix the level pattern in `smoke.sh` until it is. Remove the probe. Then make a check file with an unbound variable (`echo $NOPE`), run it, and confirm `qs list` shows no instance for this path afterwards (the EXIT trap). Run `tests/niri-validate.sh` → exit 0.

- [ ] **Step 8: Run everything green**
  Run: `node --test 'tests/*.test.mjs' && tests/smoke.sh tests/smoke/00-start.sh`
  Expected: both PASS (exit 0).

- [ ] **Step 9: Commit** — `git add -A . && git commit -m "quickshell: clean slate for Wyspa + node/smoke test harness"`
