#!/usr/bin/env bash
set -e

# === Step 1: Collect inputs via GUI ===
INPUTS=$(yad --form \
    --title="WebApp Builder" \
    --width=500 --height=300 \
    --field="Web App URL (include https://):" "" \
    --field="App Name:" "" \
    --field="Browser:CB" "Brave!Chromium!Other")

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
    Other) 
        BROWSER_CMD=$(yad --entry --title="Custom Browser" --text="Enter full browser command:")
        [[ -z "$BROWSER_CMD" ]] && exit 1
        ;;
esac

# === Step 2: Create .desktop file ===
DESKTOP_FILE_NAME=$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')
DESKTOP_FILE="$HOME/.local/share/applications/${DESKTOP_FILE_NAME}.desktop"
KEYWORDS=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /;/g')

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$BROWSER_CMD --app=$URL
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;
Icon=applications-internet
Keywords=$KEYWORDS
EOF

yad --info --text="▶ Created starter desktop entry: $DESKTOP_FILE"

# === Step 3: Detect WM_CLASS ===
ORIG_EXEC=$(grep -m1 '^Exec=' "$DESKTOP_FILE" | sed 's/^Exec=//')

BEFORE_CLASSES=$(hyprctl clients -j | jq -r '.[] | .class')

$ORIG_EXEC &
APP_PID=$!

sleep 2

AFTER_CLASSES=$(hyprctl clients -j | jq -r '.[] | .class')

kill $APP_PID 2>/dev/null || true

WM_CLASS=$(comm -13 <(echo "$BEFORE_CLASSES" | sort) <(echo "$AFTER_CLASSES" | sort) | head -n1)

if [[ -z "$WM_CLASS" ]]; then
    yad --error --text="❌ Could not detect WM_CLASS.\nClose other browser windows and try again."
    exit 1
fi

# === Step 4: Rewrite Exec line with focus-or-launch ===
cp "$DESKTOP_FILE" "$DESKTOP_FILE.bak"

NEW_EXEC="$HOME/.local/bin/focus-or-launch.sh \"$WM_CLASS\" \"$ORIG_EXEC\""
sed -i "s|^Exec=.*|Exec=$NEW_EXEC|" "$DESKTOP_FILE"

yad --info --text="✅ Updated $DESKTOP_FILE with focus-or-launch integration!\n\nWM_CLASS = $WM_CLASS\nExec = $NEW_EXEC"
