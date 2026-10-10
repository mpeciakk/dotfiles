wait_ms 600
# Two unread notifications (DND keeps the island at rest): the badge must read "2".
call notifs dnd true
call notifs inject a x y
call notifs inject a x y
expect notifs unread 2
wait_ms 600
shot rest
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
