import QtQuick
import QtQuick.Shapes
import ".."

Shape {
    id: root

    width: Config.radius_outer + Config.radius_inner
    height: Config.radius_outer + Config.radius_inner

    property color color: "#1e1e2e"

    property string type: "left"

    layer.enabled: true
    layer.samples: 4

    rotation: root.type === "left" ? 90 : 0

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"

        startX: 0
        startY: 0

        PathLine {
            x: 0
            y: root.height
        }

        PathArc {
            x: root.width
            y: 0
            radiusX: root.width
            radiusY: root.height
            useLargeArc: false
            direction: PathArc.Clockwise
        }

        PathLine {
            x: 0
            y: 0
        }
    }
}
