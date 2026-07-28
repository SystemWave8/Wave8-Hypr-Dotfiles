#!/usr/bin/env bash
set -euo pipefail
# -----------------------------
# CONFIG
# -----------------------------
RULE_DIR="$HOME/.config/hypr-local/windowrules"
FLOAT_FILE="$RULE_DIR/floating.lua"
TILED_FILE="$RULE_DIR/tiled.lua"
mkdir -p "$RULE_DIR"

# Ensure both files exist with a valid, empty Lua table so dofile() never
# errors out on a fresh host before any rules have been captured.
for f in "$FLOAT_FILE" "$TILED_FILE"; do
    if [[ ! -s "$f" ]]; then
        printf 'return {\n}\n' > "$f"
    fi
done

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
        printf 'return {\n}\n' > "$FLOAT_FILE"
        printf 'return {\n}\n' > "$TILED_FILE"
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

    # Escape for Lua pattern/regex use inside match:class / match:title
    esc_class=$(printf '%s\n' "$class" | sed 's/[.[\*^$(){}+?|]/\\&/g')
    esc_title=$(printf '%s\n' "$title" | sed 's/[.[\*^$(){}+?|]/\\&/g')
    # Escape double quotes for safe embedding inside a Lua string literal
    lua_name=$(printf '%s\n' "$name" | sed 's/"/\\"/g')

    # -----------------------------
    # STRIP HEADER / FOOTER, DEDUP EXISTING MATCHING ENTRY
    # -----------------------------
    BODY=$(sed '1d;$d' "$OUT_FILE")

    DEDUPED_BODY=$(awk \
        -v class_needle="class = \"^${esc_class}\$\"" \
        -v title_needle="title = \"^${esc_title}\$\"" \
        -v use_title="$use_title" '
        BEGIN { buf=""; found_class=0; found_title=0 }
        /^  \{/ {
            buf=$0 ORS
            found_class=0
            found_title=0
            next
        }
        buf != "" {
            buf = buf $0 ORS
            if (index($0, class_needle) > 0) { found_class=1 }
            if (use_title == "true" && index($0, title_needle) > 0) { found_title=1 }
            if ($0 ~ /^  \},/) {
                skip = (found_class == 1 && (use_title != "true" || found_title == 1))
                if (!skip) { printf "%s", buf }
                buf=""
            }
            next
        }
        { print }
    ' <<< "$BODY")

    # -----------------------------
    # BUILD NEW ENTRY
    # -----------------------------
    {
        printf '  {\n'
        printf '    name = "%s",\n' "$lua_name"
        if $use_title; then
            printf '    match = { class = "^%s$", title = "^%s$" },\n' "$esc_class" "$esc_title"
        else
            printf '    match = { class = "^%s$" },\n' "$esc_class"
        fi
        if [[ "$MODE" == "floating_ws" || "$MODE" == "tiled" ]]; then
            printf '    workspace = %s,\n' "$ACTIVE_WS"
        fi
        if [[ "$MODE" == "floating_global" || "$MODE" == "floating_ws" ]]; then
            printf '    float = true,\n'
            printf '    size = { %s, %s },\n' "$w" "$h"
            printf '    move = { %s, %s },\n' "$x" "$y"
        fi
        printf '  },\n'
    } > "$RULE_DIR/.entry.tmp"

    # -----------------------------
    # REASSEMBLE FILE: header + deduped body + new entry + footer
    # -----------------------------
    {
        printf 'return {\n'
        printf '%s\n' "$DEDUPED_BODY"
        cat "$RULE_DIR/.entry.tmp"
        printf '}\n'
    } > "$OUT_FILE.tmp" && mv "$OUT_FILE.tmp" "$OUT_FILE"

    rm -f "$RULE_DIR/.entry.tmp"
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