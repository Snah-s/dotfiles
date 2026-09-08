-------------------
---- AJUSTES ----
-------------------

-- Aplica el estado que guarda el panel de ajustes (~/.config/rofi/scripts/settings.sh).
-- El menú reescribe ~/.config/hypr/settings.lua y llama a `hyprctl reload`;
-- la recarga re-ejecuta este módulo, que vuelve a leer el fichero. Por eso la
-- operación es idempotente: aplicar dos veces lo mismo no cambia nada.
--
-- Este módulo va el ÚLTIMO en hyprland.lua, después de monitors y layout, para
-- poder sobreescribirlos.
--
-- Añadir un ajuste nuevo = 1 clave en settings.lua + 1 línea aquí.
-- Antes de escribir cualquier hl.* nuevo: /usr/share/hypr/stubs/hl.meta.lua.

local INTERNAL = "eDP-1" -- pantalla del portátil

---------------------------
---- ESTADO GUARDADO ----
---------------------------

-- dofile y no require: require cachea el módulo, así que tras un reload
-- seguiríamos viendo el estado viejo. dofile relee el fichero siempre.
-- El pcall es la red de seguridad: si el menú dejó el fichero a medias o
-- alguien lo editó mal, se degrada a los valores por defecto en vez de
-- tumbar toda la config de Hyprland.
local S = { ws = {} }
do
	local ok, data = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/settings.lua")
	if ok and type(data) == "table" then
		S = data
		S.ws = S.ws or {}
	end
end

--------------------
---- LAYOUTS ----
--------------------

-- Acepta clave numérica ([2]) y también string (["2"]), porque el fichero se
-- edita a mano y las dos formas son Lua legítimo.
local function layout_for(id)
	return (id and (S.ws[id] or S.ws[tostring(id)])) or S.layout or "scrolling"
end

local function apply_layout(id)
	hl.config({ general = { layout = layout_for(id) } })
end

-- OJO: el layout por workspace NO se puede hacer con workspace rules.
-- El stub declara HL.WorkspaceRuleSpec.layout, pero Hyprland 0.56.2 lo ignora:
-- `hyprctl workspacerules` enumera los campos que soporta de verdad (enabled,
-- monitor, default, persistent, gaps*, border*, rounding, decorate, shadow,
-- defaultName, onCreatedEmpty) y `layout` no está entre ellos. Se comprobó:
-- la regla se crea pero sale con todo <unset> y no cambia nada.
-- Por eso se reaplica el layout global en cada cambio de workspace.
-- El callback recibe un HL.Workspace, que llega como *userdata*, no como table:
-- comprobar `type(ws) == "table"` falla y acaba pasando el objeto entero como id.
-- Indexar ws.id sí funciona.
hl.on("workspace.active", function(ws)
	apply_layout(ws and ws.id)
end)

apply_layout((hl.get_active_workspace() or {}).id)

--------------------
---- MONITORES ----
--------------------

local function externals()
	local found = {}
	for _, monitor in ipairs(hl.get_monitors()) do
		if monitor.name ~= INTERNAL then
			found[#found + 1] = monitor.name
		end
	end
	return found
end

-- El interno solo se toca para apagarlo. Encenderlo no hace falta: en cada
-- reload monitors.lua lo redeclara con su modo/escala antes de que llegue esto.
local function apply_monitor(mode)
	local ext = externals()

	for _, output in ipairs(ext) do
		if mode == "internal" then
			hl.monitor({ output = output, disabled = true })
		elseif mode == "mirror" then
			hl.monitor({ output = output, mode = "preferred", position = "auto", mirror = INTERNAL })
		else -- extend, y cualquier valor desconocido
			hl.monitor({ output = output, mode = "preferred", position = "auto", scale = "auto" })
		end
	end

	-- Guarda: sin externo conectado, "external" te dejaría sin ninguna pantalla.
	if mode == "external" and #ext > 0 then
		hl.monitor({ output = INTERNAL, disabled = true })
	end
end

apply_monitor(S.monitor or "extend")

-- Al arrancar, get_monitors() puede estar todavía vacío y al enchufar una
-- pantalla nadie re-ejecuta el config: por eso este es el único callback.
hl.on("monitor.added", function()
	apply_monitor(S.monitor or "extend")
end)
