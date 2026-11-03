# Notes
- NetworkManager ignores interfaces listed in /etc/network/interfaces. Navi ships a loopback-only version; it applies on reboot, so it's safe over SSH.
- Screen sharing works out of the box on X11 (XFCE). It was a portal/PipeWire hassle on Sway.
- --no-install-recommends skips useful extras sometimes. Example: rtkit (realtime audio priority for PipeWire). Missing pieces show up as warnings: read them.
- SVG icon themes (Papirus) need librsvg2-common (the GTK SVG loader). Without it, GTK silently falls back to blurry Adwaita PNGs.
