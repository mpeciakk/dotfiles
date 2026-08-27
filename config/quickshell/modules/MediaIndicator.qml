import QtQuick
import "../components"
import "../services"

// Bar media status: a music-note glyph, dimmed when paused / bright when
// playing. Hidden when no MPRIS player is available. Tooltip shows the current
// track; click opens the Media notch drawer.
StateButton {
    id: root

    visible: Players.hasPlayer
    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    Glyph {
        anchors.fill: parent
        size: 22
        text: String.fromCodePoint(0xf0387)   // music note
        opacity: (Players.active?.isPlaying ?? false) ? 1 : 0.4

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
        text: Players.active?.trackTitle || Players.active?.trackArtist || "Media"
    }
}
