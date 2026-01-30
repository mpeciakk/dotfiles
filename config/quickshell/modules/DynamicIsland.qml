import QtQuick
import ".."
import "../components"
import "../services"
import "./"

Item {
    id: root
    width: island.width
    height: 30

    property bool opened: false
    property bool leftExpanded: opened ? false : Music.isPlaying
    property bool rightExpanded: opened ? false : false

    Item {
        id: island
        anchors.centerIn: parent
        height: parent.height
        width: islandCenter.width

        Rectangle {
            id: islandLeft
            height: 30
            width: root.leftExpanded ? 50 : 20
            topLeftRadius: Config.radius_outer
            bottomLeftRadius: Config.radius_outer
            color: Config.base_solid

            anchors.right: island.left
            anchors.rightMargin: -4

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }

            Item {
                id: islandLeftContent
                enabled: root.leftExpanded
                opacity: enabled ? 1 : 0
                anchors.fill: parent

                MusicPlayer {
                    scale: islandLeftContent.enabled ? 1 : 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.InOutCubic
                        }
                    }

                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Rectangle {
            id: islandCenter
            height: 30
            width: root.opened ? 600 : Math.min(300, t_metrics.boundingRect.width + 16)
            color: Config.base_solid

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }

            TextMetrics {
                id: t_metrics
                font: activeWindow.font
                text: activeWindow.text
            }

            Text {
                id: activeWindow
                height: parent.height
                width: parent.width
                text: Niri.focusedWindowTitle
                color: Config.text
                font: Config.font
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: islandRight
            height: 30
            width: root.rightExpanded ? 50 : 20
            topRightRadius: Config.radius_outer
            bottomRightRadius: Config.radius_outer
            color: Config.base_solid

            anchors.left: island.right
            anchors.leftMargin: -4

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }

    MouseArea {
        id: tap
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        anchors.fill: root
        onClicked: {
            root.opened = !root.opened;
        }
    }

    DynamicIslandPopup {
        id: popup
        open: root.opened
        onRequestClose: {
            root.detailsOpen = false;
        }
        anchorItem: root
    }
}
