pragma ComponentBehavior: Bound

import QtQuick
import "../services"
import ".."

Item {
    id: root

    readonly property bool isPlaying: Music.isPlaying

    width: 30
    height: 30

    readonly property real maxBarHeight: 30
    readonly property real minBarHeight: 3
    readonly property real heightRange: maxBarHeight - minBarHeight
    property var barHeights: [minBarHeight, minBarHeight, minBarHeight, minBarHeight, minBarHeight, minBarHeight]

    Connections {
        target: Cava
        function onValuesChanged() {
            if (!root.isPlaying) {
                root.barHeights = [root.minBarHeight, root.minBarHeight, root.minBarHeight, root.minBarHeight, root.minBarHeight, root.minBarHeight];
                return;
            }

            const newHeights = [];
            for (let i = 0; i < 6; i++) {
                if (Cava.values.length <= i) {
                    newHeights.push(root.minBarHeight);
                    continue;
                }

                const rawLevel = Cava.values[i];
                if (rawLevel <= 0) {
                    newHeights.push(root.minBarHeight);
                } else if (rawLevel >= 100) {
                    newHeights.push(root.maxBarHeight);
                } else {
                    newHeights.push(root.minBarHeight + Math.sqrt(rawLevel * 0.01) * root.heightRange);
                }
            }
            root.barHeights = newHeights;
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 1.5

        Repeater {
            model: 6

            Rectangle {
                required property int index

                width: 3
                height: root.barHeights[index]
                radius: 1.5
                color: Config.accent
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    enabled: root.isPlaying
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }
}
