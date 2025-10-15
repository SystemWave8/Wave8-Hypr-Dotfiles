#!/usr/bin/env bash
set -e

# === Step 1: Prompt user ===
read -rp "Enter the URL of the web app (must include https://): " URL
if [[ -z "$URL" ]]; then
    echo "No URL provided, exiting."
    exit 1
fi

if [[ "$URL" != https://* && "$URL" != http://* ]]; then
    echo "URL must start with http:// or https://"
    exit 1
fi

read -rp "Enter a name for the web app: " APP_NAME
if [[ -z "$APP_NAME" ]]; then
    echo "No name provided, exiting."
    exit 1
fi

echo "Which browser do you want to use?"
echo "1) Brave"
echo "2) Chromium"
echo "3) Other (enter manually)"
read -rp "Select [1-3]: " CHOICE

case "$CHOICE" in
    1) BROWSER_CMD="brave" ;;
    2) BROWSER_CMD="chromium" ;;
    3) read -rp "Enter full browser command: " BROWSER_CMD ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# === Step 2: Make desktop entry (starter) ===
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

echo "▶ Created initial desktop entry: $DESKTOP_FILE"

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
    echo "❌ Could not detect WM_CLASS. Try closing other browser windows and rerun."
    exit 1
fi

# === Step 4: Rewrite Exec line ===
cp "$DESKTOP_FILE" "$DESKTOP_FILE.bak"

NEW_EXEC="$HOME/.local/bin/focus-or-launch.sh \"$WM_CLASS\" \"$ORIG_EXEC\""
sed -i "s|^Exec=.*|Exec=$NEW_EXEC|" "$DESKTOP_FILE"

echo "✅ Updated $DESKTOP_FILE with focus-or-launch integration!"
echo "   WM_CLASS = $WM_CLASS"
echo "   Exec = $NEW_EXEC"
