#!/usr/bin/env bash
set -euo pipefail

CONF="$HOME/.config/hypr-local/ScrollingToggle/scrolling-toggle.conf"

# read current line 19
CURRENT=$(sed -n '19p' "$CONF" || true)
CURRENT_TRIMMED=$(echo "$CURRENT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# decide new line
if [[ "$CURRENT_TRIMMED" == "layout = dwindle" ]]; then
    NEW="layout = scrolling"
elif [[ "$CURRENT_TRIMMED" == "layout = scrolling" ]]; then
    NEW="layout = dwindle"
else
    echo "Line 19 unexpected, defaulting to 'layout = scrolling'"
    NEW="layout = scrolling"
fi

# replace line 19
TMP=$(mktemp)
awk -v n=19 -v nl="$NEW" '{
  if (NR==n) print nl;
  else print $0;
}
END {
  if (NR < n) {
    for(i=NR+1;i<n;i++) print "";
    print nl;
  }
}' "$CONF" > "$TMP"

chmod --reference="$CONF" "$TMP"
mv "$TMP" "$CONF"

echo "Replaced line 19 with: $NEW"

# reload Hyprland
hyprctl reload >/dev/null 2>&1 || echo "Hyprland reload failed."
