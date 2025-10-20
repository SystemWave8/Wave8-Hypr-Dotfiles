#!/bin/bash

# Loop through all selected files (supports multiple)
for file in "$@"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    dir="$(dirname "$file")"
    name="$(basename "$file")"
    ext="${name##*.}"
    base="${name%.*}"
    target="$dir/$base"

    mkdir -p "$target"

    case "$ext" in
        zip|ZIP)
            7z x -y "$file" -o"$target" >/dev/null ;;
        7z|7Z)
            7z x -y "$file" -o"$target" >/dev/null ;;
        zst|ZST)
            tar -I zstd -xf "$file" -C "$target" ;;
        *)
            notify-send "Auto Extract" "Unsupported file type: $name"
            continue ;;
    esac

    notify-send "Auto Extract" "Extracted $name → $target"
done
