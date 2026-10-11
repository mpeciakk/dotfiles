.pragma library

// How the launcher starts things (DESIGN W11): every start goes through `uwsm app`, so it runs in its own
// systemd scope in app-graphical.slice and outlives a restart of quickshell.service (a restart kills the
// service's whole cgroup, and a plain execDetached child stays in it).

// uwsm's Desktop Entry ID rule (Val.entry_id in uwsm's misc.py), without the ".desktop" suffix; uwsm refuses
// an ID outside it (a Steam entry "Big Walk.desktop").
var ENTRY_ID = /^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$/;

function wrap(argv) {
    return ["uwsm", "app", "--"].concat(argv);
}

// A valid ID runs as the desktop entry (uwsm reads Path=, and Terminal= through xdg-terminals.list, which no
// host has yet: it then picks the first TerminalEmulator entry); any other runs its parsed command
// (Terminal= ignored, as DesktopEntry.execute() did; the caller passes the working directory).
function entryArgv(id, command) {
    return ENTRY_ID.test(id) ? wrap([id + ".desktop"]) : wrap(command);
}
