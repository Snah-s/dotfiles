#!/usr/bin/env bash
# Fetch a launcher theme from github.com/newmanls/rofi-themes-collection and
# open the launcher with it once so you can see it.
#
#   fetch-theme.sh           pick from the repo's list (rofi menu)
#   fetch-theme.sh <name>    e.g. rounded-nord-dark, spotlight-dark, squared-nord
#
# Themes land in ~/.config/rofi/themes/, the folder rofi itself searches for
# `-theme <name>`. To make one the SUPER+SPACE launcher, edit
# ~/.config/rofi/launchers/type-1/launcher.sh: `-theme <name>` instead of
# `-theme ${dir}/${theme}.rasi`.

set -euo pipefail

REPO=newmanls/rofi-themes-collection
RAW="https://raw.githubusercontent.com/$REPO/master/themes"
DEST="$HOME/.config/rofi/themes"

name=${1:-}
if [[ -z $name ]]; then
	name=$(curl -sfL "https://api.github.com/repos/$REPO/contents/themes" |
		jq -r '.[] | select(.type == "file" and (.name | endswith(".rasi"))) | .name | rtrimstr(".rasi")' |
		rofi -dmenu -i -no-custom -p "Theme") || exit 0
fi
# the name becomes part of a URL and a file path: no slashes, no dots
[[ $name =~ ^[A-Za-z0-9_-]+$ ]] || { echo "bad theme name: $name" >&2; exit 1; }

fetch() { # fetch <path under themes/>; temp + mv so a failed download leaves nothing half-written
	mkdir -p "$(dirname "$DEST/$1")"
	curl -sfL "$RAW/$1" -o "$DEST/$1.part" && mv "$DEST/$1.part" "$DEST/$1" ||
		{ rm -f "$DEST/$1.part"; echo "could not download themes/$1 from $REPO" >&2; exit 1; }
}

fetch "$name.rasi"
# rounded-* themes @import template/rounded-template.rasi from next to themselves.
# Only plain relative paths inside themes/ are followed (no "~", no "..").
sed -n 's/^[[:space:]]*@import[[:space:]]*"\([^"]*\)".*/\1/p' "$DEST/$name.rasi" | while read -r imp; do
	[[ $imp =~ ^[A-Za-z0-9_/-]+\.rasi$ ]] || { echo "not following import: $imp" >&2; continue; }
	fetch "$imp"
done

# rofi exits 0 even on a broken theme; the parse error only shows on stderr
if rofi -theme "$DEST/$name.rasi" -dump-theme 2>&1 >/dev/null | grep -q 'Failed to parse'; then
	echo "rofi cannot parse $DEST/$name.rasi" >&2
	exit 1
fi

echo "saved $DEST/$name.rasi"
rofi -show drun -theme "$DEST/$name.rasi" || true
