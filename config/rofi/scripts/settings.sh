#!/usr/bin/env bash
# Settings panel in rofi — bind: XF86Tools (modules/binds.lua).
#
# ┌─ HOW TO EXTEND IT ──────────────────────────────────────────────────────┐
# │                                                                         │
# │ Adding a top-level category:                                            │
# │   1. one more row in the menu_main string (glyph + 2 spaces)             │
# │   2. its branch in the `case`                                           │
# │   3. the menu_<name> function, copying the template from any            │
# │      submenu below. There is no registry, no dispatch table.            │
# │                                                                         │
# │ Adding a setting that must persist in Hyprland:                         │
# │   1. an ST_<key> variable here, plus its line in state_save()           │
# │   2. a line in ~/.config/hypr/modules/settings.lua that applies it      │
# │   The state is a Lua table; over there it is read whole with dofile(),  │
# │   so there is no parser to touch.                                       │
# │                                                                         │
# │ Submenu contract:                                                       │
# │   · menu() returns ≠0 on Escape → `return 0` goes up to the parent.     │
# │     Do not invent a "‹ Back" entry.                                     │
# │   · `while :;` = the submenu stays open after acting (change profile    │
# │     and limit without reopening). The ones that run and exit have no    │
# │     loop.                                                               │
# │   · the glyph lives INSIDE the options string and is trimmed by         │
# │     label(), so the `case` reads free of invisible characters.          │
# │                                                                         │
# │ Known traps:                                                            │
# │   · for FILE lists with a preview use                                   │
# │     \0icon\x1fthumbnail://<path> and let rofi cache (XDG spec).         │
# │     Do not copy the launchers/clipboard/ pipeline: that one exists      │
# │     only because clipboard entries are not files with a mimetype.       │
# │   · this script does NOT pass -theme: it inherits config.rasi on        │
# │     purpose.                                                            │
# │   · hyprctl -j binds shows "__lua" as the dispatcher (config in Lua),   │
# │     which is why the shortcut cheatsheet reads binds.lua directly.      │
# └─────────────────────────────────────────────────────────────────────────┘

set -o pipefail

STATE="$HOME/.config/hypr/settings.lua"
IDLE_CONF="$HOME/.config/hypr/hypridle.conf"
ROFI_DIR="$HOME/.config/rofi"
WALLPAPERS="$HOME/Pictures/Wallpaper"
INTERNAL="eDP-1"

# ─── Helpers ──────────────────────────────────────────────────────────────

# menu <prompt> <options \n> [mesg] [preselected]
menu() {
	local prompt=$1 options=$2 mesg=$3 preselect=$4
	local args=(-dmenu -i -p "$prompt")
	[[ -n $mesg ]] && args+=(-mesg "$mesg")
	if [[ -n $preselect ]]; then
		local idx
		idx=$(printf '%b\n' "$options" | grep -nxF "$preselect" | head -1 | cut -d: -f1)
		[[ -n $idx ]] && args+=(-selected-row "$((idx - 1))")
	fi
	printf '%b\n' "$options" | rofi "${args[@]}"
}

# Strips the glyph: "󰈐  Profile" -> "Profile"
label() { printf '%s' "${1##*  }"; }

notify() { notify-send -a "Settings" "$1" "${2:-}"; }

# ─── State in settings.lua ────────────────────────────────────────────────
# The state file is Lua (a table), not key=value: that way modules/settings.lua
# reads it with dofile() in one line instead of with a hand-rolled parser, and a
# .conf inside ~/.config/hypr/ would be mistaken for hyprlang.
#
# Reading is done by `lua`, the authority on its own syntax; writing is done by
# bash with printf, because the values are a closed set (layout names, monitor
# modes, workspace ids) and there is no free text to escape.

declare -A ST_ws # [workspace id] = layout
ST_layout=scrolling
ST_monitor=extend

