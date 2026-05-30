import QtQuick
import "../components"
import "../services"

// Niri workspace indicators for one output. Click to focus.
Column {
    id: root

    required property string output

    spacing: Config.workspaces.spacing

    // niri can report duplicated named workspaces (and keeps an empty trailing
    // "dynamic" one per output). Dedupe structurally — by name, keeping the
    // occupied instance (else the lowest idx) — and drop empty unnamed ones.
    // This deliberately ignores live focus/active state so the list identity is
    // stable across focus switches and the chip delegates animate instead of
    // being torn down and rebuilt.
    function score(w): int {
        return w.active_window_id !== null ? 1 : 0;
    }

    readonly property var list: {
        const named = ({});
        const extra = [];
        for (const w of Niri.workspaces) {
            if (w.output !== root.output)
                continue;
            if (w.name === null || w.name === "") {
                if (w.active_window_id !== null)
                    extra.push(w);
                continue;
            }
            const cur = named[w.name];
            if (!cur || root.score(w) > root.score(cur) || (root.score(w) === root.score(cur) && w.idx < cur.idx))
                named[w.name] = w;
        }
        return Object.values(named).concat(extra).sort((a, b) => a.idx - b.idx);
    }

    // Chips fade in on add and slide when the set reshuffles.
    add: Transition {
        Anim {
            property: "opacity"
            from: 0
            to: 1
            curve: Appearance.anim.curves.standard
            duration: Appearance.anim.durations.small
        }
    }
    move: Transition {
        Anim {
            properties: "x,y"
            curve: Appearance.anim.curves.expressiveDefaultSpatial
            duration: Appearance.anim.durations.expressiveDefaultSpatial
        }
    }

    Repeater {
        model: root.list

        delegate: StateButton {
            id: chip

            required property var modelData

            readonly property bool focused: Niri.focusedId === modelData.id
            readonly property bool active: Niri.activeByOutput[modelData.output] === modelData.id
            readonly property bool urgent: Niri.urgentIds[modelData.id] === true

            implicitWidth: Config.workspaces.chipHeight
            height: Config.workspaces.chipHeight
            radius: height / 2
            anchors.horizontalCenter: parent?.horizontalCenter
            color: focused ? Colours.mauve : urgent ? Colours.red : active ? Colours.surface1 : Colours.surface0

            // springy "pop" when this chip becomes the focused one
            scale: focused ? Config.workspaces.focusedScale : 1

            onClicked: Niri.focusWorkspace(chip.modelData.output, chip.modelData.idx)

            Behavior on color {
                CAnim {
                    curve: Appearance.anim.curves.expressiveDefaultEffects
                    duration: Appearance.anim.durations.expressiveDefaultEffects
                }
            }
            Behavior on scale {
                Anim {
                    curve: Appearance.anim.curves.expressiveDefaultSpatial
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                }
            }

            Text {
                id: label

                anchors.centerIn: parent
                text: chip.modelData.name && chip.modelData.name !== "" ? chip.modelData.name : chip.modelData.idx
                color: chip.focused ? Colours.base : Colours.text
                font.pixelSize: 12
                font.bold: chip.focused

                Behavior on color {
                    CAnim {
                        duration: Appearance.anim.durations.expressiveDefaultEffects
                    }
                }
            }
        }
    }
}
