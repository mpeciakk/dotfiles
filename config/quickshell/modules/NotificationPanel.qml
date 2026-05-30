import QtQuick
import Quickshell
import "../components"
import "../services"

// Notifications as a corner notch out of the top-right, with concave shoulders
// blending into both the top and right borders. A non-modal Drawer that grows
// downward as cards arrive. Single instance on the primary screen (Notifs.list
// is global, so per-monitor would duplicate the stack). Keeps the springy notch
// open/close animation.
Drawer {
    id: root

    screen: Quickshell.screens[0] ?? null
    edge: "top-right"
    modal: false
    barSize: Config.border.thickness     // emerges from the border corner, not the bar
    shown: Notifs.count > 0

    Notifications {}
}
