#!/usr/bin/env bash
# wallpicker.sh — two-stage rofi wallpaper picker for hyprpaper
#
# Stage 1: pick a folder under ~/Pictures
# Stage 2: pick a wallpaper (thumbnail grid) from that folder
#
# Applies via: hyprctl hyprpaper wallpaper ",PATH,cover"  (monitor-agnostic)

set -euo pipefail

BASE_DIR="$HOME/Pictures"
THUMB_DIR="$HOME/Pictures/wallthumbs"
THEME="$HOME/.config/rofi/wallpicker.rasi"
THUMB_SIZE="320x180"
FIT_MODE="cover"
STATE_FILE="$HOME/.config/hypr-local/hyprpaper/last"

mkdir -p "$THUMB_DIR"
shopt -s nullglob nocaseglob

# ---------- Stage 1: folder picker ----------
folders=()
for d in "$BASE_DIR"/*/; do
    name="$(basename "$d")"
    [[ "$name" == "wallthumbs" ]] && continue   # skip our own cache folder
    [[ "$name" == "Screenshots" ]] && continue
    folders+=("$name")
done

if [[ ${#folders[@]} -eq 0 ]]; then
    notify-send "Wallpicker" "No folders found in $BASE_DIR" 2>/dev/null || echo "No folders found in $BASE_DIR"
    exit 1
fi

chosen_folder=$(printf "%s\n" "${folders[@]}" | rofi -dmenu -p "Folder" -theme "$THEME")
[[ -z "$chosen_folder" ]] && exit 0

WALL_DIR="$BASE_DIR/$chosen_folder"

# ---------- Stage 2: wallpaper picker ----------
declare -A path_map
entries=""

for img in "$WALL_DIR"/*.{jpg,jpeg,png}; do
    fname="$(basename "$img")"
    thumb="$THUMB_DIR/${fname}.thumb.png"

    # Only generate thumbnail if missing or source changed since last time
    if [[ ! -f "$thumb" || "$img" -nt "$thumb" ]]; then
        magick "$img" -resize "${THUMB_SIZE}^" -gravity center -extent "$THUMB_SIZE" "$thumb" 2>/dev/null || continue
    fi

    display_name="${fname%.*}"
    path_map["$display_name"]="$img"
    entries+="${display_name}\x00icon\x1f${thumb}\n"
done

if [[ -z "$entries" ]]; then
    notify-send "Wallpicker" "No images found in $WALL_DIR" 2>/dev/null || echo "No images found in $WALL_DIR"
    exit 1
fi

selected=$(echo -e "$entries" | rofi -dmenu -show-icons -p "Wallpaper" -theme "$THEME")
[[ -z "$selected" ]] && exit 0

chosen_path="${path_map[$selected]:-}"
if [[ -z "$chosen_path" ]]; then
    notify-send "Wallpicker" "Could not resolve selection" 2>/dev/null
    exit 1
fi

# ---------- Apply ----------
hyprctl hyprpaper wallpaper ",${chosen_path},${FIT_MODE}"

# ---------- Persist ----------
mkdir -p "$(dirname "$STATE_FILE")"
echo "$chosen_path" > "$STATE_FILE"