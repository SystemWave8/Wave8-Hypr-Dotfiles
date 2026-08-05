function fish_prompt
    # Colors
    set_color -o cyan
    set -l cyan (set_color -o cyan)
    set -l blue (set_color -o blue)
    set -l gray (set_color brblack)
    set -l normal (set_color normal)

    # Host
    set -l host (prompt_hostname)

    # Build visible path
    if test "$PWD" = "$HOME"
        set -l visible "home"
        set -l colored "{$blue}home{$normal}"
    else
        set -l rel (string replace "$HOME/" "" "$PWD")
        set -l segments (string split "/" "$rel")

        set visible ""
        set colored ""

        for seg in $segments
            if test -z "$visible"
                set visible $seg
                set colored "$blue$seg$normal"
            else
                set visible "$visible ➜ $seg"
                set colored "$colored ➜ $blue$seg$normal"
            end
        end
    end

    # First line
    printf "%s%s%s ➜ %s\n" $cyan $host $normal $colored

    # Compute indent from visible characters
    set -l firstline "$host ➜ $visible"
    set -l indent (string repeat -n (string length -- "$firstline") " ")

    # Export for other functions
    set -gx WAVE_PROMPT_INDENT $indent

    # Second line
    printf "%s%s➜ %s" $indent $gray $normal
end
