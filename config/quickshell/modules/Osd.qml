import QtQuick
import Quickshell
import "../components"
import "../services"

// Volume OSD: a passive notch out of the left bar (vertically centred) that pops
// in when the volume/mute changes and auto-hides. One per screen (Variants in
// shell.qml). `ready` gates out the initial binding settle so it doesn't flash
// on startup.
Drawer {
    id: root

    property var modelData
    screen: modelData
    edge: "left"
    modal: false
    anchorY: screen ? screen.height / 2 : 0

    property bool ready: false

    function poke(): void {
        if (!root.ready)
            return;
        // Only on the monitor the user is on (one Osd per screen via Variants).
        // If the focused output isn't known yet (empty at startup), don't suppress.
        if (root.screen && Niri.focusedOutput !== "" && root.screen.name !== Niri.focusedOutput)
            return;
        root.open();
        hideTimer.restart();
    }

    function volGlyph(): string {
        if (Audio.muted || Audio.volume <= 0)
            return String.fromCodePoint(0xf0581);   // volume-off
        if (Audio.volume < 0.34)
            return String.fromCodePoint(0xf057f);   // volume-low
        if (Audio.volume < 0.67)
            return String.fromCodePoint(0xf0580);   // volume-medium
        return String.fromCodePoint(0xf057e);       // volume-high
    }

    Component.onCompleted: readyTimer.start()

    Timer {
        id: readyTimer

        interval: 1000
        onTriggered: root.ready = true
    }
    Timer {
        id: hideTimer

        interval: 1500
        onTriggered: root.close()
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.poke();
        }
        function onMutedChanged(): void {
            root.poke();
        }
        // A default-sink switch (Bluetooth/USB) emits volume/muted from the new
        // node — suppress the OSD briefly so it doesn't flash on device changes.
        function onSinkChanged(): void {
            root.ready = false;
            readyTimer.restart();
        }
    }

    Column {
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Audio.muted ? "—" : Math.round(Audio.volume * 100) + "%"
            color: Colours.text
            font.pixelSize: 12
        }

        // Vertical level bar — fills bottom-up.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 8
            height: 130
            radius: 4
            color: Colours.surface1

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * Math.max(0, Math.min(1, Audio.volume))
                radius: parent.radius
                color: Audio.muted ? Colours.overlay1 : Colours.mauve

                Behavior on height {
                    Anim {
                        curve: Appearance.anim.curves.standard
                        duration: Appearance.anim.durations.small
                    }
                }
            }
        }

        Glyph {
            anchors.horizontalCenter: parent.horizontalCenter
            size: 26
            text: root.volGlyph()
            opacity: Audio.muted ? 0.5 : 1
        }
    }
}
