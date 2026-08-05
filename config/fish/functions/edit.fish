function edit
    set file (find . -type f | fzf)

    if test -n "$file"
        mousepad "$file" >/dev/null 2>&1 &
        disown $last_pid
    end
end