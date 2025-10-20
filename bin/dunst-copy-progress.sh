#!/bin/bash

WATCH_DIR="/run/media/$USER"   # Folder to watch (USBs, external drives, etc.)
THROTTLE=5                     # Minimum % change to trigger a new notification

declare -A last_progress

# Ensure inotifywait exists
command -v inotifywait >/dev/null 2>&1 || { echo "Install inotify-tools"; exit 1; }

inotifywait -m -r -e create -e modify -e moved_to -e close_write "$WATCH_DIR" --format '%e %w%f' | while read EVENT FILE
do
    # Only track regular files
    [ -f "$FILE" ] || continue

    # Generate a numeric notification ID per file
    notify_id=$(echo -n "$FILE" | cksum | cut -d' ' -f1)

    # Get file size for progress estimation
    CURRENT_SIZE=$(stat -c%s "$FILE")

    # Attempt to get total size (if copy is complete or if unknown, just show blocks of CURRENT_SIZE)
    TOTAL_SIZE=$CURRENT_SIZE  # For unknown total, will just show filled bar dynamically

    case "$EVENT" in
        CREATE*|MOVED_TO*)
            last_progress["$FILE"]=0
            notify-send -r $notify_id "Copying $(basename "$FILE")" "Started" -i folder
            ;;
        MODIFY*)
            # Compute % progress based on CURRENT_SIZE / TOTAL_SIZE (dynamic)
            percent=$(( CURRENT_SIZE * 100 / (TOTAL_SIZE>0 ? TOTAL_SIZE : CURRENT_SIZE) ))

            # Only update if progress changed enough
            last=${last_progress["$FILE"]}
            change=$(( percent - last ))
            if [ $change -ge $THROTTLE ] || [ $change -le -$THROTTLE ]; then
                last_progress["$FILE"]=$percent

                # Build 10-block bar
                blocks=$(( (percent + 5) / 10 ))
                bar=$(printf '█%.0s' $(seq 1 $blocks))
                empty=$(printf '░%.0s' $(seq 1 $((10 - blocks))))

                notify-send -r $notify_id "Copying $(basename "$FILE")" "$bar$empty  $percent%" -i folder
            fi
            ;;
        CLOSE_WRITE*)
            notify-send -r $notify_id "Copying $(basename "$FILE")" "Completed" -i folder
            unset last_progress["$FILE"]
            ;;
    esac
done
