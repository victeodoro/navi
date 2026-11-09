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
# Panel 1 (full width): menu | workspaces | window icons | ------ | tray, volume, power
# Panel 2 (overlay):    the clock alone, snapped to the top center. In panel 1 the
#                       clock drifted with the number of open windows.
# Colors and fonts live in dotfiles/gtk/.config/gtk-3.0/gtk.css (widget names = <plugin>-<id>).
xfce4-panel --quit || true
xfconf-query -c xfce4-panel -p / -R -r || true
rm -rf "$HOME/.config/xfce4/panel"

p() { xfconf-query -c xfce4-panel -p "$1" -n "${@:2}"; }
launcher() {  # launcher <plugin-id> <name> <exec> <icon>
  p "/plugins/plugin-$1" -t string -s launcher
  p "/plugins/plugin-$1/items" -t string -s "$2.desktop" -a
  mkdir -p "$HOME/.config/xfce4/panel/launcher-$1"
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nIcon=%s\n' \
    "$2" "$3" "$4" > "$HOME/.config/xfce4/panel/launcher-$1/$2.desktop"
}

p /configver -t int -s 2
p /panels    -t int -s 1 -t int -s 2
p /panels/dark-mode -t bool -s true

p /panels/panel-1/position        -t string -s "p=6;x=0;y=0"   # 6 = top, full width
p /panels/panel-1/position-locked -t bool   -s true
p /panels/panel-1/length          -t double -s 100
p /panels/panel-1/size            -t int    -s 28
p /panels/panel-1/icon-size       -t int    -s 16
p /panels/panel-1/background-style -t int   -s 1                # 1 = solid color
# Gruvbox bg0_h (#1d2021), fully opaque: the clock panel sits on top and any
# transparency makes its box visible against the bar.
BAR_RGBA=(-t double -s 0.114 -t double -s 0.125 -t double -s 0.129 -t double -s 1.0)
p /panels/panel-1/background-rgba "${BAR_RGBA[@]}"
p /panels/panel-1/plugin-ids -t int -s 10 -t int -s 1 -t int -s 2 -t int -s 3 \
                             -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9

p /panels/panel-2/position        -t string -s "p=9;x=0;y=0"   # 9 = top center
p /panels/panel-2/position-locked -t bool   -s true
p /panels/panel-2/length          -t double -s 1               # shrink to content
p /panels/panel-2/size            -t int    -s 28
p /panels/panel-2/disable-struts  -t bool   -s true            # don't push windows down twice
p /panels/panel-2/background-style -t int   -s 1
p /panels/panel-2/background-rgba "${BAR_RGBA[@]}"
p /panels/panel-2/plugin-ids -t int -s 4 -a                  # -a: a one-item list, not a plain int

launcher 10 navi-menu "rofi -show drun" "$NAVI_DIR/icons/navi-menu.svg"
p /plugins/plugin-1 -t string -s pager
p /plugins/plugin-1/miniature-view -t bool -s false             # numbered buttons
p /plugins/plugin-2 -t string -s tasklist
p /plugins/plugin-2/flat-buttons   -t bool -s true
p /plugins/plugin-2/show-handle    -t bool -s false
p /plugins/plugin-2/show-labels    -t bool -s false             # icons only
p /plugins/plugin-2/include-all-workspaces -t bool -s false   # only this workspace's windows
p /plugins/plugin-3 -t string -s separator
p /plugins/plugin-3/expand -t bool -s true
p /plugins/plugin-3/style  -t int  -s 0                         # 0 = invisible
p /plugins/plugin-4 -t string -s clock
p /plugins/plugin-4/mode -t int -s 2                            # 2 = digital
p /plugins/plugin-4/digital-layout      -t int    -s 3          # 3 = time only
p /plugins/plugin-4/digital-time-format -t string -s "%a %d %b  %H:%M"
p /plugins/plugin-4/digital-time-font   -t string -s "JetBrainsMono Nerd Font Bold 9"   # clock ignores the panel CSS font
p /plugins/plugin-6 -t string -s systray
p /plugins/plugin-6/square-icons -t bool -s true
p /plugins/plugin-7 -t string -s pulseaudio
p /plugins/plugin-7/enable-keyboard-shortcuts -t bool -s true
p /plugins/plugin-8 -t string -s separator
p /plugins/plugin-8/style -t int -s 0
launcher 9 navi-power "$HOME/.local/bin/navi-power" "$NAVI_DIR/icons/navi-power.svg"

