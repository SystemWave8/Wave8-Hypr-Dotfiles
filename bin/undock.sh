#!/bin/bash
sleep 1

# Move workspace 1 to eDP-1
hyprctl dispatch moveworkspacetomonitor 1 eDP-1

sleep 0.5

hyprctl dispatch movewindowpixel exact 9 35,class:^pithos$
hyprctl dispatch resizewindowpixel exact 390 846,class:^pithos$

hyprctl dispatch movewindowpixel exact 9 893,class:^org\.nickvision\.cavalier$
hyprctl dispatch resizewindowpixel exact 390 298,class:^org\.nickvision\.cavalier$

hyprctl dispatch movewindowpixel exact 411 35,title:^btop$
hyprctl dispatch resizewindowpixel exact 845 1156,title:^btop$

hyprctl dispatch movewindowpixel exact 1268 35,title:^fastfetch$
hyprctl dispatch resizewindowpixel exact 643 830,title:^fastfetch$

hyprctl dispatch movewindowpixel exact 1268 877,class:^org\.gnome\.clocks$
hyprctl dispatch resizewindowpixel exact 643 314,class:^org\.gnome\.clocks$