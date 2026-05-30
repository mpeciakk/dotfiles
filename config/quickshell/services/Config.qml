pragma Singleton

import QtQuick
import Quickshell

// Layout, sizing and behaviour tunables — the knobs you'd reach for to retheme
// the shell. Colours live in Colours.qml, motion in Appearance.qml.
Singleton {
    readonly property QtObject bar: QtObject {
        readonly property int height: 32
        readonly property int margin: 12
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
        readonly property int shoulder: 14
        readonly property int radius: 14
        readonly property int padding: 8
    }

    // Rounded "screen border" frame around the desktop. The top edge is the bar;
    // thickness is reserved on the other three sides so tiled windows inset.
    readonly property QtObject border: QtObject {
        readonly property int thickness: 10
        readonly property int rounding: 25
    }
}
