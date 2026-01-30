import QtQuick
import Quickshell
import ".."
import "."

PopupWindow {
    id: popup

    default property alias contents: content.children

    property Item anchorItem: null
    anchor.item: anchorItem
    Connections {
        target: popup.anchor
        function onAnchoring() {
            if (!popup.anchorItem) {
                return;
            }

            popup.anchor.rect.x = Math.round(popup.anchorItem.width / 2 - popup.width / 2);
            popup.anchor.rect.y = Math.round(popup.anchorItem.height);
            popup.anchor.rect.width = 1;
            popup.anchor.rect.height = 1;
        }
    }

    width: content.width + 64
    height: content.height

    visible: open || wrapper.height > 0
    color: "transparent"

    property bool open: false
    signal requestClose

    Item {
        id: wrapper
        width: parent.width
        height: popup.open ? parent.height - 1 : 0

        Behavior on height {
            SequentialAnimation {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }

        clip: true

        Item {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: parent.height

            Rectangle {
                id: content
                width: parent.width - 64
                height: parent.height
                anchors.centerIn: parent
                color: Config.base_solid
                radius: 12

                Rectangle {
                    width: parent.width
                    height: 20
                    color: "#1e1e2e"
                    anchors.top: parent.top
                }
            }

            SimpleConnector {
                color: "#1e1e2e"
                type: "left"

                anchors.right: content.left
                anchors.top: content.top
            }

            SimpleConnector {
                color: "#1e1e2e"
                type: "right"

                anchors.left: content.right
                anchors.top: content.top
            }
        }
    }
}
