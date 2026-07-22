#!/usr/bin/env bash
# wallpicker-restore.sh — reapplies the last-selected wallpaper on login
# Meant to be called via exec-once, after hyprpaper has started.

STATE_FILE="$HOME/.config/hypr-local/hyprpaper/last"
FIT_MODE="cover"
MAX_TRIES=10

# hyprpaper needs a moment to open its IPC socket on startup — retry briefly
# instead of assuming it's ready immediately.
for i in $(seq 1 "$MAX_TRIES"); do
    if hyprctl hyprpaper listactive >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

if [[ -f "$STATE_FILE" ]]; then
    stored_path="$(cat "$STATE_FILE")"
    if [[ -f "$stored_path" ]]; then
        hyprctl hyprpaper wallpaper ",${stored_path},${FIT_MODE}"
    fi
fi