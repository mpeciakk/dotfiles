import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../modules"

Item {
    id: root
    width: layout.width
    height: layout.height

    property bool detailsOpen: false

    function onOpen() {
        detailsOpen = !detailsOpen;
    }

    MouseArea {
        width: childrenRect.width
        height: childrenRect.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.onOpen()

        RowLayout {
            id: layout
            spacing: 4

            SystemClock {
                id: clock
                precision: SystemClock.Seconds
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd dd/MM/yyyy")
                color: Config.text
                font: Config.font
                rightPadding: 4
            }

            Rectangle {
                Layout.preferredWidth: 4
                Layout.preferredHeight: 4
                radius: height / 2
                color: Config.text
            }

            Text {
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: Config.text
                font: Config.font
                leftPadding: 4
            }
        }
    }

    CalendarPopup {
        id: popup
        open: root.detailsOpen
        onRequestClose: {
            root.detailsOpen = false;
        }
        anchorItem: root
    }
}
