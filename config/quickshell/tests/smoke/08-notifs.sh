expect island targetW 200
call notifs dnd true
call notifs inject test hello x
wait_ms 300
expect notifs unread 1
expect island targetW 252
call notifs dnd false
