# Notes
- NetworkManager ignores interfaces listed in /etc/network/interfaces. Navi ships a loopback-only version; it applies on reboot, so it's safe over SSH.
- Screen sharing works out of the box on X11 (XFCE). It was a portal/PipeWire hassle on Sway.
- --no-install-recommends skips useful extras sometimes. Example: rtkit (realtime audio priority for PipeWire). Missing pieces show up as warnings: read them.
- SVG icon themes (Papirus) need librsvg2-common (the GTK SVG loader). Without it, GTK silently falls back to blurry Adwaita PNGs.
- Bootstrap "skip if folder exists" checks must only create the folder AFTER a successful download, or one failed run blocks all future ones.
- xfconf properties only exist after first being set. Scripts must create them with `xfconf-query -n -t <type>`, not search for existing ones.
- `gsettings` (used to configure Nemo and other GNOME-family apps) lives in libglib2.0-bin, which --no-install-recommends leaves out.
- The XFCE panel is rebuilt from scratch by xfce-settings.sh (channel reset + recreate). Editing it through the GUI works, but the next script run wipes those changes: put them in the script.
- Panel "actions" plugin: button-title 3 means a custom label, not icon only. A Nerd Font glyph as the label gives an icon look.

## Credits
- Wallpaper `wallpapers/lain.png`: by patrika (https://alphacoders.com/users/profile/227699/patrika). Redistributed with attribution, as permitted by the author. Download link: https://wall.alphacoders.com/big.php?i=1371077
