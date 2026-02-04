#!/bin/bash

DOWNLOAD_DIR="$HOME/Downloads"
MUSIC_DIR="$HOME/Music"

mkdir -p "$MUSIC_DIR"

notify_id=8888  # fixed ID so updates overwrite

# Function to show a bar-style notification
show_bar() {
    local phase=$1       # text for phase
    local percent=$2     # 0-100
    local blocks=$(( (percent + 5) / 10 ))
    local bar=$(printf '█%.0s' $(seq 1 $blocks))
    local empty=$(printf '░%.0s' $(seq 1 $((10 - blocks))))
    notify-send -r $notify_id "$phase" "$bar$empty  $percent%" -i audio-x-generic
}

# Ask for YouTube link
LINK=$(yad --entry \
    --title="YouTube MP3 Downloader" \
    --text="Paste YouTube link here:" \
    --width=400 --height=100)

[ -z "$LINK" ] && exit 0

# --- Phase 1: Download + conversion ---
show_bar "Downloading audio..." 0
bash -ic "ytmp3 \"$LINK\"" &
DOWNLOAD_PID=$!

# Pulse-style progress (simulate fill)
for i in $(seq 1 50); do
    sleep 0.2
    show_bar "Downloading audio..." $i
    if ! kill -0 $DOWNLOAD_PID 2>/dev/null; then
        break
    fi
done

show_bar "Download complete" 50

# --- Phase 2: Wait for final MP3 ---
NEW_MP3=""
while [ -z "$NEW_MP3" ]; do
    NEW_MP3=$(ls -t "$DOWNLOAD_DIR"/*.mp3 2>/dev/null | head -n1)
    sleep 0.5
    show_bar "Waiting for MP3 file..." 55
done
sleep 1

# --- Phase 3: Picard scanning/tagging ---
for i in $(seq 56 95); do
    show_bar "Running Picard scan & tagging..." $i
    sleep 0.05
done

QT_QPA_PLATFORM=offscreen picard -d -s \
    -e "LOAD $DOWNLOAD_DIR" \
    -e "SCAN" \
    -e "SAVE_MATCHED" \
    -e "QUIT"

# --- Phase 4: Done ---
for i in $(seq 96 100); do
    show_bar "Done!" $i
    sleep 0.05
done

# --- Phase 5: Move MP3 to Music folder ---
show_bar "Moving MP3 to Music folder..." 95
NEW_MP3=$(ls -t "$DOWNLOAD_DIR"/*.mp3 2>/dev/null | head -n1)

if [ -n "$NEW_MP3" ]; then
    mv "$NEW_MP3" "$MUSIC_DIR/"
    show_bar "MP3 moved to Music folder!" 100
else
    show_bar "No MP3 found to move." 100
fi
sleep 0.5

mpc update


