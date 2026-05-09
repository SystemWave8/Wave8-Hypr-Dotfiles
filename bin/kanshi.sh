#!/bin/bash

# kanshi.sh - Setup kanshi display management for laptop systems

set -e

echo "Setting up kanshi..."

# Install kanshi
sudo pacman -S kanshi --noconfirm

# Enable and start the systemd user service
systemctl --user enable --now kanshi.service
echo "service setup"

echo "Kanshi installed, check config!"
echo "Verify service status with: systemctl --user status kanshi"