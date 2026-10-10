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
    exclusiveZone: Theme.geom.exclusive
    color: "transparent"
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "wyspa-strut"
}
