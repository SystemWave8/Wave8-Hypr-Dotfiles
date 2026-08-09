#!/usr/bin/env fish

set music_dir "$HOME/Music"

set renamed_files
set skipped_files
set conflict_files

echo "🎵 Scanning Music..."

for file in (find "$music_dir" -type f \( \
    -iname "*.mp3" -o \
    -iname "*.flac" -o \
    -iname "*.m4a" -o \
    -iname "*.ogg" -o \
    -iname "*.opus" -o \
    -iname "*.wav" \
\))

    # Get artist and title in ONE ffprobe call.
    set metadata (ffprobe -v quiet \
        -show_entries format_tags=artist,title \
        -of flat=s=_ \
        "$file" 2>/dev/null)

    set artist ""
    set title ""

    for line in $metadata
        if string match -q '*artist=*' "$line"
            set artist (string replace -r '^.*artist=' '' "$line" | string trim -c '"')
        else if string match -q '*title=*' "$line"
            set title (string replace -r '^.*title=' '' "$line" | string trim -c '"')
        end
    end

    # Missing metadata
    if test -z "$artist" -o -z "$title"
        set relative (string replace "$music_dir/" "" "$file")
        set skipped_files $skipped_files "$relative"
        continue
    end

    # Preserve original extension
    set extension (string match -r '\.[^.]+$' "$file")

    # Build desired filename
    set new_name "$artist - $title$extension"

    # Remove duplicate period before extension
    set new_name (string replace -r '\.\.' '.' "$new_name")

    set directory (dirname "$file")
    set new_path "$directory/$new_name"

    # Already correctly named
    if test "$file" = "$new_path"
        continue
    end

    # Never overwrite an existing file
    if test -e "$new_path"
        set relative (string replace "$music_dir/" "" "$file")
        set conflict_files "$relative → $new_name"
        continue
    end

    mv "$file" "$new_path"

    set renamed_files $renamed_files "$new_name"
end


echo
echo "Renamed files"
echo "-------------"

if test (count $renamed_files) -eq 0
    echo "None"
else
    for file in $renamed_files
        echo "$file"
    end
end


echo
echo "Skipped files"
echo "-------------"

if test (count $skipped_files) -eq 0
    echo "None"
else
    for file in $skipped_files
        echo "$file"
    end
end


echo
echo "Conflicts"
echo "---------"

if test (count $conflict_files) -eq 0
    echo "None"
else
    for file in $conflict_files
        echo "$file"
    end
end


echo
echo "Done."
echo (count $renamed_files) "renamed •" (count $skipped_files) "skipped •" (count $conflict_files) "conflicts"