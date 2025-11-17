#!/usr/bin/env bash
set -euo pipefail

CONF="/home/wave8l/.config/hypr/looknfeel.conf"

# read current line 26
CURRENT=$(sed -n '26p' "$CONF" || true)
CURRENT_TRIMMED=$(echo "$CURRENT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# decide new line
if [[ "$CURRENT_TRIMMED" == "layout = dwindle" ]]; then
    NEW="layout = scrolling"
elif [[ "$CURRENT_TRIMMED" == "layout = scrolling" ]]; then
    NEW="layout = dwindle"
else
    echo "Line 26 unexpected, defaulting to 'layout = scrolling'"
    NEW="layout = scrolling"
fi

# replace line 26
TMP=$(mktemp)
awk -v n=26 -v nl="$NEW" '{
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

echo "Replaced line 26 with: $NEW"

# reload Hyprland
hyprctl reload >/dev/null 2>&1 || echo "Hyprland reload failed."
