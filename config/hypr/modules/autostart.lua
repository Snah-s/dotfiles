-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("GSK_RENDERER=cairo swaync & GSK_RENDERER=cairo swayosd-server")
	hl.exec_cmd("waybar")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --type text --watch ~/.config/rofi/launchers/clipboard/store-thumb.sh") --- Stores text + renders its thumbnail
	hl.exec_cmd("wl-paste --type image --watch ~/.config/rofi/launchers/clipboard/store-thumb.sh") --- Stores image + renders its thumbnail
	hl.exec_cmd("wl-clip-persist --clipboard regular") --- Persist data through system restart
end)
