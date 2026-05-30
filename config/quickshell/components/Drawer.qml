import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../services"

// Reusable "notch" popup: a panel that slides out to the right of the vertical
// left bar with concave shoulders blending into the bar (rounded right corners).
// This is THE pattern every dropdown/drawer in this shell should use. The shape
// is the original top-bar notch rotated 90° CCW, so the geometry is identical.
//
// Usage: place content as children; call open()/close(); set anchorY to the
// screen y the notch should point at.
PanelWindow {
    id: root

    // Which screen edge the notch emerges from: "left"/"right" (out of a side,
    // positioned along the screen by anchorY), "top"/"bottom" (by anchorX), or
    // "top-right" — a corner notch flush against both the top and right borders,
    // with concave shoulders blending into each.
    property string edge: "left"
    readonly property bool fromLeft: edge === "left"
    readonly property bool fromRight: edge === "right"
    readonly property bool fromTop: edge === "top"
    readonly property bool fromBottom: edge === "bottom"
    readonly property bool fromCorner: edge === "top-right"
    readonly property bool horizontalShoulders: fromTop || fromBottom

    // Cross-axis placement: "center" on the anchor, "start" pins the near side
    // (top/left) at the anchor, "end" pins the far side (bottom/right) at it.
    property string align: "center"

    property real barSize: Config.bar.width        // bar thickness the notch emerges from
    property real anchorX: 0                        // screen x the notch points at (bottom edge)
    property real anchorY: 0                        // screen y the notch points at (left edge)
    property real shoulder: Config.drawer.shoulder  // concave corner radius (top/bottom)
    property real bottomRadius: Config.drawer.radius // convex corner radius (right side)
    property real hpadding: Config.drawer.padding
    property real vpadding: Config.drawer.padding
    property color surfaceColor: Colours.base

    // modal: grab the whole screen and close on click-away (menus). Non-modal:
    // input is limited to the panel so the rest of the screen stays click-through
    // (passive popups like notifications).
    property bool modal: true

    // Keyboard grab while open — set OnDemand for popups with text input (the
    // launcher); leave None for everything else.
    property int keyboardFocus: WlrKeyboardFocus.None

    property bool shown: false
    readonly property bool isOpen: shown
    property real prog: shown ? 1 : 0

    default property alias content: contentContainer.data

    function open(): void {
        shown = true;
    }
    function close(): void {
        shown = false;
    }
    function toggle(): void {
        shown = !shown;
    }

    // Full-screen overlay so we can catch click-away. Ignore exclusion zones so
    // the window spans the whole screen (including under the bar) — otherwise the
    // compositor shifts it right by the bar's reserved zone and the notch detaches
    // from the bar. Transparent everywhere except the drawn notch.
    color: "transparent"
    visible: prog > 0.001
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.shown ? root.keyboardFocus : WlrKeyboardFocus.None

    // Non-modal: only the panel captures input, so the rest is click-through.
    mask: root.modal ? null : panelRegion

    Region {
        id: panelRegion

        item: panel
    }

    // Springy drop in/out — overshoots slightly so the notch "pops".
    Behavior on prog {
        Anim {
            curve: Appearance.anim.curves.expressiveDefaultSpatial
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }

    // Click-away catcher (behind the panel), only when modal.
    MouseArea {
        anchors.fill: parent
        enabled: root.modal
        onClicked: root.close()
    }

    Item {
        id: panel

        // Flush against the inner edge of the bar/border (offset by barSize so
        // the concave shoulders flare past it onto the desktop and stay visible);
        // positioned along the edge by the anchor/align.
        x: {
            if (root.fromLeft)
                return root.barSize;
            if (root.fromRight || root.fromCorner)
                return root.width - width - root.barSize;
            const c = root.align === "start" ? root.anchorX : root.align === "end" ? root.anchorX - width : root.anchorX - width / 2;
            return Math.max(4, Math.min(c, root.width - width - 4));
        }
        y: {
            if (root.fromTop || root.fromCorner)
                return root.barSize;
            if (root.fromBottom)
                return root.height - height - root.barSize;
            const c = root.align === "start" ? root.anchorY : root.align === "end" ? root.anchorY - height : root.anchorY - height / 2;
            return Math.max(4, Math.min(c, root.height - height - 4));
        }
        // Corner gets one shoulder on the left and one on the bottom; side edges
        // get two shoulders on the shoulder axis; the flush axis gets none.
        width: contentContainer.implicitWidth + 2 * root.hpadding + (root.fromCorner ? root.shoulder : root.horizontalShoulders ? 2 * root.shoulder : 0)
        height: contentContainer.implicitHeight + 2 * root.vpadding + (root.fromCorner ? root.shoulder : root.horizontalShoulders ? 0 : 2 * root.shoulder)

        opacity: root.prog
        transform: [
            Scale {
                origin.x: root.fromRight || root.fromCorner ? panel.width : root.fromLeft ? 0 : panel.width / 2
                origin.y: root.fromTop || root.fromCorner ? 0 : root.fromBottom ? panel.height : panel.height / 2
                xScale: 0.9 + 0.1 * root.prog
                yScale: 0.9 + 0.1 * root.prog
            },
            Translate {
                x: root.fromLeft ? (1 - root.prog) * -16 : root.fromRight ? (1 - root.prog) * 16 : root.fromCorner ? (1 - root.prog) * 8 : 0
                y: root.fromTop ? (1 - root.prog) * -16 : root.fromBottom ? (1 - root.prog) * 16 : root.fromCorner ? (1 - root.prog) * -8 : 0
            }
        ]

        // Smoothly resize as content grows/shrinks (e.g. notifications expiring)
        // so the notch retracts instead of snapping.
        Behavior on width {
            Anim {
                curve: Appearance.anim.curves.emphasized
                duration: Appearance.anim.durations.normal
            }
        }
        Behavior on height {
            Anim {
                curve: Appearance.anim.curves.emphasized
                duration: Appearance.anim.durations.normal
            }
        }

        // Swallow clicks on the panel body (padding) so they don't close it.
        MouseArea {
            anchors.fill: parent
        }

        // Top notch (down from the top edge): the original top-bar notch — flush
        // top edge, concave shoulders top-left/top-right, convex bottom corners.
        Shape {
            anchors.fill: parent
            visible: root.fromTop
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: 0
                startY: 0

                PathLine {
                    x: panel.width
                    y: 0
                }
                PathArc {
                    x: panel.width - root.shoulder
                    y: root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: panel.width - root.shoulder
                    y: panel.height - root.bottomRadius
                }
                PathArc {
                    x: panel.width - root.shoulder - root.bottomRadius
                    y: panel.height
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: root.shoulder + root.bottomRadius
                    y: panel.height
                }
                PathArc {
                    x: root.shoulder
                    y: panel.height - root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: root.shoulder
                    y: root.shoulder
                }
                PathArc {
                    x: 0
                    y: 0
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // Left notch (out of the vertical bar): the top-bar notch rotated 90°
        // CCW — flush left edge, concave shoulders top-left/bottom-left, convex
        // corners on the right.
        Shape {
            anchors.fill: parent
            visible: root.fromLeft
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: 0
                startY: panel.height

                PathLine {
                    x: 0
                    y: 0
                }
                PathArc {
                    x: root.shoulder
                    y: root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: panel.width - root.bottomRadius
                    y: root.shoulder
                }
                PathArc {
                    x: panel.width
                    y: root.shoulder + root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: panel.width
                    y: panel.height - root.shoulder - root.bottomRadius
                }
                PathArc {
                    x: panel.width - root.bottomRadius
                    y: panel.height - root.shoulder
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: root.shoulder
                    y: panel.height - root.shoulder
                }
                PathArc {
                    x: 0
                    y: panel.height
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
            }
        }

        // Right notch (out of the right edge): the left notch mirrored in X —
        // flush right edge, concave shoulders top-right/bottom-right, convex
        // corners on the left.
        Shape {
            anchors.fill: parent
            visible: root.fromRight
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: panel.width
                startY: panel.height

                PathLine {
                    x: panel.width
                    y: 0
                }
                PathArc {
                    x: panel.width - root.shoulder
                    y: root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: root.bottomRadius
                    y: root.shoulder
                }
                PathArc {
                    x: 0
                    y: root.shoulder + root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: 0
                    y: panel.height - root.shoulder - root.bottomRadius
                }
                PathArc {
                    x: root.bottomRadius
                    y: panel.height - root.shoulder
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: panel.width - root.shoulder
                    y: panel.height - root.shoulder
                }
                PathArc {
                    x: panel.width
                    y: panel.height
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Clockwise
                }
            }
        }

        // Bottom notch (up from the bottom edge): the top-bar notch mirrored in
        // Y — flush bottom edge, concave shoulders bottom-left/bottom-right,
        // convex corners on top.
        Shape {
            anchors.fill: parent
            visible: root.fromBottom
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: 0
                startY: panel.height

                PathLine {
                    x: panel.width
                    y: panel.height
                }
                PathArc {
                    x: panel.width - root.shoulder
                    y: panel.height - root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: panel.width - root.shoulder
                    y: root.bottomRadius
                }
                PathArc {
                    x: panel.width - root.shoulder - root.bottomRadius
                    y: 0
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: root.shoulder + root.bottomRadius
                    y: 0
                }
                PathArc {
                    x: root.shoulder
                    y: root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: root.shoulder
                    y: panel.height - root.shoulder
                }
                PathArc {
                    x: 0
                    y: panel.height
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Clockwise
                }
            }
        }

        // Top-right corner notch: flush top and right edges meeting at the screen
        // corner, concave shoulders at top-left (blends into the top border) and
        // bottom-right (blends into the right border), convex bottom-left corner.
        Shape {
            anchors.fill: parent
            visible: root.fromCorner
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: 0
                startY: 0

                // top flush edge (full width, against the top border)
                PathLine {
                    x: panel.width
                    y: 0
                }
                // right flush edge (full height, against the right border, down
                // to the far corner)
                PathLine {
                    x: panel.width
                    y: panel.height
                }
                // bottom-right concave shoulder: flush corner -> body corner
                // (mirror of the top-left shoulder; same east->north sweep, CCW)
                PathArc {
                    x: panel.width - root.shoulder
                    y: panel.height - root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
                // bottom edge (body inset up by shoulder)
                PathLine {
                    x: root.shoulder + root.bottomRadius
                    y: panel.height - root.shoulder
                }
                // bottom-left convex corner
                PathArc {
                    x: root.shoulder
                    y: panel.height - root.shoulder - root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                // left wall (body inset by shoulder)
                PathLine {
                    x: root.shoulder
                    y: root.shoulder
                }
                // top-left concave shoulder: body corner -> flush corner
                PathArc {
                    x: 0
                    y: 0
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
            }
        }

        Item {
            id: contentContainer

            x: root.hpadding + (root.horizontalShoulders || root.fromCorner ? root.shoulder : 0)
            y: root.vpadding + (!root.horizontalShoulders && !root.fromCorner ? root.shoulder : 0)
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            width: implicitWidth
            height: implicitHeight
        }
    }
}
