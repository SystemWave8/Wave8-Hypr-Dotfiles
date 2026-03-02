#!/usr/bin/env bash

SCRIPTS_DIR="$HOME/.dotfiles/bin"

# Build menu entries as: "Pretty Name|real_filename"
menu_entries=$(for f in "$SCRIPTS_DIR"/*; do
    base=$(basename "$f")

    # Pretty label: replace - and _ with spaces, capitalize words
    pretty=$(echo "$base" \
        | sed -E 's/[-_]/ /g' \
        | sed -E 's/(^| )([a-z])/\U\2/g')

    echo "$pretty|$base"
done)

# Show only the pretty label in Wofi
choice=$(echo "$menu_entries" \
    | cut -d'|' -f1 \
    | wofi --dmenu --prompt "Edit Script:" --config ~/.config/wofi/hypr.conf)

# If a choice was made, find the matching real filename
if [ -n "$choice" ]; then
    real_file=$(echo "$menu_entries" | grep "^$choice|" | cut -d'|' -f2)
    mousepad "$SCRIPTS_DIR/$real_file"
fi
