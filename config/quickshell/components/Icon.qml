import QtQuick
import QtQuick.Shapes
import ".."
import "../lib/icons.js" as I

// A line icon from lib/icons.js. The paths live on a 24 grid, so the shape is scaled
// by size / 24; the stroke is widened by the inverse so it stays Theme.sizes.iconStroke
// px at every size.
Item {
    id: root

    property string name
    property color color: Theme.fg
    property real size: Theme.sizes.iconGrid

    readonly property real grid: Theme.sizes.iconGrid

    implicitWidth: root.size
    implicitHeight: root.size

    Shape {
        width: root.grid
        height: root.grid
        scale: root.size / root.grid
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: Theme.sizes.iconStroke * root.grid / root.size
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: I.paths[root.name] ?? ""
            }
        }
    }
}
