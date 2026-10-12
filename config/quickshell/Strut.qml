import QtQuick
import Quickshell
import Quickshell.Wayland

// Empty, input-transparent window that only reserves the top strip for tiled
// windows; the island itself ignores exclusion (see Island.qml).
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.notchFor(root.screen.name)?.h ?? Theme.geom.exclusive
    exclusionMode: ExclusionMode.Normal
    // The strip is given back while this screen's island is the line (fullscreen there, or hidden); on a notch
    // output only a fullscreen window gives it back.
    exclusiveZone: IslandState.exclusiveFor(root.screen.name)
    color: "transparent"
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "wyspa-strut"
}
