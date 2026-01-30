import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    required property string text

    property bool needsMarquee: false

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    height: content.height
    clip: true

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 22
        x: 0

        Text {
            id: textA
            text: root.text
            color: Config.text
            font: Config.font
            elide: Text.ElideNone
        }

        Text {
            id: textB
            text: textA.text
            color: textA.color
            font: textA.font
            elide: textA.elide
            visible: root.needsMarquee
        }
    }

    Timer {
        id: marqueeDelay
        interval: 1000
        repeat: false
        onTriggered: {
            if (root.needsMarquee) {
                marqueeAnim.start();
            }
        }
    }

    function recompute(resetPosition) {
        const usable = Math.max(0, root.width);
        root.needsMarquee = textA.paintedWidth > usable;

        marqueeAnim.stop();
        marqueeDelay.stop();

        if (resetPosition || !root.needsMarquee) {
            content.x = 0;
        }

        if (root.needsMarquee) {
            marqueeAnim.from = 0;
            marqueeAnim.to = -(textA.paintedWidth + content.spacing);
            marqueeDelay.start();
        }
    }

    onWidthChanged: recompute(false)
    Component.onCompleted: recompute(true)

    NumberAnimation {
        id: marqueeAnim
        target: content
        property: "x"
        from: 0
        to: -(textA.paintedWidth + content.spacing)
        duration: Math.max(36000, textA.paintedWidth * 22)
        loops: Animation.Infinite
        easing.type: Easing.Linear
        running: false
    }
}
