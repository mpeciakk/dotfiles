import QtQuick
import "../services"

// Text that animates on content change (caelestia's two-phase swap): the chosen
// property accelerates out to `animateFrom`, the text swaps, then decelerates
// back in to `animateTo`. Drop-in replacement for Text; set `animate: false` to
// disable. Scales from the centre by default.
Text {
    id: root

    property bool animate: true
    property string animateProp: "scale"   // "scale" or "opacity"
    property real animateFrom: 0
    property real animateTo: 1
    property int animateDuration: Appearance.anim.durations.normal

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: root.animateProp
                to: root.animateFrom
                curve: Appearance.anim.curves.standardAccel
                duration: root.animateDuration / 2
            }
            PropertyAction {}
            Anim {
                target: root
                property: root.animateProp
                to: root.animateTo
                curve: Appearance.anim.curves.standardDecel
                duration: root.animateDuration / 2
            }
        }
    }
}
