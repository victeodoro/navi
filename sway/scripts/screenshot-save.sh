#!/usr/bin/env bash

set -euo pipefail

directory="$(xdg-user-dir PICTURES)"
mkdir -p "$directory"

geometry="$(slurp)" || exit 0

grim \
    -g "$geometry" \
    "$directory/screenshot-$(date +%Y%m%d-%H%M%S).png"
