import QtQuick
import Quickshell
import Quickshell.Wayland

// The island's full-screen surface on one screen. Input is limited to the shape,
// except in modal states, where the whole surface catches clicks (click-outside closes).
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property string effState: IslandState.output === root.screen.name ? IslandState.current : "rest"
    readonly property bool modalHere: IslandState.modal && IslandState.output === root.screen.name
    readonly property string maskMode: root.modalHere ? "full" : "shape"
    readonly property var geo: IslandState.geometryFor(root.effState)

    function reportMask(): void {
        IslandState.reportMask(root.screen.name, root.maskMode);
    }

    onMaskModeChanged: root.reportMask()
    Component.onCompleted: root.reportMask()

    Connections {
        target: IslandState

        function onOutputChanged(): void {
            root.reportMask();
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wyspa"
    WlrLayershell.keyboardFocus: root.modalHere && Quickshell.env("WYSPA_TEST") !== "1" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: root.modalHere ? stage : shape.body
    }

    FocusScope {
        id: stage
        anchors.fill: parent
        focus: root.modalHere
        Keys.onEscapePressed: IslandState.close()

        MouseArea {
            anchors.fill: parent
            enabled: root.modalHere
            onClicked: IslandState.close()
        }

        IslandShape {
            id: shape
            anchors.fill: parent
            w: root.geo.w
            h: root.geo.h
            r: root.geo.r
            ears: root.geo.ears
        }
    }
}
