# Final-room projector

Generated with built-in `image_gen`, transparent background enabled.
Style references: `assets/tiles/cinematic/last-room-preview.png` and
`game/assets/rewind/cinematic/crt-cabinet.png`.

Source: `assets/projector/projector-body-source.png`.
Game texture: `game/assets/rewind/cinematic/projector-body.png`.
The generated alpha is preserved. The room draws the alpha bounds at game scale
with nearest filtering. Reels are drawn separately by TapeEater, driven by room
time so Pause freezes them and Rewind reverses them. The first reel keeps the
blue interaction cue; both stop after the boss is defeated.

## Generation prompt

Use case: stylized-concept
Asset type: transparent game scenery sprite, vintage film/tape projector BODY for the final room of Lost in Tape.
Input images: image 1 is the actual final room, use its dark side-view pixel art furniture style and scale; image 2 is the existing CRT cabinet, match its chunky pixel clusters, aged dark metal, bronze/walnut highlights and restrained cool blue edge lighting. References only, do not reproduce either scene.
Primary request: one compact haunted vintage reel-to-reel projector body, front-facing side elevation for a side-scrolling game. Low squat charcoal black metal chassis, aged brown/bronze trim, small recessed controls, subtle green pilot light, ventilation slots, short cylindrical lens protruding to the RIGHT. Two tiny exposed spindle mounts along the upper edge, LEFT at 25 percent width and RIGHT at 53 percent width; NO circular reels attached, reels will be separate animated game elements. A little tangled brown magnetic tape near the lower left. Broad sturdy base with short feet. Silhouette about twice as wide as high, designed to be readable at 40 by 20 logical game pixels. Match the existing CRT's pixel art materials; crisp coarse square pixel clusters, limited palette, dark outline, warm highlights upper left. Isolated complete prop centered with transparent margin.
Constraints: true transparent background, no floor or scene, no cast shadow, no beam, no text, no labels, no watermark, no people, no TV, no cabinet, no reel disks. No smooth illustration, no isometric camera, no fine texture noise.

