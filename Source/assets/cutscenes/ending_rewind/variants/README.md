# Rewind — incomplete rescue variants

Nineteen new PNGs generated with built-in `image_gen` using the previous ending stills and the costume PNGs as references. All final prompts are in `prompts.json`. `preview.html` provides interactive selection of rescued children, including the switch to Menjava when all three are selected.

Seven outcomes are supported: nobody; Maja; Luka; Tina; Maja + Luka; Maja + Tina; Luka + Tina. Bits are Maja=1, Luka=2, Tina=4. Masks 0–6 select Rewind; mask 7 must select `ending_exchange/manifest.json` instead.

Each combination has its own manifest with rescued names, missing names, ordered relative image paths and adapted English narration. The six nonempty outcomes have five shots. Nobody rescued has four shots, without emerging hands or a reunion.

The exact rescued set appears in each living-room and doorway group shot. Close-ups can show one of those rescued children; the original two-child extraction is reused only for Maja + Luka. Reunion priority: Maja, then Luka, then Tina. Existing matching close-ups and the empty-room finale are reused without regeneration.

The original Rewind all-three group art is not selected by any incomplete-rescue variant; it opens the seven-frame Exchange ending instead. The game plays these sequences through `game/rewind/ending.gd`, with runtime copies under `game/assets/ending/cutscenes/`. Regenerate runtime data and image copies with `python3 game/tools/import_ending_cutscenes.py` after changing source manifests or art.
