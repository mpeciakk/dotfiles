import QtQuick
import QtQuick.Shapes

// Filled notch silhouette — the Shape + ShapePath boilerplate shared by every
// edge variant of Drawer. Declare the outline as children (PathLine/PathArc),
// the start point via startX/startY, and the fill via fillColor.
Shape {
    id: root

    property color fillColor
    property alias startX: path.startX
    property alias startY: path.startY
    default property alias elements: path.pathElements

    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path

        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.fillColor
    }
}
