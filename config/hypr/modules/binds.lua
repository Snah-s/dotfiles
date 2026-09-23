---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "foot tmux"
local fileManager = "nautilus"
local menu = "~/.config/rofi/launchers/type-1/launcher.sh || pkill rofi"
local settings = "~/.config/rofi/scripts/settings.sh"

---------------------
---- MODIFIERS ------
---------------------

local uwsmApp = "uwsm-app -- "

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(uwsmApp .. terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
-- Solo dwindle/master, no hacen nada con layout = "scrolling"
-- hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("pgrep -x waybar > /dev/null && pkill -x waybar || waybar")) -- hide and show waybar (kill the process)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Screenshots
hl.bind("PRINT", hl.dsp.exec_cmd("flameshot gui"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move with Super + drag, resize with Super + Shift + drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { drag = true })
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { drag = true })

local factor = 50

-- Resize with keys
hl.bind(mainMod .. "+ SHIFT + left", hl.dsp.window.resize({x=-factor, y = 0, relative = true}), {repeating = true}) -- Resize to left
hl.bind(mainMod .. "+ SHIFT + right", hl.dsp.window.resize({x=factor, y = 0, relative = true}), {repeating = true}) -- Resize to right
hl.bind(mainMod .. "+ SHIFT + up", hl.dsp.window.resize({x=0, y = -factor, relative = true}), {repeating = true}) -- Resize to up
hl.bind(mainMod .. "+ SHIFT + down", hl.dsp.window.resize({x=0, y = factor, relative = true}), {repeating = true}) -- Resize to down
-- Laptop multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume 5"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume -5"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --min-brightness 0 --brightness -5"), { locked = true, repeating = true })

-- Clipboard History
hl.bind(mainMod .. "+ SHIFT" .. "+ V", hl.dsp.exec_cmd("~/.config/rofi/launchers/clipboard/launcher.sh"))

-- Settings menu
hl.bind("XF86Tools", hl.dsp.exec_cmd(settings))

-- Testing binds
hl.bind(mainMod .. "+ O", hl.dsp.exec_cmd("foot btop"))

