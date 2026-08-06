function newscript
    set name $argv[1]

    if not string match -q "*.*" "$name"
        set name "$name.sh"
    end

    set file ~/.local/bin/$name

    touch "$file"
    chmod +x "$file"

    mousepad "$file" >/dev/null 2>&1 &
    disown $last_pid
end