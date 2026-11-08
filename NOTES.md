# Notes
- NetworkManager ignores interfaces listed in /etc/network/interfaces. Navi ships a loopback-only version; it applies on reboot, so it's safe over SSH.
- Screen sharing works out of the box on X11 (XFCE). It was a portal/PipeWire hassle on Sway.
- --no-install-recommends skips useful extras sometimes. Example: rtkit (realtime audio priority for PipeWire). Missing pieces show up as warnings: read them.
- SVG icon themes (Papirus) need librsvg2-common (the GTK SVG loader). Without it, GTK silently falls back to blurry Adwaita PNGs.
- Bootstrap "skip if folder exists" checks must only create the folder AFTER a successful download, or one failed run blocks all future ones.

## Credits
- Wallpaper `wallpapers/lain.png`: by patrika (https://alphacoders.com/users/profile/227699/patrika). Redistributed with attribution, as permitted by the author. Download link: https://wall.alphacoders.com/big.php?i=1371077
