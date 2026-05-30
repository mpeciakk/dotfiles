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
        left: true
        right: true
    }

    implicitHeight: Config.bar.height
    color: Colours.base

    Workspaces {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Config.bar.margin

        output: bar.screen.name
    }

    Text {
        anchors.centerIn: parent

        text: Time.timeStr
        color: Colours.text
        font.family: "monospace"
        font.pixelSize: 14
    }

    Tray {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Config.bar.margin

        onRequestMenu: (handle, x) => {
            trayMenu.handle = handle;
            trayDrawer.anchorX = x;
            trayDrawer.open();
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
        id: notifDrawer

        screen: bar.screen
        modal: false
        anchorX: bar.width - 200
        shown: Notifs.count > 0

        Notifications {}
    }
}
