# A notch on the focused output (DESIGN W14): rest sits beside it (205 + 2 x 124 = 453 wide, as tall as the notch),
# every other state grows by the notch height (osd 300x44 -> 300x87). The notch is the host config's top-level
# `notch` key, hot-reloaded; it is set here for whichever output is focused, whatever machine this runs on.
# Without a notch entry the geometry is today's (tests/island.test.mjs; every other smoke runs without one).
OUT="$(niri msg -j focused-output | jq -r .name)"
# Written in place in one go (cat >), never mv: the FileView watches the file's inode.
tmp="$(mktemp)"
jq --arg o "$OUT" '. + {notch: {($o): {w: 205, h: 43}}}' "$CFG" > "$tmp"
cat "$tmp" > "$CFG"
rm -f "$tmp"
wait_ms 1000
expect island targetW 453
expect island targetH 43
call island open osd
wait_ms 300
expect island targetW 300
expect island targetH 87
call island close
wait_ms 700
expect island targetW 453
expect island targetH 43
# An unread notification grows each side by (restBadge - rest) / 2: 453 -> 505, still centred on the notch.
# DND keeps the toast away, so the island stays at rest.
call notifs dnd true
call notifs inject a x y
wait_ms 700
expect island targetW 505
expect island targetH 43
# Last: the rest shot on the notch, the split with the badge (dots left, clock + badge right, the notch empty).
shot notch
