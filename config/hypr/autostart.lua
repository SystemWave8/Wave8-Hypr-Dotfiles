-----------------
-- AUTOSTART   --
-----------------
-- Autostart necessary processes (notification daemons, status bars, etc.)
-- exec-once has no direct Lua keyword; hook hyprland.start instead,
-- which fires once per session (not on config reload).

hl.on("hyprland.start", function()
	---- ESTABLISH NETWORK ----
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/wait-for-network.sh")

	-------------------------------------------------------
	-- Waybar + wallpaper daemon

	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")

	-- Wallpaper Persistence
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/wallpicker-restore.sh")

	-- Bluetooth Connection
	-- hl.exec_cmd("bluetoothctl connect 9C:C8:E9:04:C2:0E") -- autoconnects to bluetooth
	-- hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/bt-choice.sh")

	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/dunst-copy-progress.sh")


	hl.exec_cmd("dbus-update-activation-environment --systemd --all")

	hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-hyprland")
	hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-gtk")
	hl.exec_cmd("sleep 2 && /usr/lib/xdg-desktop-portal")
end)