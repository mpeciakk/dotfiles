pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../components"
import "../services"

// Custom session lock (WlSessionLock + PAM), styled after qylock: a wallpaper
// background, a big clock + date near the top, and a centred avatar / name /
// password. Lock via IPC — bind it to a niri key:
//   qs ipc call lock lock
// Authenticates the current user against the bundled assets/pam.d/passwd
// (pam_unix → your login password). One WlSessionLock manages a surface per
// screen automatically.
//
// SAFETY: if PAM is misconfigured or quickshell crashes while locked, the
// compositor keeps the session locked — recover from a TTY (Ctrl+Alt+F2) with
// `loginctl unlock-session` or by restarting quickshell.
Scope {
    id: root

    property bool errorState: false

    function tryUnlock(pw: string): void {
        if (pam.active || pw.length === 0)
            return;
        lock.pendingPw = pw;
        pam.start();
    }

    WlSessionLock {
        id: lock

        property string pendingPw: ""

        surface: Component {
            WlSessionLockSurface {
                id: surface

                color: "black"

                // Blurred wallpaper + dim for text contrast.
                Image {
                    anchors.fill: parent
                    source: Config.wallpaper ? "file://" + Config.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: surface.screen ? surface.screen.width * surface.screen.devicePixelRatio : 0
                    sourceSize.height: surface.screen ? surface.screen.height * surface.screen.devicePixelRatio : 0

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: false
                        blurEnabled: true
                        blur: 1
                        blurMax: 48
                        blurMultiplier: 1
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.3
                }

                // Whole UI, faded in on appear.
                Item {
                    id: ui

                    anchors.fill: parent
                    opacity: 0

                    Component.onCompleted: {
                        opacity = 1;
                        pwInput.forceActiveFocus();
                    }

                    Behavior on opacity {
                        Anim {
                            curve: Appearance.anim.curves.standard
                            duration: Appearance.anim.durations.normal
                        }
                    }

                    // Clock + date, near the top.
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: parent.height * 0.16
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Time.timeStr
                            color: "white"
                            font.pixelSize: 64
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Time.dateStr
                            color: "white"
                            font.pixelSize: Config.font.xl
                            font.bold: true
                        }
                    }

                    // Avatar + name + password, centred.
                    Column {
                        anchors.centerIn: parent
                        spacing: 14

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 96
                            height: 96
                            radius: 48
                            color: Colours.surface0
                            border.width: 2
                            border.color: Qt.alpha("white", 0.5)
                            clip: true

                            Image {
                                anchors.fill: parent
                                visible: Config.lock.avatar !== ""
                                source: Config.lock.avatar ? "file://" + Config.lock.avatar : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: Config.lock.avatar === ""
                                text: (Config.lock.name || Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                                color: "white"
                                font.pixelSize: 40
                                font.bold: true
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Config.lock.name || Quickshell.env("USER") || "user"
                            color: "white"
                            font.pixelSize: Config.font.xxxl
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 280
                            height: 42
                            radius: height / 2
                            color: Qt.alpha(Colours.surface0, 0.7)
                            border.width: 1
                            border.color: root.errorState ? Colours.red : Qt.alpha("white", 0.2)

                            TextInput {
                                id: pwInput

                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 44
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                passwordCharacter: "●"
                                color: "white"
                                font.pixelSize: Config.font.lg
                                clip: true
                                enabled: !pam.active
                                focus: true

                                onTextChanged: root.errorState = false
                                onAccepted: root.tryUnlock(pwInput.text)

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    visible: pwInput.text === ""
                                    text: pam.active ? "Authenticating…" : root.errorState ? "Wrong password" : "Password"
                                    color: root.errorState ? Colours.red : Qt.alpha("white", 0.5)
                                    font: pwInput.font
                                }
                            }

                            StateButton {
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                width: 32
                                height: 32
                                radius: 16
                                effectColor: "white"
                                onClicked: root.tryUnlock(pwInput.text)

                                Text {
                                    anchors.centerIn: parent
                                    text: "→"
                                    color: "white"
                                    font.pixelSize: Config.font.xxl
                                }
                            }
                        }
                    }

                    // Clear the field + flag the error when a password is rejected.
                    Connections {
                        target: pam

                        function onCompleted(res: int): void {
                            if (res !== PamResult.Success) {
                                pwInput.text = "";
                                root.errorState = true;
                            }
                        }
                    }

                    // Now-playing, bottom-centre (hidden when nothing plays).
                    Media {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.height * 0.12
                    }
                }
            }
        }
    }

    PamContext {
        id: pam

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(lock.pendingPw);
                lock.pendingPw = "";
            }
        }
        onCompleted: res => {
            if (res === PamResult.Success)
                lock.locked = false;
        }
    }

    // Auto-lock after Config.lock.timeout seconds of inactivity (0 disables).
    // respectInhibitors keeps it from firing while something inhibits idle
    // (e.g. video playback). Disabled while already locked so it re-arms on unlock.
    IdleMonitor {
        enabled: Config.lock.timeout > 0 && !lock.locked
        timeout: Config.lock.timeout
        respectInhibitors: true
        onIsIdleChanged: if (isIdle)
            lock.locked = true
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lock.locked = true;
        }
        function unlock(): void {
            if (pam.active)
                pam.abort();
            lock.pendingPw = "";
            lock.locked = false;
        }
        function isLocked(): bool {
            return lock.locked;
        }
    }
}
