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

BROWSER_BIN=$(echo "$BROWSER_CMD" | awk '{print $1}')
if ! command -v "$BROWSER_BIN" >/dev/null 2>&1; then
    echo "❌ '$BROWSER_BIN' not found in PATH. Check the command and try again."
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
    echo "❌ Could not detect WM_CLASS after 10s. Try closing other browser windows and rerun."
    exit 1
fi

# Close the probe window by its real PID (not the launcher shell PID)
if [[ -n "$NEW_PID" ]]; then
    kill "$NEW_PID" 2>/dev/null || true
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

echo "✅ Created $DESKTOP_FILE"
echo "   WM_CLASS = $WM_CLASS"
echo "   Exec = $HOME/.local/bin/focus-or-launch.sh \"$WM_CLASS\" \"$ORIG_EXEC\""