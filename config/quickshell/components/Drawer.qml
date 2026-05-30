import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../services"

// Reusable "notch" popup: a panel that drops out of the top bar with concave
// shoulders blending into the bar (rounded bottom corners). This is THE pattern
// every dropdown/drawer in this shell should use.
//
// Usage: place content as children; call open()/close(); set anchorX to the
// screen x the notch should point at.
PanelWindow {
    id: root

    property real barHeight: Config.bar.height
    property real anchorX: 0                       // screen x the notch points at (panel centre)
    property real shoulder: Config.drawer.shoulder // concave top corner radius
    property real bottomRadius: Config.drawer.radius // convex bottom corner radius
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
    // compositor shifts it down by the bar's reserved zone and the notch detaches
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

        y: root.barHeight
        x: Math.max(4, Math.min(root.anchorX - width / 2, root.width - width - 4))
        width: contentContainer.implicitWidth + 2 * (root.hpadding + root.shoulder)
        height: contentContainer.implicitHeight + 2 * root.vpadding

        opacity: root.prog
        transform: [
            Scale {
                origin.x: panel.width / 2
                origin.y: 0
                xScale: 0.9 + 0.1 * root.prog
                yScale: 0.9 + 0.1 * root.prog
            },
            Translate {
                y: (1 - root.prog) * -16
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

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: root.surfaceColor

                startX: 0
                startY: 0

                // top edge (flush with the bar)
                PathLine {
                    x: panel.width
                    y: 0
                }
                // right concave shoulder
                PathArc {
                    x: panel.width - root.shoulder
                    y: root.shoulder
                    radiusX: root.shoulder
                    radiusY: root.shoulder
                    direction: PathArc.Counterclockwise
                }
                // right wall
                PathLine {
                    x: panel.width - root.shoulder
                    y: panel.height - root.bottomRadius
                }
                // bottom-right convex
                PathArc {
                    x: panel.width - root.shoulder - root.bottomRadius
                    y: panel.height
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                // bottom edge
                PathLine {
                    x: root.shoulder + root.bottomRadius
                    y: panel.height
                }
                // bottom-left convex
                PathArc {
                    x: root.shoulder
                    y: panel.height - root.bottomRadius
                    radiusX: root.bottomRadius
                    radiusY: root.bottomRadius
                    direction: PathArc.Clockwise
                }
                // left wall
                PathLine {
                    x: root.shoulder
                    y: root.shoulder
                }
                // left concave shoulder
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

            x: root.shoulder + root.hpadding
            y: root.vpadding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            width: implicitWidth
            height: implicitHeight
        }
    }
}
