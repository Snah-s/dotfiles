#!/usr/bin/env bash

dir="$HOME/.config/rofi/launchers/clipboard"
theme="$dir/style.rasi"
source "$dir/render.sh"
mkdir -p "$CLIP_CACHE"

mapfile -t entries < <(cliphist list | head -150)

# Self-heal: render any thumbnail missing from the cache. In steady state
# store-thumb.sh already made them all on copy, so this loop is a no-op and
# rofi opens instantly; it only does work on a cold cache (e.g. first run).
max_jobs=4
for line in "${entries[@]}"; do
	id="${line%%$'\t'*}"
	[[ -f "$CLIP_CACHE/$id.png" ]] && continue
	render_thumb "$id" "$line" &
	while (($(jobs -r -p | wc -l) >= max_jobs)); do wait -n; done
done
wait

gen_rofi_input() {
	for line in "${entries[@]}"; do
		id="${line%%$'\t'*}"
		printf '\0icon\x1f%s\n' "$CLIP_CACHE/$id.png"
	done
}

sel=$(gen_rofi_input | rofi -dmenu -format i -show-icons -no-cycle -scroll-method 0 -theme "$theme")
[[ -n "$sel" ]] && cliphist decode <<<"${entries[$sel]}" | wl-copy