state_load() {
	ST_layout=scrolling
	ST_monitor=extend
	ST_ws=()
	local key value
	while IFS='=' read -r key value; do
		case $key in
		layout) ST_layout=$value ;;
		monitor) ST_monitor=$value ;;
		ws.*) ST_ws[${key#ws.}]=$value ;;
		esac
	# The path goes through the environment, NOT as an argument: in a `lua -e`
	# chunk the script arguments do NOT reach `...`, it stays empty, and then
	# dofile() with no argument starts reading STDIN and hangs the whole menu.
	# The </dev/null is the belt in case someone steps on this rake again.
	done < <(STATE_PATH="$STATE" lua -e '
		local ok, t = pcall(dofile, os.getenv("STATE_PATH"))
		if not ok or type(t) ~= "table" then return end
		if type(t.layout)  == "string" then print("layout="  .. t.layout)  end
		if type(t.monitor) == "string" then print("monitor=" .. t.monitor) end
		for k, v in pairs(type(t.ws) == "table" and t.ws or {}) do
			if tonumber(k) and type(v) == "string" then print("ws." .. tonumber(k) .. "=" .. v) end
		end
	' </dev/null 2>/dev/null)
}

# Temp file + mv (atomic rename on the same filesystem) so a concurrent
# `hyprctl reload` never reads a half-written settings.lua.
state_save() {
	local tmp ws
	tmp=$(mktemp "$STATE.XXXXXX") || return 1
	{
		printf -- '-- Settings panel state (~/.config/rofi/scripts/settings.sh).\n'
		printf -- '-- Written by the menu, applied by modules/settings.lua via dofile().\n'
		printf -- '-- Editable by hand; the menu respects it.\n\n'
		printf 'return {\n'
		printf '\t-- "scrolling" | "dwindle" | "master"\n'
		printf '\tlayout = "%s",\n\n' "$ST_layout"
		printf '\t-- "extend" | "mirror" | "internal" | "external"\n'
		printf '\tmonitor = "%s",\n\n' "$ST_monitor"
		printf '\t-- per-workspace exceptions; the rest inherit `layout`\n'
		if ((${#ST_ws[@]} == 0)); then
			printf '\tws = {},\n'
		else
			printf '\tws = {\n'
			for ws in $(printf '%s\n' "${!ST_ws[@]}" | sort -n); do
				printf '\t\t[%d] = "%s",\n' "$ws" "${ST_ws[$ws]}"
			done
			printf '\t},\n'
		fi
		printf '}\n'
	} >"$tmp"
	# do not publish a file Lua cannot read (path via environment, see state_load)
	if F="$tmp" lua -e 'assert(loadfile(os.getenv("F")))' </dev/null 2>/dev/null; then
		mv "$tmp" "$STATE"
	else
		rm -f "$tmp"
		notify "Could not save" "the generated settings.lua is not valid Lua"
		return 1
	fi
}

# Reloads Hyprland and surfaces any config error instead of failing silently.
# reload re-runs the Lua, which re-reads settings.lua: idempotent.
hypr_apply() {
	hyprctl reload >/dev/null 2>&1
	local err
	err=$(hyprctl configerrors 2>&1 | grep -v '^[[:space:]]*$')
	[[ -n $err ]] && notify "Hyprland config error" "$err"
}

# ─── Battery ──────────────────────────────────────────────────────────────

bat_profile() { asusctl profile get 2>/dev/null | sed -n 's/^Active profile: //p'; }
bat_limit() { cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null | head -1; }
bat_charge() { cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; }

bat_mesg() {
	printf 'Profile: %s · Limit: %s%% · Charge: %s%%' \
		"$(bat_profile)" "$(bat_limit)" "$(bat_charge)"
}

menu_profile() {
	local sel opts="󰒲  Quiet\n󰗑  Balanced\n󰓅  Performance"
	while :; do
		sel=$(menu "Profile" "$opts" "Active: $(bat_profile)") || return 0
		sel=$(label "$sel")
		[[ -n $sel ]] || return 0
		asusctl profile set "$sel" >/dev/null 2>&1 || notify "Could not change the profile"
	done
}

menu_limit() {
	local sel opts="󰁻  60%\n󰁿  80%\n󰁹  100%"
	while :; do
		sel=$(menu "Charge limit" "$opts" "Current: $(bat_limit)%") || return 0
		sel=$(label "$sel")
		[[ -n $sel ]] || return 0
		asusctl battery limit "${sel%\%}" >/dev/null 2>&1 || notify "Could not set the limit"
	done
}

menu_battery() {
	local sel
	while :; do
		sel=$(menu "Battery" "󰈐  Power profile\n󰂄  Charge limit\n󰋼  Status" "$(bat_mesg)") || return 0
		case "$(label "$sel")" in
		"Power profile") menu_profile ;;
		"Charge limit") menu_limit ;;
		"Status") "$ROFI_DIR/scripts/battery.sh" ;; # already renders the full panel
		*) return 0 ;;
		esac
	done
}

# ─── Display ──────────────────────────────────────────────────────────────

externals() { hyprctl -j monitors all | jq -r --arg i "$INTERNAL" '.[] | select(.name != $i) | .name'; }

menu_monitor() {
	local sel ext
	ext=$(externals)
	if [[ -z $ext ]]; then
		rofi -e "No external monitor is connected.

Internal: $INTERNAL"
		return 0
	fi
	while :; do
		state_load
		sel=$(menu "Monitor" "󰍹  Extend\n󰢹  Mirror\n󰌢  Internal only\n󰦧  External only" \
			"Mode: $ST_monitor · External: $(tr '\n' ' ' <<<"$ext")") || return 0
		case "$(label "$sel")" in
		"Extend") ST_monitor=extend ;;
		"Mirror") ST_monitor=mirror ;;
		"Internal only") ST_monitor=internal ;;
		"External only") ST_monitor=external ;;
		*) return 0 ;;
		esac
		state_save && hypr_apply
	done
}

