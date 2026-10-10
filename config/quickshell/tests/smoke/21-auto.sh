# Automatic theme mode (reference R34): by wallpaper luminance, by sun, and the legibility boost.
# Only the temp config copy ($CFG) is written; Theme hot-reloads it.
python3 -I -c 'from PIL import Image; Image.new("RGB", (64, 64), (250, 250, 250)).save("/tmp/wyspa-bright.png"); Image.new("RGB", (64, 64), (10, 10, 10)).save("/tmp/wyspa-black.png")'
expect theme mode dark

# A dark wallpaper keeps dark, and no boost: the dark glass island stays at its own alpha.
printf '{"wallpaper":"/tmp/wyspa-black.png","lock":{"timeout":0},"island":{"modeSource":"wallpaper"}}' > "$CFG"
wait_ms 1500
expect theme mode dark
expect theme islandBg "#47161224"

# A bright wallpaper flips to light.
printf '{"wallpaper":"/tmp/wyspa-bright.png","lock":{"timeout":0},"island":{"modeSource":"wallpaper"}}' > "$CFG"
wait_ms 1500
expect theme mode light
# The boost is for the dark theme only.
expect theme islandBg "#70eae6f0"

# Dark theme (forced) over a bright wallpaper: the island's alpha rises by 0.2 (0x47 -> 0x7a), once the crossfade is done.
call theme setMode dark
wait_ms 900
expect theme islandBg "#7a161224"

# Only what is under the island counts: a bright wallpaper with a dark column at the centre (the island's crop
# is narrower than the column on any screen at least 1000 px wide) gives no boost.
python3 -I -c 'from PIL import Image; im = Image.new("RGB", (1000, 1000), (250, 250, 250)); im.paste((10, 10, 10), (400, 0, 600, 1000)); im.save("/tmp/wyspa-column.png")'
printf '{"wallpaper":"/tmp/wyspa-column.png","lock":{"timeout":0},"island":{"mode":"dark"}}' > "$CFG"
call theme setMode ""
wait_ms 1500
expect theme islandBg "#47161224"

# Sun mode without a location stays on the configured mode; the location comes from island.location.
printf '{"wallpaper":"/tmp/wyspa-black.png","lock":{"timeout":0},"island":{"modeSource":"sun","mode":"light"}}' > "$CFG"
call theme setMode ""
wait_ms 1500
expect theme mode light

# Sun mode on the equator at the longitude where it is solar noon now (light) and where it is solar midnight (dark);
# each is set against a configured mode of the opposite colour, so only the sun can produce the result.
NOON_LON="$(awk -v h="$(date -u +%H:%M | awk -F: '{print $1 + $2 / 60}')" 'BEGIN{l = (12 - h) * 15; if (l < -180) l += 360; print l}')"
MIDNIGHT_LON="$(awk -v l="$NOON_LON" 'BEGIN{print (l > 0) ? l - 180 : l + 180}')"
printf '{"wallpaper":"/tmp/wyspa-black.png","lock":{"timeout":0},"island":{"modeSource":"sun","mode":"dark","location":{"lat":0,"lon":%s}}}' "$NOON_LON" > "$CFG"
wait_ms 1500
expect theme mode light
printf '{"wallpaper":"/tmp/wyspa-black.png","lock":{"timeout":0},"island":{"modeSource":"sun","mode":"light","location":{"lat":0,"lon":%s}}}' "$MIDNIGHT_LON" > "$CFG"
wait_ms 1500
expect theme mode dark
