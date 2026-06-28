import QtQuick
import Quickshell
import "../components"
import "../services"

// Renders a system tray item's context menu (a QsMenuHandle) as clickable rows.
// Designed to live inside a Drawer.
Column {
    id: root

    property var handle: null    // QsMenuHandle from SystemTrayItem.menu
    property int menuWidth: 220
    signal closed

    spacing: 2

    QsMenuOpener {
        id: opener

        menu: root.handle ?? null
    }

    Repeater {
        model: opener.children

        delegate: Item {
            id: entry

            required property var modelData

            implicitWidth: root.menuWidth
            implicitHeight: modelData.isSeparator ? 9 : 28

            // separator
            Rectangle {
                visible: entry.modelData.isSeparator
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 1
                color: Colours.surface1
            }

            // entry row
            StateButton {
                anchors.fill: parent
                visible: !entry.modelData.isSeparator
                radius: Config.rounding.small
                disabled: !entry.modelData.enabled

                onClicked: {
                    entry.modelData.triggered();
                    if (!entry.modelData.hasChildren)
                        root.closed();
                }

                Icon {
                    id: icon

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16
                    width: visible ? size : 0    // collapse so text aligns left when iconless
                    visible: entry.modelData.icon !== ""
                    source: entry.modelData.icon
                }

                Text {
                    anchors.left: icon.right
                    anchors.leftMargin: 8
                    anchors.right: chevron.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.text ?? ""
                    color: entry.modelData.enabled ? Colours.text : Colours.overlay0
                    font.pixelSize: Config.font.md
                    elide: Text.ElideRight
                }

                Text {
                    id: chevron

                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.modelData.hasChildren
                    text: "›"
                    color: Colours.text
                    font.pixelSize: Config.font.xxl
                }
            }
        }
    }
}
