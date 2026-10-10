# The toast's "+N" series: counts while the toast is up, ends with it, and never counts a refused notification.
# No `shot` here: niri announces each screenshot as a notification of its own, which would bump the series.
# Assert `series` only, never count/unread: a stray real notification may reach this instance.
call notifs clear
call notifs dnd false
call island close
expect island current rest
call notifs inject Wyspa pierwsze x
wait_ms 300
expect island current toast
expect notifs series 1
call notifs inject Wyspa drugie x
wait_ms 300
expect notifs series 2
# The toast times out after Theme.motion.toastTimeoutMs (3600 ms); the series ends with it.
wait_ms 4500
expect island current rest
expect notifs series 0
# A notification the toast refuses (launcher is up) does not start a series.
call island open launcher
expect island current launcher
call notifs inject Wyspa trzecie x
wait_ms 300
expect island current launcher
expect notifs series 0
call island close
