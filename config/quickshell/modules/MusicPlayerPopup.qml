import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".."
import "../services"
import "../common"

Popup {
    width: 400
    height: 83 + 16

    RowLayout {
        id: wrapper
        z: 1
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        Item {
            implicitWidth: 75
            implicitHeight: 75
            Layout.alignment: Qt.AlignVCenter

            ClippingRectangle {
                anchors.centerIn: parent
                width: 83
                height: 83
                radius: Config.radius_inner
                antialiasing: true
                layer.enabled: true
                layer.smooth: true

                Image {
                    anchors.fill: parent
                    source: Music.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    visible: (Music.trackArtUrl && Music.trackArtUrl.length > 0)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Marquee {
                text: `${Music.trackTitle}`
            }

            Text {
                text: Music.trackArtist
                color: Config.text
                opacity: 0.9
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Slider {
                    progress: Music.currentPosition / Music.trackLength

                    onRelease: progress => {}
                }

                Text {
                    text: `${Music.currentPosition} / ${Music.trackLength}`
                    color: Config.text
                    opacity: 0.9
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                IconButton {
                    icon: "󰒮"
                    onClicked: Music.previous()
                }

                IconButton {
                    icon: Music.isPlaying ? "󰏤" : "󰐊"
                    onClicked: Music.playPause()
                }

                IconButton {
                    icon: "󰒭"
                    onClicked: Music.next()
                }
            }
        }
    }
}
