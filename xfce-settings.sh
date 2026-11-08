#!/usr/bin/env bash
# Navi XFCE settings. Run from INSIDE the desktop session, not over SSH.
set -euo pipefail

NAVI_DIR="$(cd "$(dirname "$0")" && pwd)"

# Hide default desktop icons
xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0   # 0 = no icons

# Appearance
xfconf-query -c xsettings -p /Net/ThemeName     -s "Gruvbox-Orange-Light"
xfconf-query -c xfwm4     -p /general/theme     -s "Navi"   # themes/gen-xfwm4.py
xfconf-query -c xfwm4     -p /general/title_font   -n -t string -s "JetBrainsMono Nerd Font Bold 9"
xfconf-query -c xfwm4     -p /general/button_layout -n -t string -s "|HMC"   # minimize, maximize, close on the right
xfconf-query -c xsettings -p /Net/IconThemeName -s "Colloid-Orange-Gruvbox-Light"

# Wallpaper (applied to every connected monitor)
WALLPAPER="$NAVI_DIR/wallpapers/lain.png"
for mon in $(xrandr --listmonitors | awk 'NR>1 {print $NF}'); do
  base="/backdrop/screen0/monitor${mon}/workspace0"
  xfconf-query -c xfce4-desktop -p "$base/last-image"  -n -t string -s "$WALLPAPER"
  xfconf-query -c xfce4-desktop -p "$base/image-style" -n -t int    -s 5   # 5 = zoomed
done

# --- Panel: one slim top bar, no dock ---
# Rebuilt from scratch on every run so the result never depends on old state.
# Layout: menu | workspaces | windows | ------ clock ------ | tray, volume, session
# Colors and fonts live in dotfiles/gtk/.config/gtk-3.0/gtk.css (widget names = <plugin>-<id>).
xfce4-panel --quit || true
xfconf-query -c xfce4-panel -p / -R -r || true
rm -rf "$HOME/.config/xfce4/panel"

p() { xfconf-query -c xfce4-panel -p "$1" -n "${@:2}"; }

p /configver -t int -s 2
p /panels    -t int -s 1 -a
p /panels/dark-mode -t bool -s true
p /panels/panel-1/position        -t string -s "p=6;x=0;y=0"   # 6 = top
p /panels/panel-1/position-locked -t bool   -s true
p /panels/panel-1/length          -t double -s 100
p /panels/panel-1/size            -t int    -s 28
p /panels/panel-1/icon-size       -t int    -s 16
p /panels/panel-1/background-style -t int   -s 1                # 1 = solid color
# Gruvbox bg0_h (#1d2021) at 92% opacity
p /panels/panel-1/background-rgba -t double -s 0.114 -t double -s 0.125 -t double -s 0.129 -t double -s 0.92
p /panels/panel-1/plugin-ids -t int -s 10 -t int -s 1 -t int -s 2 -t int -s 3 -t int -s 4 \
                             -t int -s 5 -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9

# Menu button: Debian logo that opens rofi
p /plugins/plugin-10 -t string -s launcher
p /plugins/plugin-10/items -t string -s navi-menu.desktop -a
mkdir -p "$HOME/.config/xfce4/panel/launcher-10"
cat > "$HOME/.config/xfce4/panel/launcher-10/navi-menu.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Apps
Comment=Open the app launcher
Exec=rofi -show drun
Icon=distributor-logo-debian
DESKTOP

p /plugins/plugin-1 -t string -s pager
p /plugins/plugin-1/miniature-view -t bool -s false             # numbered buttons
p /plugins/plugin-2 -t string -s tasklist
p /plugins/plugin-2/flat-buttons   -t bool -s true
p /plugins/plugin-2/show-handle    -t bool -s false
p /plugins/plugin-2/include-all-workspaces -t bool -s false   # only this workspace's windows
p /plugins/plugin-3 -t string -s separator
p /plugins/plugin-3/expand -t bool -s true
p /plugins/plugin-3/style  -t int  -s 0                         # 0 = invisible
p /plugins/plugin-4 -t string -s clock
p /plugins/plugin-4/mode -t int -s 2                            # 2 = digital
p /plugins/plugin-4/digital-layout      -t int    -s 3          # 3 = time only
p /plugins/plugin-4/digital-time-format -t string -s "%a %d %b  %H:%M"
p /plugins/plugin-4/digital-time-font   -t string -s "JetBrainsMono Nerd Font Bold 9"   # clock ignores the panel CSS font
p /plugins/plugin-5 -t string -s separator
p /plugins/plugin-5/expand -t bool -s true
p /plugins/plugin-5/style  -t int  -s 0
p /plugins/plugin-6 -t string -s systray
p /plugins/plugin-6/square-icons -t bool -s true
p /plugins/plugin-7 -t string -s pulseaudio
p /plugins/plugin-7/enable-keyboard-shortcuts -t bool -s true
p /plugins/plugin-8 -t string -s separator
p /plugins/plugin-8/style -t int -s 0
p /plugins/plugin-9 -t string -s actions
p /plugins/plugin-9/appearance   -t int -s 1                    # 1 = menu
p /plugins/plugin-9/button-title -t int -s 3                    # 3 = custom label
p /plugins/plugin-9/custom-title -t string -s $'\uf011'           # Nerd Font power glyph

setsid -f xfce4-panel >/dev/null 2>&1

# --- Workspaces ---
xfconf-query -c xfwm4 -p /general/workspace_count -s 4
xfconf-query -c xfwm4 -p /general/workspace_names -n \
  -t string -s 1 -t string -s 2 -t string -s 3 -t string -s 4

# --- Keyboard shortcuts ---
k() { xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$1" -n -t string -s "$2"; }
k Super_L          "rofi -show drun"
k "<Super>space"   "rofi -show drun"
k "<Super>Tab"     "rofi -show window"
k "<Super>e"       "nemo"
k "<Super>Return"  "alacritty"
k "<Super>r"       "rofi -show run"
k Print            "xfce4-screenshooter -f"
k "<Shift>Print"   "xfce4-screenshooter -r"
# Window tiling (xfwm4 built-ins). Dragging a window to a screen edge also tiles it.
# Note: xfconf spells Ctrl as <Primary>.
w() { xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/$1" -n -t string -s "$2"; }
w "<Super>Left"          tile_left_key
w "<Super>Right"         tile_right_key
w "<Super>Up"            maximize_window_key
w "<Super>Down"          hide_window_key
w "<Super><Shift>Left"   tile_up_left_key
w "<Super><Shift>Right"  tile_up_right_key
w "<Super><Primary>Left" tile_down_left_key
w "<Super><Primary>Right" tile_down_right_key
w "<Super>q"             close_window_key
xfconf-query -c xfwm4 -p /general/tile_on_move -n -t bool -s true
# <Super>Tab belonged to xfwm4's window switcher; free it for rofi
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Tab" -r || true

# --- Default apps ---
xdg-mime default nemo.desktop inode/directory
# Nemo: no desktop drawing, open terminals in Alacritty
gsettings set org.nemo.desktop show-desktop-icons false
gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
