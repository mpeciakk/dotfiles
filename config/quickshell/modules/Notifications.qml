import QtQuick
import Quickshell.Services.Notifications
import "../components"
import "../services"

// Stack of notification cards, meant to live inside a (non-modal) Drawer so the
// notifications drop out of the bar as a notch. A ListView (not a positioner) so
// removals use a proper `remove` transition: the leaving card slides out + fades
// in place while it's taken out of layout at once, so the rest reflow up in one
// smooth `displaced` motion (no leftover spacing to jump) and the notch
// background follows the contentHeight step via the Drawer's own resize Behavior.
ListView {
    id: root

    property int cardWidth: Config.notifs.width

    implicitWidth: cardWidth
    implicitHeight: contentHeight
    width: implicitWidth
    height: implicitHeight
    spacing: 8
    interactive: false
    clip: false                 // let a leaving card slide out past the bounds
    model: Notifs.list

    // New cards pop in.
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
            from: 0.9
            to: 1
            curve: Appearance.anim.curves.emphasized
            duration: Appearance.anim.durations.normal
        }
    }

    // Leaving card slides out to the right and fades (in place — already out of
    // layout, so it doesn't hold a slot).
    remove: Transition {
        Anim {
            property: "x"
            to: root.cardWidth
            curve: Appearance.anim.curves.emphasized
            duration: Appearance.anim.durations.normal
        }
        Anim {
            property: "opacity"
            to: 0
            curve: Appearance.anim.curves.standard
            duration: Appearance.anim.durations.small
        }
    }

    // The stack closes the gap in one smooth motion when a card is added/removed.
    displaced: Transition {
        Anim {
            property: "y"
            curve: Appearance.anim.curves.emphasized
            duration: Appearance.anim.durations.normal
        }
    }

    delegate: StateButton {
        id: card

        required property Notification modelData

        width: root.cardWidth
        implicitHeight: content.implicitHeight + 20
        radius: Config.rounding.large
        color: Colours.mantle

        // modelData goes null while the delegate lingers through the remove
        // transition — guard every access. The card is out of layout by then, so
        // a momentary blank doesn't affect sizing.
        onClicked: card.modelData?.dismiss()

        Timer {
            running: card.modelData !== null
            interval: (card.modelData?.expireTimeout ?? 0) > 0 ? card.modelData.expireTimeout : Config.notifs.defaultTimeout
            onTriggered: card.modelData?.expire()
        }

        NotificationCard {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            appName: card.modelData?.appName ?? ""
            summary: card.modelData?.summary ?? ""
            body: card.modelData?.body ?? ""
        }
    }
}
