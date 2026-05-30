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

        // Stacked HH / MM, so it fits the narrow vertical bar.
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.timeStr.split(":")[0]
                color: Colours.text
                font.family: "monospace"
                font.pixelSize: 15
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.timeStr.split(":")[1]
                color: Colours.subtext1
                font.family: "monospace"
                font.pixelSize: 15
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
}
