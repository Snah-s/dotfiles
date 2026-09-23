-- Settings panel state (~/.config/rofi/scripts/settings.sh).
-- Written by the menu, applied by modules/settings.lua via dofile().
-- Editable by hand; the menu respects it.

return {
	-- "scrolling" | "dwindle" | "master"
	layout = "scrolling",

	-- "extend" | "mirror" | "internal" | "external"
	monitor = "extend",

	-- per-workspace exceptions; the rest inherit `layout`
	ws = {},
}
