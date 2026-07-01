import QtQuick
import "../components"
import "../services"

// Bar battery status: level-reflecting glyph, red when low, green when charging.
// Hidden on machines without a battery. Tooltip shows the exact percentage.
StateButton {
    id: root

    visible: Battery.available
    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    Glyph {
        anchors.fill: parent
        size: 22
        text: Battery.glyph()
        color: Battery.charging ? Colours.green : (Battery.low ? Colours.red : Colours.text)

        Behavior on color {
            CAnim {
                curve: Appearance.anim.curves.expressiveDefaultEffects
                duration: Appearance.anim.durations.expressiveDefaultEffects
            }
        }
    }

    Tooltip {
        hostItem: root
        active: root.containsMouse
        text: Math.round(Battery.percentage * 100) + "%" + (Battery.charging ? " (charging)" : (Battery.full ? " (full)" : ""))
    }
}
