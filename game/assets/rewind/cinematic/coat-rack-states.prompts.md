# Foyer coat rack

Edited with the built-in `image_gen` tool. Output: `coat-rack-states.png`.
The 1536 × 1024 atlas contains two 768 × 1024 cells. The first shows Indiana Jones,
Simba (The Lion King), and Jack Sparrow (Pirates of the Caribbean), with the fourth
hook empty. The second adds Shrek. `foyer.gd` selects it when `total_fails >= 2`.

## Prompt

Use case: precise-object-edit. Asset type: two-state sprite atlas for the Godot pixel-art haunted-house game Lost in Tape.
Edit the reference atlas image. Keep the EXACT 1536x1024 canvas, two equal 768x1024 side-by-side cells, identical wooden coat-rack geometry, pixel-art rendering, warm lighting, aligned rack posts, base and hooks, and existing background and alpha. The left rack is the initial state and the right rack is the state after the second death. Change only the hanging costumes and remove the old wizard boots.
On BOTH racks, from left to right, show these THREE EMPTY CHILD-SIZED HALLOWEEN COSTUMES hung on the first three hooks:
1. Indiana Jones: recognizable brown fedora hanging above a brown leather jacket and tan adventure shirt, coiled whip on belt. No wearer.
2. The Lion King / Simba: golden lion onesie costume with a fluffy russet mane hood, round lion ears, cream belly and a tail hanging down. Empty hood, no actual animal.
3. Pirates of the Caribbean / Jack Sparrow: pirate tricorn hat, red bandanna with dangling braids, faded dark long pirate coat over an ivory shirt, sash and belt. Empty garment, no person.
Keep every costume clearly recognizable at tiny game scale using bold silhouettes. Fit the first three outfits into the first three quarters of the rack, reserving fourth hook at far right.
LEFT cell: fourth hook must be visibly EMPTY.
RIGHT cell: EXACTLY the same rack and the same first three outfits, plus an EMPTY SHREK COSTUME on fourth hook: bright moss-green ogre hood with two recognizable tubular ogre ears, cream tunic, short brown textured vest, brown belt and trousers. No actual head or wearer. The Shrek outfit must be recognizable and green.
Keep all costumes above the base, no labels, text, frames or additional props. Maintain identical positions and appearance of shared objects between both cells; only the extra Shrek outfit differs.
