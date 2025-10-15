#!/usr/bin/env bash
# create-webapp-desktop.sh
# Wofi-friendly webapp desktop entry generator with lowercase search

# Prompt for URL
read -rp "Enter the URL of the web app (must include https://): " URL
if [[ -z "$URL" ]]; then
    echo "No URL provided, exiting."
    exit 1
fi

# Ensure URL starts with http:// or https://
if [[ "$URL" != https://* && "$URL" != http://* ]]; then
    echo "URL must start with http:// or https://"
    exit 1
fi

# Prompt for App Name
read -rp "Enter a name for the web app (used for Desktop Entry): " APP_NAME
if [[ -z "$APP_NAME" ]]; then
    echo "No name provided, exiting."
    exit 1
fi

# Prompt for browser
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

# Sanitize app name for filename
DESKTOP_FILE_NAME=$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')
DESKTOP_FILE="$HOME/.local/share/applications/${DESKTOP_FILE_NAME}.desktop"

# Lowercase keywords for Wofi search
KEYWORDS=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /;/g')

# Create Wofi-compatible .desktop entry
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

echo "Created Wofi-compatible .desktop entry: $DESKTOP_FILE"
echo "▶ You can now test with: wofi --show drun"
