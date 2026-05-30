pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../services"

// Rounded "screen border" frame for one output (caelestia's border, reproduced
// in pure QML instead of the C++ Blobs SDF plugin). Three thin strut windows
// reserve `Config.border.thickness` on the top/right/bottom (the left is already
// reserved by the vertical bar) so tiled windows inset. A separate full-screen,
// click-through overlay fills that border region with the surface colour and
// rounds the inner corners — the desktop shows through a rounded-rect hole.
Scope {
    id: root

    property var modelData

    // --- reserve the border space ---
    component Strut: PanelWindow {
        screen: root.modelData
        color: "transparent"
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Config.border.thickness
    }

    Strut {
        anchors {
            top: true
            left: true
            right: true
        }
    }
    Strut {
        anchors {
            right: true
            top: true
            bottom: true
        }
    }
    Strut {
        anchors {
            bottom: true
            left: true
            right: true
        }
    }

    // --- draw the frame ---
    PanelWindow {
        id: frame

        readonly property real t: Config.border.thickness
        readonly property real r: Config.border.rounding
        readonly property real holeTop: t
        readonly property real holeBottom: height - t
        readonly property real holeLeft: Config.bar.width
        readonly property real holeRight: width - t

        screen: root.modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}        // click-through; the struts do the reserving
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Shape {
            anchors.fill: parent

            // Default (geometry) renderer reliably cuts the OddEvenFill hole;
            // multisample the layer so the rounded corners stay smooth.
            layer.enabled: true
            layer.smooth: true
            layer.samples: 4

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Colours.base
                fillRule: ShapePath.OddEvenFill

                // outer rectangle: the whole screen
                startX: 0
                startY: 0
                PathLine {
                    x: frame.width
                    y: 0
                }
                PathLine {
                    x: frame.width
                    y: frame.height
                }
                PathLine {
                    x: 0
                    y: frame.height
                }
                PathLine {
                    x: 0
                    y: 0
                }

                // inner rounded-rect hole (OddEvenFill cuts it out)
                PathMove {
                    x: frame.holeLeft + frame.r
                    y: frame.holeTop
                }
                PathLine {
                    x: frame.holeRight - frame.r
                    y: frame.holeTop
                }
                PathArc {
                    x: frame.holeRight
                    y: frame.holeTop + frame.r
                    radiusX: frame.r
                    radiusY: frame.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: frame.holeRight
                    y: frame.holeBottom - frame.r
                }
                PathArc {
                    x: frame.holeRight - frame.r
                    y: frame.holeBottom
                    radiusX: frame.r
                    radiusY: frame.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: frame.holeLeft + frame.r
                    y: frame.holeBottom
                }
                PathArc {
                    x: frame.holeLeft
                    y: frame.holeBottom - frame.r
                    radiusX: frame.r
                    radiusY: frame.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: frame.holeLeft
                    y: frame.holeTop + frame.r
                }
                PathArc {
                    x: frame.holeLeft + frame.r
                    y: frame.holeTop
                    radiusX: frame.r
                    radiusY: frame.r
                    direction: PathArc.Clockwise
                }
            }
        }
    }
}
