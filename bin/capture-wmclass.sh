#!/usr/bin/env bash
set -e

DESKTOP_FILE="$1"
if [[ -z "$DESKTOP_FILE" ]]; then
    echo "Usage: $0 /path/to/app.desktop"
    exit 1
fi

# Grab the Exec line from the .desktop
ORIG_EXEC=$(grep -m1 '^Exec=' "$DESKTOP_FILE" | sed 's/^Exec=//')

# Take a snapshot of existing WM_CLASS values
BEFORE_CLASSES=$(hyprctl clients -j | jq -r '.[] | .class')

# Launch the app in background
$ORIG_EXEC &
APP_PID=$!

# Give it a moment to appear
sleep 2

# Take a snapshot after launch
AFTER_CLASSES=$(hyprctl clients -j | jq -r '.[] | .class')

# Kill the test app if it created a new process
kill $APP_PID 2>/dev/null || true

# Detect the new WM_CLASS
WM_CLASS=$(comm -13 <(echo "$BEFORE_CLASSES" | sort) <(echo "$AFTER_CLASSES" | sort) | head -n1)

if [[ -z "$WM_CLASS" ]]; then
    echo "❌ Could not detect WM_CLASS. Try closing other browser windows and rerun."
    exit 1
fi

# Backup original desktop file
cp "$DESKTOP_FILE" "$DESKTOP_FILE.bak"

# Rewrite Exec= line with focus-or-launch
NEW_EXEC="$HOME/.local/bin/focus-or-launch.sh \"$WM_CLASS\" \"$ORIG_EXEC\""
sed -i "s|^Exec=.*|Exec=$NEW_EXEC|" "$DESKTOP_FILE"

echo "✅ Updated $DESKTOP_FILE with focus-or-launch integration!"
echo "   WM_CLASS = $WM_CLASS"
