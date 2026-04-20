#!/bin/bash
# cleanup-hypr-local-autostart.sh
# Comments out all active exec-once lines in hypr-local autostart

CONFIG="$HOME/.config/hypr-local/autostart.conf"

sed -i -E "s|^(exec-once.*)$|#\1|" "$CONFIG"
echo "All exec-once lines commented out in $CONFIG"