menu_layout() {
	local sel opts="󱒆  scrolling\n󰕰  dwindle\n󰯍  master"
	while :; do
		state_load
		sel=$(menu "Global layout" "$opts" "Current: $ST_layout") || return 0
		sel=$(label "$sel")
		[[ -n $sel ]] || return 0
		ST_layout=$sel
		state_save && hypr_apply
	done
}

# Per-workspace exception. "inherit" deletes the key and the WS falls back to global.
menu_layout_ws() {
	local ws sel pick rows
	while :; do
		state_load
		rows=""
		for ws in {1..10}; do
			rows+="  Workspace $ws — ${ST_ws[$ws]:-inherit ($ST_layout)}\n"
		done
		sel=$(menu "Layout per workspace" "${rows%\\n}" "Global: $ST_layout") || return 0
		ws=$(sed -nE 's/^.*Workspace ([0-9]+) —.*$/\1/p' <<<"$sel")
		[[ -n $ws ]] || return 0

		pick=$(menu "Workspace $ws" "󰜘  inherit\n󱒆  scrolling\n󰕰  dwindle\n󰯍  master" \
			"Now: ${ST_ws[$ws]:-inherit ($ST_layout)}") || continue
		pick=$(label "$pick")
		[[ -n $pick ]] || continue

		if [[ $pick == inherit ]]; then
			unset 'ST_ws[$ws]'
		else
			ST_ws[$ws]=$pick
		fi
		state_save && hypr_apply
	done
}

# ─── Hypridle ─────────────────────────────────────────────────────────────
# hypridle.conf is hyprlang (separate app, not Lua). Each listener is identified
# by its on-timeout, never by position: reordering the file breaks nothing.
#
# The menu ONLY edits timeouts. It never fires a dpms/lock/suspend directly:
# turning the screen off is hypridle's exclusive business when its time is up.
# Do not add a "turn the screen off now" here — leaving the panel off without the
# user asking for it is exactly the failure to avoid.

IDLE_DIM='brightnessctl -s set'
IDLE_KBD='kbd_backlight'
IDLE_LOCK='loginctl lock-session'
IDLE_DPMS='dpms off'
IDLE_SUSPEND='systemctl suspend'

