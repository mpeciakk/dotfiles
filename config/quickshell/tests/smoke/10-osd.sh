wait_ms 1800
# The values settling at startup must not have raised an OSD.
expect island current rest
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+
wait_ms 200
expect island current osd
wait_ms 500
expect island contentState osd
shot osd
wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-
wait_ms 1700
expect island current rest
