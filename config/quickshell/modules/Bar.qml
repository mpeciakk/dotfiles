import QtQuick
import Quickshell
import ".."

PanelWindow {
    id: root
    required property var modelData

    property list<Item> leftItems
    property list<Item> centerItems
    property list<Item> rightItems

    anchors {
        top: true
        left: true
        right: true
    }
    screen: modelData
    implicitHeight: 30
    color: "transparent"

    margins {
        top: Config.padding
        left: Config.padding
        right: Config.padding
    }

    BarSection {
        id: left
        items: root.leftItems
        color: Config.base_solid
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
    }

    BarSection {
        id: center
        items: root.centerItems
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
    }

    BarSection {
        id: right
        items: root.rightItems
        color: Config.base_solid
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
    }
}
