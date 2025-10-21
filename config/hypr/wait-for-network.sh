#!/bin/bash

notify-send "Greetings System Wave"

# Wait until we have connectivity
while ! ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do
    sleep 2
done

###############################################################################
# Use this if you run into issues with reconnecting to Wi-Fi after boot.
# For now, it’s optional — toggle with the flag below.
###############################################################################

USE_IPV6_FIX=false   # ← set this to true if you want to apply the IPv6 fix

if $USE_IPV6_FIX; then
    notify-send "Applying IPv6 Fix..."

    # Disable IPv6 on wlan0 (using visudo NOPASSWD rule)
    sudo sysctl -w net.ipv6.conf.wlan0.disable_ipv6=1

    notify-send "Re-Establishing IPv4..."

    # Force reconnect after disabling IPv6
    ip link set wlan0 down
    sleep 2
    ip link set wlan0 up

    # Wait again until connection is restored
    while ! ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do
        sleep 2
    done
fi

###############################################################################

# Msg when network is ready
notify-send "Network is up! Launching Apps!"
sleep 1
notify-send "Have a great day!"

# Launch apps
pithos &
cavalier &
env GTK_THEME=Adwaita:dark /home/wave8l/.local/bin/gnome-clocks-dark &

# Terminal apps

#if run in Alacritty

#alacritty -t "btop" -e btop &
#alacritty -t "fastfetch" -e sh -c "fastfetch; exec $SHELL"

#if run in kitty

kitty -T "btop" btop &
kitty -T "fastfetch" sh -c "fastfetch; exec $SHELL" &



