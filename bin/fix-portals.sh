#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# fix-portals.sh
# Safely reset XDG Desktop Portal stack for Hyprland
# -----------------------------------------------------------------------------

echo "== Stopping portal services =="
systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland

echo "== Killing any leftover portal processes =="
killall xdg-desktop-portal 2>/dev/null || true
killall xdg-desktop-portal-hyprland 2>/dev/null || true

echo "== Clearing portal cache =="
rm -rf ~/.cache/xdg-desktop-portal

echo "== Reloading user systemd daemon =="
systemctl --user daemon-reload

echo "== Starting portal services =="
systemctl --user start xdg-desktop-portal-hyprland
systemctl --user start xdg-desktop-portal

echo "== Waiting 2 seconds for services to initialize =="
sleep 2

echo "== Checking portal status =="
systemctl --user status xdg-desktop-portal | grep Active
systemctl --user status xdg-desktop-portal-hyprland | grep Active

echo "✅ Portal stack reset complete. Log out and back in if needed."
