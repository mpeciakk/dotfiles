pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../lib/fullscreen.js" as F

// Which outputs currently show a fullscreen window (the island collapses to the line there).
// The toplevel list is read inside the binding, so a window turning fullscreen, moving to
// another screen or closing re-evaluates it; so do niri's windows and active workspaces.
Singleton {
    id: root

    readonly property var outputs: F.fullscreenOutputs(
        ToplevelManager.toplevels.values.map(t => ({
            fullscreen: t.fullscreen,
            title: t.title,
            appId: t.appId,
            screens: t.screens.map(s => s.name)
        })),
        Niri.windowList,
        Niri.activeByOutput
    )

    function on(name: string): bool {
        return root.outputs.includes(name);
    }
}
