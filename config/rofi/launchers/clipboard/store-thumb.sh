#!/usr/bin/env bash
# --watch target for wl-paste: stores the clip in cliphist and renders its
# thumbnail right then, so the menu never generates anything at open time.
dir="$HOME/.config/rofi/launchers/clipboard"
source "$dir/render.sh"
mkdir -p "$CLIP_CACHE"

cliphist store # consumes stdin, assigns the id (and trims to max-items)

line=$(cliphist list | head -1) # newest entry = the one we just stored
id="${line%%$'\t'*}"
[[ -n "$id" ]] && render_thumb "$id" "$line"

# drop thumbnails whose entry cliphist has since evicted (max-items cap).
# ponytail: grep-per-file over ~150 ids, runs in the background on copy — fine.
valid=$(cliphist list | cut -f1)
for f in "$CLIP_CACHE"/*.png; do
	[[ -e "$f" ]] || continue
	grep -qxF "$(basename "$f" .png)" <<<"$valid" || rm -f "$f"
done
