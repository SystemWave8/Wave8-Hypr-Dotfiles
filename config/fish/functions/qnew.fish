function qnew

    set dir ~

    while true
        set next (find -L $dir -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | fzf --bind "tab:accept")

        if test -z "$next"
            break
        end

        set dir "$dir/$next"
    end

    set target_dir $dir

    read -P "Filename: " filename

    if test -n "$filename"

        set file "$target_dir/$filename"

        touch "$file"

        setsid mousepad "$file" >/dev/null 2>&1 &
        disown

        exit
    end

end