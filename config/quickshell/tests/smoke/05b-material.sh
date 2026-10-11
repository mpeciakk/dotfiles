call island open control
wait_ms 700
shot material-glass
printf '{"wallpaper":"~/.config/dotfiles/wp2.jpg","lock":{"timeout":0},"island":{"glass":false}}' > "$CFG"
wait_ms 900
shot material-solid
