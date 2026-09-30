if status is-interactive


### Deleted Greeting ###

set -g fish_greeting

### Cleaning up fzf - > Too many hits ###

set -gx FZF_DEFAULT_OPTS "--height=40% --border"

### adding in .local/bin path....maybe? ###

fish_add_path ~/.local/bin


### Password Prompt Change ###

function fish_preexec --on-event fish_preexec
    set -gx SUDO_PROMPT "$WAVE_PROMPT_INDENT""Enter Password: "
end

#set -gx SUDO_PROMPT "                                      Enter Password: "

### Aliases ###

# Audio and Video Download commands
alias ytmp3='yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$HOME/Downloads/%(title)s.%(ext)s"'
alias ytmkv 'yt-dlp -f "bv*+ba/b" --merge-output-format mkv -o "$HOME/Downloads/%(title)s.%(ext)s"'


# System
alias wave='yay -Syu --noconfirm'
alias catsddm='cat /etc/sddm.conf.d/autologin.conf'
alias soss='steamos-session-select'
alias catoss='cat /usr/lib/os-session-select'

# BC-250
alias bc250='cd ~/bc250-40cu-unlock'
alias cyan='sudo nano /etc/cyan-skillfish-governor-smu/config.toml'
alias gov='sudo systemctl restart cyan-skillfish-governor-smu'
alias cu='~/bc250-40cu-unlock/scripts/cu_map.sh'
alias bc250-rebuild='cd ~/bc250-40cu-unlock && sudo ./scripts/bc250-enable-40cu-arch.sh build && sudo mkinitcpio -P && sudo reboot'
alias music-rename='music-rename.fish'

#Relay Specific

alias relay-pack='python3 relay-md.py pack'
alias relay-unpack='python3 relay-md.py unpack'
alias relay-check='python3 relay-md.py check'
alias relay-diff='python3 relay-md.py diff'

#Markdown Pack - > Non Specific

alias md-pack='python3 relay-md.py pack'
alias md-unpack='python3 relay-md.py unpack'
alias md-check='python3 relay-md.py check'
alias md-diff='python3 relay-md.py diff'

#Reset Fish While in terminal

alias source-fish='source ~/.config/fish/config.fish'

#ComfyUI

alias comfy 'cd ~/AI/comfyui; and source .venv/bin/activate.fish'
alias comfystart 'python main.py'


end

zoxide init fish | source
