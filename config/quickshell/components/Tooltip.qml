import QtQuick
import Quickshell
import "../services"

// Small hover tooltip that pops out to the right of `hostItem` (e.g. a bar
// indicator). Set `active` to the host's hover state and `text` to the content;
// it appears after a short delay so it doesn't flash. A separate PopupWindow
// because bar content can't render outside the narrow bar surface.
PopupWindow {
    id: root

    property Item hostItem
    property string text: ""
    property bool active: false
    property bool shown: false

    anchor.item: hostItem
    anchor.edges: Edges.Right
    anchor.gravity: Edges.Right

    implicitWidth: label.implicitWidth + 20
    implicitHeight: label.implicitHeight + 12
    color: "transparent"
    visible: root.shown && root.text.length > 0

    onActiveChanged: {
        if (root.active) {
            delay.restart();
        } else {
            delay.stop();
            root.shown = false;
        }
    }

    Timer {
        id: delay

        interval: 400
        onTriggered: root.shown = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Config.rounding.large
        color: Colours.surface0
        border.width: 1
        border.color: Colours.surface1

        Text {
            id: label

            anchors.centerIn: parent
            text: root.text
            color: Colours.text
            font.pixelSize: 13
        }
    }
}
