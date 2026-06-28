import QtQuick
import "../components"
import "../services"

// Compact now-playing widget over the active MPRIS player (Players.active):
// cover art, title/artist, and prev / play-pause / next. Hidden when nothing is
// playing. Reusable (lock screen now, dashboard later).
Item {
    id: root

    readonly property var player: Players.active

    // Normalise the art URL: some players emit a bare path with no scheme.
    readonly property string artUrl: {
        const u = root.player?.trackArtUrl ?? "";
        if (u === "")
            return "";
        return /^[a-z][a-z0-9+.-]*:/i.test(u) ? u : "file://" + u;
    }

    implicitWidth: 360
    implicitHeight: 64
    visible: Players.hasPlayer

    Row {
        anchors.centerIn: parent
        spacing: 14

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 56
            radius: Config.rounding.large
            color: Colours.surface0
            clip: true

            Image {
                id: art

                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 112
                sourceSize.height: 112
                visible: status === Image.Ready
            }
            Glyph {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready    // shown while loading or on failure
                size: 24
                text: String.fromCodePoint(0xf0387)    // music note
                color: Colours.overlay1
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: 230
            spacing: 2

            Text {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                color: Colours.text
                font.pixelSize: Config.font.lg
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: Colours.subtext1
                font.pixelSize: Config.font.sm
                elide: Text.ElideRight
                visible: text !== ""
            }

            Row {
                spacing: 6
                topPadding: 4

                component Ctl: StateButton {
                    property string glyph: ""
                    property bool can: true

                    implicitWidth: 30
                    height: 26
                    radius: Config.rounding.small
                    effectColor: Colours.text
                    disabled: !can
                    opacity: can ? 1 : 0.4

                    Glyph {
                        anchors.fill: parent
                        size: 16
                        text: parent.glyph
                    }
                }

                Ctl {
                    glyph: String.fromCodePoint(0xf04ae)   // skip-previous
                    can: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }
                Ctl {
                    glyph: String.fromCodePoint((root.player?.isPlaying ?? false) ? 0xf03e4 : 0xf040a)   // pause / play
                    can: root.player?.canTogglePlaying ?? false
                    onClicked: root.player?.togglePlaying()
                }
                Ctl {
                    glyph: String.fromCodePoint(0xf04ad)   // skip-next
                    can: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }
        }
    }
}
