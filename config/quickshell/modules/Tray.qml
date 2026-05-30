import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../components"
import "../services"

Row {
    id: tray

    spacing: Config.tray.spacing

    // Emitted on right-click (or left-click of a menu-only item). Bar wires this
    // to a Drawer so the menu drops out of the bar as a notch.
    signal requestMenu(var handle, real x)

    // Icons pop in as apps register and slide when one leaves.
    add: Transition {
        Anim {
            property: "scale"
            from: 0
            to: 1
            curve: Appearance.anim.curves.expressiveDefaultSpatial
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
        Anim {
            property: "opacity"
            from: 0
            to: 1
            curve: Appearance.anim.curves.standard
            duration: Appearance.anim.durations.small
        }
    }
    move: Transition {
        Anim {
            properties: "x,y"
            curve: Appearance.anim.curves.expressiveDefaultSpatial
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }

    Repeater {
        model: SystemTray.items

        delegate: StateButton {
            id: item

            required property SystemTrayItem modelData

            width: Config.tray.size
            height: Config.tray.size
            radius: 6
            anchors.verticalCenter: parent?.verticalCenter
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: event => {
                const x = item.mapToItem(null, item.width / 2, 0).x;
                if (event.button === Qt.LeftButton && !item.modelData.onlyMenu)
                    item.modelData.activate();
                else if (item.modelData.hasMenu)
                    tray.requestMenu(item.modelData.menu, x);
            }

            Icon {
                anchors.centerIn: parent
                size: Config.tray.iconSize
                source: item.modelData.icon
            }
        }
    }
}
