#!/usr/bin/env bash
# Sync live ~/.config into this repo. Run: ./sync.sh   (preview: ./sync.sh -n)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${XDG_CONFIG_HOME:-$HOME/.config}"
RS="rsync -a --delete --exclude .git/ --exclude .vscode/"
RF="rsync -aR" # -R keeps each file's path under config/
[ "${1:-}" = "-n" ] && RS="$RS --dry-run -v" && RF="$RF --dry-run -v" # preview without writing

# Whole dirs mirrored verbatim
for d in hypr kitty nvim waybar swaync rofi foot tmux xsettingsd nwg-look btop; do
  $RS "$SRC/$d/" "$REPO/config/$d/"
done

# Single files: the rest of their dirs is state or personal (gtk bookmarks, Code caches)
(cd "$SRC" && $RF gtk-3.0/settings.ini gtk-4.0/settings.ini mimeapps.list code-flags.conf \
  Code/User/settings.json Code/User/keybindings.json "$REPO/config/")

# zsh: only rc files (plugins/themes are submodules, history is gitignored)
if [ "${1:-}" != "-n" ]; then
  for f in .zshrc .zshenv .p10k.zsh; do cp "$SRC/zsh/$f" "$REPO/config/zsh/$f"; done
  # files install.sh deploys outside ~/.config: keep them in step or install clobbers newer ones
  cp "$HOME/.gitconfig" "$REPO/config/git/.gitconfig"
  cp "$HOME/.zshenv" "$REPO/.zshenv"
  pacman -Qqe >"$REPO/pkglist.txt"
fi
