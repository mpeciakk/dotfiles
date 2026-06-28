import QtQuick
import "../services"

// Shared notification card body: app name (with an optional timestamp), summary
// and body. Used by the popup stack (Notifications) and the history list
// (NotificationCenter); each wraps it in its own StateButton + click/expiry logic
// and anchors it. Pass `time` (a Date) to show the "hh:mm" stamp, omit for none.
Column {
    id: root

    property string appName: ""
    property string summary: ""
    property string body: ""
    property var time: undefined

    spacing: 3

    // App name + optional timestamp on the same row.
    Item {
        width: parent.width
        height: appText.implicitHeight
        visible: appText.visible || timeText.visible

        Text {
            id: appText

            anchors.left: parent.left
            width: timeText.visible ? parent.width - timeText.width - 6 : parent.width
            text: root.appName
            color: Colours.overlay2
            font.pixelSize: Config.font.xs
            elide: Text.ElideRight
            visible: text !== ""
        }

        Text {
            id: timeText

            anchors.right: parent.right
            text: root.time !== undefined ? Qt.formatDateTime(root.time, "hh:mm") : ""
            color: Colours.overlay1
            font.pixelSize: Config.font.xs
            visible: root.time !== undefined
        }
    }

    Text {
        width: parent.width
        text: root.summary
        color: Colours.text
        font.pixelSize: Config.font.lg
        font.bold: true
        elide: Text.ElideRight
        visible: text !== ""
    }

    Text {
        width: parent.width
        text: root.body
        color: Colours.subtext1
        font.pixelSize: Config.font.md
        wrapMode: Text.Wrap
        maximumLineCount: 4
        elide: Text.ElideRight
        visible: text !== ""
    }
}
