#!/usr/bin/env bash

set -euo pipefail

geometry="$(slurp)" || exit 0
grim -g "$geometry" - | wl-copy
