import QtQuick
import QtQuick.Shapes
import "../services"

// Hover/press highlight with a Material-style ripple on click (caelestia
// StateLayer). Fills its parent, paints a translucent rounded tint that
// brightens on hover/press, and expands a soft radial-gradient disc from the
// press point — clipped to a rounded-rect matching the parent's radius — that
// fades out on release. Self-contained.
MouseArea {
    id: root

    property bool disabled
    property color effectColor: Colours.text
    property real radius: parent?.radius ?? 0
    property bool shapeMorph: false           // expand the ripple slightly past the bounds
    property real stateOpacity: pressed ? 0.12 : containsMouse ? 0.08 : 0

    // ripple state
    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius: 0
    property real endRadiusAtPress

    // corner radius clamped to the half-extents (for the ripple clip path)
    readonly property real cr: Math.min(root.radius, width / 2, height / 2)

    // farthest corner from the press point, so the disc covers the whole surface
    readonly property real endRadius: {
        const d = (x, y) => Math.hypot(root.pressX - x, root.pressY - y);
        return Math.max(d(0, 0), d(width, 0), d(0, height), d(width, height)) * (root.shapeMorph ? 1.16 : 1);
    }

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: e => {
        pressX = e.x;
        pressY = e.y;
        fadeAnim.complete();
        circleRadius = 0;
        circle.opacity = 0.12;
        endRadiusAtPress = endRadius;
        rippleAnim.restart();
    }
    onPressedChanged: {
        if (!pressed && !rippleAnim.running && circle.opacity > 0)
            fadeAnim.start();
    }
    onCircleRadiusChanged: {
        // released mid-grow: fade once the disc has finished expanding
        if (!pressed && circleRadius > endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }
    onCanceled: fadeAnim.start()

    Anim {
        id: rippleAnim

        alwaysRunToEnd: true
        target: root
        property: "circleRadius"
        from: 0
        to: root.endRadius
        curve: Appearance.anim.curves.expressiveSlowEffects
        duration: Appearance.anim.durations.expressiveSlowEffects * 2
    }

    Anim {
        id: fadeAnim

        target: circle
        property: "opacity"
        to: 0
        curve: Appearance.anim.curves.expressiveSlowEffects
        duration: Appearance.anim.durations.expressiveSlowEffects
    }

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

    // Ripple: a radial-gradient disc (opaque inside circleRadius, transparent at
    // the edge) clipped to the rounded-rect shape so it respects the radius.
    Shape {
        id: circle

        anchors.fill: parent
        opacity: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.pressX
                centerY: root.pressY
                centerRadius: Math.max(1, root.circleRadius)
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(root.effectColor, 1)
                }
                GradientStop {
                    position: 0.99
                    color: Qt.alpha(root.effectColor, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.effectColor, 0)
                }
            }

            startX: root.cr
            startY: 0

            PathLine {
                x: root.width - root.cr
                y: 0
            }
            PathArc {
                x: root.width
                y: root.cr
                radiusX: root.cr
                radiusY: root.cr
                direction: PathArc.Clockwise
            }
            PathLine {
                x: root.width
                y: root.height - root.cr
            }
            PathArc {
                x: root.width - root.cr
                y: root.height
                radiusX: root.cr
                radiusY: root.cr
                direction: PathArc.Clockwise
            }
            PathLine {
                x: root.cr
                y: root.height
            }
            PathArc {
                x: 0
                y: root.height - root.cr
                radiusX: root.cr
                radiusY: root.cr
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 0
                y: root.cr
            }
            PathArc {
                x: root.cr
                y: 0
                radiusX: root.cr
                radiusY: root.cr
                direction: PathArc.Clockwise
            }
        }
    }
}
