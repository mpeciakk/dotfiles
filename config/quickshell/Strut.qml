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

    implicitHeight: Theme.geom.exclusive
    exclusionMode: ExclusionMode.Normal
    // The strip is given back while this screen's island is the line (fullscreen there, or hidden).
    exclusiveZone: IslandState.lineRequested(root.screen.name) ? 0 : Theme.geom.exclusive
    color: "transparent"
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "wyspa-strut"
}
