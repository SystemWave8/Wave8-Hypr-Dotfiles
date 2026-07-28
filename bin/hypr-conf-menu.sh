#!/usr/bin/env bash
CONFIG_DIR="$HOME/.dotfiles/config/hypr"

# Build menu entries as: "Pretty Name|real_filename.ext"
menu_entries=$(shopt -s nullglob
    for f in "$CONFIG_DIR"/*.conf "$CONFIG_DIR"/*.lua; do
        filename=$(basename "$f")
        base="${filename%.*}"
        ext="${filename##*.}"

        # Pretty label: replace - and _ with spaces, capitalize words
        pretty=$(echo "$base" \
            | sed -E 's/[-_]/ /g' \
            | sed -E 's/(^| )([a-z])/\U\2/g')

        # If both a .conf and .lua exist with the same base name, disambiguate
        if [[ -e "$CONFIG_DIR/$base.conf" && -e "$CONFIG_DIR/$base.lua" ]]; then
            pretty="$pretty ($ext)"
        fi

        echo "$pretty|$filename"
    done)

# Show only the pretty label in Wofi
choice=$(echo "$menu_entries" \
    | cut -d'|' -f1 \
    | wofi --dmenu --prompt "Edit Hypr config:" --config ~/.config/wofi/hypr.conf)

# If a choice was made, find the matching real filename
if [ -n "$choice" ]; then
    real_file=$(echo "$menu_entries" | grep -F "$choice|" | cut -d'|' -f2)
    mousepad "$CONFIG_DIR/$real_file"
fi