#!/usr/bin/env bash
# Navi step 1/3: base system, desktop packages, dotfiles, themes, system files.
# Run by install.sh, not by hand.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

sudo apt-get update
install_list packages/system.txt
install_list packages/desktop.txt

# Default terminal: Alacritty. xorg needs "some terminal", and on a fresh install
# it comes before Alacritty, so apt pulls in xterm. Both have the same priority,
# so xterm could win and apps marked Terminal=true (micro from the menu, text
# files from Nemo) opened in xterm. GLib and rofi both follow this alternative.
sudo update-alternatives --set x-terminal-emulator /usr/bin/alacritty

# VM-only packages, auto-detected
if systemd-detect-virt -q; then
  install_list packages/vm.txt
fi

# --- Dotfiles: COPIED into $HOME, not linked ---
# Links let apps and installers write into the repo (settings, PATH lines).
# Copies keep the repo clean; re-running install.sh resets these files to the
# repo versions, so make changes in the repo, not in $HOME.
# First remove links left by the old stow setup, or cp would write through them.
find "$HOME" -maxdepth 4 -path "$PWD" -prune -o -type l -print | while read -r link; do
  case "$(readlink -f "$link")" in "$PWD/dotfiles/"*) rm "$link" ;; esac
done
for pkg in dotfiles/*/; do
  cp -rT --preserve=mode "$pkg" "$HOME"
done

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

# --- Font: JetBrains Mono Nerd Font (pinned release) ---
NERD_FONTS_TAG="v3.4.0"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if [ ! -d "$FONT_DIR" ]; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONTS_TAG/JetBrainsMono.tar.xz" \
    | tar -xJ -C "$tmp"
  mkdir -p "$(dirname "$FONT_DIR")"
  mv "$tmp" "$FONT_DIR"
  fc-cache -f
fi

# --- yazi: terminal file manager, not packaged in Debian (pinned release) ---
YAZI_TAG="v26.9.1"
if ! command -v yazi >/dev/null || [[ "$(yazi --version)" != *"${YAZI_TAG#v}"* ]]; then
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/yazi.zip" \
    "https://github.com/sxyazi/yazi/releases/download/$YAZI_TAG/yazi-x86_64-unknown-linux-gnu.zip"
  unzip -q "$tmp/yazi.zip" -d "$tmp"
  sudo install -m 755 "$tmp"/yazi-x86_64-unknown-linux-gnu/{yazi,ya} /usr/local/bin/
  rm -rf "$tmp"
fi

# --- btop theme: btop rewrites its config, so only seed it once ---
if [ ! -f "$HOME/.config/btop/btop.conf" ]; then
  mkdir -p "$HOME/.config/btop"
  echo 'color_theme = "gruvbox_dark"' > "$HOME/.config/btop/btop.conf"
fi

# --- Login shell: zsh ---
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  sudo chsh -s /usr/bin/zsh "$USER"
fi

# --- Login screen (LightDM greeter): needs system-wide copies, it can't read $HOME ---
sudo install -D -m 644 wallpapers/lain.png /usr/share/backgrounds/navi/lain.png
sudo install -D -m 644 system/usr/share/themes/Navi-Greeter/gtk-3.0/gtk.css \
  /usr/share/themes/Navi-Greeter/gtk-3.0/gtk.css
sudo install -m 644 system/etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf

# System config files
sudo install -m 644 system/etc/default/keyboard /etc/default/keyboard
sudo setupcon || true

sudo install -m 644 system/etc/network/interfaces /etc/network/interfaces

# X server: touchpad tap to click, no screen blanking. Apply from the next login;
# scripts/desktop.sh applies both to the running session.
sudo install -D -m 644 -t /etc/X11/xorg.conf.d \
  system/etc/X11/xorg.conf.d/30-touchpad.conf \
  system/etc/X11/xorg.conf.d/10-no-blanking.conf

# Audio: ASUS X515EA internal mic (see the modprobe file). Only on that exact
# codec (Realtek ALC256, ASUS subsystem 1043:102f); applies after a reboot.
if grep -qx 0x10ec0256 /sys/class/sound/hwC*D*/vendor_id 2>/dev/null &&
   grep -qx 0x1043102f /sys/class/sound/hwC*D*/subsystem_id 2>/dev/null; then
  sudo install -D -m 644 system/usr/lib/firmware/navi/asus-x515ea-mic.fw /usr/lib/firmware/navi/asus-x515ea-mic.fw
  sudo install -D -m 644 system/etc/modprobe.d/navi-asus-x515ea-mic.conf /etc/modprobe.d/navi-asus-x515ea-mic.conf
fi
