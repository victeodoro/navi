#!/usr/bin/env python3
"""Navi xfwm4 theme generator.

xfwm4 themes are a themerc file plus XPM images for every frame piece
(corners, edges, title bar, buttons). Drawing them by hand is tedious, so
this script paints them from a palette. Edit the colors below, then run:

    ./themes/gen-xfwm4.py      # writes dotfiles/navi-theme/.local/share/themes/Navi/xfwm4

XPM has no partial transparency: a pixel is a color or fully transparent
("None"). Transparent pixels cut the window shape, which is how the top
corners get rounded. Inner edges are anti-aliased by blending with the
title color, since that background is known.
"""
import math, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "../dotfiles/navi-theme/.local/share/themes/Navi/xfwm4")

TITLE_H = 30   # title bar height
BORDER  = 2    # frame thickness
RADIUS  = 9    # top corner radius
BTN_W   = 24   # button cell width
DOT_R   = 6    # button dot radius

STATES = {
    #           title bg   frame      text
    "active":   ("#282828", "#d65d0e", "#ebdbb2"),
    "inactive": ("#1d2021", "#3c3836", "#7c6f64"),
}
# Buttons: classic glyphs (minimize, maximize, close) in the palette
GLYPH        = "#a89984"   # normal, focused window
GLYPH_HOVER  = "#fe8019"   # minimize / maximize on hover
CLOSE_HOVER  = "#fb4934"   # close on hover
GLYPH_INACTIVE = "#665c54"
HOVER_BG     = "#3c3836"   # soft round pad behind a hovered button
GLYPH_SIZE   = 9           # px, square box the glyph fits in
STROKE       = 1.5


def rgb(h):  return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
def hexc(c): return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)
def mix(a, b, t): return hexc([x + (y - x) * t for x, y in zip(rgb(a), rgb(b))])
def shade(c, f): return mix(c, "#ffffff", f) if f > 0 else mix(c, "#000000", -f)


