# Install guide
Everything is done by the scripts; this is the order, plus the few steps that can't be scripted.

1. Fresh Debian 13 netinst, no desktop. As root: `apt install sudo git`, `usermod -aG sudo <user>`, log out and back in.
2. Clone the repo and run `./install.sh` (or `./install.sh --work`). It asks for your sudo password once.
3. Reboot and log in. scripts/desktop.sh runs once by itself (autostart entry navi-first-login, log in ~/.cache/navi-first-login.log). If it fails it retries on the next login. Run from inside the desktop, install.sh applies it right away instead.
4. Log out and back in once. The X config (touchpad, no blanking), the keyring unlock and the lock screen only start on a new login.

Personal, not scripted:
- GitHub over SSH with a key not named id_ed25519/id_rsa: SSH won't offer it (you get "Permission denied (publickey)" and never a passphrase prompt). Add to ~/.ssh/config: `Host github.com` / `IdentityFile ~/.ssh/<key>` / `IdentitiesOnly yes` / `AddKeysToAgent yes`.
- Git identity: `git config --global user.name <name>` and `user.email <email>`.

# Notes
- NetworkManager ignores interfaces listed in /etc/network/interfaces. Navi ships a loopback-only version; it applies on reboot, so it's safe over SSH.
- Screen sharing works out of the box on X11 (XFCE). It was a portal/PipeWire hassle on Sway.
- --no-install-recommends skips useful extras sometimes. Example: rtkit (realtime audio priority for PipeWire). Missing pieces show up as warnings: read them.
- SVG icon themes (Papirus) need librsvg2-common (the GTK SVG loader). Without it, GTK silently falls back to blurry Adwaita PNGs.
- Bootstrap "skip if folder exists" checks must only create the folder AFTER a successful download, or one failed run blocks all future ones.
- xfconf properties only exist after first being set. Scripts must create them with `xfconf-query -n -t <type>`, not search for existing ones.
- `gsettings` (used to configure Nemo and other GNOME-family apps) lives in libglib2.0-bin, which --no-install-recommends leaves out.
- The XFCE panel is rebuilt from scratch by scripts/desktop.sh (channel reset + recreate). Editing it through the GUI works, but the next script run wipes those changes: put them in the script.
- Alacritty opacity under xfwm4 looks far stronger than the number: 0.95 already shows windows behind clearly. 0.98 reads as subtle glass.
- Nerd Font icons are Unicode private-use characters. Some editors and copy-paste paths silently drop them; if a prompt shows blanks, check the file with `grep -P '[\x{e000}-\x{f8ff}]'`.
- Dotfile folders keep their files under a hidden `.config/` (e.g. dotfiles/rofi/.config/rofi/). Use `ls -a` to see it. Bootstrap copies that tree into $HOME as is.
- rofi `@theme "navi"` broke when launched from $HOME: the bare name matched the ~/navi repo folder. Use a full path to the .rasi file.
- Changing the login shell (chsh) only applies after logging out and back in: the running session keeps SHELL=/bin/bash.
- Panel styling is GTK CSS in ~/.config/gtk-3.0/gtk.css, scoped with `.xfce4-panel` and plugin names like `#pager-1`. The clock plugin ignores CSS fonts: it has its own digital-time-font setting.
- xfwm4 allows ONE key per window action. Binding Super+Up to maximize while Alt+F10 still had it silently killed one of them; this broke Alt+F4/Alt+F10. scripts/desktop.sh unbinds the old key first. Changes need an xfwm4 restart (or re-login) to fully apply.
- Never bind bare Super_L as a shortcut: it grabs Super and swallows every Super+<key> combo. xcape maps a Super tap to Super+Space instead.
- Debugging shortcuts: when xfwm4 doesn't match a window shortcut it replays the key to the app, so you see junk like `;3~` typed in the terminal.
- xfconf arrays: a single value is stored as a plain int unless you pass `-a`. A panel with `plugin-ids` saved as a plain int shows up empty.
- XFCE panels can't center a plugin inside a full-width panel (expanding separators shift with the window list). Navi uses three non-overlapping panels (44/12/44%). Don't overlay panels: clicking the lower one raises it over the other.
- A custom tiling script (wmctrl) misplaced Firefox and was removed: apps that draw their own title bar report frames differently. xfwm4's built-in tiling handles them.
- Panel hover styles look like rendering bugs in screenshots when the mouse is parked on the bar. Move the pointer away before judging.
- Screenshots: the dialog's default action lives in ~/.config/xfce4/xfce4-screenshooter (action=2 is clipboard). Ctrl+C doesn't work in that dialog; Enter confirms. Clipman keeps the image after the tool exits.
- Dotfiles are copied, not linked (stow was dropped). With links, anything that edited a config wrote into the repo: xfconf saved live settings into dotfiles/xfce4, GTK wrote bookmarks, the Claude Code installer appended a PATH line to .zshrc. Bootstrap removes old stow links before copying. Edit dotfiles in the repo and re-run install.sh; edits made in $HOME get overwritten.
- Colloid installs three variants. -Light has near-black tray icons (unreadable on a dark bar); the plain name mixes Light app icons with the Dark variant's status icons. Tray apps (nm-applet, blueman) only re-read the icon theme on restart.
- Legacy tray icons (nm-applet, blueman use XEmbed) ignore CSS padding. Space them with the systray's square-icons; pad the other plugins' buttons in CSS.
- Never `pkill -f <name>` from a script whose own command line contains <name>: it kills itself. Use `pkill -x` or match the exact path.
- ASUS batteries can flick to "discharging" for ~30 s at 100% on AC. Check /var/lib/upower/history-time-empty-*.dat before blaming the charger. xfce4-power-manager's general-notification=false silences those popups; low/critical warnings stay.
- libinput leaves tap-to-click off. An xorg.conf.d InputClass is the stable fix (any touchpad, login screen included); xfconf's pointers settings are tied to the device name.
- Debian 13 ships pkexec as its own package. Without it, XFCE Power Manager's brightness slider moves but does nothing (it runs the backlight helper through pkexec).
- `xfce4` pulls a polkit agent to satisfy a dependency; with --no-install-recommends apt picked ukui-polkit, which only autostarts on UKUI/MATE. Navi installs mate-polkit and autostarts it itself (dotfiles/autostart).
- The screen goes black from three separate timers: X's own blanking (600 s default, `xset q`), DPMS, and XFCE Power Manager's idle dimming. XFCE 4.20 has no blank-on-* setting; X config handles blanking.
- Proton VPN stores its login through python3-proton-keyring-linux, which needs a Secret Service (gnome-keyring). Without libpam-gnome-keyring the keyring stays locked and asks for its own password.
- rofi needs a double-click to run an entry by default; a single click only highlights it, and clicking away closes the menu. That made the power menu look broken. config.rasi sets single-click accept.
- XFCE settings (xfconf, panel, xinput, xset) need the running session, so they can't run from the text console on a fresh install. install.sh drops a one-shot autostart entry instead of asking for a second script run.
- whiptail prints checklist picks on stderr (it owns stdout for drawing): capture with `3>&1 1>&2 2>&3`. `--separate-output` gives one pick per line, unquoted.
- The code (VS Code) package adds its own copy of Microsoft's repo unless debconf says no (code/add-microsoft-repo). Two entries for one repo with different Signed-By keys make apt refuse to run.
- Vendor apt keys here are ASCII-armored; apt reads them as-is when saved with a .asc extension, so no gpg --dearmor step (and no gnupg dependency).
- Microsoft has no Teams app for Linux since 2022. teams-for-linux (Flathub) is a community wrapper of the web app.
- Dead internal mic on ASUS X515EA (also seen on LMDE): it isn't hardware or a missing package. The kernel's generic ASUS quirk sets codec pin 0x13 as the internal mic (`/sys/class/sound/hwC0D0/driver_pin_configs`), but the BIOS (`init_pin_configs`) puts the real analog mic on 0x1b. Recording gave exact zeros. The fix is a hda patch file loaded with `snd-hda-intel patch=` that resets 0x13 to unused, since user pin configs override driver ones. If the mic is still silent after a reboot, delete `/etc/modprobe.d/navi-asus-x515ea-mic.conf` and reboot to undo it. Test with `arecord -d 3 /tmp/t.wav && aplay /tmp/t.wav`.
- With the mic fixed, calls sounded echoey and repeating: PipeWire's default 100% input level maxed the codec's two boost stages (~66 dB), so room and speaker sound came back far too loud. `scripts/desktop.sh` sets the source to 40%, which drops the hardware boost to 0. Without pipewire-alsa, plain ALSA programs like arecord open the sound card directly and fail with "Device or resource busy" because PipeWire already has it.

## Credits
- Wallpaper `wallpapers/lain.png`: by patrika (https://alphacoders.com/users/profile/227699/patrika). Redistributed with attribution, as permitted by the author. Download link: https://wall.alphacoders.com/big.php?i=1371077
