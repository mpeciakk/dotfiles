MIC_MUTED=$(pactl get-source-mute 0 | awk -F' ' '{print $2}')

if [ "$MIC_MUTED" = "no" ]; then
  echo "MIC"
else
  echo ""
fi
