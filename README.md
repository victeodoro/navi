# Navi

## Manual pre-steps (fresh Debian 13 netinst, no desktop)

1. Log as root (`su -`), install git and sudo (`apt install sudo git`) and set your user as part as sudo group (`usermod -aG sudo <user>`). Logout and the changes should take place.
2. Clone this repo (`git clone git@github.com:victeodoro/navi.git`), then run `./bootstrap.sh`
3. Log into XFCE, then run `./xfce-settings.sh` from a terminal inside the desktop.

## Decisions
- Desktop: XFCE, minimal core with no goodies. Chose it over Cinnamon/Sway for being light and modular.
- Keyboard: pt-BR ABNT2, set in system/etc/default/keyboard
- VM: KVM with SPICE; guest tools in packages/vm.txt
- Layout: no desktop icons, no dock, one slim top bar (workspaces, windows, clock, tray, power).
- Launcher: rofi with a custom warm Gruvbox theme (dotfiles/rofi). Super opens it.
- File managers: Nemo (GUI, from Linux Mint, follows the GTK theme) + yazi (terminal, pinned GitHub release).

## Shortcuts
| Keys | Action |
|---|---|
| Super / Super+Space | App launcher (rofi) |
| Super+Tab | Window switcher (rofi) |
| Super+R | Run a command (rofi) |
| Super+Return | Terminal (Alacritty) |
| Super+E | File manager (Nemo) |
| Print / Shift+Print | Screenshot full screen / region |
