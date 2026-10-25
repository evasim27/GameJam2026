# Wall sconce

`wall-sconce-generated.png` is the original transparent image created with the built-in imagegen tool. The game uses `../../game/assets/rewind/cinematic/wall-sconce.png`, a 24x48 RGBA sprite displayed at half scale, matching the texel size of the Noble Interior furniture.

Preparation: crop the generated image to the bounds where alpha > 8, `(238, 365, 606, 1509)`, resize proportionally to 48 pixels high with nearest-neighbor sampling (15x48), and center on a transparent 24x48 canvas at `(4, 0)`. Preserve the generated alpha. The wall light and its flicker are rendered separately by `rewind/wall_decor.gd`.

Reference images:

- `game/assets/rewind/cinematic/candle.png`: wax, flame and brass materials.
- `game/assets/noble_interior/table_side.png`: pixel density and furniture shading.
- `game/assets/noble_interior/clock_tall.png`: aged ornament and brown outlines.

Generation prompt: [prompt.txt](prompt.txt).
