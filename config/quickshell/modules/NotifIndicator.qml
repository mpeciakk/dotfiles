import QtQuick
import Quickshell
import "../components"
import "../services"

// Bar notification button: a bell (tinted for the dark bar) with a count badge
// for active notifications, dimmed when DND is on. Click opens the notification
// center (wired by the bar). Hover shows a tooltip.
StateButton {
    id: root

    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    Glyph {
        anchors.fill: parent
        size: 22
        text: String.fromCodePoint(Notifs.dnd ? 0xf009b : 0xf009a)   // bell-off / bell
        opacity: Notifs.dnd ? 0.5 : 1
    }

    // Count badge.
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 2
        anchors.topMargin: 2
        width: 14
        height: 14
        radius: 7
        color: Colours.mauve
        visible: Notifs.count > 0

        Text {
            anchors.centerIn: parent
            text: Notifs.count
            color: Colours.base
            font.pixelSize: 9
            font.bold: true
        }
    }

    Tooltip {
        hostItem: root
        active: root.containsMouse
        text: Notifs.dnd ? "Do Not Disturb" : Notifs.history.length + " notifications"
    }
}
