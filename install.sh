#!/usr/bin/env bash
# Bootstrap an Arch machine from these dotfiles: packages + external tools + configs.
# Idempotent — safe to re-run. Regenerate the package list with: pacman -Qqe > pkglist.txt
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

# --- 1. yay (AUR helper) ---------------------------------------------------
if ! command -v yay >/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel git
  tmp=$(mktemp -d); git clone https://aur.archlinux.org/yay.git "$tmp"
  (cd "$tmp" && makepkg -si --noconfirm); rm -rf "$tmp"
fi

# --- 2. packages (native + AUR, from the committed snapshot) ---------------
yay -S --needed --noconfirm - < "$REPO/pkglist.txt"

# --- 3. external installers not in the repos -------------------------------
if [ ! -x "$HOME/.local/bin/micromamba" ]; then
  "${SHELL}" <(curl -L micro.mamba.pm/install.sh)   # micromamba
fi
if [ ! -d "$HOME/.nvm" ]; then
  git clone https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
  ( . "$HOME/.nvm/nvm.sh" && nvm install --lts )     # nvm + latest LTS node
fi

# --- 4. zsh plugin/theme submodules ----------------------------------------
git -C "$REPO" submodule update --init --recursive

# --- 5. deploy configs (repo -> ~), the reverse of sync.sh -----------------
for d in hypr kitty nvim waybar swaync rofi zsh; do
  rsync -a "$REPO/.config/$d/" "$CFG/$d/"
done
cp "$REPO/.zshenv" "$HOME/.zshenv"
cp "$REPO/.config/git/.gitconfig" "$HOME/.gitconfig"

echo "Done. Log out/in (or start Hyprland) to pick everything up."
