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
    property bool badge: Notifs.unread > 0
    property string osdKind: "volume"
    property real osdValue: 0
    property bool osdMuted: false
    // False while the audio and backlight values settle after startup; no OSD until then.
    property bool osdReady: false
    // "shape" | "full": input-mask mode of the island on `output`, reported by that screen's Island.
    property string maskMode: "shape"
    // output name -> the state whose content layer is fully entered ("" while a transition runs).
    property var shownByOutput: ({})
    // output name -> whether that output's Rest layer is loaded and lit (true from enter start until the island leaves rest).
    property var restLoadedByOutput: ({})

    // The launcher, as the IPC sees it. The lit Launcher layer owns the field and mirrors its mode, row
    // count and selected row here; `launcherQuery` is the one text both sides write. `launcherMenuRequest`
    // is a menu id the launcher enters (and clears) as soon as it is lit.
    property string launcherQuery: ""
    property string launcherMode: "apps"
    property int launcherCount: 0
    property string launcherResult: ""
    property string launcherMenuRequest: ""

    // The power menu: the label powerDone shows (set when a button is confirmed), and the request for the
    // session lock. Nothing is connected to lockRequested until the lock screen (Task 19).
    property string powerLabel: ""
    signal lockRequested

    // What the user sees: the island on `output`, or at rest the one on the focused output.
    readonly property string contentState: root.shownByOutput[root.current === "rest" ? Niri.focusedOutput : root.output] ?? ""

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

    function showOsd(kind: string, value: real, muted: bool): void {
        if (!root.osdReady)
            return;
        root.osdKind = kind;
        root.osdValue = value;
        root.osdMuted = muted;
        root.request("osd");
    }

    function reportMask(output: string, m: string): void {
        if (output === root.output)
            root.maskMode = m;
    }

    function reportShown(output: string, s: string): void {
        root.shownByOutput = Object.assign({}, root.shownByOutput, { [output]: s });
    }

    function reportRest(output: string, loaded: bool): void {
        root.restLoadedByOutput = Object.assign({}, root.restLoadedByOutput, { [output]: loaded });
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

    Timer {
        running: true
        interval: Theme.motion.osdTimeoutMs
        onTriggered: root.osdReady = true
    }

    // The series ends when the toast does: whatever the island moves on to (rest, centre).
    property bool toastShown: false
    onCurrentChanged: {
        if (root.toastShown && root.current !== "toast")
            Notifs.resetSeries();
        root.toastShown = root.current === "toast";
        if (root.current === "center")
            Notifs.markRead();
    }

    // The toast needs request() to accept it (not while the centre or a higher state is up) and no DND;
    // a notification the toast does not show never counts towards "+N".
    Connections {
        target: Notifs

        function onArrived(): void {
            // What lands in an open centre is read as it lands, or the badge would count it once the centre closes.
            if (root.current === "center")
                Notifs.markRead();
            if (Notifs.dnd)
                return;
            if (!root.request("toast"))
                Notifs.resetSeries();
        }
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.showOsd("volume", Audio.volume, Audio.muted);
        }

        function onMutedChanged(): void {
            root.showOsd("volume", Audio.volume, Audio.muted);
        }
    }

    Connections {
        target: Brightness

        function onValueChanged(): void {
            if (Brightness.available)
                root.showOsd("brightness", Brightness.value, false);
        }
    }

    IpcHandler {
        target: "island"

        readonly property string current: root.current
        readonly property string output: root.output
        readonly property bool hidden: root.hidden
        readonly property string maskMode: root.maskMode
        readonly property string contentState: root.contentState
        readonly property bool restLoaded: root.restLoadedByOutput[Niri.focusedOutput] ?? false
        readonly property int targetW: root.geometryFor(root.current).w
        readonly property int targetH: root.geometryFor(root.current).h
        readonly property string launcherQuery: root.launcherQuery
        readonly property int launcherCount: root.launcherCount
        readonly property string launcherMode: root.launcherMode
        readonly property string launcherResult: root.launcherResult
        readonly property string powerLabel: root.powerLabel

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

        function launcherSetQuery(q: string): void {
            root.launcherQuery = q;
        }

        function launcherMenu(id: string): void {
            root.launcherMenuRequest = id;
            root.request("launcher");
        }
    }
}
