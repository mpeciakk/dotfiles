import QtQuick
import Quickshell
import "../components"
import "../services"

// Bar VPN status: dim when no endpoint is up, bright + green dot when connected.
// Click opens the launcher's VPN menu.
StateButton {
    id: root

    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "menu", "vpn"])

    Glyph {
        anchors.fill: parent
        size: 22
        text: String.fromCodePoint(0xf099d)   // nf-md-shield_lock
        opacity: Vpn.active ? 1 : 0.4

        Behavior on opacity {
            Anim {
                curve: Appearance.anim.curves.expressiveDefaultEffects
                duration: Appearance.anim.durations.expressiveDefaultEffects
            }
        }
    }

    // Connected dot.
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 3
        anchors.bottomMargin: 3
        width: 7
        height: 7
        radius: 3.5
        color: Colours.green
        border.width: 1.5
        border.color: Colours.base
        visible: Vpn.active
        scale: Vpn.active ? 1 : 0

        Behavior on scale {
            Anim {
                curve: Appearance.anim.curves.expressiveDefaultSpatial
                duration: Appearance.anim.durations.expressiveDefaultSpatial
            }
        }
    }

    Tooltip {
        hostItem: root
        active: root.containsMouse
        text: Vpn.active ? Vpn.names.join(", ") : "VPN off"
    }
}
