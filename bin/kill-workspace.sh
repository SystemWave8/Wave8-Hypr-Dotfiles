#!/bin/bash

# Get the current workspace name
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.name')

# Close all windows on the current workspace
hyprctl clients -j | jq -r --arg ws "$CURRENT_WS" '
    .[] | select(.workspace.name == $ws) | .address
' | while read WIN; do
    echo "Closing $WIN on workspace $CURRENT_WS"
    hyprctl dispatch closewindow address:$WIN
done
