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
install_list packages/theme.txt

# VM-only packages, auto-detected
if systemd-detect-virt -q; then
  install_list packages/vm.txt
fi

# --- Icons: Colloid, Gruvbox scheme, orange folders (pinned release) ---
COLLOID_ICONS_TAG="2026-08-10"
if [ ! -d "$HOME/.local/share/icons/Colloid-Orange-Gruvbox-Light" ]; then
  tmp="$(mktemp -d)"
  git clone --depth 1 --branch "$COLLOID_ICONS_TAG" https://github.com/vinceliuice/Colloid-icon-theme "$tmp"
  (cd "$tmp" && ./install.sh -s gruvbox -t orange)
  rm -rf "$tmp"
fi

# --- GTK theme: Gruvbox (Fausto-Korpsvart), light + orange accent (pinned commit) ---
GRUVBOX_GTK_COMMIT="578cd220b5ff6e86b078a6111d26bb20ec8c733f"
if [ ! -d "$HOME/.themes/Gruvbox-Orange-Light" ]; then
  tmp="$(mktemp -d)"
  git -C "$tmp" init -q
  git -C "$tmp" fetch -q --depth 1 https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme "$GRUVBOX_GTK_COMMIT"
  git -C "$tmp" checkout -q FETCH_HEAD
  (cd "$tmp/themes" && ./install.sh -c light -t orange)
  rm -rf "$tmp"
fi

# System config files
sudo install -m 644 system/etc/default/keyboard /etc/default/keyboard
sudo setupcon || true

sudo install -m 644 system/etc/network/interfaces /etc/network/interfaces
