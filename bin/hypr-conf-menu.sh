#!/usr/bin/env bash

CONFIG_DIR="$HOME/.dotfiles/config/hypr"

# Build the menu entries (remove .conf and capitalize words)
menu_entries=$(for f in "$CONFIG_DIR"/*.conf; do
    name=$(basename "$f" .conf)
    # Capitalize first letter of each word
    clean_name=$(echo "$name" | sed -E 's/(^|_|\b)([a-z])/\U\2/g')
    echo "$clean_name"
done)

# Show Wofi menu using the slim, centered config
choice=$(echo "$menu_entries" | wofi --dmenu --prompt "Edit Hypr config:" --config ~/.config/wofi/hypr.conf)

# Open the selected file in mousepad
if [ -n "$choice" ]; then
    # Convert back to lowercase filename to match actual .conf
    filename=$(echo "$choice" | tr '[:upper:]' '[:lower:]')
    mousepad "$CONFIG_DIR/${filename}.conf"
fi