setsid -f xfce4-panel >/dev/null 2>&1

# --- Workspaces ---
xfconf-query -c xfwm4 -p /general/workspace_count -s 4
xfconf-query -c xfwm4 -p /general/workspace_names -n \
  -t string -s 1 -t string -s 2 -t string -s 3 -t string -s 4

# --- Keyboard shortcuts ---
k() { xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/$1" -n -t string -s "$2"; }
k "<Super>space"   "rofi -show drun"
k "<Super>Tab"     "rofi -show window"
k "<Super>e"       "nemo"
k "<Super>Return"  "alacritty"
k "<Super>r"       "rofi -show run"
# Directional tiling, Cinnamon style (Left then Up = top-left quarter)
k "<Super>Left"    "$HOME/.local/bin/navi-tile left"
k "<Super>Right"   "$HOME/.local/bin/navi-tile right"
k "<Super>Up"      "$HOME/.local/bin/navi-tile up"
k "<Super>Down"    "$HOME/.local/bin/navi-tile down"
# Screenshots, Cinnamon style: add Ctrl to copy straight to the clipboard
k Print                    "xfce4-screenshooter -f"      # full screen  -> dialog
k "<Shift>Print"           "xfce4-screenshooter -r"      # region       -> dialog
k "<Alt>Print"             "xfce4-screenshooter -w"      # window       -> dialog
k "<Primary>Print"         "xfce4-screenshooter -f -c"   # full screen  -> clipboard
k "<Primary><Shift>Print"  "xfce4-screenshooter -r -c"   # region       -> clipboard
k "<Primary><Alt>Print"    "xfce4-screenshooter -w -c"   # window       -> clipboard
# Power menu
k "<Primary><Alt>Delete"   "$HOME/.local/bin/navi-power"
# xfwm4 window actions. xfconf spells Ctrl as <Primary>.
# xfwm4 allows ONE key per action: if two keys map to the same action, one
# silently stops working (this broke Alt+F4 once). w() unbinds the old key first.
w() {
  xfconf-query -c xfce4-keyboard-shortcuts -lv \
    | awk -v a="$2" -v k="/xfwm4/custom/$1" '$1 ~ "^/xfwm4/custom/" && $2 == a && $1 != k {print $1}' \
    | while read -r old; do xfconf-query -c xfce4-keyboard-shortcuts -p "$old" -r; done
  xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/$1" -n -t string -s "$2"
}
# Super+arrows belong to navi-tile (below), so xfwm4's own tiling goes back to
# its keypad defaults. Two programs can't grab the same key.
w "<Super>KP_Left"     tile_left_key
w "<Super>KP_Right"    tile_right_key
w "<Super>KP_Up"       tile_up_key
w "<Super>KP_Down"     tile_down_key
w "<Super>KP_Home"     tile_up_left_key
w "<Super>KP_Page_Up"  tile_up_right_key
w "<Super>KP_End"      tile_down_left_key
w "<Super>KP_Next"     tile_down_right_key
w "<Alt>F10"           maximize_window_key
w "<Alt>F9"            hide_window_key
w "<Super>1"           workspace_1_key      # was Ctrl+F1, etc.
w "<Super>2"           workspace_2_key
w "<Super>3"           workspace_3_key
w "<Super>4"           workspace_4_key
# Close stays on Alt+F4 (xfwm4 default)
xfconf-query -c xfwm4 -p /general/tile_on_move -n -t bool -s true
# Never bind bare Super_L: it grabs the key and swallows every Super+<key>
# combo (tiling broke because of it). xcape (autostarted) turns a Super tap
# into Super+Space instead.
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Super_L -r 2>/dev/null || true
# <Super>Tab belonged to xfwm4's window switcher; free it for rofi
xfconf-query -c xfce4-keyboard-shortcuts -p "/xfwm4/custom/<Super>Tab" -r || true

# --- Default apps ---
xdg-mime default nemo.desktop inode/directory
# Nemo: no desktop drawing, open terminals in Alacritty
gsettings set org.nemo.desktop show-desktop-icons false
gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
