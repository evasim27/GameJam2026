# New ending cutscenes

Two five-frame source-art sequences generated with the built-in `image_gen` tool.
The opening cutscenes and the three supplied costume PNGs were used as visual references.

- `ending_rewind/variants/`: all seven incomplete-rescue outcomes (0, 1 or 2 rescued children), with exact cast variants and adapted narration. Start at `variants/index.json`.
- `ending_rewind/`: the original storyboard and shared matching close-ups; the original all-three group frames are reference artwork only.
- `ending_exchange/`: the children leave, the lone protagonist, the view from inside the CRT, a palm on the glass, the ejected cassette.
- `ending_preview.html`: interactive preview of both sequences.

Each folder contains a `manifest.json` with ordered frames and the supplied English narration. Narration is deliberately separate from the image. Diegetic text (`REWIND`, `DO NOT PLAY`) is part of the artwork.

## Continuity

The protagonist retains the opening's green Shrek hood, cream tunic, brown vest and trousers. Luka wears Indiana Jones, Maja wears Simba, and Tina wears Jack Sparrow, following `assets/costumes/`. The children remain young; the garments have worn and faded surfaces. Dates follow the supplied caption and existing game data: Maja 1989, Luka 1994, Tina 2003.

The living room retains the floral wallpaper, wooden wainscot, wingback chair with lace cloth, coffee table, rug, CRT cabinet and VHS shelf. The two perspective-reversal frames look outward from inside the CRT through a blue glass rim and scanlines.

## Integration notes

The new endings are connected in `game/rewind/ending.gd`. Playable images are copied into `game/assets/ending/cutscenes/`; `game/rewind/ending_sequences.gd` contains the generated sequence data. To sync source art and captions again, run `python3 game/tools/import_ending_cutscenes.py` and let Godot import the textures.

The Rewind variants cover masks 0–6 (Maja=1, Luka=2, Tina=4). Each variant manifest lists rescued and missing names and ordered relative frame paths. Mask 7 selects Menjava instead. Both the game and the preview use this selection. The game derives the mask from the actual rescued memory names, not just their count.

Narration wraps to the 320×180 cutscene view and each shot allows enough time to finish typing. Any key advances, Escape opens the persistent result screen, and R on that screen restarts the game. The previous bedroom scenes, candy overlays and failure ghosts are no longer part of the ending.

Nineteen additional PNGs provide individual rescues, exact living-room and doorway casts, Luka and Tina reunion alternatives, and the no-rescue variant. Shared close-ups and the empty-room finale are reused. Reunion priority is Maja if rescued, otherwise Luka, otherwise Tina. With nobody rescued there is no extraction or reunion; that sequence has four shots.

The new name on the final cassette is provisionally `ALEX`; no canonical protagonist name was supplied.
