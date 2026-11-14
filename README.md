# Navi

## Install (fresh Debian 13 netinst, no desktop)

1. As root (`su -`): `apt install sudo git`, then `usermod -aG sudo <user>`. Log out and back in.
2. As your user:
   ```sh
   git clone https://github.com/victeodoro/navi.git   # HTTPS: no SSH key needed yet
   cd navi && ./install.sh          # personal desktop
   ./install.sh --work              # or: work desktop, pick the work apps from a list
   ```
3. Reboot and log in. The desktop settings apply by themselves on that first login; when the notice shows, log out and back in once.

Re-running `./install.sh` (also from inside the desktop) is safe: installed apps are skipped and dotfiles reset to the repo versions. Personal steps that can't be scripted: install guide in NOTES.md.

## Apps
| Group | Apps | When |
|---|---|---|
| all | Firefox ESR, Chromium, Obsidian, Postman, omp, Burp Suite Community, nmap, aircrack-ng, micro, zathura, Ristretto, btop/bat/fzf/ripgrep/fd | always |
| personal | Spotify, Proton VPN, Proton Pass | without `--work` |
| work | Teams (teams-for-linux), Slack, LibreOffice, Cloudflare WARP, Heroku CLI, gcloud, Claude Code, VS Code | `--work`, each one picked in the menu |

Debian apps are listed in packages/apps.txt; everything else has a recipe in scripts/apps.sh (to add an app: write an `app_<id>` function and put the id in one of the lists at the top).

## Decisions
- Desktop: XFCE, minimal core with no goodies. Chose it over Cinnamon/Sway for being light and modular.
- Keyboard: pt-BR ABNT2, set in system/etc/default/keyboard
- VM: KVM with SPICE; guest tools in packages/vm.txt
- Layout: no desktop icons, no dock, one top bar made of three side-by-side panels (menu, workspaces, window list / clock / tray, power). Styled in dotfiles/gtk, which also themes menus and the calendar.
- Tiling: xfwm4's built-in. No animations: xfwm4 has none.
- Power menu: navi-power (rofi) replaces the XFCE logout dialog.
- Login screen: LightDM GTK greeter with the wallpaper and a Navi-Greeter theme (system/).
- Windows: Gruvbox-Orange-Light xfwm4 theme, same as the GTK theme.
- Browsers: Firefox ESR and Chromium (Debian's, security updates through apt).
- Launcher: rofi with a custom warm Gruvbox theme (dotfiles/rofi). Super opens it.
- Shell: zsh (Kali's default too) with autosuggestions + syntax highlighting, starship prompt, fastfetch banner. Terminal: Alacritty only (xfce4-terminal removed).
- File managers: Nemo (GUI, from Linux Mint, follows the GTK theme) + yazi (terminal, pinned GitHub release).
- Hardware panels: Blueman (Bluetooth), XFCE Power Manager (battery, brightness).
- App sources, in order of preference: Debian apt > the vendor's signed apt repo (WARP, gcloud, VS Code, Proton VPN) > Flathub (Spotify, Teams, Slack, Obsidian, Postman) > the vendor's installer (Proton Pass, Heroku, Claude Code, omp, Burp). Self-updating apps install per-user so their updater can write to its own folder.
- Install scripts: install.sh is the entry point; it runs scripts/system.sh (packages, dotfiles, themes, system files), scripts/apps.sh (apps) and scripts/desktop.sh (XFCE settings; needs the session, so on a fresh install it runs on the first login).
- Logins (Proton, Slack, VS Code...) live in gnome-keyring, unlocked at login.
- Icons: Colloid, plain "Colloid-Orange-Gruvbox" variant (light app icons, light tray icons for the dark bar). Only the menu and power buttons are custom SVGs (icons/).
- Touchpad: tap to click, set for every touchpad in system/etc/X11/xorg.conf.d.
- Screen: never blanks, dims or turns off by itself. Lock: only on demand (Super+L or the power menu), via light-locker, which shows the login screen.
- Packages: packages/system.txt (below the desktop), desktop.txt (XFCE and its tools), apps.txt (Debian apps for every desktop), vm.txt (only inside a VM).
- Dotfiles: copied into $HOME by install.sh, not linked, so apps never write into the repo.

## Shortcuts
| Keys | Action |
|---|---|
| Super (tap) / Super+Space | App launcher (rofi); press again to close |
| Super+Tab | Window switcher (rofi) |
| Super+R | Run a command (rofi) |
| Super+L | Lock the screen |
| Super+Return | Terminal (Alacritty) |
| Super+E | File manager (Nemo) |
| Super+←/→/↑/↓ | Tile to left/right/top/bottom half (xfwm4) |
| Super+Shift+←/→ · Super+Ctrl+←/→ | Tile to top / bottom corners |
| Super+1…4 | Go to workspace 1…4 |
| Alt+F4 / Alt+F10 / Alt+F9 | Close / maximize / minimize |
| Print · Shift+Print · Alt+Print | Screenshot screen · region · window; the dialog defaults to clipboard, press Enter |
| Ctrl+Alt+Delete | Power menu |
