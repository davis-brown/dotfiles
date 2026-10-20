#!/usr/bin/env python3
"""Generate the Tokyo Night skyline wallpaper as SVG on stdout.

The seed is fixed, so the output is reproducible. To regenerate the PNG:

    python3 generate_wallpaper.py |
        rsvg-convert -o .config/omarchy/backgrounds/tokyo-night/davis-skyline.png
"""
import random

W, H = 3840, 2400
rnd = random.Random(1987)

P = {
    "bg0": "#0b0b11", "bg1": "#13141c", "bg2": "#1a1b26", "bg3": "#24283b",
    "fg": "#c0caf5", "muted": "#414868", "comment": "#565f89",
    "blue": "#7aa2f7", "cyan": "#7dcfff", "magenta": "#bb9af7",
    "yellow": "#e0af68", "red": "#f7768e", "orange": "#ff9e64",
}

out = []
add = out.append
add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add(f'''<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="{P['bg0']}"/>
  <stop offset="0.45" stop-color="{P['bg1']}"/>
  <stop offset="0.72" stop-color="#1f2335"/>
  <stop offset="0.80" stop-color="#2a2e4a"/>
</linearGradient>
<radialGradient id="horizon" cx="0.5" cy="0.8" r="0.6" fx="0.5" fy="0.8">
  <stop offset="0" stop-color="{P['magenta']}" stop-opacity="0.30"/>
  <stop offset="0.35" stop-color="{P['blue']}" stop-opacity="0.12"/>
  <stop offset="1" stop-color="{P['blue']}" stop-opacity="0"/>
</radialGradient>
<radialGradient id="moonglow" cx="0.5" cy="0.5" r="0.5">
  <stop offset="0" stop-color="{P['blue']}" stop-opacity="0.35"/>
  <stop offset="0.4" stop-color="{P['blue']}" stop-opacity="0.10"/>
  <stop offset="1" stop-color="{P['blue']}" stop-opacity="0"/>
</radialGradient>
<linearGradient id="moon" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#e3e8ff"/>
  <stop offset="1" stop-color="{P['fg']}"/>
</linearGradient>
<linearGradient id="water" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="{P['bg1']}"/>
  <stop offset="1" stop-color="{P['bg0']}"/>
</linearGradient>
<linearGradient id="haze" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="{P['magenta']}" stop-opacity="0"/>
  <stop offset="1" stop-color="{P['magenta']}" stop-opacity="0.10"/>
</linearGradient>
</defs>''')

horizon = int(H * 0.80)
add(f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
add(f'<rect width="{W}" height="{H}" fill="url(#horizon)"/>')

# Stars, thinning toward the horizon
for _ in range(420):
    x = rnd.uniform(0, W)
    y = rnd.uniform(0, horizon) ** 1.25 / horizon ** 0.25
    r = rnd.choice([1.2, 1.5, 1.8, 2.2, 2.8, 3.4])
    c = rnd.choices([P["fg"], P["blue"], P["cyan"], P["magenta"]], [6, 2, 1, 1])[0]
    o = round(rnd.uniform(0.15, 0.8) * (1 - y / horizon * 0.8), 2)
    add(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{r}" fill="{c}" opacity="{o}"/>')

# Moon, off-center right third
mx, my, mr = int(W * 0.70), int(H * 0.26), 120
add(f'<circle cx="{mx}" cy="{my}" r="{mr * 6}" fill="url(#moonglow)"/>')
add(f'<mask id="crescent"><rect width="{W}" height="{H}" fill="white"/>'
    f'<circle cx="{mx + 44}" cy="{my - 22}" r="{mr * 0.92:.0f}" fill="black"/></mask>')
add(f'<circle cx="{mx}" cy="{my}" r="{mr}" fill="url(#moon)" mask="url(#crescent)"/>')


def skyline(base, hmin, hmax, wmin, wmax, color, lit, window_opacity, gap=(0, 14)):
    x = -rnd.randint(0, 60)
    buildings = []
    while x < W:
        w = rnd.randint(wmin, wmax)
        h = rnd.randint(hmin, hmax)
        # occasional tower
        if rnd.random() < 0.08:
            h = int(h * rnd.uniform(1.5, 2.0))
        buildings.append((x, w, h))
        x += w + rnd.randint(*gap)
    for x, w, h in buildings:
        top = base - h
        add(f'<rect x="{x}" y="{top}" width="{w}" height="{h + 2}" fill="{color}"/>')
        if rnd.random() < 0.25:  # antenna
            ax = x + w // 2
            add(f'<rect x="{ax - 2}" y="{top - 60}" width="4" height="60" fill="{color}"/>')
            if rnd.random() < 0.6:
                add(f'<circle cx="{ax}" cy="{top - 62}" r="5" fill="{P["red"]}" opacity="0.85"/>')
        if lit:
            for wy in range(top + 26, base - 20, 34):
                for wx in range(x + 14, x + w - 18, 26):
                    if rnd.random() < lit:
                        c = rnd.choices([P["yellow"], P["blue"], P["cyan"], P["magenta"], P["orange"]], [5, 3, 2, 2, 1])[0]
                        add(f'<rect x="{wx}" y="{wy}" width="10" height="14" fill="{c}" opacity="{window_opacity}"/>')


# Far skyline: low contrast, catches the horizon glow
skyline(horizon, 120, 330, 70, 180, "#232741", 0.05, 0.35)
add(f'<rect y="{horizon - 420}" width="{W}" height="420" fill="url(#haze)"/>')
# Near skyline: dark, more lit windows
skyline(horizon, 60, 260, 110, 260, P["bg1"], 0.11, 0.75, gap=(-8, 4))

# Water with soft reflections
add(f'<rect y="{horizon}" width="{W}" height="{H - horizon}" fill="url(#water)"/>')
add(f'<rect x="{mx - 70}" y="{horizon + 30}" width="140" height="6" fill="{P["fg"]}" opacity="0.25"/>')
for i in range(40):
    y = horizon + 20 + i * 11
    w = rnd.randint(30, 260) * (1 - i / 50)
    x = mx - w / 2 + rnd.uniform(-60, 60)
    add(f'<rect x="{x:.0f}" y="{y}" width="{w:.0f}" height="3" fill="{P["blue"]}" opacity="{0.22 * (1 - i / 40):.2f}"/>')
for _ in range(160):
    x = rnd.uniform(0, W)
    y = rnd.uniform(horizon + 10, H)
    c = rnd.choice([P["yellow"], P["blue"], P["magenta"], P["cyan"]])
    add(f'<rect x="{x:.0f}" y="{y:.0f}" width="{rnd.randint(8, 40)}" height="2" fill="{c}" opacity="{rnd.uniform(0.05, 0.18):.2f}"/>')

# Wordmark: a shell prompt, bottom left
font = "JetBrainsMono Nerd Font"
add(f'<text x="200" y="{H - 200}" font-family="{font}" font-size="64" letter-spacing="2">'
    f'<tspan fill="{P["blue"]}">~/davis</tspan>'
    f'<tspan fill="{P["magenta"]}" dx="28">❯</tspan>'
    f'<tspan fill="{P["comment"]}" dx="28">_</tspan></text>')

add("</svg>")
print("\n".join(out))
