#!/bin/bash

notify-send "Greetings System Wave"
# Wait until we have connectivity
while ! ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do
    sleep 2
done
###############################################################################
# Use this if you run into issues with reconnecting to Wi-Fi after boot.
# For now, it's optional — toggle with the flag below.
###############################################################################
USE_IPV6_FIX=false   # ← set this to true if you want to apply the IPv6 fix
if $USE_IPV6_FIX; then
    notify-send "Applying IPv6 Fix..."
    sudo sysctl -w net.ipv6.conf.wlan0.disable_ipv6=1
    notify-send "Re-Establishing IPv4..."
    ip link set wlan0 down
    sleep 2
    ip link set wlan0 up
    while ! ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; do
        sleep 2
    done
fi
###############################################################################
notify-send "Network is up! Launching Apps!"
sleep 1
notify-send "Have a great day!"

# Launch apps
if [[ "$(hostname)" == "airland" ]]; then
    pithos &
    kitty -T "btop" btop &
    exit 0
fi

pithos &
cavalier &
env GTK_THEME=Adwaita:dark $HOME/.local/bin/gnome-clocks-dark &
kitty -T "btop" btop &
kitty -T "fastfetch" sh -c "fastfetch; exec $SHELL" &