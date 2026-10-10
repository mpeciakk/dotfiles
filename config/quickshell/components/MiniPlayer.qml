import QtQuick
import QtQuick.Effects
import Quickshell
import ".."
import "../components" as Components

// A tile with the cover, title and artist of an MPRIS player and its prev / play-pause / next buttons
// (reference 3.7). `player` is a Quickshell MprisPlayer (null is fine: the buttons are then inert).
// In test mode (WYSPA_TEST=1) the buttons only log what they would do, never touch the player.
Rectangle {
    id: root

    property var player: null

    readonly property var spec: Theme.layout.miniPlayer
    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property bool playing: root.player?.isPlaying ?? false

    implicitHeight: root.spec.art + 2 * root.spec.pad
    radius: Theme.radii.tile
    color: Theme.tile

    // The one place the player is controlled; test mode only logs.
    function perform(what: string, action: var): void {
        if (root.testMode)
            console.info("mini player (test mode): would " + what);
        else
            action();
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.spec.pad
        spacing: root.spec.gap

        Rectangle {
            id: art

            width: root.spec.art
            height: root.spec.art
            radius: root.spec.artRadius
            color: Theme.sel

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize: Qt.size(root.spec.art * 2, root.spec.art * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }
            }

            Rectangle {
                id: artMask

                anchors.fill: parent
                radius: art.radius
                visible: false
                layer.enabled: true
            }
        }

        Column {
            width: parent.width - art.width - controls.width - 2 * root.spec.gap
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spec.textGap

            Text {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.titleFont
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.artistFont
            }
        }

        Row {
            id: controls

            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                width: root.spec.skip
                height: root.spec.skip
                enabled: root.player?.canGoPrevious ?? false
                opacity: enabled ? 1 : root.spec.disabledOpacity
                onClicked: root.perform("go to the previous track", () => root.player.previous())

                Components.Icon {
                    anchors.centerIn: parent
                    name: "skip-back"
                    size: root.spec.skipIcon
                }
            }

            Rectangle {
                width: root.spec.play
                height: root.spec.play
                radius: root.spec.play / 2
                color: Theme.inverseBg

                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.perform("toggle playing", () => root.player.togglePlaying())
                }

                Components.Icon {
                    anchors.centerIn: parent
                    name: root.playing ? "pause" : "play"
                    color: Theme.inverseFg
                    size: root.spec.playIcon
                }
            }

            MouseArea {
                width: root.spec.skip
                height: root.spec.skip
                enabled: root.player?.canGoNext ?? false
                opacity: enabled ? 1 : root.spec.disabledOpacity
                onClicked: root.perform("go to the next track", () => root.player.next())

                Components.Icon {
                    anchors.centerIn: parent
                    name: "skip-forward"
                    size: root.spec.skipIcon
                }
            }
        }
    }
}
