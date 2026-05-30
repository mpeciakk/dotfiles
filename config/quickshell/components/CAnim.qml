import QtQuick
import "../services"

// ColorAnimation preset for smooth colour transitions (chips, tints).
ColorAnimation {
    property var curve: Appearance.anim.curves.standard

    duration: Appearance.anim.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
