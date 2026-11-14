#!/usr/bin/env bash
# Navi installer: the only script you run. As your normal user, from anywhere:
#   ./install.sh          personal desktop: shared apps + personal apps
#   ./install.sh --work   work desktop: shared apps + the work apps you pick
# Safe to re-run: installed apps are skipped and dotfiles reset to the repo versions.
set -euo pipefail
cd "$(dirname "$0")"
source scripts/lib.sh
source scripts/apps.sh        # app lists only (for the --work menu)

usage() { sed -n '2,5s/^# \{0,1\}//p' "$0"; }

profile=personal
for arg in "$@"; do
  case "$arg" in
    --work)    profile=work ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 1 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  echo "Run install.sh as your normal user (it uses sudo when needed), not as root." >&2
  exit 1
fi

# --- Work apps: pick from a checklist before anything installs ---
work_apps=()
if [ "$profile" = work ]; then
  command -v whiptail >/dev/null || { sudo apt-get update && sudo apt-get install -y whiptail; }
  items=()
  for entry in "${WORK_APPS[@]}"; do
    items+=("${entry%%|*}" "${entry#*|}" OFF)
  done
  # whiptail draws on the terminal and prints the picks on stderr; swap the streams to capture them
  picks=$(whiptail --title "Navi: work apps" --separate-output \
    --checklist "Space selects, Enter installs. Shared apps (Obsidian, Chromium, Burp...) are always installed." \
    20 78 "${#WORK_APPS[@]}" "${items[@]}" 3>&1 1>&2 2>&3) || { echo "Cancelled, nothing installed."; exit 1; }
  mapfile -t work_apps <<< "$picks"
  [ -n "${work_apps[0]:-}" ] || work_apps=()
  echo "Work apps: ${work_apps[*]:-none}"
fi

# --- sudo: ask once, keep it alive until the install ends ---
sudo -v
while sudo -n true 2>/dev/null; do sleep 50; kill -0 "$$" 2>/dev/null || exit; done &
keepalive=$!
trap 'kill "$keepalive" 2>/dev/null || true' EXIT

bash scripts/system.sh
bash scripts/apps.sh "$profile" "${work_apps[@]}"

# --- XFCE settings: need the desktop session ---
if in_xfce_session; then
  bash scripts/desktop.sh
  echo
  echo "Done. Log out and back in once so every setting takes effect."
else
  mkdir -p "$HOME/.config/autostart"
  printf '[Desktop Entry]\nType=Application\nName=Navi first-login setup\nExec="%s" --first-login\nX-GNOME-Autostart-enabled=true\n' \
    "$PWD/scripts/desktop.sh" > "$HOME/.config/autostart/navi-first-login.desktop"
  echo
  echo "Done. Reboot and log in: the desktop settings apply by themselves on the first login."
  echo "When the 'settings applied' notice shows, log out and back in once."
fi
