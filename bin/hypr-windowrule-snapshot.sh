#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# CONFIG
# -----------------------------
RULE_DIR="$HOME/.config/hypr-local-windowrules"
FLOAT_FILE="$RULE_DIR/floating.conf"
TILED_FILE="$RULE_DIR/tiled.conf"

mkdir -p "$RULE_DIR"

# -----------------------------
# MODE SELECTION
# -----------------------------
ACTION=$(printf \
"capture → floating\ncapture → floating - w/ workspace\ncapture → tiled\nreset\ncancel\n" \
| wofi --dmenu --prompt "Hypr Rule Recorder")

[[ -z "$ACTION" || "$ACTION" == "cancel" ]] && exit 0

case "$ACTION" in
    "capture → floating")
        MODE="floating_global"
        OUT_FILE="$FLOAT_FILE"
        ;;
    "capture → floating - w/ workspace")
        MODE="floating_ws"
        OUT_FILE="$FLOAT_FILE"
        ;;
    "capture → tiled")
        MODE="tiled"
        OUT_FILE="$TILED_FILE"
        ;;
    "reset")
        > "$FLOAT_FILE"
        > "$TILED_FILE"
        notify-send -a "Hypr Rule Recorder" -u low "All window rules reset"
        exit 0
        ;;
    *)
        exit 1
        ;;
esac


# -----------------------------
# ACTIVE WORKSPACE
# -----------------------------
ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')


# -----------------------------
# CAPTURE WINDOWS
# -----------------------------
hyprctl clients -j | jq -c --argjson ws "$ACTIVE_WS" '
    .[] | select(.workspace.id == $ws)
' | while read -r win; do

    class=$(jq -r '.class' <<< "$win")
    title=$(jq -r '.title' <<< "$win")
    x=$(jq -r '.at[0]' <<< "$win")
    y=$(jq -r '.at[1]' <<< "$win")
    w=$(jq -r '.size[0]' <<< "$win")
    h=$(jq -r '.size[1]' <<< "$win")

    [[ -z "$class" || "$class" == "null" ]] && continue

    # -----------------------------
    # RULE IDENTITY
    # -----------------------------
    use_title=false
    if [[ "$class" == "kitty" && -n "$title" && "$title" != "null" ]]; then
        use_title=true
    fi

    name="$class"
    $use_title && name="$title"

    esc_class=$(printf '%s\n' "$class" | sed 's/[.[\*^$(){}+?|]/\\&/g')
    esc_title=$(printf '%s\n' "$title" | sed 's/[.[\*^$(){}+?|]/\\&/g')

    # -----------------------------
    # REMOVE EXISTING MATCHING RULE
    # -----------------------------
    awk -v class="^$esc_class$" \
        -v title="^$esc_title$" \
        -v ws="$ACTIVE_WS" \
        -v use_title="$use_title" '
        BEGIN { skip=0; buf="" }

        /^windowrule[[:space:]]*{/ {
            skip=0
            buf=$0 ORS
            next
        }

        buf != "" {
            buf = buf $0 ORS

            if (
                $0 ~ "match:class = " class &&
                (!use_title || $0 ~ "match:title = " title)
            ) {
                skip=1
            }

            if ($0 ~ /^}/) {
                if (!skip) {
                    printf "%s", buf
                }
                buf=""
            }
            next
        }

        { print }
    ' "$OUT_FILE" > "$OUT_FILE.tmp" && mv "$OUT_FILE.tmp" "$OUT_FILE"


    # -----------------------------
    # APPEND NEW RULE
    # -----------------------------
    {
        echo "windowrule {"
        echo "    name = $name"
        echo "    match:class = ^$esc_class$"

        if $use_title; then
            echo "    match:title = ^$esc_title$"
        fi

        echo

        # Only apply workspace restriction if requested
        if [[ "$MODE" == "floating_ws" || "$MODE" == "tiled" ]]; then
            echo "    workspace = $ACTIVE_WS"
        fi

        if [[ "$MODE" == "floating_global" || "$MODE" == "floating_ws" ]]; then
            echo "    float = on"
            echo "    size = $w $h"
            echo "    move = $x $y"
        fi

        echo "}"
        echo
    } >> "$OUT_FILE"

done


echo "Rules updated in $OUT_FILE"

notify-send \
  -a "Hypr Rule Recorder" \
  -u low \
  "Layout Updated ($MODE)"

# -----------------------------
# CLEANUP TEMP FILES
# -----------------------------
find "$RULE_DIR" -type f -name "*.tmp" -exec rm -f {} +