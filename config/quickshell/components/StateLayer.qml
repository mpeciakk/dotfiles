import QtQuick
import "../services"

// Hover/press highlight with a Material-style ripple on click. Fills its parent,
// paints a translucent rounded tint that brightens on hover/press, and expands a
// circle from the press point that fades out on release. Self-contained.
MouseArea {
    id: root

    property bool disabled
    property color effectColor: Colours.text
    property real radius: parent?.radius ?? 0
    property real stateOpacity: pressed ? 0.12 : containsMouse ? 0.08 : 0

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: e => {
        ripple.x = e.x;
        ripple.y = e.y;
        ripple.opacity = 0.18;
        rippleGrow.restart();
    }
    onReleased: rippleFade.restart()
    onCanceled: rippleFade.restart()

    // Hover/press tint.
    Rectangle {
        anchors.fill: parent

        radius: root.radius
        color: root.effectColor
        opacity: root.stateOpacity

        Behavior on opacity {
            Anim {
                curve: Appearance.anim.curves.expressiveDefaultEffects
                duration: Appearance.anim.durations.expressiveDefaultEffects
            }
        }
    }

    // Ripple, clipped to the parent's bounds.
    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: ripple

            readonly property real endSize: Math.max(root.width, root.height) * 2.4

            width: 0
            height: 0
            radius: width / 2
            color: root.effectColor
            opacity: 0
            // keep the circle centred on the press point as it grows
            transform: Translate {
                x: -ripple.width / 2
                y: -ripple.height / 2
            }

            Anim {
                id: rippleGrow

                target: ripple
                properties: "width,height"
                from: 0
                to: ripple.endSize
                curve: Appearance.anim.curves.expressiveSlowEffects
                duration: Appearance.anim.durations.expressiveSlowEffects * 2
            }

            Anim {
                id: rippleFade

                target: ripple
                property: "opacity"
                to: 0
                curve: Appearance.anim.curves.expressiveSlowEffects
                duration: Appearance.anim.durations.expressiveSlowEffects
            }
        }
    }
}
