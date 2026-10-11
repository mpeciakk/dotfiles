# The notification centre: opening marks everything read, the island height follows the content,
# dismissing and clearing empty it. DND stays on so no toast interferes.
# niri announces each screenshot as a notification of its own (this instance is the daemon): the
# shot is the last line.
call notifs clear
call notifs dnd true
call island close
call notifs inject appA A1 x
call notifs inject appA A2 x
call notifs inject appB B1 x
wait_ms 400
expect notifs count 3
expect notifs unread 3
call island open center
wait_ms 700
expect island current center
expect notifs unread 0
# appA collapsed with one stack layer, appB single: 14 + 36 + 10 + (12 + (28 + 64 + 7) + (28 + 64)) + 16
expect island targetH 279
# A notification arriving while the centre is open is read at once and grows the list: appB gets a stack layer too.
call notifs inject appB B2 x
wait_ms 300
expect notifs unread 0
expect island targetH 286
# Closed again: the badge counts only what arrived since (unread, not the total).
call island close
wait_ms 600
call notifs inject appC C1 x
wait_ms 300
expect notifs count 5
expect notifs unread 1
expect island targetW 252
# An empty centre is hMin tall.
call notifs clear
call island open center
wait_ms 700
expect notifs count 0
expect island targetH 170
# Twelve groups overflow: the island stops at hMax (620) and the list scrolls inside it.
for i in $(seq 1 12); do call notifs inject "app$i" t x; done
wait_ms 400
expect island targetH 620
call notifs clear
call island close
wait_ms 600
expect notifs dndOn true
expect notifs count 0
# Last: rebuild the list for the picture and look at it open.
call notifs inject appA A1 x
call notifs inject appA A2 x
call notifs inject appB B1 x
call island open center
wait_ms 900
shot center
