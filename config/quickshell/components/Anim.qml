import QtQuick
import "../services"

// NumberAnimation preset wired to the motion tokens. Set `curve` to any
// Appearance.anim.curves.* array; override `duration` per use.
NumberAnimation {
    property var curve: Appearance.anim.curves.standard

    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
