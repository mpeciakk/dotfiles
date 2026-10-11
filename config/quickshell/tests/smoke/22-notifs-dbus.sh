# smoke: private-bus
# Notifications over D-Bus (DESIGN W15), on a private session bus: this instance is the notification daemon.
# A replacement updates the card in place and moves it to the top (no new unread, no new series), a close by the
# app removes the card, a transient notification is toast only. `series` counts while the toast is up (3.6 s from
# the last arrival), so the checks stay close together. No `shot`: nothing here needs one.
call notifs clear
call notifs dnd false
call island close
expect island current rest

id=$(notify-send -p a)
wait_ms 300
expect notifs count 1
expect notifs unread 1
expect notifs series 1
expect notifs top a

# The replacement: same card, new text, nothing counted.
notify-send -r "$id" b
wait_ms 300
expect notifs count 1
expect notifs unread 1
expect notifs series 1
expect notifs top b

# A second card; replacing the first moves it above the second.
id2=$(notify-send -p c)
wait_ms 300
expect notifs count 2
expect notifs unread 2
expect notifs series 2
expect notifs top c
notify-send -r "$id" d
wait_ms 300
expect notifs count 2
expect notifs unread 2
expect notifs series 2
expect notifs top d

# Transient: the toast shows it, the history and the badge do not know it.
notify-send -e t
wait_ms 300
expect island current toast
expect notifs count 2
expect notifs unread 2
expect notifs series 3
expect notifs top d

# A close by the app removes the card.
close() { gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.CloseNotification "$1" >/dev/null || { echo "FAIL: CloseNotification $1"; FAILED=1; }; }
close "$id"
wait_ms 300
expect notifs count 1
expect notifs unread 1
expect notifs top c
close "$id2"
wait_ms 300
expect notifs count 0
expect notifs unread 0
