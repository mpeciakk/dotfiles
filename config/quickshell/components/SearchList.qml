import QtQuick
import Quickshell
import "../services"

// Search-field-over-a-list skeleton: the reusable command-palette / menu /
// config-screen building block. A SearchField drives a ListView (ScriptModel so
// the filtered list keeps live delegates; a gliding highlight; ApplyRange so ↑/↓
// scroll). Provide `values` (an array — Apps.query results, menu items, …) and a
// `delegate` (typically a ListRow); handle `activated` (Enter — mouse clicks are
// the delegate's own `clicked`) and `escaped`.
Item {
    id: root

    property alias text: field.text
    property alias placeholder: field.placeholder
    property var values: []
    property Component delegate
    property int itemHeight: Config.launcher.itemHeight
    property int maxVisible: Config.launcher.maxVisible

    signal activated(var item, int index)
    signal escaped

    readonly property var currentItem: list.currentItem
    readonly property int currentIndex: list.currentIndex
    readonly property int count: list.count

    function activate(): void {
        field.text = "";
        field.forceActiveFocus();
    }
    function reset(): void {
        field.text = "";
    }

    implicitWidth: Config.launcher.width
    implicitHeight: field.height + 8 + list.height

    onValuesChanged: list.currentIndex = 0

    SearchField {
        id: field

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        onUp: list.decrementCurrentIndex()
        onDown: list.incrementCurrentIndex()
        onAccepted: if (root.values.length > 0)
            root.activated(root.values[Math.max(0, list.currentIndex)], list.currentIndex)
        onEscaped: root.escaped()
    }

    ListView {
        id: list

        anchors.top: field.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(contentHeight, root.maxVisible * root.itemHeight)

        clip: true
        spacing: 2
        currentIndex: 0
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false   // keys are driven from the field

        // ScriptModel diffs `values` by object identity, so filtering keeps live
        // delegates instead of rebuilding the whole list (no flash). No list
        // transitions on purpose — under fast typing they get interrupted and
        // leave delegates stuck at partial opacity/scale or overlapping; rows
        // snap to position and the gliding highlight carries the polish.
        model: ScriptModel {
            values: root.values
        }
        delegate: root.delegate

        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        highlightFollowsCurrentItem: false
        highlight: Rectangle {
            radius: Config.rounding.large
            color: Colours.surface1
            width: list.width
            height: root.itemHeight
            y: list.currentItem ? list.currentItem.y : 0

            Behavior on y {
                Anim {
                    curve: Appearance.anim.curves.emphasized
                    duration: Appearance.anim.durations.normal
                }
            }
        }
    }
}
