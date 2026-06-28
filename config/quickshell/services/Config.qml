pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Layout, sizing and behaviour tunables — the knobs you'd reach for to retheme
// the shell. Colours live in Colours.qml, motion in Appearance.qml.
//
// Per-user / per-host values (wallpaper, lock, vpn) live in the shared
// ~/.config/dotfiles/config.json (deployed by dotter) so the same shell runs
// unchanged on multiple machines. Missing/invalid file → built-in defaults.
Singleton {
    id: root

    property var data: ({})

    function expandUser(p: string): string {
        return p && p.startsWith("~") ? Quickshell.env("HOME") + p.slice(1) : p;
    }

    FileView {
        path: `${Quickshell.env("HOME")}/.config/dotfiles/config.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                root.data = ({});
            }
        }
        onLoadFailed: root.data = ({})
    }

    readonly property string wallpaper: root.expandUser(root.data.wallpaper ?? "~/.config/dotfiles/wp2.jpg")

    readonly property QtObject bar: QtObject {
        readonly property int width: 44       // vertical bar thickness
        readonly property int margin: 10
    }

    readonly property QtObject workspaces: QtObject {
        readonly property int spacing: 6
        readonly property int chipHeight: 22
        readonly property real focusedScale: 1.12
    }

    readonly property QtObject tray: QtObject {
        readonly property int spacing: 4
        readonly property int size: 26
        readonly property int iconSize: 18
    }

    readonly property QtObject notifs: QtObject {
        readonly property int width: 320
        readonly property int defaultTimeout: 5000
    }

    readonly property QtObject launcher: QtObject {
        readonly property int width: 460
        readonly property int itemHeight: 52
        readonly property int maxVisible: 7
    }

    readonly property QtObject drawer: QtObject {
        readonly property int padding: 8
        readonly property int radius: 20              // convex body corners
        readonly property int shoulder: 20            // concave blend into the bar (matches body)
        // Content sits `padding` inside the body, so its corners are concentric
        // with the body when content radius = radius - padding (= rounding.large).
    }

    // Corner radii for clickable surfaces (tray icons, menu/launcher rows,
    // notification cards).
    readonly property QtObject rounding: QtObject {
        readonly property int small: 6
        readonly property int large: 12
    }

    // Rounded "screen border" frame around the desktop. The left edge is the bar;
    // thickness is reserved on the other three sides so tiled windows inset.
    readonly property QtObject border: QtObject {
        readonly property int thickness: 10
        readonly property int rounding: 12     // inner hole corners (screen edge stays square)
    }

    readonly property QtObject lock: QtObject {
        readonly property string avatar: root.expandUser((root.data.lock && root.data.lock.avatar) || "")  // avatar image path; empty → initial letter
        readonly property string name: (root.data.lock && root.data.lock.name) || ""                       // display name; empty → $USER
        readonly property int timeout: (root.data.lock && root.data.lock.timeout) ?? 300                    // auto-lock after this many seconds idle (0 = off)
    }
}
