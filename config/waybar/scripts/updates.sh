#!/usr/bin/env bash
# This network breaks aur.archlinux.org's TLS intermittently (curl 35, the "EOF"
# yay spits out) and yay does not retry: a single OK ping is not enough, so
# demand 3 consecutive connections using the same query yay makes.
aur_stable() {
	local url="https://aur.archlinux.org/rpc?type=info&v=5$(pacman -Qmq | sed 's/^/\&arg[]=/' | tr -d '\n')"
	for _ in 1 2 3; do
		curl -sf -m 10 -o /dev/null "$url" || return 1
	done
}

if aur_stable; then
	echo ":: AUR stable, updating with yay"
	# If yay fails, ask again: AUR down -> it was the network, carry on with pacman.
	# AUR healthy -> you cancelled or a build broke, don't push it.
	if ! yay -Syu && ! aur_stable; then
		echo ":: AUR died mid-run, falling back to official repos"
		sudo pacman -Syu
	fi
else
	echo ":: AUR unstable on this network, official repos only"
	sudo pacman -Syu
fi
read -rp "Press Enter to close..."
