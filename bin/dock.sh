#!/bin/bash
sleep 1

# Move workspace 1 to DP-2
hyprctl dispatch moveworkspacetomonitor 1 DP-2

sleep 0.5

hyprctl dispatch movewindowpixel exact 9 35,class:^pithos$
hyprctl dispatch resizewindowpixel exact 387 712,class:^pithos$

hyprctl dispatch movewindowpixel exact 9 759,class:^org\.nickvision\.cavalier$
hyprctl dispatch resizewindowpixel exact 387 312,class:^org\.nickvision\.cavalier$

hyprctl dispatch movewindowpixel exact 408 35,title:^btop$
hyprctl dispatch resizewindowpixel exact 832 1036,title:^btop$

hyprctl dispatch movewindowpixel exact 1252 35,title:^fastfetch$
hyprctl dispatch resizewindowpixel exact 659 726,title:^fastfetch$

hyprctl dispatch movewindowpixel exact 1252 773,title:^clock$
hyprctl dispatch resizewindowpixel exact 659 298,title:^clock$