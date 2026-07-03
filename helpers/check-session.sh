#!/usr/bin/env bash

set -u

echo "==> Sway session"
if [[ "${XDG_CURRENT_DESKTOP:-}" == "sway" ]]; then
    echo "OK: running inside Sway"
else
    echo "WARNING: current desktop is '${XDG_CURRENT_DESKTOP:-unknown}'"
fi

echo
echo "==> Audio"
if command -v wpctl >/dev/null 2>&1; then
    wpctl status || echo "WARNING: PipeWire/WirePlumber is not responding."
else
    echo "ERROR: wpctl was not found."
fi

echo
echo "==> Session processes"
for process in mako nm-applet blueman-applet lxqt-policykit-agent; do
    if pgrep -x "$process" >/dev/null 2>&1; then
        echo "OK: $process is running"
    else
        echo "WARNING: $process is not running"
    fi
done

echo
echo "==> User services"
systemctl --user --no-pager --full status \
    pipewire.service \
    pipewire-pulse.service \
    wireplumber.service \
    xdg-desktop-portal.service \
    2>/dev/null || true

echo
echo "==> Sending test notification"
notify-send "Sway check" "Session diagnostics completed."
