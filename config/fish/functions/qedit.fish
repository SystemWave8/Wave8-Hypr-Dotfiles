function qedit
    set file (find . -type f | fzf)
    if test -n "$file"
        setsid mousepad "$file" >/dev/null 2>&1 &
        disown
        exit
    end
end