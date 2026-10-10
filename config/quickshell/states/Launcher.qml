import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../services"
import "../components" as Components
import "../lib/calc.js" as Calc
import "../lib/fuzzy.js" as F

// The launcher (reference 3.6, R29): a search pill, mode chips and a list of three visible rows.
// The first character of the query picks the mode: "=" calculator (Enter copies the result), ">" shell
// command, "@" open windows; otherwise apps, with the menus (Menus) listed first. A menu row drills into
// that menu's items; Esc leaves the menu, and only then closes the launcher.
// In test mode (WYSPA_TEST=1) nothing is ever run: every action only logs what it would do.
Item {
    id: root

    // Set by IslandContent for every state layer.
    property bool active: false
    property string output: ""

    readonly property var spec: Theme.layout.launcher
    readonly property bool testMode: Quickshell.env("WYSPA_TEST") === "1"
    readonly property var chips: [
        { mode: "apps", prefix: "", label: "Wszystko" },
        { mode: "calc", prefix: "=", label: "kalkulator" },
        { mode: "command", prefix: ">", label: "polecenie" },
        { mode: "windows", prefix: "@", label: "okna" }
    ]
    readonly property var prefixModes: ({ "=": "calc", ">": "command", "@": "windows" })

    // The menu being drilled into ("" = none) and its items, as listed by its script.
    property string menuId: ""
    property var menuItems: []
    property int selected: 0
    property int pendingRefreshes: 0

    readonly property string query: IslandState.launcherQuery
    readonly property string mode: root.menuId !== "" ? "menu" : (root.prefixModes[root.query.charAt(0)] ?? "apps")
    // What is searched for: the query without its mode prefix.
    readonly property string needle: (root.menuId === "" && root.query.charAt(0) in root.prefixModes ? root.query.slice(1) : root.query).trim()
    readonly property var rows: root.active ? root.buildRows() : []
    readonly property var current: root.rows[root.selected] ?? null
    readonly property int rowH: root.spec.icon + 2 * root.spec.rowPadY

    function buildRows(): var {
        const q = root.needle;
        if (root.mode === "calc") {
            const v = Calc.evaluate(q);
            return v === null ? [] : [{ kind: "calc", label: Calc.format(v), sub: "Wynik · Enter kopiuje", glyph: "calculator", ranges: [] }];
        }
        if (root.mode === "command")
            return q === "" ? [] : [{ kind: "command", text: q, label: "Uruchom: " + q, sub: "Polecenie powłoki", glyph: "terminal", ranges: [] }];
        if (root.mode === "windows")
            return root.windowRows(q);
        if (root.mode === "menu")
            return root.itemRows(q);
        const menus = [];
        for (const m of Menus.list) {
            const hit = F.match(q, m.title);
            if (hit)
                menus.push({ kind: "menu", menuId: m.id, label: m.title, sub: "Menu", iconName: m.icon, ranges: hit.ranges, score: hit.score });
        }
        menus.sort((a, b) => b.score - a.score);
        // Apps.query reads Apps.list, so this binding runs again when DesktopEntries finishes loading.
        const apps = Apps.query(q).map(r => ({ kind: "app", entry: r.entry, label: r.entry.name, sub: r.entry.comment || r.entry.genericName || "", iconName: r.entry.icon, ranges: r.ranges }));
        return menus.concat(apps);
    }

    function windowRows(q: string): var {
        const hits = [];
        for (const w of Niri.windowList) {
            const title = w.title ?? "";
            const app = w.app_id ?? "";
            const hit = F.rank(q, title, [app]);
            if (hit)
                hits.push({ kind: "window", id: w.id, label: title || app, sub: app, iconName: app.toLowerCase(), glyph: "app-window", ranges: hit.ranges, score: hit.score, order: hits.length });
        }
        // Niri.windowList is most recently focused first: the order breaks score ties.
        return hits.sort((a, b) => b.score - a.score || a.order - b.order);
    }

    function itemRows(q: string): var {
        const iconName = Menus.get(root.menuId)?.icon ?? "";
        const hits = [];
        for (const it of root.menuItems) {
            const hit = F.match(q, it.label);
            if (hit)
                hits.push({ kind: "item", command: it.command, label: it.label, sub: it.sublabel, iconName, dot: it.active ? 1 : 0, ranges: hit.ranges, score: hit.score, order: hits.length });
        }
        return hits.sort((a, b) => b.score - a.score || a.order - b.order);
    }

    // The name as StyledText with the matched `ranges` in the accent colour.
    function highlight(text: string, ranges: var): string {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        let out = "";
        let at = 0;
        for (const r of ranges) {
            out += esc(text.slice(at, r[0])) + "<font color=\"" + Theme.accent + "\">" + esc(text.slice(r[0], r[1])) + "</font>";
            at = r[1];
        }
        return out + esc(text.slice(at));
    }

    // Test mode only logs what `action` would do.
    function perform(what: string, action: var): void {
        if (root.testMode)
            console.info("launcher (test mode): would " + what);
        else
            action();
    }

    function run(row: var): void {
        if (!row)
            return;
        if (row.kind === "menu") {
            root.enterMenu(row.menuId);
        } else if (row.kind === "app") {
            root.perform("launch " + row.entry.name, () => Apps.launch(row.entry));
            IslandState.close();
        } else if (row.kind === "calc") {
            root.perform("copy " + row.label, () => Quickshell.execDetached(["wl-copy", "--", row.label]));
            IslandState.close();
        } else if (row.kind === "command") {
            root.perform("run: " + row.text, () => Quickshell.execDetached(["sh", "-c", row.text]));
            IslandState.close();
        } else if (row.kind === "window") {
            root.perform("focus window " + row.id, () => Niri.focusWindow(row.id));
            IslandState.close();
        } else if (row.kind === "item") {
            root.perform("run menu command: " + row.command, () => Quickshell.execDetached(["sh", "-c", row.command]));
            if (Menus.get(root.menuId)?.closeOnRun) {
                IslandState.close();
            } else {
                // A toggle (systemctl, tailscale) often takes longer than one tick to change the reported state.
                root.pendingRefreshes = root.spec.refreshes;
                refreshTimer.restart();
            }
        }
    }

    function move(delta: int): void {
        root.selected = Math.max(0, Math.min(root.rows.length - 1, root.selected + delta));
    }

    function enterMenu(id: string): void {
        if (!Menus.get(id))
            return;
        root.menuId = id;
        // Drop the previous menu's rows so they do not flash.
        root.menuItems = [];
        root.selected = 0;
        input.text = "";
        root.loadMenu();
    }

    function leaveMenu(): void {
        root.menuId = "";
        root.selected = 0;
        input.text = "";
    }

    function loadMenu(): void {
        const m = Menus.get(root.menuId);
        if (!m)
            return;
        menuProc.running = false;
        menuProc.command = m.argv;
        menuProc.running = true;
    }

    // Esc: out of a menu first, else close.
    function back(): void {
        if (root.menuId !== "")
            root.leaveMenu();
        else
            IslandState.close();
    }

    function takeMenuRequest(): void {
        const id = IslandState.launcherMenuRequest;
        if (id === "")
            return;
        IslandState.launcherMenuRequest = "";
        root.enterMenu(id);
    }

    onActiveChanged: {
        if (root.active) {
            root.menuId = "";
            root.menuItems = [];
            root.selected = 0;
            input.text = "";
            IslandState.launcherQuery = "";
            input.forceActiveFocus();
            root.takeMenuRequest();
        } else {
            refreshTimer.stop();
            menuProc.running = false;
        }
    }

    onQueryChanged: root.selected = 0

    onRowsChanged: {
        if (root.selected >= root.rows.length)
            root.selected = Math.max(0, root.rows.length - 1);
    }

    onSelectedChanged: list.positionViewAtIndex(root.selected, ListView.Contain)

    // Only the lit layer reports to the IPC; the values stay at their last value while the layer leaves.
    Binding {
        target: IslandState
        property: "launcherMode"
        value: root.mode
        when: root.active
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: IslandState
        property: "launcherCount"
        value: root.rows.length
        when: root.active
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: IslandState
        property: "launcherResult"
        value: root.current?.label ?? ""
        when: root.active
        restoreMode: Binding.RestoreNone
    }

    Connections {
        target: IslandState

        function onLauncherQueryChanged(): void {
            if (root.active && input.text !== IslandState.launcherQuery)
                input.text = IslandState.launcherQuery;
        }

        function onLauncherMenuRequestChanged(): void {
            if (root.active)
                root.takeMenuRequest();
        }
    }

    Process {
        id: menuProc

        stdout: StdioCollector {
            id: menuOut

            onStreamFinished: {
                root.menuItems = menuOut.text.split("\n").filter(l => l.length > 0).map(l => {
                    const [active, label, sublabel, command] = l.split("\t");
                    return { active: active === "1", label: label ?? "", sublabel: sublabel ?? "", command: command ?? "" };
                });
            }
        }
    }

    Timer {
        id: refreshTimer

        interval: root.spec.refreshMs
        repeat: true
        onTriggered: {
            root.loadMenu();
            root.pendingRefreshes--;
            if (root.pendingRefreshes <= 0)
                refreshTimer.stop();
        }
    }

    component Kbd: Rectangle {
        property string label
        property real padY: Theme.layout.launcher.kbdPadY
        property color textColor: Theme.fg

        implicitWidth: kbdText.implicitWidth + 2 * Theme.layout.launcher.kbdPadX
        implicitHeight: kbdText.implicitHeight + 2 * padY
        radius: Theme.radii.kbd
        color: Theme.chip

        Text {
            id: kbdText

            anchors.centerIn: parent
            text: parent.label
            color: parent.textColor
            font.family: Theme.fonts.mono
            font.pixelSize: Theme.layout.launcher.kbdFont
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.spec.pad
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.spec.fieldH
            radius: Theme.radii.field
            color: Theme.tile

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.spec.fieldPadX
                anchors.rightMargin: root.spec.fieldPadX
                spacing: root.spec.fieldGap

                Components.Icon {
                    name: "search"
                    size: root.spec.searchIcon
                    color: Theme.fgMuted
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextInput {
                        id: input

                        anchors.fill: parent
                        anchors.leftMargin: root.spec.caretGap
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: Theme.fg
                        selectionColor: Theme.accentSoft
                        selectedTextColor: Theme.fg
                        font.family: Theme.fonts.ui
                        font.pixelSize: root.spec.queryFont

                        cursorDelegate: Rectangle {
                            width: root.spec.caretW
                            height: root.spec.caretH
                            color: Theme.accent
                        }

                        onTextChanged: {
                            if (root.active)
                                IslandState.launcherQuery = input.text;
                        }

                        Keys.onPressed: event => {
                            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                            if (event.key === Qt.Key_Escape) {
                                root.back();
                            } else if (event.key === Qt.Key_Down) {
                                root.move(1);
                            } else if (event.key === Qt.Key_Up) {
                                root.move(-1);
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.run(root.current);
                            } else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                root.run(root.rows[event.key - Qt.Key_1]);
                            } else {
                                return;
                            }
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: root.spec.caretGap
                        verticalAlignment: Text.AlignVCenter
                        visible: input.text === ""
                        text: root.menuId !== "" ? (Menus.get(root.menuId)?.title ?? "") + "…" : "Szukaj aplikacji, menu…"
                        color: Theme.fgDim
                        font.family: Theme.fonts.ui
                        font.pixelSize: root.spec.queryFont
                    }
                }

                Kbd {
                    label: "esc"
                    textColor: Theme.fgMuted
                }
            }
        }

        RowLayout {
            Layout.topMargin: root.spec.chipsPadTop
            Layout.bottomMargin: root.spec.chipsPadBottom
            Layout.leftMargin: root.spec.chipsPadX
            spacing: root.spec.chipsGap

            Repeater {
                model: root.chips

                Rectangle {
                    id: chip

                    required property var modelData

                    readonly property bool lit: chip.modelData.mode === (root.mode === "menu" ? "apps" : root.mode)

                    Layout.preferredHeight: root.spec.chipH
                    Layout.preferredWidth: chipRow.implicitWidth + 2 * root.spec.chipPadX
                    radius: Theme.radii.chip
                    color: chip.lit ? Theme.chip : "transparent"

                    Row {
                        id: chipRow

                        anchors.centerIn: parent
                        spacing: root.spec.chipPrefixGap

                        Text {
                            visible: chip.modelData.prefix !== ""
                            text: chip.modelData.prefix
                            color: Theme.accent
                            font.family: Theme.fonts.mono
                            font.pixelSize: root.spec.chipFont
                        }

                        Text {
                            text: chip.modelData.label
                            color: chip.lit ? Theme.fg : Theme.fgMuted
                            font.family: Theme.fonts.ui
                            font.pixelSize: root.spec.chipFont
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.spec.visibleRows * root.rowH + (root.spec.visibleRows - 1) * root.spec.rowGap

            ListView {
                id: list

                anchors.fill: parent
                clip: true
                spacing: root.spec.rowGap
                boundsBehavior: Flickable.StopAtBounds
                model: root.rows

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool picked: row.index === root.selected
                    readonly property string iconUrl: row.modelData.iconName ? Quickshell.iconPath(row.modelData.iconName, true) : ""
                    readonly property bool pictured: row.iconUrl !== "" && rowImage.status === Image.Ready

                    width: list.width
                    height: root.rowH
                    radius: Theme.radii.tile
                    color: row.picked ? Theme.sel : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        enabled: root.active
                        onClicked: root.run(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.spec.rowPadX
                        anchors.rightMargin: root.spec.rowPadX
                        spacing: root.spec.rowInnerGap

                        Rectangle {
                            Layout.preferredWidth: root.spec.icon
                            Layout.preferredHeight: root.spec.icon
                            radius: Theme.radii.iconMd
                            color: Theme.chip

                            Image {
                                id: rowImage

                                anchors.centerIn: parent
                                width: root.spec.iconImage
                                height: root.spec.iconImage
                                source: row.iconUrl
                                sourceSize.width: root.spec.iconImage
                                sourceSize.height: root.spec.iconImage
                                fillMode: Image.PreserveAspectFit
                                visible: row.pictured
                            }

                            Components.Icon {
                                anchors.centerIn: parent
                                visible: !row.pictured && (row.modelData.glyph ?? "") !== ""
                                name: row.modelData.glyph ?? ""
                                size: root.spec.iconGlyph
                                color: Theme.fg
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !row.pictured && (row.modelData.glyph ?? "") === ""
                                text: row.modelData.label.charAt(0).toUpperCase()
                                color: Theme.fg
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
                                textFormat: Text.StyledText
                                text: root.highlight(row.modelData.label, row.modelData.ranges)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: Theme.fg
                                font.family: Theme.fonts.ui
                                font.pixelSize: root.spec.nameFont
                                font.weight: Font.Medium
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: row.modelData.sub !== ""
                                text: row.modelData.sub
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                color: Theme.fgMuted
                                font.family: Theme.fonts.ui
                                font.pixelSize: root.spec.descFont
                            }
                        }

                        Rectangle {
                            visible: (row.modelData.dot ?? 0) === 1
                            Layout.preferredWidth: root.spec.dot
                            Layout.preferredHeight: root.spec.dot
                            radius: root.spec.dot / 2
                            color: Theme.accent
                        }

                        Kbd {
                            visible: row.picked
                            label: "↵"
                            padY: root.spec.kbdPadYRow
                        }

                        Text {
                            visible: !row.picked && row.index < root.spec.shortcuts
                            text: "^" + (row.index + 1)
                            color: Theme.fgMuted
                            font.family: Theme.fonts.mono
                            font.pixelSize: root.spec.kbdFont
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.rows.length === 0 && !menuProc.running
                text: "Brak wyników"
                color: Theme.fgMuted
                font.family: Theme.fonts.ui
                font.pixelSize: root.spec.emptyFont
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 1 + root.spec.footerPadTop + hints.implicitHeight + root.spec.footerPadBottom

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Theme.divider
            }

            RowLayout {
                id: hints

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 1 + root.spec.footerPadTop
                anchors.leftMargin: root.spec.footerPadX
                anchors.rightMargin: root.spec.footerPadX
                spacing: root.spec.footerGap

                Repeater {
                    model: [["↑↓", "wybierz"], ["↵", "otwórz"], ["^1–9", "wiersz"]]

                    Text {
                        required property var modelData

                        textFormat: Text.StyledText
                        text: "<font color=\"" + Theme.fg + "\">" + modelData[0] + "</font> " + modelData[1]
                        color: Theme.fgMuted
                        font.family: Theme.fonts.ui
                        font.pixelSize: root.spec.footerFont
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "prefiks zmienia tryb"
                    color: Theme.fgMuted
                    font.family: Theme.fonts.ui
                    font.pixelSize: root.spec.footerFont
                }
            }
        }
    }
}
