import QtQuick
import QtQuick.Shapes

// The island's morphing silhouette: ONE fill path holding the body and both
// concave ears (no seams), plus a clipped content area that follows the body.
// Fills the island window; `body` is the rectangle the island occupies.
Item {
    id: root

    property real w: 0
    property real h: 0
    property real r: 0
    property bool ears: true
    property color fillColor: Theme.islandBg
    property bool lineMode: false

    default property alias content: clipArea.data
    readonly property Item body: bodyItem

    readonly property real animW: root.w
    readonly property real animH: root.h
    readonly property real animR: root.r
    // Clamped so the path stays valid while h shrinks (h - r >= ear).
    readonly property real animEar: root.earAmount * Math.min(Theme.geom.ear, root.animH - root.animR)

    property real earAmount: root.ears ? 1 : 0
    Behavior on earAmount {
        NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.earFadeMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.easeCurve }
    }

    Behavior on w {
        NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.morphMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.morphCurve }
    }
    Behavior on h {
        NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.morphMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.morphCurve }
    }
    Behavior on r {
        NumberAnimation { duration: Theme.reducedMotion ? 0 : Theme.motion.morphMs; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.morphCurve }
    }

    property color fill: root.lineMode ? Theme.line : root.fillColor
    Behavior on fill {
        ColorAnimation { duration: Theme.motion.bgColorMs }
    }

    // Own geometry follows the animated shape: a Region tracks only this item.
    Item {
        id: bodyItem
        x: (root.width - root.animW) / 2
        y: 0
        width: root.animW
        height: root.animH

        Item {
            id: clipArea
            anchors.fill: parent
            clip: true
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: path

            readonly property real left: bodyItem.x
            readonly property real right: bodyItem.x + bodyItem.width
            readonly property real e: root.animEar
            readonly property real rr: root.animR

            fillColor: root.fill
            strokeColor: "transparent"
            strokeWidth: -1

            startX: path.left - path.e
            startY: 0
            PathArc {
                x: path.left
                y: path.e
                radiusX: path.e
                radiusY: path.e
                direction: PathArc.Clockwise
            }
            PathLine { x: path.left; y: root.animH - path.rr }
            PathArc {
                x: path.left + path.rr
                y: root.animH
                radiusX: path.rr
                radiusY: path.rr
                direction: PathArc.Counterclockwise
            }
            PathLine { x: path.right - path.rr; y: root.animH }
            PathArc {
                x: path.right
                y: root.animH - path.rr
                radiusX: path.rr
                radiusY: path.rr
                direction: PathArc.Counterclockwise
            }
            PathLine { x: path.right; y: path.e }
            PathArc {
                x: path.right + path.e
                y: 0
                radiusX: path.e
                radiusY: path.e
                direction: PathArc.Clockwise
            }
        }
    }
}
