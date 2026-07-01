import QtQuick
import "../components"
import "../services"

// Bar network status: wifi / ethernet glyph, dimmed when offline. Hidden on
// machines without NetworkManager. Tooltip shows the active connection name.
StateButton {
    id: root

    visible: Network.available
    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    Glyph {
        anchors.fill: parent
        size: 22
        text: Network.glyph()
        opacity: Network.connected ? 1 : 0.4

        Behavior on opacity {
            Anim {
                curve: Appearance.anim.curves.expressiveDefaultEffects
                duration: Appearance.anim.durations.expressiveDefaultEffects
            }
        }
    }

    Tooltip {
        hostItem: root
        active: root.containsMouse
        text: Network.connected ? Network.name : "Offline"
    }
}
