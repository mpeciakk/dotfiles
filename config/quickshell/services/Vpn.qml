pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live VPN state for the bar indicator. Reuses the launcher menu's `menus/vpn.sh`
// (single source of truth) — `list` already prints the active flag per endpoint;
// we poll it and expose whether any endpoint is up plus the active names.
Singleton {
    id: root

    property bool active: false
    property var names: []         // labels of the currently-active endpoints

    readonly property string script: Qt.resolvedUrl("../menus/vpn.sh").toString().replace(/^file:\/\//, "")

    function refresh(): void {
        // Don't restart an in-flight run (toggling running false→true races the
        // teardown and can drop the poll); just start one if idle. A watchdog
        // kills a hung run so the poll can recover.
        if (!proc.running) {
            proc.running = true;
            watchdog.restart();
        }
    }

    Process {
        id: proc

        command: ["bash", root.script, "list"]

        stdout: StdioCollector {
            id: out

            onStreamFinished: {
                const active = out.text.split("\n").filter(l => l.length > 0).filter(l => l.split("\t")[0] === "1").map(l => l.split("\t")[1]);
                root.names = active;
                root.active = active.length > 0;
            }
        }
    }

    Timer {
        running: true
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // If a `vpn.sh list` run hangs (e.g. tailscale/systemctl blocking), kill it
    // so the next poll isn't permanently skipped.
    Timer {
        id: watchdog

        interval: 8000
        onTriggered: if (proc.running)
            proc.running = false
    }
}
