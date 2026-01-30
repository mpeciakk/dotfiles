import QtQuick
import "../services"
import ".."

Text {
    id: root
    height: parent.height
    width: parent.width
    // maxW
    text: Niri.focusedWindowTitle
    color: Config.text
    font: Config.font
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
