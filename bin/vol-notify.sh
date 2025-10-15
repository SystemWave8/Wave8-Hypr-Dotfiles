#!/bin/bash

sink="@DEFAULT_AUDIO_SINK@"

# Extract numeric volume (0-1 float)
vol=$(wpctl get-volume "$sink" | awk '{print $2}')

# Get mute state
muted=$(wpctl get-mute "$sink")

# Set a fixed notification ID for volume updates
notify_id=9999

if [[ "$muted" == "true" ]]; then
    notify-send -r $notify_id "Volume" "Muted" -i audio-volume-muted
else
    # Convert to 0-100%
    vol_percent=$(awk "BEGIN {printf \"%d\", $vol*100}")

    # Build 10-block bar
    blocks=$(( (vol_percent + 5) / 10 ))
    bar=$(printf '█%.0s' $(seq 1 $blocks))
    empty=$(printf '░%.0s' $(seq 1 $((10 - blocks))))

    notify-send -r $notify_id "Volume" "$bar$empty  $vol_percent%" -i audio-volume-high
fi
