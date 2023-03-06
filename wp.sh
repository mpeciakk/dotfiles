#!/bin/bash
wallpapers=($(ls ~/.config/wallpapers))
random=$((RANDOM % ${#wallpapers[@]}))
while [ "$(cat ~/.config/wallpapers/.random)" == "${wallpapers[$random]}" ]; do
	random=$((RANDOM % ${#wallpapers[@]}))
done

wp=${wallpapers[$random]}

if [ ! -z "$1" ]; then
	wp="$1"
fi

wal -i ~/.config/wallpapers/$wp 2>/dev/null
xwallpaper --zoom ~/.config/wallpapers/$wp
echo "$wp" > ~/.config/wallpapers/.random
