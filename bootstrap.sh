#!/usr/bin/env bash
# Navi bootstrap: run as your normal user (uses sudo where needed)
set -euo pipefail
cd "$(dirname "$0")"

install_list() {
  sed -e 's/#.*//' -e '/^\s*$/d' "$1" | xargs sudo apt-get install -y --no-install-recommends
}

sudo apt-get update
install_list packages/system.txt
install_list packages/desktop.txt

# VM-only packages, auto-detected
if systemd-detect-virt -q; then
  install_list packages/vm.txt
fi

# --- Proton VPN: Proton's own signed apt repo, so updates come through apt ---
# The release package only adds the repo + its key. Pinned and checksum-verified.
PROTONVPN_RELEASE="1.0.10"
PROTONVPN_RELEASE_SHA256="c8a9fffb4ebdd63db08ce7f11c9b0ac394064ae6a210feb9ab63a0f7d8d060a7"
if [ ! -f /etc/apt/sources.list.d/protonvpn-stable.sources ]; then
  tmp="$(mktemp -d)"; chmod 755 "$tmp"
  curl -fsSL -o "$tmp/release.deb" \
    "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_${PROTONVPN_RELEASE}_all.deb"
  echo "$PROTONVPN_RELEASE_SHA256  $tmp/release.deb" | sha256sum --check --quiet -
  sudo dpkg -i "$tmp/release.deb"
  rm -rf "$tmp"
  sudo apt-get update
fi
install_list packages/apps.txt

# --- Dotfiles: COPIED into $HOME, not linked ---
# Links let apps and installers write into the repo (settings, PATH lines).
# Copies keep the repo clean; re-running bootstrap resets these files to the
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

# --- Spotify: Flatpak, per-user so it needs no sudo ---
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install -y --noninteractive flathub com.spotify.Client

# --- Proton Pass: no apt repo, Proton ships a .deb. The app announces updates itself.
# Only installed once, so a re-run never downgrades a newer self-updated version.
PROTON_PASS_VERSION="1.43.1"
PROTON_PASS_SHA512="0060237052fca72d74f985f6d93a0943c97a83592df368ee2516ebacc057de4f451fc8b8458f367f311bd5700da5849d815b3ccc8543718dbb22f80bd3cd949b"
if ! dpkg -s proton-pass >/dev/null 2>&1; then
  tmp="$(mktemp -d)"; chmod 755 "$tmp"   # apt reads local .debs as the _apt user
  curl -fsSL -o "$tmp/proton-pass.deb" \
    "https://proton.me/download/pass/linux/proton-pass_${PROTON_PASS_VERSION}_amd64.deb"
  echo "$PROTON_PASS_SHA512  $tmp/proton-pass.deb" | sha512sum --check --quiet -
  sudo apt-get install -y --no-install-recommends "$tmp/proton-pass.deb"
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
# xfce-settings.sh applies both to the running session.
sudo install -D -m 644 -t /etc/X11/xorg.conf.d \
  system/etc/X11/xorg.conf.d/30-touchpad.conf \
  system/etc/X11/xorg.conf.d/10-no-blanking.conf
