# THE LONE PATH

*Small steps. Big silence.*

A short atmospheric top‑down mystery game for the browser — a small interactive story, not a big RPG.
You wake up at night in an unknown forest with a lantern and one clear goal: **find 5 old notes**,
search the old house for what was hidden inside it, and piece together what happened here.

Built with **pure HTML5 Canvas + CSS + JavaScript**. No engine, no npm, no external assets —
every visual (trees, house, quarry crane, radio tower, lake, fires, player, fog, rain, lighting)
is drawn procedurally in code, and the whole soundscape (wind, drone, birds, fire crackle) is
generated with the Web Audio API. The game therefore has **zero dependencies** and works offline.

Playtime: 10–25 minutes.

## Languages

Click a flag in the menu or the pause screen — **EN / RU / UK** — and everything switches:
menu, HUD, chapters, objectives, the notes themselves. The choice is remembered between runs,
and a first-time visit follows your browser language.

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
| `E` | interact / read / take |
| `Esc` | menu, or close the note panel |
| `M` | mute |

## The five mechanics (and nothing else)

1. **Movement** — smooth free walking on one small map.
2. **Lantern** — a warm cone of light that starts right at the lamp in the player's hand,
   plus a small ambient pool at his feet; no batteries, always works.
3. **Interaction** — `[E] READ / EXAMINE / TAKE / ENTER` prompts on a handful of objects.
4. **Notes & things** — 5 collectible pages that tell the story; inside the house you must
   find 3 items and open the locked cabinet to get the page hidden there.
5. **Orientation** — a minimal round compass pointing at the current objective (chapter note,
   then the house, then the cabinet…), with the chapter and objective written in the HUD.

No combat, no enemies, no crafting, no XP, no procedural generation.

## One night, five chapters, five places

The story runs as five soft chapters on a single hand‑made 1600×1600 map plus one interior:

| Chapter | Place | What happens |
|---|---|---|
| I | **The Camp** | the first note by the cold fire pit |
| II | **The House** | enter the cabin; search the room; unlock the cabinet with the iron key; read the hidden journal |
| III | **The Abandoned Quarry** | the black water pit, the car on the rim, the crane bent over the edge |
| IV | **The Radio Tower** | a dead station's mast whose red beacon still blinks; a hut with a warm kettle |
| V | **The Foggy Lake** | the pier, the lamp lit this evening, the last note |

Collecting the five notes sends you back to the house. What waits there changes the ending —
*you were never alone.*

## Project structure

```
the-lone-path/
├── index.html            page + all UI overlays (menu, flags, note panel, HUD, finale)
├── css/style.css         dark cinematic UI styling
├── js/utils.js           rng, math helpers
├── js/audio.js           procedural ambient audio (Web Audio)
├── js/i18n.js            EN/RU/UK dictionary + flag switcher, localizes everything
├── js/assets.js          every sprite drawn in code + light/fog sprites + menu art
├── js/world.js           hand-made map: zones, water, props, notes, colliders, baked ground, interior
├── js/game.js            loop: two worlds, player, camera, lighting, chapters, interaction, finale
├── PLAY_on_Windows.bat   double-click to play (opens index.html)
└── SERVE_local_http.bat  optional local http server (needs Python)
```

## How the night lighting works

There is no 3D engine and no lightmaps. One full‑screen darkness layer (a translucent black
canvas) has holes punched out of it with `destination-out`: the lantern cone anchored at the
player's hand, a soft pool at his feet, round holes around every fire, the pier lamp and the
lit house window. Then a `lighter` pass adds the warm glow of lamps and fires, the blinking red
beacon of the tower, fireflies, dust drifting through the beam and pale pulses over uncollected
notes. The interior of the house reuses the exact same pipeline with its own lantern — only the
map (and the fear) changes.
