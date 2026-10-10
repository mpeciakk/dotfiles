pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "lib/island.js" as L
import "services"

// The island's state machine: which state it is in, on which output, and the geometry that implies.
Singleton {
    id: root

    property string current: "rest"
    property string output: ""
    property bool hidden: false
    property int centerHeight: Theme.geom.center.hMin
    property bool badge: false
    property string osdKind: "volume"

    readonly property bool modal: L.isModal(root.current)

    readonly property var timeouts: ({
        osd: Theme.motion.osdTimeoutMs,
        toast: Theme.motion.toastTimeoutMs,
        powerDone: Theme.motion.powerDoneMs
    })

    function geometryFor(s: string): var {
        return L.geometry(s, Theme.geom, { centerHeight: root.centerHeight, badge: root.badge });
    }

    // IPC passes arbitrary strings; only own keys of PRIORITY are real states.
    function request(s: string): bool {
        if (s === "rest") {
            root.close();
            return true;
        }
        if (!Object.keys(L.PRIORITY).includes(s) || !L.accepts(root.current, s))
            return false;
        root.output = Niri.focusedOutput;
        root.current = s;
        if (s in root.timeouts) {
            autoClose.interval = root.timeouts[s];
            autoClose.restart();
        } else {
            autoClose.stop();
        }
        return true;
    }

    function close(): void {
        autoClose.stop();
        root.current = "rest";
    }

    function toggle(s: string): void {
        if (root.current === s)
            root.close();
        else
            root.request(s);
    }

    function toggleHidden(): void {
        root.hidden = !root.hidden;
    }

    Timer {
        id: autoClose
        onTriggered: root.close()
    }

    IpcHandler {
        target: "island"

        readonly property string current: root.current
        readonly property string output: root.output
        readonly property bool hidden: root.hidden
        readonly property int targetW: root.geometryFor(root.current).w
        readonly property int targetH: root.geometryFor(root.current).h

        function open(s: string): void {
            root.request(s);
        }

        function toggle(s: string): void {
            root.toggle(s);
        }

        function close(): void {
            root.close();
        }

        function hide(): void {
            root.toggleHidden();
        }
    }
}
