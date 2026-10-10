pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight brightness from sysfs. `available` is false (and `value` stays 0) on machines
// without a backlight, e.g. the desktop. Setting goes through brightnessctl.
Singleton {
    id: root

    // The first backlight device directory, "" when there is none.
    property string dir: ""
    readonly property bool available: root.dir !== ""
    property real level: 0
    property real maxLevel: 0
    readonly property real value: root.maxLevel > 0 ? Math.max(0, Math.min(1, root.level / root.maxLevel)) : 0

    function set(v: real): void {
        Quickshell.execDetached(["brightnessctl", "set", Math.round(v * 100) + "%"]);
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -d \"$d\" ] && echo \"$d\" && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.dir = text.trim()
        }
    }

    FileView {
        path: root.available ? `${root.dir}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.level = parseInt(text())
    }

    FileView {
        path: root.available ? `${root.dir}/max_brightness` : ""
        onLoaded: root.maxLevel = parseInt(text())
    }
}
