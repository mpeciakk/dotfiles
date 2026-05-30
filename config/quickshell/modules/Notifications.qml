import QtQuick
import Quickshell.Services.Notifications
import "../components"
import "../services"

// Stack of notification cards, meant to live inside a (non-modal) Drawer so the
// notifications drop out of the bar as a notch. Each card auto-expires.
Column {
    id: root

    property int cardWidth: Config.notifs.width

    width: cardWidth
    spacing: 8

    // Cards pop in and the stack slides to close gaps when one leaves.
    add: Transition {
        Anim {
            property: "opacity"
            from: 0
            to: 1
            curve: Appearance.anim.curves.standard
            duration: Appearance.anim.durations.small
        }
        Anim {
            property: "scale"
            from: 0.85
            to: 1
            curve: Appearance.anim.curves.expressiveDefaultSpatial
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }
    move: Transition {
        Anim {
            properties: "x,y"
            curve: Appearance.anim.curves.emphasized
            duration: Appearance.anim.durations.normal
        }
    }

    Repeater {
        model: Notifs.list

        delegate: StateButton {
            id: card

            required property Notification modelData

            width: root.cardWidth
            implicitHeight: layout.implicitHeight + 20
            radius: 12
            color: Colours.mantle

            onClicked: card.modelData.dismiss()

            Timer {
                running: true
                interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : Config.notifs.defaultTimeout
                onTriggered: card.modelData.expire()
            }

            Column {
                id: layout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 3

                Text {
                    width: parent.width
                    text: card.modelData.appName
                    color: Colours.overlay2
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Text {
                    width: parent.width
                    text: card.modelData.summary
                    color: Colours.text
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Text {
                    width: parent.width
                    text: card.modelData.body
                    color: Colours.subtext1
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }
    }
}
