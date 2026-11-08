#!/usr/bin/env bash
# Navi XFCE settings. Run from INSIDE the desktop session, not over SSH.
set -euo pipefail

# Appearance
xfconf-query -c xsettings -p /Net/IconThemeName -s "<THEME_NAME>"
xfconf-query -c xsettings -p /Net/ThemeName     -s "Gruvbox-Orange-Light"
xfconf-query -c xfwm4     -p /general/theme     -s "Gruvbox-Orange-Light"
xfconf-query -c xsettings -p /Net/IconThemeName -s "Colloid-Orange-Gruvbox-Light"
