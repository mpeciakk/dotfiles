pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import ".."

Singleton {
    id: root

    property var currentPlayer: null
    property real currentPosition: 0
    property int selectedPlayerIndex: 0
    property bool isPlaying: currentPlayer ? currentPlayer.isPlaying : false
    property string trackTitle: currentPlayer ? (currentPlayer.trackTitle || "Unknown Track") : ""
    property string trackArtist: currentPlayer ? (currentPlayer.trackArtist || "Unknown Artist") : ""
    property string trackAlbum: currentPlayer ? (currentPlayer.trackAlbum || "Unknown Album") : ""
    property string trackArtUrl: currentPlayer ? (currentPlayer.trackArtUrl || "") : ""
    property string trackUrl: currentPlayer ? (currentPlayer.metadata["xesam:url"] || "") : ""
    property real trackLength: currentPlayer ? currentPlayer.length : 0
    property bool canPlay: currentPlayer ? currentPlayer.canPlay : false
    property bool canPause: currentPlayer ? currentPlayer.canPause : false
    property bool canGoNext: currentPlayer ? currentPlayer.canGoNext : false
    property bool canGoPrevious: currentPlayer ? currentPlayer.canGoPrevious : false
    property bool canSeek: currentPlayer ? currentPlayer.canSeek : false
    property bool hasPlayer: getAvailablePlayers().length > 0

    function getAvailablePlayers() {
        if (!Mpris.players || !Mpris.players.values) {
            return [];
        }

        let allPlayers = Mpris.players.values;
        let controllablePlayers = [];

        for (let i = 0; i < allPlayers.length; i++) {
            let player = allPlayers[i];
            if (player && player.canControl) {
                controllablePlayers.push(player);
            }
        }

        return controllablePlayers;
    }

    function findActivePlayer() {
        let availablePlayers = getAvailablePlayers();
        if (availablePlayers.length === 0) {
            return null;
        }

        if (selectedPlayerIndex < availablePlayers.length) {
            return availablePlayers[selectedPlayerIndex];
        } else {
            selectedPlayerIndex = 0;
            return availablePlayers[0];
        }
    }

    function updateCurrentPlayer() {
        let newPlayer = findActivePlayer();
        if (newPlayer !== currentPlayer) {
            currentPlayer = newPlayer;
            currentPosition = currentPlayer ? currentPlayer.position : 0;
        }
    }

    function playPause() {
        if (currentPlayer) {
            if (currentPlayer.isPlaying) {
                currentPlayer.pause();
            } else {
                currentPlayer.play();
            }
        }
    }

    function play() {
        if (currentPlayer && currentPlayer.canPlay) {
            currentPlayer.play();
        }
    }

    function pause() {
        if (currentPlayer && currentPlayer.canPause) {
            currentPlayer.pause();
        }
    }

    function next() {
        if (currentPlayer && currentPlayer.canGoNext) {
            currentPlayer.next();
        }
    }

    function previous() {
        if (currentPlayer && currentPlayer.canGoPrevious) {
            currentPlayer.previous();
        }
    }

    Timer {
        id: positionTimer
        interval: 1000
        running: root.currentPlayer && root.currentPlayer.isPlaying && root.currentPlayer.length > 0
        repeat: true
        onTriggered: {
            if (root.currentPlayer && root.currentPlayer.isPlaying) {
                root.currentPosition = root.currentPlayer.position;
            }
        }
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.updateCurrentPlayer();
        }
    }

    Component.onCompleted: {
        root.updateCurrentPlayer();
    }
}
