#!/usr/bin/env bash
# Navi bootstrap: run as your normal user (uses sudo where needed)
set -euo pipefail
cd "$(dirname "$0")"

install_list() {
  sed -e 's/#.*//' -e '/^\s*$/d' "$1" | xargs sudo apt-get install -y --no-install-recommends
}

sudo apt-get update

install_list packages/base.txt
install_list packages/desktop.txt
install_list packages/theme.txt
install_list packages/shell.txt
install_list packages/apps.txt

# --- Dotfiles ---
# Apps write their own files (e.g. GTK bookmarks) into these folders, so they
# must be real directories; otherwise stow links the whole folder into the repo.
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/autostart" "$HOME/.local/bin" "$HOME/.config/micro"
(cd dotfiles && stow -t "$HOME" --restow */)

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

# --- Spotify: Flatpak, per-user so it needs no sudo ---
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y --noninteractive flathub com.spotify.Client

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
