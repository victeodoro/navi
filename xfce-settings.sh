#!/usr/bin/env bash
# Navi XFCE settings. Run from INSIDE the desktop session, not over SSH.
set -euo pipefail

NAVI_DIR="$(cd "$(dirname "$0")" && pwd)"

# Hide default desktop icons
xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0   # 0 = no icons

# Appearance
xfconf-query -c xsettings -p /Net/ThemeName     -s "Gruvbox-Orange-Light"
xfconf-query -c xfwm4     -p /general/theme     -s "Gruvbox-Orange-Light"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Colloid-Orange-Gruvbox-Light"

# Wallpaper (applied to every connected monitor)
WALLPAPER="$NAVI_DIR/wallpapers/lain.png"
for mon in $(xrandr --listmonitors | awk 'NR>1 {print $NF}'); do
  base="/backdrop/screen0/monitor${mon}/workspace0"
  xfconf-query -c xfce4-desktop -p "$base/last-image"  -n -t string -s "$WALLPAPER"
  xfconf-query -c xfce4-desktop -p "$base/image-style" -n -t int    -s 5   # 5 = zoomed
done
