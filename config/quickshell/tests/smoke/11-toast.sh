call notifs inject Wyspa pierwsze x
wait_ms 300
expect island current toast
call notifs inject Wyspa drugie x
wait_ms 600
expect island contentState toast
# The toast times out after Theme.motion.toastTimeoutMs (3600 ms).
wait_ms 4500
expect island current rest
# DND keeps the toast away.
call notifs dnd true
call notifs inject Wyspa trzecie x
wait_ms 300
expect island current rest
call notifs dnd false
# Last: a series again for the picture (niri's screenshot notification would restart the toast).
call notifs inject Wyspa pierwsze x
wait_ms 300
call notifs inject Wyspa drugie x
wait_ms 600
shot toast-series
