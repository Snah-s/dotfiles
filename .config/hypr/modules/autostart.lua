-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
	hl.exec_cmd("sleep 1 && /usr/lib/xdg-desktop-portal-hyprland")
	hl.exec_cmd("sleep 2 && /usr/lib/xdg-desktop-portal")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("swaync & swayosd-server")
	hl.exec_cmd("waybar")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --type text --watch cliphist store") --- Stores only text data
	hl.exec_cmd("wl-paste --type image --watch cliphist store") --- Stores only image data
	hl.exec_cmd("wl-clip-persist --clipboard regular") --- Persist data through system restart
end)
