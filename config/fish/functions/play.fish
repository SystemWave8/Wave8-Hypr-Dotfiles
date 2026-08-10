function play
    set -l music_dir "$HOME/Music"

    # Find a song
    set -l selected (find "$music_dir" -maxdepth 1 -type f \( \
    -iname '*.mp3' -o \
    -iname '*.flac' -o \
    -iname '*.m4a' -o \
    -iname '*.ogg' -o \
    -iname '*.wav' \
	\) -printf '%f\n' | fzf --height=40% --border)

    # Nothing selected
    if test -z "$selected"
        return
    end

    # Convert filesystem path to MPD-relative path
    set -l song "$selected"

    # Look for the song in the current MPD queue
    set -l position

    for entry in (mpc -f '%position%\t%file%' playlist)
        set -l parts (string split -m 1 \t -- "$entry")

        if test "$parts[2]" = "$song"
            set position "$parts[1]"
            break
        end
    end

    # If it isn't queued, add it
    if test -z "$position"
        mpc add "$song" >/dev/null

        # Find the newly added song's queue position
        for entry in (mpc -f '%position%\t%file%' playlist)
            set -l parts (string split -m 1 \t -- "$entry")

            if test "$parts[2]" = "$song"
                set position "$parts[1]"
                break
            end
        end
    end

    # Play the selected song
    if test -n "$position"
        mpc play "$position" >/dev/null
    end

    # Focus existing rmpc or launch it
    "$HOME/.local/bin/focus-or-launch.sh" \
        "rmpc" \
        "kitty --class rmpc -T rmpc rmpc"
	
	exit
end