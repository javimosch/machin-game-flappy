# machin-game-flappy

A **Flappy-Bird-style** game as a real **native desktop app** — written in **[machin](https://github.com/javimosch/machin)** (MFL) and drawn with [raylib](https://www.raylib.com/) through machin's C FFI. Real PNG **sprites** on a real OpenGL window: tap **Space** (or click) to flap the bird up through the gaps in the scrolling pipes; one point per pipe, hit a pipe or the ground and it's over.

Part of [**awesome-machin**](https://github.com/javimosch/awesome-machin) — the machin ecosystem.

> **Agents:** [`SKILL.md`](SKILL.md) covers the build (incl. no-root raylib), the texture/FFI mapping, and the int/float gotcha this game hit.

```
   0
 ▓▓        ▓▓
 ▓▓        ▓▓
 ▓▓   🐤
              ▓▓
 ▓▓           ▓▓
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ← ground
```

## Why it exists

The machin north star is "build real things, let usage drive features." This is the **sprite/texture** dogfood for machin's C FFI — the GUI counterpart to the terminal [machin-game-snake](https://github.com/javimosch/machin-game-snake), and a sibling to [machin-game-2048](https://github.com/javimosch/machin-game-2048). It exercises a corner the earlier GUI demo didn't:

- **Textures as FFI struct handles.** `LoadTexture` returns a `Texture2D` (a by-value struct) **across** the FFI; the bird/pipes/ground/bg are real PNGs uploaded to the GPU.
- **Float-field by-value structs.** `DrawTextureRec` / `DrawTexturePro` take `Rectangle` and `Vector2` — structs with `f32` fields — plus an `f32` rotation. The bird is a 3-frame sprite sheet (a source `Rectangle` per frame) tilted by its velocity; the two pipes reuse one texture, the top one flipped via a **negative source height**.

That all worked on the existing FFI — but building the physics surfaced a genuine language gap that became **machin v0.43.0**: there was no `int`→`float` conversion, so `byte_at`-derived randomness and concrete-int coordinates couldn't enter float math. The new **`float()`** builtin fixes it. (See the gotcha in [`SKILL.md`](SKILL.md).)

## Build

Needs the `machin` compiler (**v0.43.0+**), a C compiler, **raylib**, and a display (X11/desktop). A GUI binary links the system graphics stack, so — unlike machin's headless tools — it is **not** a no-dependency binary.

```bash
./build.sh            # → ./machin-game-flappy
./machin-game-flappy  # run from the repo root so it finds assets/
```

`build.sh` uses a **system raylib** if installed (`sudo apt-get install libraylib-dev`, `brew install raylib`, …); otherwise it **vendors raylib's prebuilt static release** into `vendor/` automatically — no root required.

## Play

- **Space** / **left-click** — flap
- pass between pipes to score; hit a pipe or the ground to end
- **Space** again — restart · **Esc** — quit

## How it works

- **World in floats.** Bird `y`/velocity, pipe `x`, gap centers are all `float`; gravity `0.45`/frame, a flap sets velocity to `-7.5`.
- **Three recycled pipes.** Each scrolls left at a fixed speed; off the left edge it wraps to the right with a new random gap (`rand_bytes` → `float()`), un-scored.
- **Sprites.** `assets/` holds the bird sheet, pipe, ground, and background PNGs (committed). The bird animates over 3 frames and rotates with its velocity; the ground scrolls as two tiled copies.
- **Collision.** AABB of the bird box against each pipe's body and the ground.

See [`flappy.src`](flappy.src). `build.sh` runs `machin encode` to produce the canonical `flappy.mfl`, then `machin build`.

## License

MIT (art assets included under the same license)
