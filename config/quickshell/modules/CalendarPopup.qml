pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import ".."
import "../common"

Popup {
    id: root
    width: wrapper.width + 64 + Config.padding * 2
    height: wrapper.height + Config.padding * 3

    readonly property date today: new Date()
    property date selectedDate: new Date()

    readonly property int year: selectedDate.getFullYear()
    readonly property int month: selectedDate.getMonth()

    readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

    readonly property int firstDayOffset: {
        const startDay = new Date(year, month, 1).getDay();
        return (startDay + 6) % 7;
    }

    readonly property list<string> weekDays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    function isCurrentMonth() {
        return today.getFullYear() === year && today.getMonth() === month;
    }

    readonly property int cellSize: 32

    onOpenChanged: {
        if (open) {
            selectedDate = new Date(today);
        }
    }

    ColumnLayout {
        id: wrapper
        z: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        RowLayout {
            IconButton {
                icon: "<"
                onClicked: {
                    root.selectedDate.setMonth(root.selectedDate.getMonth() - 1);
                }
            }

            Text {
                id: monthYearLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Config.text
                font: Config.font_bold
                text: Qt.formatDate(new Date(root.year, root.month), "MMMM yyyy")
            }

            IconButton {
                icon: ">"
                onClicked: {
                    root.selectedDate.setMonth(root.selectedDate.getMonth() + 1);
                }
            }
        }

        Row {
            spacing: 8
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Config.padding

            Repeater {
                model: root.weekDays

                Text {
                    required property int index
                    required property string modelData

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter

                    color: Config.text
                    font: Config.font_bold
                    text: modelData
                    width: root.cellSize
                    height: root.cellSize
                }
            }
        }

        Grid {
            columns: 7
            spacing: 8

            Layout.bottomMargin: Config.padding

            Repeater {
                model: root.firstDayOffset + root.daysInMonth

                Item {
                    id: cell

                    required property int index
                    readonly property int day: index >= root.firstDayOffset ? index - root.firstDayOffset + 1 : 0
                    readonly property bool isToday: day > 0 && root.isCurrentMonth() && day === root.today.getDate()

                    height: root.cellSize
                    width: root.cellSize

                    Rectangle {
                        anchors.fill: parent
                        color: Config.surface
                        radius: width / 2
                        visible: cell.isToday
                    }

                    Text {
                        anchors.centerIn: parent
                        font: Config.font
                        color: cell.isToday ? Config.accent : Config.text
                        text: cell.day > 0 ? cell.day : ""
                    }
                }
            }
        }
    }
}
