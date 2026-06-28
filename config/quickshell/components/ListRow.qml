import QtQuick
import "../services"

// A selectable list row: leading icon, label + sublabel, and an optional trailing
// state dot. Built on StateButton (hover/press/ripple + `clicked`). Used as the
// delegate in SearchList for the launcher, menus and config screens. Transparent
// so SearchList's gliding highlight shows through.
StateButton {
    id: root

    property string iconSource: ""
    property alias label: labelText.text
    property alias sublabel: subText.text
    property int dot: -1                  // -1 none · 0 hollow (off) · 1 filled (on)
    property real rowHeight: Config.launcher.itemHeight

    implicitWidth: Config.launcher.width
    width: ListView.view ? ListView.view.width : implicitWidth
    height: rowHeight
    radius: Config.rounding.large
    color: "transparent"

    Icon {
        id: rowIcon

        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        size: parent.height - 18
        source: root.iconSource
        visible: root.iconSource !== ""
    }

    Rectangle {
        id: dotItem

        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: root.dot >= 0
        width: 10
        height: 10
        radius: 5
        color: root.dot === 1 ? Colours.green : "transparent"
        border.width: root.dot === 1 ? 0 : 2
        border.color: Colours.overlay0
    }

    Column {
        anchors.left: rowIcon.visible ? rowIcon.right : parent.left
        anchors.leftMargin: rowIcon.visible ? 12 : 16
        anchors.right: dotItem.visible ? dotItem.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            id: labelText

            width: parent.width
            color: Colours.text
            font.pixelSize: Config.font.lg
            elide: Text.ElideRight
        }

        Text {
            id: subText

            width: parent.width
            color: Colours.overlay1
            font.pixelSize: Config.font.sm
            elide: Text.ElideRight
            visible: text !== ""
        }
    }
}
