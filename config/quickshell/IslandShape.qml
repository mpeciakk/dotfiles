import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

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

    // One path for every layer that needs the silhouette (fill, shadow source).
    component Silhouette: Shape {
        id: sil

        required property color paint
        required property real bodyLeft
        required property real bodyWidth
        required property real bodyHeight
        required property real earSize
        required property real cornerRadius
        // The rim: a stroke of the open path (no top edge, the top is the screen edge).
        property color stroke: "transparent"
        property real strokeW: -1

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: outline

            readonly property real right: sil.bodyLeft + sil.bodyWidth

            fillColor: sil.paint
            strokeColor: sil.stroke
            strokeWidth: sil.strokeW

            startX: sil.bodyLeft - sil.earSize
            startY: 0
            PathArc {
                x: sil.bodyLeft
                y: sil.earSize
                radiusX: sil.earSize
                radiusY: sil.earSize
                direction: PathArc.Clockwise
            }
            PathLine { x: sil.bodyLeft; y: sil.bodyHeight - sil.cornerRadius }
            PathArc {
                x: sil.bodyLeft + sil.cornerRadius
                y: sil.bodyHeight
                radiusX: sil.cornerRadius
                radiusY: sil.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: outline.right - sil.cornerRadius; y: sil.bodyHeight }
            PathArc {
                x: outline.right
                y: sil.bodyHeight - sil.cornerRadius
                radiusX: sil.cornerRadius
                radiusY: sil.cornerRadius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: outline.right; y: sil.earSize }
            PathArc {
                x: outline.right + sil.earSize
                y: 0
                radiusX: sil.earSize
                radiusY: sil.earSize
                direction: PathArc.Clockwise
            }
        }
    }

    // Shadow (W2): the silhouette is drawn opaque into a layer sized to the shape plus
    // padding (never the full-screen window), and the effect's shadow is masked by the
    // same silhouette, inverted, so only the part outside the shape remains.
    Item {
        id: shadowHost

        readonly property real pad: Theme.shadowPad

        visible: !root.lineMode
        x: bodyItem.x - root.animEar - shadowHost.pad
        y: 0
        width: root.animW + 2 * root.animEar + 2 * shadowHost.pad
        height: root.animH + shadowHost.pad

        Item {
            id: shadowSource
            anchors.fill: parent
            layer.enabled: true
            visible: false

            Silhouette {
                anchors.fill: parent
                paint: Qt.alpha(Theme.shadowColor, 1)
                bodyLeft: shadowHost.pad + root.animEar
                bodyWidth: root.animW
                bodyHeight: root.animH
                earSize: root.animEar
                cornerRadius: root.animR
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: shadowSource
            autoPaddingEnabled: false
            shadowEnabled: true
            shadowColor: Theme.shadowColor
            shadowVerticalOffset: Theme.shadowY
            shadowBlur: 1
            blurMax: Theme.shadowBlur
            maskEnabled: true
            maskInverted: true
            maskSource: shadowSource
        }
    }

    // Declared before bodyItem: later siblings paint on top, so content stays above the fill.
    Silhouette {
        anchors.fill: parent
        paint: root.fill
        bodyLeft: bodyItem.x
        bodyWidth: root.animW
        bodyHeight: root.animH
        earSize: root.animEar
        cornerRadius: root.animR
    }

    // Own geometry follows the animated shape: a Region tracks only this item.
    Item {
        id: bodyItem
        x: (root.width - root.animW) / 2
        y: 0
        width: root.animW
        height: root.animH

        // Absorbs clicks on the body so they never reach the click-outside catcher
        // below; sits under clipArea, so interactive content still gets its events first.
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: clipArea
            anchors.fill: parent
            clip: true
        }

        // Bottom-edge highlight of the glass (§2a): 1 px along the bottom edge and both bottom corners.
        Shape {
            anchors.fill: parent
            visible: !root.lineMode && Theme.sheen > 0
            opacity: Theme.sheen
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                id: edgePath
                readonly property real inset: 0.5

                fillColor: Qt.alpha(Theme.sheenEdge, 0)
                strokeColor: Theme.sheenEdge
                strokeWidth: Theme.sizes.ringWidth

                startX: edgePath.inset
                startY: root.animH - root.animR
                PathArc {
                    x: root.animR
                    y: root.animH - edgePath.inset
                    radiusX: root.animR - edgePath.inset
                    radiusY: root.animR - edgePath.inset
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: root.animW - root.animR; y: root.animH - edgePath.inset }
                PathArc {
                    x: root.animW - edgePath.inset
                    y: root.animH - root.animR
                    radiusX: root.animR - edgePath.inset
                    radiusY: root.animR - edgePath.inset
                    direction: PathArc.Counterclockwise
                }
            }
        }
    }

    // The rim (R13, §2a) paints above the content and takes no input: the ring and, on glass, the
    // outline, stroked along the whole silhouette with its ears, so the island reads as coming out of
    // the top edge. The line state drops both (R16).
    Silhouette {
        anchors.fill: parent
        visible: !root.lineMode
        paint: "transparent"
        stroke: Theme.ring
        strokeW: Theme.sizes.ringWidth
        bodyLeft: bodyItem.x
        bodyWidth: root.animW
        bodyHeight: root.animH
        earSize: root.animEar
        cornerRadius: root.animR
    }

    Silhouette {
        anchors.fill: parent
        visible: !root.lineMode && Theme.sheen > 0
        opacity: Theme.sheen
        paint: "transparent"
        stroke: Theme.sheenOutline
        strokeW: Theme.sizes.ringWidth
        bodyLeft: bodyItem.x
        bodyWidth: root.animW
        bodyHeight: root.animH
        earSize: root.animEar
        cornerRadius: root.animR
    }
}
