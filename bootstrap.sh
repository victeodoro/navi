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

# VM-only packages, auto-detected
if systemd-detect-virt -q; then
  install_list packages/vm.txt
fi

# System config files
sudo install -m 644 system/etc/default/keyboard /etc/default/keyboard
sudo setupcon || true

sudo install -m 644 system/etc/network/interfaces /etc/network/interfaces
