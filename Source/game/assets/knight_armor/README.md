# Oklep na stojalu

Temen pixel-art oklep na lesenem podstavku za Lost in Tape. Prosojno ozadje, pogled v levo, šest faz zamaha z mečem. Različica v2 ima bolj grobe piksle in manj drobnih detajlov po vzoru buče. Podstavki so pri izvozu poravnani. Vseh šest sličic ima enako sidro na dnu podstavka.

- `knight-armor-idle-v2.png`: mirujoča poza, 128 × 128 px.
- `knight-armor-swing-v2-6f.png`: vodoraven sprite sheet, 768 × 128 px, šest sličic po 128 × 128 px.
- `manifest.json`: sličice, sidro in časovne nastavitve.
- `res://rewind/objects/knight_armor.tscn`: pripravljen AnimatedSprite2D; položaj vozlišča je sredina dna podstavka.
- `res://rewind/objects/knight_armor_preview.tscn`: primerjava z osnovno bučo v istem merilu in s ponavljajočim zamahom; v Godotu odpri in zaženi s F6.

Animacije: `idle` (mirovanje), `swing` (en zamah), `display` (mirovanje in ponavljajoč zamah). Za en zamah pokliči `play("swing")`; po signalu `animation_finished` lahko pokličeš `play("idle")`. Za nasprotno smer uporabi `scale.x = -abs(scale.x)`, da se zrcali tudi sidro in ohrani merilo.

To je samostojen grafični asset; postavitev sob in pravila igre niso spremenjeni. Pri vključitvi v časovni trak igre izbiraj sličico iz `run.room_time`, tako kot pri ostalih TapeObject objektih, da zamah sledi previjanju.

Izdelano z vgrajenim orodjem `image_gen`. Izvirnik, generacijski prompt in animirani GIF so v `assets/knight_armor/` v korenu repozitorija. Produkcijski PNG ohranja prosojnost; GIF ima temno ozadje za predogled.

Preverjeno z Godot 4.5.1: uvoz assetov in zagon predogledne scene v headless načinu.

Merilo v2: vidna mirujoča poza s podstavkom je visoka 64 slikovnih pik v teksturi. Scena uporablja merilo 0.439814815, zato je oklep visok 28.14814815 igralnih pik, osnovna buča (`size = 1`) pa 14.07407407. Razmerje je 2 : 1. Dvignjen meč med zamahom sega nad to višino. Večja buča (`size = 1.5`) ni referenca tega razmerja.

Izvoz ponoviš z `python3 game/tools/export_knight_armor.py` (Pillow). Prejšnja PNG asseta sta ohranjena. Nova izvirna slika in prompt sta `assets/knight_armor/knight-armor-source-v2.png` in `assets/knight_armor/prompt-v2.md`. Primerjava je `assets/knight_armor/knight-armor-pumpkin-comparison-v2.gif`.
