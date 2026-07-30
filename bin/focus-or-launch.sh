#!/bin/bash
# focus-or-launch.sh
# Usage: focus-or-launch.sh <window-class> "<launch command>"

CLASS="$1"
CMD="$2"

ADDR=$(hyprctl clients -j | jq -r --arg class "$CLASS" '.[] | select(.class==$class) | .address' | head -1)

if [ -n "$ADDR" ]; then
  hyprctl dispatch "hl.dsp.focus({window = \"address:$ADDR\"})"
else
  hyprctl dispatch "hl.dsp.exec_cmd(\"$CMD\")"
fi