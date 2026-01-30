import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"

Scope {
    id: notificationPopup

    PanelWindow {
        id: root
        visible: (Notifications.popupList.length > 0)
        // screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:notificationPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusiveZone: 0

        anchors {
            top: true
            right: true
            bottom: true
        }

        mask: Region {
            item: listview.contentItem
        }

        color: "transparent"
        implicitWidth: 300

        NotificationListView {
            id: listview
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
                rightMargin: 4
                topMargin: 4
            }
            implicitWidth: parent.width - Appearance.sizes.elevationMargin * 2
            popup: true
        }
    }
}
