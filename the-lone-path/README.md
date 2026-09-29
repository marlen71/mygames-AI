# THE LONE PATH

*Small steps. Big silence.*

A short atmospheric top‑down mystery game for the browser — a small interactive story, not a big RPG.
You wake up at night in an unknown forest with a flashlight and one clear goal: **find 5 old notes**
and piece together what happened here.

Built with **pure HTML5 Canvas + CSS + JavaScript**. No engine, no npm, no external assets —
every visual (trees, cabin, car, tent, fire, player, fog, rain, lighting) is drawn procedurally in code,
and the whole soundscape (wind, drone, birds, fire crackle) is generated with the Web Audio API.
The game therefore has **zero dependencies** and works offline.

Playtime: 10–20 minutes.

## Run it on Windows

Three options — any of them works:

1. **Double‑click `PLAY_on_Windows.bat`** — opens the game in your default browser.
2. **Double‑click `index.html`** — same thing, straight in a file tab.
3. *(optional, nicest)* run `SERVE_local_http.bat` — starts a tiny local web server at
   `http://localhost:8123` and opens the browser there (needs Python; useful if you want
   fullscreen/autoplay behavior to be exactly like a website).

Then press **START** in the menu.

> Recommended browser: Chrome / Edge / Firefox (anything modern). Keyboard required.

## Controls

| Key | Action |
|---|---|
| `WASD` / arrows | move |
| `F` | flashlight on/off |
| `E` | interact / read |
| `Esc` | menu |
| `M` | mute |

## The five mechanics (and nothing else)

1. **Movement** — smooth free walking on one small map.
2. **Flashlight** — a soft light cone + darkness overlay; no batteries, always works.
3. **Interaction** — `[E] READ` / `[E] EXAMINE` prompts on a handful of objects.
4. **Notes** — 5 collectible pages that tell the story; no inventory.
5. **Orientation** — a minimal round compass pointing to the next note (then to the CABIN).

No combat, no enemies, no crafting, no XP, no procedural generation. One hand-made map
(1600×1600), five zones: Start, Camp, Cabin, Wreck, Deep Forest — and a final clearing
where the story ends.

## Project structure

```
the-lone-path/
├── index.html            page + all UI overlays (menu, note panel, HUD, finale)
├── css/style.css         dark cinematic UI styling
├── js/utils.js           rng, math helpers
├── js/audio.js           procedural ambient audio (Web Audio)
├── js/assets.js          every sprite drawn in code + light/fog sprites + menu art
├── js/world.js           hand-made map: zones, props, notes, colliders, baked ground
├── js/game.js            loop: player, camera, lighting, interaction, states, finale
├── PLAY_on_Windows.bat   double-click to play (opens index.html)
└── SERVE_local_http.bat  optional local http server (needs Python)
```

## How the “pseudo‑3D” works

There is no 3D engine. The isometric feel comes from:
objects drawn as *base point + vertically extruded bodies*, soft elliptical ground shadows,
y‑sorting (the player can walk *behind* trees and get occluded), a single darkness layer with
the flashlight cone punched out of it, drifting fog and a vignette.