idle_get() { # idle_get <on-timeout pattern>
	awk -v pat="$1" '
		/^[[:space:]]*listener[[:space:]]*\{/ { inb=1; t=""; hit=0; next }
		inb {
			# anchor on ^timeout so the "on-timeout =" line is not captured
			if ($0 ~ /^[[:space:]]*timeout[[:space:]]*=/ && match($0, /=[[:space:]]*[0-9]+/)) {
				s = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); t = s
			}
			if (index($0, pat)) hit = 1
			if ($0 ~ /^[[:space:]]*\}/) { if (hit && t != "") { print t; exit } inb = 0 }
		}
	' "$IDLE_CONF"
}

idle_set() { # idle_set <file> <on-timeout pattern> <seconds>
	local tmp
	tmp=$(mktemp "$IDLE_CONF.XXXXXX") || return 1
	awk -v pat="$2" -v val="$3" '
		/^[[:space:]]*listener[[:space:]]*\{/ { inb=1; n=0; hit=0; buf[++n]=$0; next }
		inb {
			buf[++n] = $0
			if (index($0, pat)) hit = 1
			if ($0 ~ /^[[:space:]]*\}/) {
				for (i = 1; i <= n; i++) {
					line = buf[i]
					if (hit && line ~ /^[[:space:]]*timeout[[:space:]]*=/) {
						sub(/=[[:space:]]*[0-9]+/, "= " val, line)
						# the comment in the file notes the value in minutes:
						# leaving it as-is would be a lie, so it is regenerated
						sub(/[[:space:]]*#.*$/, "", line)
						line = line (val >= 60 ? sprintf("   # %gmin", val / 60) : sprintf("   # %ds", val))
					}
					print line
				}
				inb = 0
			}
			next
		}
		{ print }
	' "$1" >"$tmp" && mv "$tmp" "$1"
}

idle_restart() {
	pkill -x hypridle
	pgrep -x hypridle >/dev/null || { hypridle >/dev/null 2>&1 & disown; }
}

# A non-ascending order does not break hypridle, but it gives odd behaviour
# (locking before dimming). It warns and applies anyway, so this function always
# returns 0: the caller restarts the daemon no matter what.
idle_check_order() {
	local d l p s
	d=$(idle_get "$IDLE_DIM") l=$(idle_get "$IDLE_LOCK")
	p=$(idle_get "$IDLE_DPMS") s=$(idle_get "$IDLE_SUSPEND")
	[[ $d =~ ^[0-9]+$ && $l =~ ^[0-9]+$ && $p =~ ^[0-9]+$ && $s =~ ^[0-9]+$ ]] || return 0
	((d > l || l > p || p > s)) &&
		notify "Timeouts out of order" "dim ${d}s · lock ${l}s · screen off ${p}s · suspend ${s}s"
	return 0
}

ask_seconds() { # ask_seconds <label> <current>
	local value
	value=$(menu "$1 (seconds)" "60\n120\n150\n300\n600\n900\n1800\n3600" "Current: ${2}s") || return 1
	[[ $value =~ ^[0-9]+$ ]] && ((value > 0)) || return 1
	printf '%s' "$value"
}

menu_hypridle() {
	local sel status new
	while :; do
		pgrep -x hypridle >/dev/null && status="ON" || status="OFF"
		sel=$(menu "Hypridle" \
			"󱫖  Hypridle: $status\n󰃞  Dim\n󰌾  Lock\n󰶐  Screen off\n󰤄  Suspend" \
			"dim $(idle_get "$IDLE_DIM")s · lock $(idle_get "$IDLE_LOCK")s · screen off $(idle_get "$IDLE_DPMS")s · suspend $(idle_get "$IDLE_SUSPEND")s") || return 0

		case "$(label "$sel")" in
		"Hypridle: ON") pkill -x hypridle ;;
		"Hypridle: OFF") { hypridle >/dev/null 2>&1 & disown; } ;;
		"Dim")
			new=$(ask_seconds Dim "$(idle_get "$IDLE_DIM")") || continue
			# both dimming listeners (screen and keyboard) are a single step
			idle_set "$IDLE_CONF" "$IDLE_DIM" "$new"
			idle_set "$IDLE_CONF" "$IDLE_KBD" "$new"
			idle_check_order && idle_restart
			;;
		"Lock")
			new=$(ask_seconds Lock "$(idle_get "$IDLE_LOCK")") || continue
			idle_set "$IDLE_CONF" "$IDLE_LOCK" "$new"
			idle_check_order && idle_restart
			;;
		"Screen off")
			new=$(ask_seconds "Screen off" "$(idle_get "$IDLE_DPMS")") || continue
			idle_set "$IDLE_CONF" "$IDLE_DPMS" "$new"
			idle_check_order && idle_restart
			;;
		"Suspend")
			new=$(ask_seconds Suspend "$(idle_get "$IDLE_SUSPEND")") || continue
			idle_set "$IDLE_CONF" "$IDLE_SUSPEND" "$new"
			idle_check_order && idle_restart
			;;
		*) return 0 ;;
		esac
	done
}

