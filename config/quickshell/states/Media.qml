import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import ".."
import "../components" as Components
import "../services"

// The media state (reference 3.3): cover, title and artist of the active MPRIS player, an equaliser while it
// plays, and prev / play-pause / next. It is not the MiniPlayer component: that one is a tile (own background,
// 60 px high, 40 px cover, 38 px play button, no equaliser) for the control panel; here the island is the
// background and the sizes differ. Sizes they share are read from layout.miniPlayer, the rest from layout.media.
// No player, or one without a track: a "Nic nie gra" placeholder instead. A paused track keeps its controls,
// which is how it is resumed. In test mode (WYSPA_TEST=1) the buttons only log, never touch the player.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.media
    readonly property var shared: Theme.layout.miniPlayer
    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property var player: Players.active
    readonly property bool hasTrack: (root.player?.trackTitle ?? "") !== ""
    readonly property bool playing: root.player?.isPlaying ?? false

    // The one place the player is controlled; test mode only logs.
    function perform(what: string, action: var): void {
        if (root.testMode)
            console.info("media (test mode): would " + what);
        else
            action();
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasTrack
        text: "Nic nie gra"
        color: Theme.fgMuted
        font.family: Theme.fonts.ui
        font.pixelSize: root.spec.emptyFont
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.shared.pad
        anchors.rightMargin: root.shared.pad
        visible: root.hasTrack
        spacing: root.shared.gap

        Rectangle {
            id: art

            Layout.preferredWidth: root.spec.art
            Layout.preferredHeight: root.spec.art
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
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: root.shared.textGap

            Text {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.fg
                font.family: Theme.fonts.ui
                font.pixelSize: root.shared.titleFont
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.shared.artistFont
            }
        }

        // The equaliser's bars run one cycle at shifted phases, like the one on the rest island.
        Row {
            id: eq

            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: root.spec.eqMarginRight
            visible: root.playing
            spacing: root.spec.eqGap

            Repeater {
                model: root.spec.eqDelayMs

                Item {
                    id: bar

                    required property int modelData

                    // Fraction of the full bar height.
                    property real level: root.spec.eqScaleMin

                    width: root.spec.eqBarW
                    height: root.spec.eqH

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * bar.level
                        color: Theme.accent
                    }

                    SequentialAnimation {
                        running: eq.visible && root.active

                        // A negative delay starts the cycle part-way in; the same steady state is a later start.
                        PauseAnimation { duration: (Theme.motion.eqMs + bar.modelData) % Theme.motion.eqMs }
                        SequentialAnimation {
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: bar
                                property: "level"
                                to: 1
                                duration: Theme.motion.eqMs / 2
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: bar
                                property: "level"
                                to: root.spec.eqScaleMin
                                duration: Theme.motion.eqMs / 2
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                width: root.shared.skip
                height: root.shared.skip
                enabled: root.player?.canGoPrevious ?? false
                opacity: enabled ? 1 : root.shared.disabledOpacity
                onClicked: root.perform("go to the previous track", () => root.player.previous())

                Components.Icon {
                    anchors.centerIn: parent
                    name: "skip-back"
                    size: root.shared.skipIcon
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
                    size: root.shared.playIcon
                }
            }

            MouseArea {
                width: root.shared.skip
                height: root.shared.skip
                enabled: root.player?.canGoNext ?? false
                opacity: enabled ? 1 : root.shared.disabledOpacity
                onClicked: root.perform("go to the next track", () => root.player.next())

                Components.Icon {
                    anchors.centerIn: parent
                    name: "skip-forward"
                    size: root.shared.skipIcon
                }
            }
        }
    }
}
