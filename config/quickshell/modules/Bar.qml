import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

PanelWindow {
    id: bar

    property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
    }

    implicitWidth: Config.bar.width
    color: Colours.base

    // Workspaces at the top.
    Workspaces {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Config.bar.margin

        output: bar.screen.name
    }

    // Tray + clock at the bottom.
    Column {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Config.bar.margin
        spacing: 10

        Tray {
            anchors.horizontalCenter: parent.horizontalCenter

            onRequestMenu: (handle, y) => {
                trayMenu.handle = handle;
                trayDrawer.anchorY = y;
                trayDrawer.open();
            }
        }

        VpnIndicator {}

        VolumeIndicator {}

        // Optional status widgets — each hides itself when unsupported
        // (no battery / no NetworkManager). Click the network icon for the
        // Wi-Fi + Bluetooth management drawer.
        NetworkIndicator {
            onClicked: {
                networkDrawer.anchorY = mapToItem(null, 0, height / 2).y;
                networkDrawer.open();
            }
        }

        BatteryIndicator {}

        // Stacked HH / MM, so it fits the narrow vertical bar. Click → calendar.
        StateButton {
            id: clockButton

            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: clock.implicitWidth + 8
            implicitHeight: clock.implicitHeight + 6
            radius: Config.rounding.small

            onClicked: {
                calendarDrawer.anchorY = clockButton.mapToItem(null, 0, clockButton.height / 2).y;
                calendarDrawer.open();
            }

            Column {
                id: clock

                anchors.centerIn: parent
                spacing: -2

                SwapText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.timeStr.split(":")[0]
                    color: Colours.text
                    font.family: "monospace"
                    font.pixelSize: Config.font.xl
                    font.bold: true
                }

                SwapText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Time.timeStr.split(":")[1]
                    color: Colours.subtext1
                    font.family: "monospace"
                    font.pixelSize: Config.font.xl
                }
            }
        }

        // Notification bell — last, below the clock.
        NotifIndicator {
            onClicked: {
                centerDrawer.anchorY = mapToItem(null, 0, height / 2).y;
                centerDrawer.open();
            }
        }
    }

    Drawer {
        id: trayDrawer

        screen: bar.screen

        TrayMenu {
            id: trayMenu

            onClosed: trayDrawer.close()
        }
    }

    Drawer {
        id: calendarDrawer

        screen: bar.screen

        Calendar {}
    }

    Drawer {
        id: centerDrawer

        screen: bar.screen

        NotificationCenter {}
    }

    Drawer {
        id: networkDrawer

        screen: bar.screen

        NetworkMenu {
            active: networkDrawer.shown
        }
    }
}
