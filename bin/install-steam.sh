#!/bin/bash

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (sudo ./install_steam.sh)"
    exit 1
fi

PACMAN_CONF="/etc/pacman.conf"

echo "==> Enabling multilib repository..."

if grep -q "^\[multilib\]" "$PACMAN_CONF"; then
    echo "    multilib is already enabled, skipping..."
else
    sed -i '/^#\[multilib\]/{
        s/^#//
        n
        s/^#//
    }' "$PACMAN_CONF"
    echo "    multilib enabled."
fi

echo "==> Syncing package databases..."
pacman -Sy

echo "==> Installing Steam..."
pacman -S --noconfirm steam

echo "==> Installing gamescope..."
pacman -S --noconfirm gamescope

echo "==> Installing mangohud..."
pacman -S --noconfirm mangohud

echo "==> Installing AUR gamescope session packages..."
# AUR packages must be installed as a regular user
SUDO_USER_HOME=$(eval echo "~$SUDO_USER")

sudo -u "$SUDO_USER" yay -S --noconfirm gamescope-session-git gamescope-session-steam-git

echo "Done! Steam and Gamescope have been installed."
