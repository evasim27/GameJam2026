# Okostnjak z mečem

Okostnjak za Lost in Tape z grobimi piksli, temnimi obrobami in preprostim senčenjem po vzoru buče ter potrjenega oklepa v2. Prosojno ozadje, pogled v levo, šest faz zamaha z mečem. Noge so poravnane na skupno sidro; brez podstavka.

- `skeleton-idle.png`: mirujoča poza, 128 × 128 px.
- `skeleton-swing-6f.png`: šest sličic po 128 × 128 px, vodoraven trak 768 × 128 px.
- `manifest.json`: sidro, časovne nastavitve in merilo.
- `res://rewind/objects/skeleton.tscn`: AnimatedSprite2D z animacijami `idle`, `swing` (en zamah) in `display` (ponavljajoč zamah z vmesnim mirovanjem).
- `res://rewind/objects/skeleton_preview.tscn`: primerjava z osnovno bučo; odpri v Godotu in zaženi s F6.

Vidna mirujoča poza je visoka 64 pik v teksturi. Merilo scene je 0.439814815: okostnjak je visok 28.14814815 igralnih pik, osnovna buča (`size = 1`) pa 14.07407407. Razmerje je 2 : 1, enako kot pri oklepu v2. Dvignjen meč med zamahom sega nad to višino.

Položaj vozlišča je sredina med stopali na tleh. Za en zamah pokliči `play("swing")`, nato po signalu `animation_finished` po potrebi `play("idle")`. Za nasprotno smer nastavi `scale.x = -abs(scale.x)`. Pri vključitvi v sistem previjanja izbiraj sličico iz `run.room_time`, tako kot pri drugih TapeObject objektih.

Asset je pripravljen za uporabo; postavitev sob in pravila igre niso spremenjeni.

Izdelano z vgrajenim `image_gen`. Izvirnik, prompt in GIF primerjava so v `assets/skeleton/` v korenu repozitorija. Izvoz ponoviš z `python3 game/tools/export_skeleton.py` (Pillow). Produkcijski PNG ohranja alpha prosojnost; GIF uporablja temno ozadje.

Preverjeno: vseh šest sličic ima prosojnost, neobrezano vsebino in skupno višino tal. Razmerje višine mirujoče poze je 2 : 1 glede na osnovno bučo. Uvoz in zagon primerjalne scene sta uspešna v Godotu 4.5.1 v headless načinu.
