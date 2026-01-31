#!/usr/bin/env bash

CONFIG_DIR="$HOME/.dotfiles/config/hypr"

# Build menu entries as: "Pretty Name|real_filename.conf"
menu_entries=$(for f in "$CONFIG_DIR"/*.conf; do
    base=$(basename "$f" .conf)

    # Pretty label: replace - and _ with spaces, capitalize words
    pretty=$(echo "$base" \
        | sed -E 's/[-_]/ /g' \
        | sed -E 's/(^| )([a-z])/\U\2/g')

    echo "$pretty|$base.conf"
done)

# Show only the pretty label in Wofi
choice=$(echo "$menu_entries" \
    | cut -d'|' -f1 \
    | wofi --dmenu --prompt "Edit Hypr config:" --config ~/.config/wofi/hypr.conf)

# If a choice was made, find the matching real filename
if [ -n "$choice" ]; then
    real_file=$(echo "$menu_entries" | grep "^$choice|" | cut -d'|' -f2)
    mousepad "$CONFIG_DIR/$real_file"
fi
