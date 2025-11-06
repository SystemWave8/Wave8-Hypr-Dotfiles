#!/bin/bash

CLASS="$1"
shift
CMD="$@"

# Find a matching window ID (works for multi-word class names)
WINID=$(hyprctl clients | awk -v cls="$CLASS" '
/Window/ { addr = $2 }
/^[[:space:]]*class:/ {
    line = $0
    sub(/^[[:space:]]*class:[[:space:]]*/, "", line)  # strip "class:" + spaces/tabs
    if (line == cls) print addr
}')

if [ -n "$WINID" ]; then
    hyprctl dispatch focuswindow address:0x$WINID
else
    $CMD &
fi