def write_xpm(name, rows):
    """rows: list of lists of color strings or None (transparent)."""
    h, w = len(rows), len(rows[0])
    colors = sorted({c for r in rows for c in r}, key=lambda c: (c is None, c or ""))
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#+-"
    cpp = 1 if len(colors) <= len(chars) else 2
    keys = {}
    for i, c in enumerate(colors):
        keys[c] = chars[i] if cpp == 1 else chars[i // len(chars)] + chars[i % len(chars)]
    lines = [f'"{w} {h} {len(colors)} {cpp}",']
    lines += [f'"{keys[c]} c {c or "None"}",' for c in colors]
    lines += ['"' + "".join(keys[c] for c in r) + '",' for r in rows]
    lines[-1] = lines[-1].rstrip(",")
    name = name.replace("-", "_")
    with open(os.path.join(OUT, name.replace("_", "-") + ".xpm"), "w") as f:
        f.write(f"/* XPM */\nstatic char * {name}_xpm[] = {{\n" + "\n".join(lines) + "\n};\n")


def solid(w, h, c): return [[c] * w for _ in range(h)]


def title_column(bg, fr, w=1):
    return [[fr] * w if y < BORDER else [bg] * w for y in range(TITLE_H)]


def corner(bg, fr, mirror):
    """Rounded top corner: transparent outside, frame ring, title bg inside."""
    w = RADIUS + 1
    rows = []
    for y in range(TITLE_H):
        row = []
        for x in range(w):
            px = x + 0.5
            py = y + 0.5
            if py < RADIUS:
                d = math.hypot(RADIUS - px, RADIUS - py) if px < RADIUS else RADIUS - py
                if d > RADIUS:
                    c = None
                elif d > RADIUS - BORDER:
                    c = fr
                elif d > RADIUS - BORDER - 1:          # soften inner edge
                    c = mix(bg, fr, d - (RADIUS - BORDER - 1))
                else:
                    c = bg
            else:
                c = fr if px < BORDER else bg
            row.append(c)
        rows.append(row[::-1] if mirror else row)
    return rows


def seg_dist(px, py, x1, y1, x2, y2):
    dx, dy = x2 - x1, y2 - y1
    t = max(0.0, min(1.0, ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (x1 + t * dx), py - (y1 + t * dy))


def glyph_segments(name, cx, cy):
    g = GLYPH_SIZE / 2
    if name == "hide":
        return [(cx - g, cy + g - 1, cx + g, cy + g - 1)]
    if name == "maximize":
        x0, y0, x1, y1 = cx - g, cy - g, cx + g, cy + g
        return [(x0, y0, x1, y0), (x1, y0, x1, y1), (x1, y1, x0, y1), (x0, y1, x0, y0)]
    if name == "maximize-toggled":   # two stacked squares = "restore"
        s, o = g - 1.5, 2
        a = [(cx - g, cy - g + o, cx - g + 2 * s, cy - g + o), (cx - g + 2 * s, cy - g + o, cx - g + 2 * s, cy + g),
             (cx - g + 2 * s, cy + g, cx - g, cy + g), (cx - g, cy + g, cx - g, cy - g + o)]
        b = [(cx - g + o, cy - g, cx + g, cy - g), (cx + g, cy - g, cx + g, cy + g - o), (cx - g + o, cy - g, cx - g + o, cy - g + o)]
        return a + b
    if name == "close":
        return [(cx - g, cy - g, cx + g, cy + g), (cx - g, cy + g, cx + g, cy - g)]
    raise ValueError(name)


def button(bg, fr, name, color, pad=None):
    """A title-bar cell with an anti-aliased glyph, optionally on a round pad."""
    cx, cy = BTN_W / 2, BORDER + (TITLE_H - BORDER) / 2
    rows = title_column(bg, fr, BTN_W)
    segs = glyph_segments(name, cx, cy)
    for y in range(BORDER, TITLE_H):
        for x in range(BTN_W):
            px, py = x + 0.5, y + 0.5
            c = bg
            if pad:
                cover = max(0.0, min(1.0, 10.5 - math.hypot(px - cx, py - cy)))
                c = mix(c, pad, cover)
            d = min(seg_dist(px, py, *sg) for sg in segs)
            cover = max(0.0, min(1.0, STROKE / 2 + 0.5 - d))
            rows[y][x] = mix(c, color, cover)
    return rows


def main():
    os.makedirs(OUT, exist_ok=True)
    for state, (bg, fr, text) in STATES.items():
        s = state
        for i in range(1, 6):
            write_xpm(f"title-{i}-{s}", title_column(bg, fr))
        write_xpm(f"top-left-{s}", corner(bg, fr, mirror=False))
        write_xpm(f"top-right-{s}", corner(bg, fr, mirror=True))
        write_xpm(f"left-{s}", solid(BORDER, 1, fr))
        write_xpm(f"right-{s}", solid(BORDER, 1, fr))
        write_xpm(f"bottom-{s}", solid(1, BORDER, fr))
        write_xpm(f"bottom-left-{s}", solid(BORDER, BORDER, fr))
        write_xpm(f"bottom-right-{s}", solid(BORDER, BORDER, fr))

        for name in ("hide", "maximize", "maximize-toggled", "close"):
            if state == "active":
                hover = CLOSE_HOVER if name == "close" else GLYPH_HOVER
                variants = {
                    "active":   (GLYPH, None),
                    "prelight": (hover, HOVER_BG),
                    "pressed":  (shade(hover, -0.2), HOVER_BG),
                }
            else:
                variants = {"inactive": (GLYPH_INACTIVE, None)}
            for v, (color, pad) in variants.items():
                write_xpm(f"{name}-{v}", button(bg, fr, name, color, pad))

    with open(os.path.join(OUT, "themerc"), "w") as f:
        f.write(f"""# Navi xfwm4 theme, generated by themes/gen-xfwm4.py. Edit the script, not this.
active_text_color={STATES['active'][2]}
inactive_text_color={STATES['inactive'][2]}
title_alignment=center
full_width_title=true
title_shadow_active=false
title_shadow_inactive=false
title_vertical_offset_active={BORDER // 2}
title_vertical_offset_inactive={BORDER // 2}
button_offset={RADIUS - 2}
button_spacing=0
maximized_offset=0
show_app_icon=false
""")
    print("wrote", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
