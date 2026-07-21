#!/usr/bin/env bash
# Sync live ~/.config into this repo. Run: ./sync.sh   (preview: ./sync.sh -n)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${XDG_CONFIG_HOME:-$HOME/.config}"
RS="rsync -a --delete --exclude .git/ --exclude .vscode/"
[ "${1:-}" = "-n" ] && RS="$RS --dry-run -v"   # preview without writing

# Whole dirs mirrored verbatim
for d in hypr kitty nvim waybar swaync rofi; do
  $RS "$SRC/$d/" "$REPO/.config/$d/"
done

# zsh: only rc files (plugins/themes are submodules, history is gitignored)
if [ "${1:-}" != "-n" ]; then
  for f in .zshrc .zshenv .p10k.zsh; do cp "$SRC/zsh/$f" "$REPO/.config/zsh/$f"; done
  cp "$HOME/.gitconfig" "$REPO/.config/git/.gitconfig"
fi

echo "Synced. Review with: git -C '$REPO' status"
