#!/usr/bin/env bash
# Shared thumbnail renderer for the clipboard menu. Sourced by store-thumb.sh
# (on copy) and launcher.sh (self-heal/backfill). The magick params live here
# so thumbnails always match no matter which path generated them.
CLIP_CACHE="$HOME/.cache/cliphist-thumbs"
CLIP_FONT="/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"

# render_thumb <id> <cliphist-list-line> — writes $CLIP_CACHE/<id>.png if absent.
# The explicit -font skips magick's per-run fontconfig scan (~1s -> ~0.13s);
# nice keeps it off the foreground's CPU.
render_thumb() {
	local id=$1 line=$2 thumb="$CLIP_CACHE/$1.png"
	[[ -f "$thumb" ]] && return
	if [[ "$line" == *"[[ binary data"* ]]; then
		cliphist decode <<<"$line" |
			nice -n 19 magick - -thumbnail '300x300^' -gravity center -extent 300x300 "$thumb" 2>/dev/null
	else
		printf '%s' "${line#*$'\t'}" |
			nice -n 19 magick -size 300x300 -background "#183A43" -fill white \
				-font "$CLIP_FONT" -pointsize 22 -gravity northwest caption:@- "$thumb" 2>/dev/null
	fi
}
