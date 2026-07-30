#!/usr/bin/env bash
set -e

# === Step 1: Collect inputs via GUI ===
INPUTS=$(yad --form \
    --title="WebApp Builder" \
    --width=500 --height=300 \
    --field="Web App URL (include https://):" "" \
    --field="App Name:" "" \
    --field="Browser:CB" "Brave!Chromium!Helium!Other")

# If cancelled, exit
[[ $? -ne 0 ]] && exit 1

URL=$(echo "$INPUTS" | cut -d'|' -f1)
APP_NAME=$(echo "$INPUTS" | cut -d'|' -f2)
BROWSER_CHOICE=$(echo "$INPUTS" | cut -d'|' -f3)

if [[ -z "$URL" || -z "$APP_NAME" ]]; then
    yad --error --text="URL and App Name are required."
    exit 1
fi

# Browser selection
case "$BROWSER_CHOICE" in
    Brave) BROWSER_CMD="brave" ;;
    Chromium) BROWSER_CMD="chromium" ;;
    Helium) BROWSER_CMD="helium-browser" ;;
    Other)
        BROWSER_CMD=$(yad --entry --title="Custom Browser" --text="Enter full browser command:")
        [[ -z "$BROWSER_CMD" ]] && exit 1
        ;;
esac

BROWSER_BIN=$(echo "$BROWSER_CMD" | awk '{print $1}')
if ! command -v "$BROWSER_BIN" >/dev/null 2>&1; then
    yad --error --text="❌ '$BROWSER_BIN' not found in PATH."
    exit 1
fi

ORIG_EXEC="$BROWSER_CMD --app=$URL"

# === Step 2: Detect WM_CLASS by launching and polling ===
BEFORE_JSON=$(hyprctl clients -j)
BEFORE_ADDRS=$(echo "$BEFORE_JSON" | jq -r '.[].address')

$ORIG_EXEC >/dev/null 2>&1 &
disown

WM_CLASS=""
NEW_ADDR=""
NEW_PID=""

for i in $(seq 1 20); do
    sleep 0.5
    AFTER_JSON=$(hyprctl clients -j)
    AFTER_ADDRS=$(echo "$AFTER_JSON" | jq -r '.[].address')
    NEW_ADDR=$(comm -13 <(echo "$BEFORE_ADDRS" | sort) <(echo "$AFTER_ADDRS" | sort) | head -n1)

    if [[ -n "$NEW_ADDR" ]]; then
        WM_CLASS=$(echo "$AFTER_JSON" | jq -r --arg addr "$NEW_ADDR" '.[] | select(.address==$addr) | .class')
        NEW_PID=$(echo "$AFTER_JSON" | jq -r --arg addr "$NEW_ADDR" '.[] | select(.address==$addr) | .pid')
        break
    fi
done

if [[ -z "$WM_CLASS" ]]; then
    yad --error --text="❌ Could not detect WM_CLASS after 10s.\nClose other browser windows and try again."
    exit 1
fi

# Close only the probe window itself, targeted by its Hyprland address.
# (Killing by PID is unsafe for single-process browsers like Helium, where
# one process can own multiple windows -- that would close all of them.)
if [[ -n "$NEW_ADDR" ]]; then
    hyprctl dispatch "hl.dsp.window.close({window = \"address:$NEW_ADDR\"})" >/dev/null 2>&1 \
        || kill "$NEW_PID" 2>/dev/null || true
fi

# === Step 3: Write final desktop entry directly (no fragile sed) ===
DESKTOP_FILE_NAME=$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')
DESKTOP_FILE="$HOME/.local/share/applications/${DESKTOP_FILE_NAME}.desktop"
KEYWORDS=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /;/g')

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$HOME/.local/bin/focus-or-launch.sh "$WM_CLASS" "$ORIG_EXEC"
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;
Icon=applications-internet
Keywords=$KEYWORDS
EOF

yad --info --text="✅ Created $DESKTOP_FILE\n\nWM_CLASS = $WM_CLASS\nExec = $HOME/.local/bin/focus-or-launch.sh \"$WM_CLASS\" \"$ORIG_EXEC\""