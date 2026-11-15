#!/usr/bin/env bash
# Navi step 2/3: apps. Run by install.sh, not by hand:
#   scripts/apps.sh personal               all + personal apps
#   scripts/apps.sh work <app id>...       all + the work apps picked in the menu
# install.sh also sources this file to read the work app list for its menu.
#
# Three groups:
#   all       every Navi desktop: apt packages in packages/apps.txt + ALL_APPS
#   personal  only without --work: PERSONAL_APPS
#   work      only with --work, chosen from WORK_APPS in a menu
# Each app id maps to an app_<id> function below. Where to get an app, in order
# of preference: Debian apt > the vendor's signed apt repo > Flathub > the
# vendor's own installer. Apps that update themselves install per-user, so
# their updater can write to its own folder.

ALL_APPS=(obsidian postman omp burp proton)
PERSONAL_APPS=(spotify)
# "id|description" for the --work menu, in menu order
WORK_APPS=(
  "teams|Microsoft Teams (teams-for-linux; Microsoft has no Linux app)"
  "slack|Slack"
  "libreoffice|LibreOffice: Writer, Calc, Impress"
  "warp|Cloudflare WARP"
  "heroku|Heroku CLI"
  "gcloud|Google Cloud CLI (gcloud)"
  "claude|Claude Code (claude CLI)"
  "vscode|Visual Studio Code"
)

# ---------- all ----------
app_obsidian() { flatpak_app md.obsidian.Obsidian; }
app_postman()  { flatpak_app com.getpostman.Postman; }

app_omp() {   # omp.sh coding agent; the installer checks the binary's SHA-256 and puts it in ~/.local/bin
  [ -x "$HOME/.local/bin/omp" ] || curl -fsSL https://omp.sh/install | sh
}

app_burp() {  # Burp Suite Community: PortSwigger's installer (bundles its own Java), unattended
  local dir="$HOME/.local/share/BurpSuiteCommunity" tmp
  [ -x "$dir/BurpSuiteCommunity" ] && return 0
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/burp.sh" "https://portswigger.net/burp/releases/download?product=community&type=Linux"
  sh "$tmp/burp.sh" -q -dir "$dir"
  rm -rf "$tmp"
  if ! ls "$HOME"/.local/share/applications/*[Bb]urp*.desktop >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/share/applications"
    printf '[Desktop Entry]\nType=Application\nName=Burp Suite Community\nExec=%s\nIcon=applications-internet\nCategories=Network;Security;\n' \
      "$dir/BurpSuiteCommunity" > "$HOME/.local/share/applications/burpsuite-community.desktop"
  fi
}

# ---------- personal ----------
app_spotify() { flatpak_app com.spotify.Client; }

app_proton() {
  # Proton VPN: Proton's own signed apt repo, so updates come through apt.
  # The release package only adds the repo + its key. Pinned and checksum-verified.
  local PROTONVPN_RELEASE="1.0.10"
  local PROTONVPN_RELEASE_SHA256="c8a9fffb4ebdd63db08ce7f11c9b0ac394064ae6a210feb9ab63a0f7d8d060a7"
  local tmp
  if [ ! -f /etc/apt/sources.list.d/protonvpn-stable.sources ]; then
    tmp="$(mktemp -d)"; chmod 755 "$tmp"
    curl -fsSL -o "$tmp/release.deb" \
      "https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_${PROTONVPN_RELEASE}_all.deb"
    echo "$PROTONVPN_RELEASE_SHA256  $tmp/release.deb" | sha256sum --check --quiet -
    sudo dpkg -i "$tmp/release.deb"
    rm -rf "$tmp"
    sudo apt-get update
  fi
  # "gnome" is only the name, works on XFCE. The indicator library gives it a tray icon.
  apt_install proton-vpn-gnome-desktop gir1.2-ayatanaappindicator3-0.1

  # Proton Pass: no apt repo, Proton ships a .deb and the app announces updates.
  # Only installed once, so a re-run never downgrades a newer self-updated version.
  local PROTON_PASS_VERSION="1.43.1"
  local PROTON_PASS_SHA512="0060237052fca72d74f985f6d93a0943c97a83592df368ee2516ebacc057de4f451fc8b8458f367f311bd5700da5849d815b3ccc8543718dbb22f80bd3cd949b"
  if ! dpkg -s proton-pass >/dev/null 2>&1; then
    tmp="$(mktemp -d)"; chmod 755 "$tmp"   # apt reads local .debs as the _apt user
    curl -fsSL -o "$tmp/proton-pass.deb" \
      "https://proton.me/download/pass/linux/proton-pass_${PROTON_PASS_VERSION}_amd64.deb"
    echo "$PROTON_PASS_SHA512  $tmp/proton-pass.deb" | sha512sum --check --quiet -
    apt_install "$tmp/proton-pass.deb"
    rm -rf "$tmp"
  fi
}

# ---------- work ----------
app_teams()       { flatpak_app com.github.IsmaelMartinez.teams_for_linux; }
app_slack()       { flatpak_app com.slack.Slack; }
app_libreoffice() { apt_install libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3 libreoffice-style-colibre; }

app_warp() {
  apt_repo cloudflare-warp https://pkg.cloudflareclient.com/pubkey.gpg \
    https://pkg.cloudflareclient.com/ "$(. /etc/os-release && echo "$VERSION_CODENAME")" main
  apt_install cloudflare-warp
}

app_heroku() {  # standalone build in ~/.local/lib, so `heroku update` can replace itself
  if [ ! -x "$HOME/.local/lib/heroku/bin/heroku" ]; then
    mkdir -p "$HOME/.local/lib"
    curl -fsSL https://cli-assets.heroku.com/channels/stable/heroku-linux-x64.tar.gz | tar -xz -C "$HOME/.local/lib"
  fi
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.local/lib/heroku/bin/heroku" "$HOME/.local/bin/heroku"
}

app_gcloud() {
  apt_repo google-cloud-sdk https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    https://packages.cloud.google.com/apt cloud-sdk main
  apt_install google-cloud-cli
}

app_claude() {  # Anthropic's native installer, to ~/.local/bin; updates itself
  [ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash
}

app_vscode() {
  # Stop the code package from adding a second copy of its repo (duplicate
  # sources with different keys make apt refuse to run).
  echo "code code/add-microsoft-repo boolean false" | sudo debconf-set-selections
  apt_repo vscode https://packages.microsoft.com/keys/microsoft.asc \
    https://packages.microsoft.com/repos/code stable main
  apt_install code
}

# ---------- run ----------
main() {
  set -euo pipefail
  cd "$(dirname "$0")/.."
  source scripts/lib.sh
  local profile="${1:?usage: apps.sh personal|work [app id...]}"; shift
  local app

  install_list packages/apps.txt
  for app in "${ALL_APPS[@]}"; do echo "==> $app"; "app_$app"; done

  case "$profile" in
    personal) for app in "${PERSONAL_APPS[@]}"; do echo "==> $app"; "app_$app"; done ;;
    work)     for app in "$@";                  do echo "==> $app"; "app_$app"; done ;;
    *) echo "apps.sh: unknown profile '$profile'" >&2; exit 1 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
