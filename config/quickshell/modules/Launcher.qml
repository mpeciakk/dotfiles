import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import "../services"

// Launcher content built on the reusable SearchList + ListRow.
//   • list mode (default): registered menus (Menus) on top, then apps (Apps.query).
//     Both filter by the search text; selecting a menu drills into it, selecting
//     an app launches it.
//   • menu mode: a chosen menu's items (from its `list` script); selecting one
//     runs its command then re-lists so the active dot refreshes.
// `startMenu` (set via IPC) opens straight into a menu. Esc backs out of a menu,
// then closes. Meant to live inside a (modal, keyboard-focused) Drawer.
Item {
    id: root

    signal close

    property string startMenu: ""

    property string menuId: ""
    property var menuItems: []

    readonly property string mode: menuId !== "" ? "menu" : "list"
    readonly property string filterText: palette.text.trim().toLowerCase()

    readonly property var results: {
        if (root.mode === "menu")
            return root.menuItems.filter(it => root.filterText === "" || it.label.toLowerCase().includes(root.filterText));
        // Menus first (filtered by title), then apps.
        const menus = Menus.list.filter(m => root.filterText === "" || m.title.toLowerCase().includes(root.filterText));
        return menus.concat(Apps.query(palette.text));
    }

    implicitWidth: palette.implicitWidth
    implicitHeight: palette.implicitHeight

    function activate(): void {
        palette.activate();
        if (root.startMenu)
            root.enterMenu(root.startMenu);
        else
            root.menuId = "";
    }
    function reset(): void {
        palette.reset();
        root.menuId = "";
    }

    function enterMenu(id: string): void {
        root.menuId = id;
        root.menuItems = [];   // drop the previous menu's rows so they don't flash
        palette.text = "";
        root.loadMenu();
    }
    function exitMenu(): void {
        root.menuId = "";
        palette.text = "";
    }
    function loadMenu(): void {
        const m = Menus.get(root.menuId);
        if (!m) {
            root.menuItems = [];
            return;
        }
        menuProc.running = false;
        menuProc.command = m.argv;
        menuProc.running = true;
    }

    // A result is a menu definition (has argv), a menu item (in menu mode), or an
    // app (DesktopEntry) — the row shape and the activate action differ per kind.
    function kindOf(m: var): string {
        if (root.menuId !== "")
            return "item";
        return m && m.argv !== undefined ? "menu" : "app";
    }

    // Activate a row (Enter or click).
    function run(item: var): void {
        if (!item)
            return;
        const k = root.kindOf(item);
        if (k === "menu") {
            root.enterMenu(item.id);
        } else if (k === "app") {
            Apps.launch(item);
            root.close();
        } else {
            if (item.command)
                Quickshell.execDetached(["sh", "-c", item.command]);
            // Re-list a few times: the toggle command (systemctl/tailscale) often
            // takes longer than one tick to change the reported state.
            root.pendingRefreshes = 4;
            refreshTimer.restart();
        }
    }

    // Row field accessors (shape differs per kind).
    function rowLabel(m: var): string {
        const k = root.kindOf(m);
        return (k === "menu" ? m.title : k === "app" ? m.name : m.label) ?? "";
    }
    function rowSub(m: var): string {
        const k = root.kindOf(m);
        if (k === "menu")
            return "Menu";
        if (k === "app")
            return (m.comment || m.genericName) ?? "";
        return m.sublabel ?? "";
    }
    function rowIcon(m: var): string {
        if (root.kindOf(m) === "item")
            return Quickshell.iconPath(Menus.get(root.menuId)?.icon ?? "", "application-x-executable");
        return Quickshell.iconPath(m.icon, "application-x-executable");   // menu def or app
    }
    function rowDot(m: var): int {
        if (root.kindOf(m) !== "item")
            return -1;
        return m.active ? 1 : 0;
    }

    Process {
        id: menuProc

        stdout: StdioCollector {
            id: menuOut

            onStreamFinished: {
                const lines = menuOut.text.split("\n").filter(l => l.length > 0);
                root.menuItems = lines.map(l => {
                    const p = l.split("\t");
                    return {
                        active: p[0] === "1",
                        label: p[1] ?? "",
                        sublabel: p[2] ?? "",
                        command: p[3] ?? ""
                    };
                });
            }
        }
    }

    property int pendingRefreshes: 0

    Timer {
        id: refreshTimer

        interval: 700
        repeat: true
        onTriggered: {
            root.loadMenu();
            root.pendingRefreshes--;
            if (root.pendingRefreshes <= 0)
                refreshTimer.stop();
        }
    }

    Component {
        id: rowDelegate

        ListRow {
            required property var modelData

            iconSource: root.rowIcon(modelData)
            label: root.rowLabel(modelData)
            sublabel: root.rowSub(modelData)
            dot: root.rowDot(modelData)

            onClicked: root.run(modelData)
        }
    }

    SearchList {
        id: palette

        anchors.fill: parent
        values: root.results
        delegate: rowDelegate
        placeholder: root.mode === "menu" ? (Menus.get(root.menuId)?.title ?? "") + "…" : "Search apps & menus…"

        onActivated: item => root.run(item)
        onEscaped: {
            if (root.mode === "menu")
                root.exitMenu();
            else
                root.close();
        }
    }
}
