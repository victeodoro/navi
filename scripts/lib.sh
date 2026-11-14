# Navi: helpers shared by the install steps. Sourced, not run.

# install_list <file>: apt-install every package in a list (comments and blank lines skipped)
install_list() {
  sed -e 's/#.*//' -e '/^\s*$/d' "$1" | xargs sudo apt-get install -y --no-install-recommends
}

# apt_install <pkg>...
apt_install() {
  sudo apt-get install -y --no-install-recommends "$@"
}

# apt_repo <name> <key url> <repo url> <suite> <component>
# Adds a vendor's signed apt repo once. Keys are ASCII-armored, which apt reads
# directly as .asc (no gpg needed). The key only signs this one repo (Signed-By).
apt_repo() {
  local name="$1" key="/usr/share/keyrings/$1.asc"
  [ -f "/etc/apt/sources.list.d/$name.sources" ] && return 0
  curl -fsSL "$2" | sudo tee "$key" >/dev/null
  printf 'Types: deb\nURIs: %s\nSuites: %s\nComponents: %s\nSigned-By: %s\n' "$3" "$4" "$5" "$key" \
    | sudo tee "/etc/apt/sources.list.d/$name.sources" >/dev/null
  sudo apt-get update
}

# flatpak_app <id>: per-user Flatpak from Flathub (no sudo; updates with `flatpak update`)
flatpak_app() {
  flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak --user install -y --noninteractive flathub "$1"
}

# in_xfce_session: true when running inside the graphical XFCE session
in_xfce_session() {
  [ -n "${DISPLAY:-}" ] && pgrep -u "$USER" -x xfce4-session >/dev/null
}
