# Notes
- NetworkManager ignores interfaces listed in /etc/network/interfaces. Navi ships a loopback-only version; it applies on reboot, so it's safe over SSH.
- Screen sharing works out of the box on X11 (XFCE). It was a portal/PipeWire hassle on Sway.
- --no-install-recommends skips useful extras sometimes. Example: rtkit (realtime audio priority for PipeWire). Missing pieces show up as warnings: read them.
- SVG icon themes (Papirus) need librsvg2-common (the GTK SVG loader). Without it, GTK silently falls back to blurry Adwaita PNGs.
- Bootstrap "skip if folder exists" checks must only create the folder AFTER a successful download, or one failed run blocks all future ones.
- xfconf properties only exist after first being set. Scripts must create them with `xfconf-query -n -t <type>`, not search for existing ones.
- `gsettings` (used to configure Nemo and other GNOME-family apps) lives in libglib2.0-bin, which --no-install-recommends leaves out.
- The XFCE panel is rebuilt from scratch by xfce-settings.sh (channel reset + recreate). Editing it through the GUI works, but the next script run wipes those changes: put them in the script.
- Alacritty opacity under xfwm4 looks far stronger than the number: 0.95 already shows windows behind clearly. 0.98 reads as subtle glass.
- Nerd Font icons are Unicode private-use characters. Some editors and copy-paste paths silently drop them; if a prompt shows blanks, check the file with `grep -P '[\x{e000}-\x{f8ff}]'`.
- Dotfile folders keep their files under a hidden `.config/` (e.g. dotfiles/rofi/.config/rofi/). Use `ls -a` to see it. Stow mirrors that path into $HOME.
- rofi `@theme "navi"` broke when launched from $HOME: the bare name matched the ~/navi repo folder. Use a full path to the .rasi file.
- Changing the login shell (chsh) only applies after logging out and back in: the running session keeps SHELL=/bin/bash.
- Panel styling is GTK CSS in ~/.config/gtk-3.0/gtk.css, scoped with `.xfce4-panel` and plugin names like `#pager-1`. The clock plugin ignores CSS fonts: it has its own digital-time-font setting.
- ~/.config/gtk-3.0 must be a real folder before stow runs, or GTK apps write bookmarks into the repo.
- xfwm4 allows ONE key per window action. Binding Super+Up to maximize while Alt+F10 still had it silently killed one of them; this broke Alt+F4/Alt+F10. xfce-settings.sh unbinds the old key first. Changes need an xfwm4 restart (or re-login) to fully apply.
- Never bind bare Super_L as a shortcut: it grabs Super and swallows every Super+<key> combo. xcape maps a Super tap to Super+Space instead.
- Debugging shortcuts: when xfwm4 doesn't match a window shortcut it replays the key to the app, so you see junk like `;3~` typed in the terminal.
- xfconf arrays: a single value is stored as a plain int unless you pass `-a`. A panel with `plugin-ids` saved as a plain int shows up empty.
- XFCE panels can't center a plugin inside a full-width panel (expanding separators shift with the window list). Navi uses three non-overlapping panels (44/12/44%). Don't overlay panels: clicking the lower one raises it over the other.
- A custom tiling script (wmctrl) misplaced Firefox and was removed: apps that draw their own title bar report frames differently. xfwm4's built-in tiling handles them.
- Panel hover styles look like rendering bugs in screenshots when the mouse is parked on the bar. Move the pointer away before judging.
- Screenshots: the dialog's default action lives in ~/.config/xfce4/xfce4-screenshooter (action=2 is clipboard). Ctrl+C doesn't work in that dialog; Enter confirms. Clipman keeps the image after the tool exits.

## Credits
- Wallpaper `wallpapers/lain.png`: by patrika (https://alphacoders.com/users/profile/227699/patrika). Redistributed with attribution, as permitted by the author. Download link: https://wall.alphacoders.com/big.php?i=1371077
