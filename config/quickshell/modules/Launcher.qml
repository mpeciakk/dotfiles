import QtQuick
import Quickshell
import "../components"
import "../services"

// App launcher content: a search field over a results list. Meant to live inside
// a (modal, keyboard-focused) Drawer so it drops out of the bar as a notch.
// Type to filter, ↑/↓ to move, Enter to launch, Esc to close.
Item {
    id: root

    signal close

    readonly property var results: Apps.query(search.text)

    implicitWidth: Config.launcher.width
    implicitHeight: searchBox.height + 8 + list.height

    function activate(): void {
        search.text = "";
        search.forceActiveFocus();
    }
    function reset(): void {
        search.text = "";
    }
    function accept(): void {
        if (root.results.length > 0) {
            Apps.launch(root.results[Math.max(0, list.currentIndex)]);
            root.close();
        }
    }

    onResultsChanged: list.currentIndex = 0

    Rectangle {
        id: searchBox

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        radius: height / 2
        color: Colours.surface0

        TextInput {
            id: search

            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Colours.text
            font.pixelSize: 15
            selectByMouse: true
            selectionColor: Colours.mauve

            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onReturnPressed: root.accept()
            Keys.onEnterPressed: root.accept()
            Keys.onEscapePressed: root.close()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: search.text === ""
                text: "Search apps…"
                color: Colours.overlay0
                font: search.font
            }
        }
    }

    ListView {
        id: list

        anchors.top: searchBox.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(contentHeight, Config.launcher.maxVisible * Config.launcher.itemHeight)

        clip: true
        spacing: 2
        currentIndex: 0
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false   // keys are driven from the search field

        delegate: StateButton {
            id: appRow

            required property var modelData

            width: ListView.view.width
            height: Config.launcher.itemHeight
            radius: 12
            color: ListView.isCurrentItem ? Colours.surface1 : "transparent"

            onClicked: {
                Apps.launch(appRow.modelData);
                root.close();
            }

            Behavior on color {
                CAnim {
                    curve: Appearance.anim.curves.expressiveDefaultEffects
                    duration: Appearance.anim.durations.expressiveDefaultEffects
                }
            }

            Icon {
                id: appIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                size: parent.height - 18
                source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
            }

            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: appRow.modelData.name ?? ""
                    color: Colours.text
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: (appRow.modelData.comment || appRow.modelData.genericName) ?? ""
                    color: Colours.overlay1
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }
    }
}
