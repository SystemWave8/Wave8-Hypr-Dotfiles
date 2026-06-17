#!/bin/bash
sleep 1

# Move workspace 1 to eDP-1
hyprctl dispatch moveworkspacetomonitor 1 eDP-1

sleep 0.5

# Detect resolution
RES=$(hyprctl monitors -j | python3 -c "import json,sys; m=[m for m in json.load(sys.stdin) if m['name']=='eDP-1'][0]; print(f\"{m['width']}x{m['height']}\")")

if [ "$RES" = "1920x1200" ]; then
    # Precision
    hyprctl dispatch movewindowpixel exact 9 35,class:^pithos$
    hyprctl dispatch resizewindowpixel exact 390 846,class:^pithos$

    hyprctl dispatch movewindowpixel exact 9 893,class:^org\.nickvision\.cavalier$
    hyprctl dispatch resizewindowpixel exact 390 298,class:^org\.nickvision\.cavalier$

    hyprctl dispatch movewindowpixel exact 411 35,title:^btop$
    hyprctl dispatch resizewindowpixel exact 845 1156,title:^btop$

    hyprctl dispatch movewindowpixel exact 1268 35,title:^fastfetch$
    hyprctl dispatch resizewindowpixel exact 643 830,title:^fastfetch$

    hyprctl dispatch movewindowpixel exact 1268 877,title:^clock$
    hyprctl dispatch resizewindowpixel exact 643 314,title:^clock$

elif [ "$RES" = "2736x1824" ]; then
    # Surface
    hyprctl dispatch movewindowpixel exact 9 35,class:^pithos$
    hyprctl dispatch resizewindowpixel exact 363 864,class:^pithos$

    hyprctl dispatch movewindowpixel exact 9 911,class:^org\.nickvision\.cavalier$
    hyprctl dispatch resizewindowpixel exact 363 296,class:^org\.nickvision\.cavalier$

    hyprctl dispatch movewindowpixel exact 384 35,title:^btop$
    hyprctl dispatch resizewindowpixel exact 756 1172,title:^btop$

    hyprctl dispatch movewindowpixel exact 1152 35,title:^fastfetch$
    hyprctl dispatch resizewindowpixel exact 663 902,title:^fastfetch$

    hyprctl dispatch movewindowpixel exact 1152 949,title:^clock$
    hyprctl dispatch resizewindowpixel exact 663 258,title:^clock$
fi