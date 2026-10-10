import QtQuick
import Quickshell
import ".."
import "../lib/power.js" as P

// The one gate to the machine's power: perform(kind) is the ONLY code in the tree that runs a power
// command (Theme.tokens.power.commands) or asks for the session lock (IslandState.lockRequested). The power
// menu (states/Power.qml) and the lock screen both instantiate this and call perform(); neither runs
// anything itself. What perform() does is decided by P.plan(): in test mode (WYSPA_TEST=1) it only logs
// what it would do. tests/power.test.mjs pins all of this to this file.
Item {
    id: root

    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"

    function perform(kind: string): void {
        const p = P.plan(kind, Theme.tokens.power.commands, root.testMode);
        console.info(p.message);
        if (!p.execute)
            return;
        if (p.lock)
            IslandState.lockRequested();
        else
            Quickshell.execDetached(p.argv);
    }
}
