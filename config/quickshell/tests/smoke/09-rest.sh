wait_ms 600
# Two more unread notifications than at the start (DND keeps the island at rest; a stray real notification may
# already be counted, hence relative): the badge must read base + 2.
unread="$(qs ipc -p "$DIR" prop get notifs unread 2>&1)"
if [[ "$unread" =~ ^[0-9]+$ ]]; then echo "ok: notifs.unread baseline = $unread"; else echo "FAIL: notifs.unread baseline expected a number got '$unread'"; FAILED=1; unread=0; fi
call notifs dnd true
call notifs inject a x y
call notifs inject a x y
expect notifs unread "$((unread + 2))"
wait_ms 600
expect island contentState rest
# contentState is "rest" even for an empty host; this proves the Rest layer itself loaded and went active.
expect island restLoaded true
# Entering a state that has a layer takes scale delay + duration; a layerless one only the opacity
# end (380 ms). Stretch the scale so that a timer interval left over from the previous (layerless)
# target would show: the layer's enter must really last until 120 + 1500 ms.
printf '{"wallpaper":"~/.config/dotfiles/wp2.jpg","lock":{"timeout":0},"island":{"motion":{"enterScaleMs":1500}}}' > "$CFG"
wait_ms 300
call island open launcher
wait_ms 600
call island close
wait_ms 900
expect island contentState ""
wait_ms 1100
expect island contentState rest
shot rest
