# ~/.dotfiles/bash_aliases

alias ytmp3='yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$HOME/Downloads/%(title)s.%(ext)s"'

alias wave='yay -Syu --noconfirm'

# any other aliases can go here
#alias ll='ls -lh'
#alias gs='git status'

alias catsddm='cat /etc/sddm.conf.d/autologin.conf'
alias soss='steamos-session-select'
alias catoss='cat /usr/lib/os-session-select'




#BC-250 Specific

alias bc250='cd bc250-40cu-unlock'
alias cyan='sudo nano /etc/cyan-skillfish-governor-smu/config.toml'
alias gov='sudo systemctl restart cyan-skillfish-governor-smu'

# Check the CU Map

alias cu='sudo /home/wave8bc/bc250-40cu-unlock/scripts/cu_map.sh'