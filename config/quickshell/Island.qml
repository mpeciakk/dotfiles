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

    // Blur (W1) covers the body and both concave ears (an ear = rect minus ellipse),
    // only while the island is glass and not collapsed to the line. A zero-sized ear
    // is an empty region, so the ears drop out when `animEar` is 0.
    // `shape` is also a Region property name, so Regions read through these aliases.
    readonly property Item islandBody: shape.body
    readonly property real cornerRadius: shape.animR
    readonly property real earSize: shape.animEar
    property Region blurShape: Region {
        Region {
            item: root.islandBody
            bottomLeftRadius: root.cornerRadius
            bottomRightRadius: root.cornerRadius
        }
        Region {
            x: root.islandBody.x - root.earSize
            y: 0
            width: root.earSize
            height: root.earSize
        }
        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Subtract
            x: root.islandBody.x - 2 * root.earSize
            y: 0
            width: 2 * root.earSize
            height: 2 * root.earSize
        }
        Region {
            x: root.islandBody.x + root.islandBody.width
            y: 0
            width: root.earSize
            height: root.earSize
        }
        Region {
            shape: RegionShape.Ellipse
            intersection: Intersection.Subtract
            x: root.islandBody.x + root.islandBody.width
            y: 0
            width: 2 * root.earSize
            height: 2 * root.earSize
        }
    }
    BackgroundEffect.blurRegion: Theme.glass && root.effState !== "line" ? root.blurShape : null

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
            lineMode: root.effState === "line"

            IslandContent {
                id: content
                anchors.fill: parent
                target: root.effState
                output: root.screen.name
                onShownChanged: IslandState.reportShown(root.screen.name, content.shown)
                Component.onCompleted: IslandState.reportShown(root.screen.name, content.shown)
            }
        }
    }
}
