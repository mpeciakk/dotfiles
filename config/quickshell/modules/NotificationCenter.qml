import QtQuick
import Quickshell
import "../components"
import "../services"

// Notification center (swaync-style): a header with a Do-Not-Disturb toggle and
// Clear-all, over a scrollable list of notification history (Notifs.history).
// Click a card to remove it. Meant to live inside a Drawer opened from the bar.
Item {
    id: root

    implicitWidth: Config.notifs.centerWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col

        width: parent.width
        spacing: 10

        // Header.
        Item {
            width: parent.width
            height: 28

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Colours.text
                font.pixelSize: Config.font.xl
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                StateButton {
                    implicitWidth: dndLabel.implicitWidth + 16
                    height: 26
                    radius: Config.rounding.small
                    color: Notifs.dnd ? Colours.mauve : Colours.surface1
                    onClicked: Notifs.dnd = !Notifs.dnd

                    Text {
                        id: dndLabel

                        anchors.centerIn: parent
                        text: "DND"
                        color: Notifs.dnd ? Colours.base : Colours.subtext1
                        font.pixelSize: Config.font.sm
                        font.bold: true
                    }
                }

                StateButton {
                    implicitWidth: clearLabel.implicitWidth + 16
                    height: 26
                    radius: Config.rounding.small
                    color: Colours.surface1
                    visible: Notifs.history.length > 0
                    onClicked: Notifs.clearHistory()

                    Text {
                        id: clearLabel

                        anchors.centerIn: parent
                        text: "Clear"
                        color: Colours.subtext1
                        font.pixelSize: Config.font.sm
                    }
                }
            }
        }

        // Empty state.
        Text {
            width: parent.width
            visible: Notifs.history.length === 0
            text: "No notifications"
            color: Colours.overlay1
            font.pixelSize: Config.font.md
            horizontalAlignment: Text.AlignHCenter
            topPadding: 24
            bottomPadding: 24
        }

        // History list.
        ListView {
            width: parent.width
            height: Math.min(contentHeight, Config.notifs.historyMaxHeight)
            visible: Notifs.history.length > 0
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: Notifs.history
            }

            delegate: StateButton {
                id: card

                required property var modelData

                width: ListView.view.width
                implicitHeight: content.implicitHeight + 20
                radius: Config.rounding.large
                color: Colours.mantle

                onClicked: Notifs.removeItem(card.modelData)

                NotificationCard {
                    id: content

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    appName: card.modelData.appName
                    summary: card.modelData.summary
                    body: card.modelData.body
                    time: card.modelData.time
                }
            }
        }
    }
}
