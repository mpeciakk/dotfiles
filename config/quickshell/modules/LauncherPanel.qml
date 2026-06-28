import QtQuick
import Quickshell.Wayland
import "../components"
import "../services"

// One instance per monitor (Variants in shell.qml), each pinned to its own
// screen so no layer surface ever moves between outputs. `active` is driven by
// the global launcher state for the focused output, so the launcher opens on the
// monitor the user is on and grabs the keyboard there. Toggle over IPC:
//   qs ipc call launcher toggle
// Emits closedByUser when dismissed (Esc / click-away) so the global state resets.
Drawer {
    id: panel

    property var modelData
    property bool active: false
    property string startMenu: ""        // open straight into this menu (IPC `menu <id>`)
    signal closedByUser

    screen: modelData
    modal: true
    edge: "bottom"
    barSize: Config.border.thickness     // emerges from the bottom border, not the bar
    keyboardFocus: WlrKeyboardFocus.OnDemand
    anchorX: screen ? screen.width / 2 : 0

    onActiveChanged: active ? open() : close()
    onShownChanged: {
        if (content.item)
            shown ? content.item.activate() : content.item.reset();
        // Closed while still meant to be active ⇒ the user dismissed it
        // (Esc or click-away); tell the global state to reset.
        if (!shown && active)
            panel.closedByUser();
    }

    // Lazy: the launcher UI (and its app-list ListView) only exists while this
    // monitor's launcher is open/animating, so the hidden per-monitor instances
    // cost nothing. Stays loaded through the close animation (active || visible).
    Loader {
        id: content

        active: panel.active || panel.visible
        sourceComponent: Launcher {
            startMenu: panel.startMenu
            onClose: panel.close()
        }
        // Catch the case where the item finishes loading after shown flipped.
        onLoaded: if (panel.shown)
            item.activate()
    }
}
