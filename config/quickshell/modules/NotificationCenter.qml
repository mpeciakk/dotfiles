import QtQuick
import Quickshell
import "../components"
import "../services"

// Notification center (swaync-style): a header with a Do-Not-Disturb toggle and
// Clear-all, over a scrollable list of notification history (Notifs.history).
// Click a card to remove it. Meant to live inside a Drawer opened from the bar.
Item {
    id: root

    implicitWidth: 360
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
                font.pixelSize: 15
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
                        font.pixelSize: 12
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
                        font.pixelSize: 12
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
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            topPadding: 24
            bottomPadding: 24
        }

        // History list.
        ListView {
            width: parent.width
            height: Math.min(contentHeight, 480)
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
                implicitHeight: cardCol.implicitHeight + 20
                radius: Config.rounding.large
                color: Colours.mantle

                onClicked: Notifs.removeItem(card.modelData)

                Column {
                    id: cardCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 3

                    Item {
                        width: parent.width
                        height: appText.implicitHeight

                        Text {
                            id: appText

                            anchors.left: parent.left
                            text: card.modelData.appName
                            color: Colours.overlay2
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatDateTime(card.modelData.time, "hh:mm")
                            color: Colours.overlay1
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        width: parent.width
                        text: card.modelData.summary
                        color: Colours.text
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    Text {
                        width: parent.width
                        text: card.modelData.body
                        color: Colours.subtext1
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
