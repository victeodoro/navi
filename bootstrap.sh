#!/usr/bin/env bash
# Navi bootstrap: run as root user
set -euo pipefail
cd "$(dirname "$0")"

install_list() {
  sed -e 's/#.*//' -e '/^\s*$/d' "$1" | xargs sudo apt-get install -y --no-install-recommends
}

sudo apt-get update

install_list packages/base.txt
install_list packages/desktop.txt
install_list packages/themes.txt

# VM-only packages, auto-detected
if systemd-detect-virt -q; then
  install_list packages/vm.txt
fi

# --- Icons: Colloid, Gruvbox scheme, yellow folders (pinned release) ---
COLLOID_ICONS_TAG="2026-08-10"
if [ ! -d "$HOME/.local/share/icons/Colloid-Yellow-Gruvbox-Light" ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch "$COLLOID_ICONS_TAG" https://github.com/vinceliuice/Colloid-icon-theme "$tmp"
  (cd "$tmp" && ./install.sh -s gruvbox -t yellow)
  rm -rf "$tmp"
fi

# System config files
sudo install -m 644 system/etc/default/keyboard /etc/default/keyboard
sudo setupcon || true

sudo install -m 644 system/etc/network/interfaces /etc/network/interfaces
