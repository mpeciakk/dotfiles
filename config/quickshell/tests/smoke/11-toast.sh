call notifs inject Wyspa pierwsze x
wait_ms 300
expect island current toast
call notifs inject Wyspa drugie x
wait_ms 600
expect island contentState toast
shot toast-series
# niri announces each screenshot as a notification of its own, which restarts the toast's 3600 ms.
wait_ms 5500
expect island current rest
# DND keeps the toast away.
call notifs dnd true
call notifs inject Wyspa trzecie x
wait_ms 300
expect island current rest
call notifs dnd false
