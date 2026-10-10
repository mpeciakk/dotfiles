# The launcher: the apps list is populated on the first open (DesktopEntries loads asynchronously), each prefix
# switches the mode, a menu opens straight from IPC. Test mode: nothing is ever executed, only logged.
# Menu rows are never printed (the clipboard menu lists private content); only vpn is opened, and only listed.
call island open launcher
wait_ms 600
expect island launcherMode apps
count="$(qs ipc -p "$DIR" prop get island launcherCount 2>&1)"
if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 0 ]; then echo "ok: island.launcherCount = $count (> 0)"; else echo "FAIL: island.launcherCount expected > 0 got '$count'"; FAILED=1; fi
call island launcherSetQuery "=2+3*4"
wait_ms 200
expect island launcherMode calc
expect island launcherResult 14
expect island launcherCount 1
shot launcher-calc
call island launcherSetQuery "=2+"
wait_ms 200
expect island launcherCount 0
call island launcherSetQuery ">echo hi"
wait_ms 200
expect island launcherMode command
expect island launcherResult "Uruchom: echo hi"
call island launcherSetQuery "@"
wait_ms 200
expect island launcherMode windows
call island launcherSetQuery "zzzqqqxxx"
wait_ms 200
expect island launcherMode apps
expect island launcherCount 0
call island launcherMenu vpn
wait_ms 600
expect island launcherMode menu
expect island launcherQuery ""
call island close
wait_ms 600
call island open launcher
wait_ms 600
expect island launcherMode apps
# The selected label does not outlive the launcher (the clipboard menu's preview would stay readable over IPC).
call island launcherSetQuery "=2+3*4"
wait_ms 200
expect island launcherResult 14
call island close
wait_ms 600
expect island launcherResult ""
