import QtQuick

/**
 * A ListView with animations.
 */
ListView {
    id: root
    spacing: 5
    property real removeOvershoot: 20 // Account for gaps and bouncy animations
    property int dragIndex: -1
    property real dragDistance: 0
    property bool popin: true
    // Accumulated scroll destination so wheel deltas stack while animating
    property real scrollTargetY: 0

    property real touchpadScrollFactor: 100
    property real mouseScrollFactor: 50
    property real mouseScrollDeltaThreshold: 120

    function resetDrag() {
        root.dragIndex = -1;
        root.dragDistance = 0;
    }

    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

    MouseArea {
        visible: false
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (wheelEvent) {
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
            // The angleDelta.y of a touchpad is usually small and continuous,
            // while that of a mouse wheel is typically in multiples of ±120.
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;

            const maxY = Math.max(0, root.contentHeight - root.height);
            const base = scrollAnim.running ? root.scrollTargetY : root.contentY;
            var targetY = Math.max(0, Math.min(base - delta * scrollFactor, maxY));

            root.scrollTargetY = targetY;
            root.contentY = targetY;
            wheelEvent.accepted = true;
        }
    }

    onContentYChanged: {
        if (!scrollAnim.running) {
            root.scrollTargetY = root.contentY;
        }
    }
}
