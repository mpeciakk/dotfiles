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

    property var animCurveOpen: Appearance.anim.curves.emphasizedDecel
    property var animCurveClose: Appearance.anim.curves.emphasizedAccel
    property int animDuration: Appearance.anim.durations.expressiveSlowEffects

    property bool shown: false
    property real prog: progDriver.p

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

    // Cross-axis position for the side/top/bottom edges: place by anchor + align,
    // clamped to stay on-screen (limit is the screen extent on that axis).
    function alignedPos(anchor: real, size: real, limit: real): real {
        const c = align === "start" ? anchor : align === "end" ? anchor - size : anchor - size / 2;
        return Math.max(4, Math.min(c, limit - size - 4));
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

    Item {
        id: progDriver

        property real p: 0

        states: State {
            name: "open"
            when: root.shown
            PropertyChanges {
                target: progDriver
                p: 1
            }
        }
        transitions: [
            Transition {
                to: "open"
                Anim {
                    target: progDriver
                    property: "p"
                    curve: root.animCurveOpen
                    duration: root.animDuration
                }
            },
            Transition {
                from: "open"
                Anim {
                    target: progDriver
                    property: "p"
                    curve: root.animCurveClose
                    duration: root.animDuration
                }
            }
        ]
    }

    // Click-away catcher (behind the panel), only when modal.
    MouseArea {
        anchors.fill: parent
        enabled: root.modal
        onClicked: root.close()
    }

    // Clips away the strip behind the bar/border on the emergence edge, so the
    // panel slides out from *under* the bar/edge panels instead of over them.
    Item {
        id: clipper

        x: root.fromLeft ? root.barSize : 0
        y: root.fromTop || root.fromCorner ? root.barSize : 0
        width: root.width - (root.fromLeft || root.fromRight || root.fromCorner ? root.barSize : 0)
        height: root.height - (root.fromTop || root.fromBottom || root.fromCorner ? root.barSize : 0)
        clip: true

        Item {
            id: panel

            // Flush against the inner edge of the bar/border (offset by barSize
            // so the concave shoulders flare past it onto the desktop and stay
            // visible); positioned along the edge by the anchor/align. Coords are
            // relative to the clipper (offset by clipper.x/y).
            x: (root.fromLeft ? root.barSize : root.fromRight || root.fromCorner ? root.width - width - root.barSize : root.alignedPos(root.anchorX, width, root.width)) - clipper.x
            y: (root.fromTop || root.fromCorner ? root.barSize : root.fromBottom ? root.height - height - root.barSize : root.alignedPos(root.anchorY, height, root.height)) - clipper.y
        // Corner gets one shoulder on the left and one on the bottom; side edges
        // get two shoulders on the shoulder axis; the flush axis gets none.
        width: contentContainer.implicitWidth + 2 * root.hpadding + (root.fromCorner ? root.shoulder : root.horizontalShoulders ? 2 * root.shoulder : 0)
        height: contentContainer.implicitHeight + 2 * root.vpadding + (root.fromCorner ? root.shoulder : root.horizontalShoulders ? 0 : 2 * root.shoulder)

        // Pure slide like caelestia's offset animation: the panel slides its full
        // extent off the edge it emerges from (tucked behind the bar/border by
        // `barSize`), with no scaling.
        opacity: root.prog > 0 ? 1 : 0
        transform: Translate {
            readonly property real off: 1 - root.prog

            x: root.fromLeft ? -(panel.width + root.barSize) * off : root.fromRight ? (panel.width + root.barSize) * off : 0
            y: root.fromTop || root.fromCorner ? -(panel.height + root.barSize) * off : root.fromBottom ? (panel.height + root.barSize) * off : 0
        }

        // Smoothly resize as content grows/shrinks (e.g. notifications expiring)
        // so the notch retracts instead of snapping.
        // Only animate content-driven resize while fully open — during the
        // open/close slide the size snaps to its target so the panel slides in at
        // the right size instead of growing as it appears (which looks wrong when
        // the single card that opens the drawer also grows the panel from zero).
        Behavior on width {
            enabled: root.prog >= 1
            Anim {
                curve: Appearance.anim.curves.emphasized
                duration: Appearance.anim.durations.normal
            }
        }
        Behavior on height {
            enabled: root.prog >= 1
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
        NotchShape {
            visible: root.fromTop
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

        // Left notch (out of the vertical bar): the top-bar notch rotated 90°
        // CCW — flush left edge, concave shoulders top-left/bottom-left, convex
        // corners on the right.
        NotchShape {
            visible: root.fromLeft
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

        // Right notch (out of the right edge): the left notch mirrored in X —
        // flush right edge, concave shoulders top-right/bottom-right, convex
        // corners on the left.
        NotchShape {
            visible: root.fromRight
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

        // Bottom notch (up from the bottom edge): the top-bar notch mirrored in
        // Y — flush bottom edge, concave shoulders bottom-left/bottom-right,
        // convex corners on top.
        NotchShape {
            visible: root.fromBottom
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

        // Top-right corner notch: flush top and right edges meeting at the screen
        // corner, concave shoulders at top-left (blends into the top border) and
        // bottom-right (blends into the right border), convex bottom-left corner.
        NotchShape {
            visible: root.fromCorner
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
}
