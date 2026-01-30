import QtQuick
import ".."

Rectangle {
    id: island

    property list<Item> items

    radius: Config.radius_outer

    color: "transparent"

    height: parent.height
    width: content.width + Config.padding * 4

    Row {
        id: content
        width: childrenRect.width
        height: parent.height
        spacing: Config.padding

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: Config.padding * 2
            rightMargin: Config.padding * 2
        }
    }

    Component.onCompleted: {
        for (var item of items) {
            item.parent = content;
            item.anchors.verticalCenter = content.verticalCenter;
        }
    }
}
