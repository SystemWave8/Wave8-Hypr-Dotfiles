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
"capture → floating\ncapture → tiled\nreset → floating\nreset → tiled\ncancel\n" \
| wofi --dmenu --prompt "Hypr Rule Recorder")

[[ -z "$ACTION" || "$ACTION" == "cancel" ]] && exit 0

case "$ACTION" in
    "capture → floating")
        MODE="floating"
        OUT_FILE="$FLOAT_FILE"
        ;;
    "capture → tiled")
        MODE="tiled"
        OUT_FILE="$TILED_FILE"
        ;;
    "reset → floating")
        > "$FLOAT_FILE"
        notify-send -a "Hypr Rule Recorder" -u low "Floating rules reset"
        exit 0
        ;;
    "reset → tiled")
        > "$TILED_FILE"
        notify-send -a "Hypr Rule Recorder" -u low "Tiled rules reset"
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

    # Human-readable name
    name="$class"
    $use_title && name="$title"

    # Escape regex characters
    esc_class=$(printf '%s\n' "$class" | sed 's/[.[\*^$(){}+?|]/\\&/g')
    esc_title=$(printf '%s\n' "$title" | sed 's/[.[\*^$(){}+?|]/\\&/g')

    # -----------------------------
    # REMOVE EXISTING MATCHING RULE
    # Identity = class (+ title if kitty) + workspace
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
                $0 ~ "workspace = " ws &&
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
        echo "    workspace = $ACTIVE_WS"

        if [[ "$MODE" == "floating" ]]; then
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
