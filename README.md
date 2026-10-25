# Lost in Tape

Enoigralska 2D grozljiva ugankarska igra za GameJam BEST × ŠS FERI 2026. Na noč čarovnic Lea vstopi v preklet VHS-posnetek. Igralec upravlja predvajanje kasete: previjanje vrača hišo v preteklost, Lea pa ostane na mestu. Odmevi neuspehov postanejo namigi in del ugank.

## Dokumentacija

Dokumentacijo bo ekipa dodala naknadno. [Avtorji in viri assetov](game/CREDITS.md).

## Zagon iz projekta na Windows

1. Prenesite oziroma klonirajte repozitorij in odprite Godot 4.7.2, standardno različico brez .NET.
2. Uvozite `game/project.godot`. Trenutna igra je v `game/`, starejši projekt `game_v1/` ni glavna različica.
3. Počakajte na uvoz grafik in zvokov, nato pritisnite **F5**. Glavna scena je `game/rewind/main.tscn`.
4. Vključite zvok; piski in opozorila pomagajo pri ugankah.

## Kontrole

| Tipka | Dejanje |
| --- | --- |
| D ali desna puščica | PLAY / PAUSE |
| Drži A ali levo puščico | REWIND hiše |
| Shift + A ali leva puščica | Hitrejši REWIND |
| Drži F | FF po že videnem posnetku |
| E ali preslednica | GLITCH / TRACKING v pravem trenutku |
| E | Vstop v skrivno sobo oziroma predvajanje njene kasete |
| R | Ponovni poskus sobe |
| Preslednica v uvodu in zaključku | Naslednji kader |
| Esc v uvodu | Preskok uvoda |
| Esc na zadnjem zaslonu | Izhod iz igre |

Ukazi se odklepajo postopoma. Premor ne porablja kasete. V skrivni sobi D preklaplja hojo; preslednica preskoči skrivni video.

## Windows različica za oddajo

Samostojen Windows izvoz še ni priložen. Predvidena lokacija je `Build/LostInTape/LostInTape.exe`. Zraven morajo ostati pripadajoči `.pck`, če ni vgrajen v `.exe`, in vse druge datoteke, ki jih ustvari izvoz. Za izdelavo izvoza v Godotu namestite ustrezne izvozne predloge in uporabite Windows Desktop release izvoz.

Končni paket je treba preizkusiti na drugem Windows računalniku. Zagon iz urejevalnika ne nadomešča obvezne izvršne različice.

## Video in predstavitev

Video in predstavitev še nista priložena. Za oddajo je zahtevan 30-sekundni MP4 dejanskega igranja v pokončnem formatu 1080 × 1920 z imenom `Ekipa_LostInTape_Video.mp4`. Povezavo do videa dodajte sem, ko bo pripravljen. Predstavitev in video se oddajata tudi skupaj kot `Ekipa_LostInTape_Predstavitev_Video.zip` po navodilih organizatorjev.

## Viri in AI

Projekt vključuje AI-podprto kodo, besedila in grafiko ter zunanje assete. Podrobnosti, avtorji, licence in odprte postavke so v dokumentaciji ter `game/CREDITS.md`. Pri filmski sliki Billyja dovoljenje za javno distribucijo ni pridobljeno; za Jigsawov glas in dva VHS-posnetka je treba dopolniti izvor ter pogoje uporabe pred oddajo.
