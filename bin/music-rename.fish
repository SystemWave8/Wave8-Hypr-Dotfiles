#!/usr/bin/env fish

set music_dir "$HOME/Music"
set apply_mode false

if test (count $argv) -gt 0
    if test "$argv[1]" = "--apply"
        set apply_mode true
    else if test "$argv[1]" = "--preview"
        set apply_mode false
    else
        echo "Usage: music-rename.fish [--preview|--apply]"
        exit 1
    end
end

for file in (find "$music_dir" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.opus" -o -iname "*.wav" \))

    set artist (ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")
    set title (ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")

    if test -z "$artist" -o -z "$title"
        echo "SKIP: "(string replace "$music_dir/" "" "$file")" — missing artist or title"
        continue
    end

    set extension (string match -r '\.[^.]+$' "$file")
    set new_name "$artist - $title$extension"

    # Remove duplicate period before extension
    set new_name (string replace -r '\.\.' '.' "$new_name")

    set directory (dirname "$file")
    set new_path "$directory/$new_name"

    # Already correct
    if test "$file" = "$new_path"
        echo "OK: "(basename "$file")
        continue
    end

    # Destination already exists
    if test -e "$new_path"
        echo "CONFLICT: "(basename "$file")
        echo "  → $new_name"
        echo "  Target already exists — skipped"
        echo
        continue
    end

    if $apply_mode
        mv "$file" "$new_path"
        echo "RENAMED: "(basename "$file")
        echo "      → $new_name"
    else
        echo "WOULD RENAME: "(basename "$file")
        echo "          → $new_name"
    end

    echo
end