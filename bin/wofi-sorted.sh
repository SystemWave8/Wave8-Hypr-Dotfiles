#!/bin/bash
# wofi-sorted.sh

appdirs=(/usr/share/applications ~/.local/share/applications)

app_list=""
for dir in "${appdirs[@]}"; do
    for file in "$dir"/*.desktop; do
        [ -f "$file" ] || continue
        name=$(grep -m1 "^Name=" "$file" | cut -d= -f2-)
        desktop_id=$(basename "$file" .desktop)

        # grab keywords (optional, may be empty)
        keywords=$(grep -m1 "^Keywords=" "$file" | cut -d= -f2- | tr ';' ' ')

        # build searchable line: Name [keywords]|DesktopID
        app_list+="$name [$keywords]|$desktop_id"$'\n'
    done
done

choice=$(echo "$app_list" \
    | sort -fV \
    | cut -d'|' -f1 \
    | wofi --show dmenu --prompt "Apps:")

if [ -n "$choice" ]; then
    desktop_id=$(echo "$app_list" | grep -F "^$choice" | cut -d'|' -f2)
    gtk-launch "$desktop_id"
fi
