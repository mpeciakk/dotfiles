import QtQuick

MouseArea {
    id: tap
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    property Item targetItem
    property real hoverScale: 1.08
    property real pressScale: 0.92

    onPressedChanged: {
        if (!targetItem) {
            return;
        }

        targetItem.scale = pressed ? pressScale : (containsMouse ? hoverScale : 1.0);
    }
    onContainsMouseChanged: {
        if (!targetItem || pressed) {
            return;
        }

        targetItem.scale = containsMouse ? hoverScale : 1.0;
    }
}
