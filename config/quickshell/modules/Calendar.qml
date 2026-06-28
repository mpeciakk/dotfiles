import QtQuick
import "../components"
import "../services"

// Self-contained month calendar (Monday-first), today highlighted. Prev/next
// arrows page months. Meant to live inside a Drawer opened from the bar clock.
Item {
    id: root

    property date cursor: new Date()   // any day within the displayed month
    readonly property int cell: 34

    implicitWidth: cell * 7
    implicitHeight: col.implicitHeight

    function shiftMonth(n: int): void {
        root.cursor = new Date(root.cursor.getFullYear(), root.cursor.getMonth() + n, 1);
    }

    readonly property var days: {
        const c = root.cursor;
        const year = c.getFullYear();
        const month = c.getMonth();
        const offset = (new Date(year, month, 1).getDay() + 6) % 7;   // Monday-first
        const dim = new Date(year, month + 1, 0).getDate();
        const today = new Date();
        const thisMonth = today.getFullYear() === year && today.getMonth() === month;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = i - offset + 1;
            const inMonth = d >= 1 && d <= dim;
            out.push({
                day: inMonth ? d : new Date(year, month, d).getDate(),
                inMonth: inMonth,
                today: inMonth && thisMonth && d === today.getDate()
            });
        }
        return out;
    }

    Column {
        id: col

        width: parent.width
        spacing: 6

        // Header: ‹  Month YYYY  ›
        Item {
            width: parent.width
            height: 30

            StateButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: Config.rounding.small
                onClicked: root.shiftMonth(-1)

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: Colours.text
                    font.pixelSize: 18
                }
            }

            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(root.cursor, "MMMM yyyy")
                color: Colours.text
                font.pixelSize: 14
                font.bold: true
            }

            StateButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: Config.rounding.small
                onClicked: root.shiftMonth(1)

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: Colours.text
                    font.pixelSize: 18
                }
            }
        }

        // Weekday labels.
        Row {
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                delegate: Text {
                    required property string modelData

                    width: root.cell
                    height: 22
                    text: modelData
                    color: Colours.overlay1
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Day grid.
        Grid {
            columns: 7

            Repeater {
                model: root.days

                delegate: Item {
                    required property var modelData

                    width: root.cell
                    height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        visible: modelData.today
                        color: Colours.mauve
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: 13
                        font.bold: modelData.today
                        color: modelData.today ? Colours.base : modelData.inMonth ? Colours.text : Colours.overlay0
                    }
                }
            }
        }
    }
}
