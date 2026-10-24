# Skeleton sword animation

Tool: built-in `image_gen`, transparent background enabled.
References: approved knight v2 and in-game pumpkin.

+Use case: stylized-concept
Asset type: production six-frame pixel-art skeleton enemy sword attack sheet for Lost in Tape.
Reference image 1 is the approved knight animation: match its COARSE pixel density, side-view direction and six poses, but replace the armor with a bare animated skeleton. Reference image 2 is the pumpkin: match its simple broad pixel clusters, thick dark outline and limited shading. The new skeleton should be twice the pumpkin height, about 64 logical art pixels from skull top to soles versus pumpkin 32.
Output exactly SIX equally sized square cells in a 3-column 2-row grid on a true transparent background. One consistent skeleton facing LEFT, slight three-quarter side view. Large readable ivory skull with hollow dark eye sockets, jaw, simplified rib cage, spine, pelvis, jointed limbs. Muted warm ivory bones, two beige shadow tones and dark purplish outlines. No flesh, no gore, no glowing eyes. Holds a simple slightly worn steel sword with small brass crossguard. NO armor, NO helmet, NO clothes, NO cape, NO shield, NO wooden pedestal. Feet rest on a shared invisible baseline and stay planted across the swing.
Six poses reading order: 1 idle sword down-left; 2 anticipation sword lifted back; 3 sword raised overhead; 4 forceful downward-left slash with a restrained pale pixel motion arc; 5 low follow-through; 6 recovery toward idle.
Hard large square art pixels, deliberately low detail, no tiny texture scratches, no stipple, no dithering, no antialiasing, no smooth gradients. Same skull size, bones, sword, camera, scale and feet positions in all frames.
IMPORTANT exact grid: every 512x512 cell independently contains entire skeleton and full sword, with at least 25px transparent padding on ALL edges. Feet at 90% of each cell height, skeleton resting skull at around 25% height. Skeleton centered at 65% cell width, leaving space for sword at left. No part crosses a cell boundary. No floor, no background, no cast shadows, no labels, no borders, no text.
