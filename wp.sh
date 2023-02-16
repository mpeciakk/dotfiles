#!/bin/bash
wallpapers=($(ls ~/.config/wallpapers))
random=$((RANDOM % ${#wallpapers[@]}))
while [ "$(cat ~/.config/wallpapers/.random)" == "${wallpapers[$random]}" ]; do
	random=$((RANDOM % ${#wallpapers[@]}))
done
wal -i ~/.config/wallpapers/${wallpapers[$random]} 2>/dev/null
xwallpaper --zoom ~/.config/wallpapers/${wallpapers[$random]}
echo "${wallpapers[$random]}" > ~/.config/wallpapers/.random
