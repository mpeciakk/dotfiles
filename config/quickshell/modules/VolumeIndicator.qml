import QtQuick
import Quickshell
import "../components"
import "../services"

// Bar volume control: icon reflects level/mute, scroll changes volume, click
// toggles mute.
StateButton {
    id: root

    implicitWidth: Config.tray.size
    height: Config.tray.size
    radius: Config.rounding.small
    anchors.horizontalCenter: parent?.horizontalCenter

    onClicked: Audio.toggleMute()

    function volGlyph(): string {
        if (Audio.muted || Audio.volume <= 0)
            return String.fromCodePoint(0xf0581);   // volume-off
        if (Audio.volume < 0.34)
            return String.fromCodePoint(0xf057f);   // volume-low
        if (Audio.volume < 0.67)
            return String.fromCodePoint(0xf0580);   // volume-medium
        return String.fromCodePoint(0xf057e);       // volume-high
    }

    Glyph {
        anchors.fill: parent
        size: 22
        text: root.volGlyph()
        opacity: Audio.muted ? 0.5 : 1
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        // Scale by notches (120 = one mouse step = 5%) so touchpad scroll, which
        // arrives as many small deltas, doesn't slam the volume in one gesture.
        onWheel: event => Audio.changeVolume(event.angleDelta.y / 120 * 0.05)
    }

    Tooltip {
        hostItem: root
        active: root.containsMouse
        text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
    }
}
