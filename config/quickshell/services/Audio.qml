pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default audio sink (Pipewire) — volume/mute state and controls. PwObjectTracker
// keeps the sink's audio bound so volume/muted stay live.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: root.sink?.ready ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false

    function setVolume(v: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function changeVolume(delta: real): void {
        root.setVolume(root.volume + delta);
    }
    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    // Nerd Font volume glyph for the current level/mute state (bar + OSD).
    function volumeGlyph(): string {
        if (root.muted || root.volume <= 0)
            return String.fromCodePoint(0xf0581);   // volume-off
        if (root.volume < 0.34)
            return String.fromCodePoint(0xf057f);   // volume-low
        if (root.volume < 0.67)
            return String.fromCodePoint(0xf0580);   // volume-medium
        return String.fromCodePoint(0xf057e);       // volume-high
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
