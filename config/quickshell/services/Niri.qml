pragma Singleton
pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io
import "../common"

Singleton {
    id: root
    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")

    property var workspaces: []
    property var windows: []
    property int focusedWindowIndex: -1
    property int focusedWorkspaceIndex: -1
    property string focusedWindowTitle: "(No active window)"

    onWindowsChanged: updateFocusedWindowTitle()
    onFocusedWindowIndexChanged: updateFocusedWindowTitle()

    function updateFocusedWindowTitle() {
        if (focusedWindowIndex >= 0 && focusedWindowIndex < windows.length) {
            focusedWindowTitle = windows[focusedWindowIndex].title || "(Unnamed window)";
        } else {
            focusedWindowTitle = "(No active window)";
        }
    }

    Socket {
        id: requestSocket
        path: root.socketPath
        connected: true
    }

    Socket {
        id: eventStreamSocket
        path: root.socketPath
        connected: true

        onConnectionStateChanged: {
            if (connected) {
                send('"EventStream"');
            }
        }

        parser: SplitParser {
            onRead: line => {
                try {
                    const event = JSON.parse(line);
                    root.handleNiriEvent(event);
                } catch (e) {
                    console.warn(`NiriService: Failed to parse event:\n${line}\nError: ${e}`);
                }
            }
        }
    }

    function handleNiriEvent(event) {
        const eventType = Object.keys(event)[0];

        switch (eventType) {
        case 'WorkspacesChanged':
            handleWorkspacesChanged(event.WorkspacesChanged);
            break;
        case 'WorkspaceActivated':
            handleWorkspaceActivated(event.WorkspaceActivated);
            break;
        case 'WorkspaceActiveWindowChanged':
            handleWorkspaceActiveWindowChanged(event.WorkspaceActiveWindowChanged);
            break;
        case 'WindowFocusChanged':
            handleWindowFocusChanged(event.WindowFocusChanged);
            break;
        case 'WindowsChanged':
            handleWindowsChanged(event.WindowsChanged);
            break;
        case 'WindowOpenedOrChanged':
            handleWindowOpenedOrChanged(event.WindowOpenedOrChanged);
        }

        function handleWorkspacesChanged(data) {
            const workspacesList = [];

            for (const ws of data.workspaces) {
                workspacesList.push({
                    id: ws.id,
                    idx: ws.idx,
                    name: ws.name || "",
                    output: ws.output || "",
                    isFocused: ws.is_focused === true,
                    isActive: ws.is_active === true,
                    isUrgent: ws.is_urgent === true,
                    activeWindowId: ws.active_window_id
                });
            }

            workspacesList.sort((a, b) => {
                return a.id - b.id;
            });

            root.workspaces = workspacesList;
        }

        function handleWorkspaceActivated(data) {
            const idx = root.workspaces.findIndex(ws => ws.id === data.id);

            root.workspaces = root.workspaces.map((ws, i) => {
                return {
                    id: ws.id,
                    idx: ws.idx,
                    name: ws.name,
                    output: ws.output,
                    isFocused: i === idx,
                    isActive: ws.isActive,
                    isUrgent: ws.isUrgent,
                    activeWindowId: ws.activeWindowId
                };
            });

            focusedWorkspaceIndex = idx;
        }

        function handleWindowFocusChanged(data) {
            const focusedId = data.id;
            if (focusedId) {
                root.focusedWindowIndex = root.windows.findIndex(w => w.id === focusedId);
                if (root.focusedWindowIndex < 0) {
                    root.focusedWindowIndex = 0;
                }
            } else {
                root.focusedWindowIndex = -1;
            }
        }

        function handleWindowsChanged(data) {
            const windowsData = data.windows;
            const windowsList = [];
            for (const win of windowsData) {
                windowsList.push({
                    id: win.id,
                    title: win.title || "",
                    appId: win.app_id || "",
                    workspaceId: win.workspace_id || null,
                    isFocused: win.is_focused === true
                });
            }

            windowsList.sort((a, b) => a.id - b.id);
            root.windows = windowsList;
            for (let i = 0; i < windowsList.length; i++) {
                if (windowsList[i].isFocused) {
                    root.focusedWindowIndex = i;
                    break;
                }
            }
        }

        function handleWorkspaceActiveWindowChanged(data) {
            const idx = root.workspaces.findIndex(ws => ws.id === data.workspace_id);

            root.workspaces = root.workspaces.map((ws, i) => {
                return {
                    id: ws.id,
                    idx: ws.idx,
                    name: ws.name,
                    output: ws.output,
                    isFocused: i === idx,
                    isActive: ws.isActive,
                    isUrgent: ws.isUrgent,
                    activeWindowId: ws.activeWindowId
                };
            });

            focusedWorkspaceIndex = idx;
        }

        function handleWindowOpenedOrChanged(data) {
            console.log(data);
            const window = data.window;
            const idx = root.windows.findIndex(w => w.id === window.id);
            const windowsList = [...windows];

            if (idx >= 0) {
                windowsList[idx] = {
                    id: window.id,
                    title: window.title || "",
                    appId: window.app_id || "",
                    workspaceId: window.workspace_id || null,
                    isFocused: window.is_focused === true
                };
            } else {
                windowsList.push({
                    id: window.id,
                    title: window.title || "",
                    appId: window.app_id || "",
                    workspaceId: window.workspace_id || null,
                    isFocused: window.is_focused === true
                });
            }

            windowsList.sort((a, b) => a.id - b.id);
            root.windows = windowsList;

            for (let i = 0; i < windowsList.length; i++) {
                if (windowsList[i].isFocused) {
                    root.focusedWindowIndex = i;
                    break;
                }
            }
        }
    }
}
