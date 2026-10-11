import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services"
import "../lib/notifs.js" as N

// The notification toast (reference 3.4 variant B, R26/R30): the newest notification's picture
// (image, appIcon, else the app's initial on a colour picked by hash), the title, "app · body"
// and a "+N" chip while more arrived in the series. A 2 px bar runs down the time left. A click
// opens the notification centre. IslandState decides when the toast opens and closes.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.toast
    readonly property var snap: Notifs.latest ?? ({ appName: "", summary: "", body: "", appIcon: "", image: "" })
    readonly property string picture: N.iconSource(root.snap, name => Quickshell.iconPath(name, true))
    readonly property bool pictured: root.picture !== "" && icon.status === Image.Ready
    readonly property int more: Notifs.series - 1
    // The series resets while the layer is still fading out (more = -1): the chip keeps its last value.
    property int shownMore: 0

    Binding {
        target: root
        property: "shownMore"
        value: root.more
        when: root.more >= 0
        restoreMode: Binding.RestoreNone
    }

    // Fraction of the bar still showing: full for the bar's delay, then linear down to empty.
    property real remaining: 1

    function restartBar(): void {
        barRun.restart();
    }

    onActiveChanged: {
        if (root.active)
            root.restartBar();
    }

    Connections {
        target: Notifs

        function onArrived(): void {
            root.restartBar();
        }
    }

    SequentialAnimation {
        id: barRun

        PropertyAction { target: root; property: "remaining"; value: 1 }
        PauseAnimation { duration: Theme.motion.toastBarDelayMs }
        NumberAnimation {
            target: root
            property: "remaining"
            to: 0
            duration: Theme.motion.toastBarMs
            easing.type: Easing.Linear
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.active
        onClicked: IslandState.request("center")
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.spec.padX
        anchors.rightMargin: root.spec.padX
        spacing: root.spec.gap

        Rectangle {
            Layout.preferredWidth: root.spec.icon
            Layout.preferredHeight: root.spec.icon
            radius: root.spec.iconRadius
            color: root.pictured ? Theme.chip : N.appColor(root.snap.appName, Theme.appColors)

            Image {
                id: icon

                anchors.centerIn: parent
                width: root.spec.iconImage
                height: root.spec.iconImage
                source: root.picture
                sourceSize.width: root.spec.iconImage
                sourceSize.height: root.spec.iconImage
                fillMode: Image.PreserveAspectFit
                visible: root.pictured
            }

            Text {
                anchors.centerIn: parent
                visible: !root.pictured
                text: N.initial(root.snap.appName)
                color: Theme.accentFg
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.iconLetter
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.spec.textGap

            Text {
                Layout.fillWidth: true
                text: root.snap.summary
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Theme.fg
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.titleFont
                font.weight: Font.Medium
            }

            Text {
                Layout.fillWidth: true
                text: [root.snap.appName, root.snap.body].filter(s => s !== "").join(" · ")
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.bodyFont
            }
        }

        Rectangle {
            visible: root.shownMore > 0
            Layout.preferredWidth: chipText.implicitWidth + 2 * root.spec.chipPad
            Layout.preferredHeight: root.spec.chipH
            radius: root.spec.chipRadius
            color: Theme.accent

            Text {
                id: chipText

                anchors.centerIn: parent
                text: "+" + root.shownMore
                color: Theme.accentFg
                font.family: Theme.fonts.mono
                font.pixelSize: root.spec.chipFont
                font.weight: Font.Medium
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.spec.barInset
        anchors.rightMargin: root.spec.barInset
        height: root.spec.barH
        color: Theme.sel

        Rectangle {
            width: parent.width * root.remaining
            height: parent.height
            color: Theme.accent
        }
    }
}
