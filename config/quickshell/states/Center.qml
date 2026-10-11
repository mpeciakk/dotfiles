import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services"
import "../components" as Components
import "../lib/notifs.js" as N

// The notification centre (reference 3.5): a header (count, do-not-disturb switch, "Wyczyść") above
// the history grouped by app. A group shows its newest card on top of up to two stack layers, or all
// its cards when expanded. Above the maximum height the list scrolls. The island's height follows
// `wantedHeight` through the normal morph.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.center
    // The height bounds come from geom.center, so a config override of it reaches centerHeight().
    readonly property var metrics: Object.assign({}, root.spec, { hMin: Theme.geom.center.hMin, hMax: Theme.geom.center.hMax })
    // app -> whether its group shows every card.
    property var expanded: ({})
    readonly property int wantedHeight: N.centerHeight(Notifs.groups, root.expanded, root.metrics)
    readonly property bool empty: Notifs.groups.length === 0

    // Only the lit layer drives the island; the height stays at its last value while the layer leaves.
    Binding {
        target: IslandState
        property: "centerHeight"
        value: root.wantedHeight
        when: root.active
        restoreMode: Binding.RestoreNone
    }

    function toggleGroup(app: string): void {
        root.expanded = Object.assign({}, root.expanded, { [app]: root.expanded[app] !== true });
    }

    function clearAll(): void {
        Notifs.clearAll();
        root.expanded = ({});
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: root.spec.pad
        anchors.leftMargin: root.spec.pad
        anchors.rightMargin: root.spec.pad
        anchors.bottomMargin: root.spec.bottom
        spacing: root.spec.gap

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.spec.header
            Layout.leftMargin: root.spec.headerPadX
            Layout.rightMargin: root.spec.headerPadX
            spacing: root.spec.headerGap

            Text {
                text: "Powiadomienia"
                color: Theme.fg
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.titleFont
                font.weight: Font.DemiBold
            }

            Text {
                text: Notifs.history.length
                color: Theme.fgMuted
                font.family: Theme.fonts.mono
                font.pixelSize: root.spec.countFont
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredHeight: root.spec.btnH
                Layout.preferredWidth: dndRow.implicitWidth + 2 * root.spec.btnPadX
                radius: root.spec.btnRadius
                color: Notifs.dnd ? Theme.accent : Theme.chip

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.motion.buttonBgMs
                        easing.type: Easing.InOutQuad
                    }
                }

                Row {
                    id: dndRow

                    anchors.centerIn: parent
                    spacing: root.spec.dndGap

                    Components.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "moon"
                        size: root.spec.dndIcon
                        color: Notifs.dnd ? Theme.onAccent : Theme.fg
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Nie przeszkadzać"
                        color: Notifs.dnd ? Theme.onAccent : Theme.fg
                        font.family: Theme.fonts.ui
                        font.pixelSize: root.spec.btnFont
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.active
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }

            Item {
                Layout.preferredHeight: root.spec.btnH
                Layout.preferredWidth: clearText.implicitWidth + 2 * root.spec.btnPadX

                Text {
                    id: clearText

                    anchors.centerIn: parent
                    text: "Wyczyść"
                    color: Theme.fgMuted
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.btnFont
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.active
                    onClicked: root.clearAll()
                }
            }
        }

        ColumnLayout {
            visible: root.empty
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.spec.emptyGap

            Item {
                Layout.fillHeight: true
            }

            Components.Icon {
                Layout.alignment: Qt.AlignHCenter
                name: "check"
                size: root.spec.emptyIcon
                color: Theme.fgMuted
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Wszystko przeczytane"
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.emptyFont
            }

            Item {
                Layout.fillHeight: true
            }
        }

        Item {
            visible: !root.empty
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: list

                anchors.fill: parent
                contentWidth: width
                contentHeight: groups.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: groups

                    width: list.width
                    spacing: root.spec.groupGap

                    Repeater {
                        model: Notifs.groups

                        Column {
                            id: group

                            required property var modelData

                            readonly property int count: group.modelData.items.length
                            readonly property bool open: root.expanded[group.modelData.app] === true
                            readonly property bool stacked: !group.open && group.count > 1
                            property real stackPad: !group.stacked ? 0 : (group.count > 2 ? root.spec.stackPad2 : root.spec.stackPad1)

                            width: groups.width
                            spacing: root.spec.groupHeader - root.spec.groupHeadH

                            Behavior on stackPad {
                                NumberAnimation {
                                    duration: Theme.motion.stackPadMs
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            RowLayout {
                                width: group.width
                                height: root.spec.groupHeadH
                                spacing: root.spec.groupHeadGap

                                Text {
                                    Layout.leftMargin: root.spec.groupHeadPadX
                                    text: group.modelData.app.toUpperCase()
                                    color: Theme.fgMuted
                                    font.family: Theme.fonts.ui
                                    font.pixelSize: root.spec.groupFont
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: root.spec.groupLetterEm * root.spec.groupFont
                                }

                                Text {
                                    text: group.count
                                    color: Theme.fgDim
                                    font.family: Theme.fonts.mono
                                    font.pixelSize: root.spec.groupCountFont
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Item {
                                    visible: group.count > 1
                                    Layout.preferredHeight: root.spec.groupBtn
                                    Layout.preferredWidth: toggleText.implicitWidth + 2 * root.spec.togglePadX

                                    Text {
                                        id: toggleText

                                        anchors.centerIn: parent
                                        text: group.open ? "Zwiń" : "Pokaż " + group.count
                                        color: Theme.accent
                                        font.family: Theme.fonts.ui
                                        font.pixelSize: root.spec.toggleFont
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.active
                                        onClicked: root.toggleGroup(group.modelData.app)
                                    }
                                }

                                Item {
                                    Layout.preferredHeight: root.spec.groupBtn
                                    Layout.preferredWidth: root.spec.groupBtn
                                    Layout.rightMargin: root.spec.groupHeadPadX

                                    Components.Icon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: root.spec.groupBtnIcon
                                        color: Theme.fgMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root.active
                                        onClicked: Notifs.dismissApp(group.modelData.app)
                                    }
                                }
                            }

                            Item {
                                id: stack

                                width: group.width
                                height: cards.height + group.stackPad

                                // The stack layers (reference 3.5) show only where they peek out below the card: the
                                // glass card is translucent, so a layer behind it would shine through.
                                Item {
                                    visible: group.stacked && group.count > 2
                                    y: root.spec.card + root.spec.stackPad1
                                    width: stack.width
                                    height: root.spec.stackPad2 - root.spec.stackPad1
                                    clip: true

                                    Rectangle {
                                        x: root.spec.layer2Inset
                                        y: root.spec.stackPad2 - parent.y
                                        width: stack.width - 2 * root.spec.layer2Inset
                                        height: root.spec.card
                                        radius: root.spec.cardRadius
                                        color: Theme.card
                                        opacity: root.spec.stack2Opacity
                                    }
                                }

                                Item {
                                    visible: group.stacked
                                    y: root.spec.card
                                    width: stack.width
                                    height: root.spec.stackPad1
                                    clip: true

                                    Rectangle {
                                        x: root.spec.layer1Inset
                                        y: root.spec.stackPad1 - parent.y
                                        width: stack.width - 2 * root.spec.layer1Inset
                                        height: root.spec.card
                                        radius: root.spec.cardRadius
                                        color: Theme.card
                                        opacity: root.spec.stack1Opacity
                                    }
                                }

                                Column {
                                    id: cards

                                    width: stack.width
                                    spacing: root.spec.cardGap

                                    Repeater {
                                        model: group.modelData.items

                                        Rectangle {
                                            id: card

                                            required property var modelData
                                            required property int index

                                            // A card renders its snapshot long after the notification itself is gone, and an
                                            // image://qsimage/ URL of it is dead by then: storedSource() drops only those.
                                            readonly property string picture: N.storedSource({ image: card.modelData.image, appIcon: card.modelData.appIcon }, name => Quickshell.iconPath(name, true))
                                            readonly property bool pictured: card.picture !== "" && cardImage.status === Image.Ready

                                            visible: group.open || card.index === 0
                                            width: cards.width
                                            height: root.spec.card
                                            radius: root.spec.cardRadius
                                            color: Theme.card

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: root.spec.cardPadL
                                                anchors.rightMargin: root.spec.cardPadR
                                                spacing: root.spec.cardInnerGap

                                                Rectangle {
                                                    Layout.preferredWidth: root.spec.cardIcon
                                                    Layout.preferredHeight: root.spec.cardIcon
                                                    radius: root.spec.cardIconRadius
                                                    color: card.pictured ? Theme.chip : N.appColor(card.modelData.appName, Theme.appColors)

                                                    Image {
                                                        id: cardImage

                                                        anchors.centerIn: parent
                                                        width: root.spec.cardIconImage
                                                        height: root.spec.cardIconImage
                                                        sourceSize.width: root.spec.cardIconImage
                                                        sourceSize.height: root.spec.cardIconImage
                                                        source: card.picture
                                                        cache: false
                                                        fillMode: Image.PreserveAspectFit
                                                        visible: card.pictured
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        visible: !card.pictured
                                                        text: N.initial(card.modelData.appName)
                                                        color: Theme.onAccent
                                                        font.family: Theme.fonts.ui
                                                        font.pixelSize: root.spec.cardIconLetter
                                                        font.weight: Font.DemiBold
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: root.spec.cardTextGap

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: card.modelData.summary
                                                        textFormat: Text.PlainText
                                                        elide: Text.ElideRight
                                                        maximumLineCount: 1
                                                        color: Theme.fg
                                                        font.family: Theme.fonts.ui
                                                        font.pixelSize: root.spec.cardTitleFont
                                                        font.weight: Font.Medium
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: card.modelData.body
                                                        textFormat: Text.PlainText
                                                        elide: Text.ElideRight
                                                        maximumLineCount: 1
                                                        color: Theme.fgMuted
                                                        font.family: Theme.fonts.ui
                                                        font.pixelSize: root.spec.cardBodyFont
                                                    }
                                                }

                                                Text {
                                                    text: Qt.formatTime(card.modelData.time, "HH:mm")
                                                    color: Theme.fgDim
                                                    font.family: Theme.fonts.mono
                                                    font.pixelSize: root.spec.cardTimeFont
                                                }

                                                Item {
                                                    Layout.preferredWidth: root.spec.dismissBtn
                                                    Layout.preferredHeight: root.spec.dismissBtn

                                                    Components.Icon {
                                                        anchors.centerIn: parent
                                                        name: "x"
                                                        size: root.spec.dismissIcon
                                                        color: Theme.fgDim
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        enabled: root.active
                                                        onClicked: Notifs.dismiss(card.modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Thin scrollbar in the island's padding, right of the list; only while the list overflows.
            Rectangle {
                visible: list.contentHeight > list.height
                anchors.left: parent.right
                y: list.visibleArea.yPosition * list.height
                width: root.spec.scrollW
                height: list.visibleArea.heightRatio * list.height
                radius: root.spec.scrollW / 2
                color: Theme.chip
            }
        }
    }
}
