pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../lib/niri.js" as N

// Talks to niri over its IPC event stream and exposes the live workspace list
// and open windows.
// Each workspace: { id, idx, name, output, active_window_id, ... }.
//
// `workspaces` is the structural list — it only changes when workspaces are
// added/removed/renamed, so the workspace widget's delegates stay alive across
// focus switches. Live focus/active/urgent state lives in separate reactive
// maps (keyed by workspace id) so flipping them animates the existing chips
// instead of rebuilding them.
Singleton {
    id: root

    property var workspaces: []
    property int focusedId: -1
    property var activeByOutput: ({})    // output name -> active workspace id
    property var urgentIds: ({})         // workspace id -> true

    // Open windows keyed by id, and the same set most-recently-focused first
    // (consumed by the launcher's `@` mode).
    property var windows: ({})
    readonly property var windowList: N.sortWindows(root.windows)

    // The output of the focused workspace = the monitor the user is on. Used to
    // place global popups (launcher) on the active monitor.
    readonly property string focusedOutput: {
        const w = root.workspaces.find(w => w.id === root.focusedId);
        return w ? w.output : "";
    }

    function focusWindow(id: int): void {
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)]);
    }

    function applyEvent(line: string): void {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }

        const windows = N.reduceWindows(root.windows, ev);
        if (windows !== root.windows)
            root.windows = windows;

        if (ev.WorkspacesChanged) {
            const list = ev.WorkspacesChanged.workspaces;
            root.workspaces = list;
            // Seed the live maps from the structural snapshot.
            const active = {};
            const urgent = {};
            let focused = -1;
            for (const w of list) {
                if (w.is_active)
                    active[w.output] = w.id;
                if (w.is_focused)
                    focused = w.id;
                if (w.is_urgent)
                    urgent[w.id] = true;
            }
            root.activeByOutput = active;
            root.urgentIds = urgent;
            root.focusedId = focused;
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const target = root.workspaces.find(w => w.id === id);
            if (!target)
                return;
            root.activeByOutput = Object.assign({}, root.activeByOutput, {
                [target.output]: id
            });
            if (ev.WorkspaceActivated.focused)
                root.focusedId = id;
        } else if (ev.WorkspaceUrgencyChanged) {
            const id = ev.WorkspaceUrgencyChanged.id;
            root.urgentIds = Object.assign({}, root.urgentIds, {
                [id]: ev.WorkspaceUrgencyChanged.urgent
            });
        }
    }

    Process {
        running: true
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            onRead: line => root.applyEvent(line)
        }
    }
}
