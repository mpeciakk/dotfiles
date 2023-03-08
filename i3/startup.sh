#!/bin/bash

bash $HOME/.config/polybar/launch.sh --panels
picom --config $HOME/.config/picom/picom.conf --experimental-backends
killall wired && wired &
bash ~/.fehbg &
nm-applet
setxkbmap pl