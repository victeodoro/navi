#!/usr/bin/env bash
# Navi XFCE settings. Run from INSIDE the desktop session, not over SSH.
set -euo pipefail

# Appearance
xfconf-query -c xsettings -p /Net/IconThemeName -s "<THEME_NAME>"
