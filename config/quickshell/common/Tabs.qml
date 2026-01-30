pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    property var tabsModel: []
    property int currentIndex: 0
    signal tabChanged(int index)

    RowLayout {
        id: tabBar
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        Repeater {
            model: root.tabsModel
            delegate: Rectangle {
                id: delegate
                implicitHeight: tab.height
                implicitWidth: 56
                color: "transparent"

                property bool hovered: false
                required property int index
                required property var modelData

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.currentIndex !== delegate.index) {
                            root.currentIndex = delegate.index;
                            root.tabChanged(delegate.index);
                        }
                    }
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }

                ColumnLayout {
                    id: tab
                    spacing: 2
                    anchors.centerIn: parent
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        text: delegate.modelData.label
                        font.pixelSize: 12
                        font.bold: delegate.index === root.currentIndex
                        color: delegate.index === root.currentIndex ? Config.text : (delegate.hovered ? Config.accent : Config.text)
                        Layout.alignment: Qt.AlignCenter
                    }

                    Rectangle {
                        width: 24
                        height: 2
                        radius: 1
                        color: delegate.index === root.currentIndex ? (Config.accent) : "transparent"
                        Layout.alignment: Qt.AlignCenter
                    }
                }
            }
        }
    }
}
