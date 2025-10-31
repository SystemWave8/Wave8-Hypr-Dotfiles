#!/usr/bin/env bash
# toggle-window.sh <WM_CLASS> <command>
# Toggles an app: if its window exists, kill it; otherwise, launch it.

wm_class="$1"
shift
cmd="$@"

# Check if the window is open
if hyprctl clients | grep -q "class: $wm_class"; then
  # Kill the process associated with the window
  pid=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$wm_class\") | .pid")
  if [ -n "$pid" ]; then
    kill "$pid"
    exit 0
  fi
else
  # Launch it
  $cmd &
fi