menu_display() {
	local sel
	while :; do
		sel=$(menu "Display" "󰍹  Monitor\n󱂬  Global layout\n󰝘  Layout per workspace\n󱫖  Hypridle") || return 0
		case "$(label "$sel")" in
		"Monitor") menu_monitor ;;
		"Global layout") menu_layout ;;
		"Layout per workspace") menu_layout_ws ;;
		"Hypridle") menu_hypridle ;;
		*) return 0 ;;
		esac
	done
}

# ─── Wallpaper ────────────────────────────────────────────────────────────
# No thumbnail pipeline: the thumbnail:// prefix lets rofi use the XDG system
# (man 5 rofi-thumbnails), whose ~/.cache/thumbnails/ cache is already warm
# because nautilus fills it. That way rofi never decodes the originals
# (there are 4096×2305 PNGs; ~16 MB in total).

menu_wallpaper() {
	local -a files
	mapfile -t files < <(find "$WALLPAPERS" -maxdepth 1 -type f \
		\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) |
		sort)
	((${#files[@]})) || {
		rofi -e "No images in $WALLPAPERS"
		return 0
	}

	local idx
	idx=$(
		for f in "${files[@]}"; do
			printf '%s\0icon\x1fthumbnail://%s\n' "$(basename "${f%.*}")" "$f"
		done | rofi -dmenu -i -p "Wallpaper" -show-icons -format i \
			-theme-str 'element-icon { size: 96px; } listview { lines: 5; }'
	) || return 0
	[[ $idx =~ ^[0-9]+$ ]] && awww img "${files[idx]}"
}

# ─── Shortcuts and help ───────────────────────────────────────────────────

pager() { kitty -e "$@" >/dev/null 2>&1 & disown; }

# Opens and exits: leaving the menu on top of the pager makes no sense, so this
# submenu has no `while`.
menu_help() {
	local sel
	sel=$(menu "Shortcuts and help" "󰌌  Hyprland\n󰈙  Nvim\n󰆍  Terminal\n󱆃  Bash") || return 0
	case "$(label "$sel")" in
	# hyprctl -j binds returns "__lua" as the dispatcher with a Lua config,
	# so the readable source is the module itself.
	"Hyprland") pager bat --style=plain --paging=always "$HOME/.config/hypr/modules/binds.lua" ;;
	"Nvim") pager nvim -c 'help index' -c 'only' ;;
	"Terminal") pager bat --style=plain --paging=always "$HOME/.config/kitty/kitty.conf" ;;
	"Bash") pager man bash ;;
	esac
}

# ─── Main menu ────────────────────────────────────────────────────────────

menu_main() {
	local sel
	while :; do
		sel=$(menu "Settings" "󰁹  Battery\n󰍹  Display\n󰋩  Wallpaper\n󰖩  Wi-Fi\n󰧑  Shortcuts and help") || return 0
		case "$(label "$sel")" in
		"Battery") menu_battery ;;
		"Display") menu_display ;;
		"Wallpaper") menu_wallpaper ;;
		"Wi-Fi") "$ROFI_DIR/scripts/wifi.sh" ;;
		"Shortcuts and help") menu_help ;;
		*) return 0 ;;
		esac
	done
}

menu_main
