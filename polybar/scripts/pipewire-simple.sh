#!/bin/sh

getDefaultSink() {
    defaultSink=$(pactl info | awk -F : '/Default Sink:/{print $2}')
    description=$(pactl list sinks | sed -n "/${defaultSink}/,/Description/s/^\s*Description: \(.*\)/\1/p")
    echo "${description}"
}

getDefaultSource() {
    defaultSource=$(pactl info | awk -F : '/Default Source:/{print $2}')
    description=$(pactl list sources | sed -n "/${defaultSource}/,/Description/s/^\s*Description: \(.*\)/\1/p")
    echo "${description}"
}

VOLUME=$(pamixer --get-volume-human)
VOLUME_RAW=$(pamixer --get-volume)
SINK=$(getDefaultSink)
SOURCE=$(getDefaultSource)

case $1 in
    "--up")
        pamixer --increase 10
        ;;
    "--down")
        pamixer --decrease 10
        ;;
    "--mute")
        pamixer --toggle-mute
        ;;
    *)
        if [ "$VOLUME" = "muted" ]; then
            echo "ﱝ  ${VOLUME}"
        elif (( $VOLUME_RAW < 33 )); then
            echo "  ${VOLUME}"
        elif (( $VOLUME_RAW > 33 )) && (( $VOLUME_RAW < 66 )); then
            echo "  ${VOLUME}"
        else
            echo "  ${VOLUME}"
        fi
esac