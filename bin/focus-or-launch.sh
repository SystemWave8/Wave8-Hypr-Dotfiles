#!/bin/bash

# Usage: focus-or-launch.sh <class> <launch command...>
# Example: focus-or-launch.sh brave-youtube.com__-Default "brave --app=https://youtube.com"

CLASS="$1"
shift
CMD="$@"

# Find a matching window ID
WINID=$(hyprctl clients | awk -v cls="$CLASS" '/Window/{addr=$2}/class:/{if ($2 == cls) print addr}')

if [ -n "$WINID" ]; then
    # Focus existing window
    hyprctl dispatch focuswindow address:0x$WINID
else
    # Launch new instance
    $CMD &
fi
