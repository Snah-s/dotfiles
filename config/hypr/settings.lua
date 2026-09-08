-- Estado del panel de ajustes (~/.config/rofi/scripts/settings.sh).
-- Lo escribe el menú y lo aplica modules/settings.lua vía dofile().
-- Editable a mano; el menú lo respeta.

return {
	-- "scrolling" | "dwindle" | "master"
	layout = "scrolling",

	-- "extend" | "mirror" | "internal" | "external"
	monitor = "extend",

	-- excepciones por workspace; el resto hereda `layout`
	ws = {},
}
