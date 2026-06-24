---
name: machin-game-demo-flappy
description: Build, run, and modify machin-game-demo-flappy — a Flappy-Bird-style native raylib desktop game in machin (MFL). Use when working on this repo, or as a worked example of textures/sprites over the C FFI (Texture2D handles, f32-field Rectangle/Vector2 structs, sprite sheets, rotation) and machin's int/float conversion rules.
---

# machin-game-demo-flappy

A Flappy-Bird-style game as a native raylib desktop window, written in [machin](https://github.com/javimosch/machin) (MFL). It is the reference example for **textures/sprites** in machin (the FFI counterpart to [machin-game-demo-2048](https://github.com/javimosch/machin-game-demo-2048), which used only shapes + text).

> The shared game-dev setup, build-and-verify workflow, and the cross-cutting caveats/gotchas (esp. the `int`/`float` rule this game drove `float()` to fix) live in the canonical **[machin-gamedev skill](https://github.com/javimosch/machin/blob/main/skills/machin-gamedev/SKILL.md)**. This file is flappy's specifics.

## Build & run

```bash
./build.sh                 # machin encode flappy.src -> flappy.mfl, then machin build -> ./machin-game-demo-flappy
./machin-game-demo-flappy       # run from the repo root so assets/ resolves
```

Needs `machin` **v0.43.0+** (uses `float()`), a C compiler, **raylib**, and a display.

- **System raylib** (`apt-get install libraylib-dev`, `brew install raylib`): detected via `pkg-config`/headers, built directly.
- **No root:** `build.sh` downloads raylib's prebuilt **static** release into `vendor/` and injects `cflags`/`:libraylib.a` into a throwaway `.mfl`; the committed `flappy.src` stays system-style.

Controls: Space / left-click to flap, Space to restart, Esc to quit.

## Textures over the FFI

The whole graphics surface is the `extern "raylib" { … }` block; everything else is pure MFL. Beyond 2048's scalars + `Color`, this game drives:

| MFL | raylib C | FFI feature |
|-----|----------|-------------|
| `cstruct Texture2D { id u32 width i32 height i32 mipmaps i32 format i32 }` | `Texture2D` (all-int handle) | a by-value **struct returned** from `LoadTexture` |
| `cstruct Rectangle { x f32 y f32 width f32 height f32 }`, `Vector2 { x f32 y f32 }` | same | by-value structs with **f32 fields** |
| `fn DrawTextureRec(Texture2D, Rectangle, Vector2, Color)` | same | struct args by value |
| `fn DrawTexturePro(Texture2D, Rectangle, Rectangle, Vector2, f32, Color)` | same | + an **f32 rotation** scalar |

Tricks worth copying:

- **Sprite sheet:** the bird is one 144×48 PNG of three 48×48 frames; the source `Rectangle{float(frame*48), 0, 48, 48}` selects the frame, `DrawTexturePro` rotates it around its center (`origin = Vector2{24,24}`) by an angle derived from velocity.
- **Flip with a negative source height:** the top and bottom pipes share one texture; the top one is drawn with `Rectangle{0,0,88,-600}` (negative height ⇒ vertical flip) so its cap faces down. No second asset.
- **Tiled scroll:** the ground is drawn as two copies at `gx` and `gx+WIN_W`, with `gx = -(scroll % WIN_W)`.

## The int/float gotcha (important)

MFL has **no implicit `int`→`float`**. A flexible numeric *literal* (`48`, `560`) promotes against a float, but a **concrete** int does **not** — and that's a hard `int vs float` compile error. Concrete ints come from: a function return (even `func BIRD_X() { n = 110 }`), `byte_at`, `len`, a typed parameter, an `int`-slice element, and they also can't go straight into an `f32`/`f64` `cstruct` field.

Fixes used here (all need machin v0.43.0+ `float()`):
- World-coordinate constants return **floats** (`GROUND_Y() { n = 560.0 }`) so they mix with `bird_y`.
- `rnd_gap` wraps its `byte_at` math: `160.0 + float((byte_at(r,0) << 8 | byte_at(r,1)) % 260)`.
- A concrete int into an `f32` field is wrapped: `Rectangle{float(frame*48), 0, 48, 48}`.
- Loop indices stay pure `int`: `init_pipes` uses a float accumulator (`x = x + SPACING()`), never `i * SPACING()` (which would drag the index to float).
- Going the other way for an FFI `i32` arg: `int(GROUND_Y())`.

Rule of thumb: keep a value in one numeric world; cross with `float(x)` / `int(x)` explicitly.

## Modifying

- **Difficulty:** `GAP_H` (gap half-height), `SPACING` (pipe distance), `SPEED` (scroll), and the `0.45` gravity / `-7.5` flap in `main`.
- **Art:** replace the PNGs in `assets/` (keep the bird sheet 3×48px frames, or adjust `frame*48` and the frame count).
- **Window:** `WIN_W`/`WIN_H` (stay int — they feed `InitWindow`/UI).
- After any edit to `flappy.src`, re-run `./build.sh` (never hand-edit `flappy.mfl` — it is generated).
