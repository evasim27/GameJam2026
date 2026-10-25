# Lost in Tape

Enoigralska 2D grozljiva ugankarska igra za GameJam BEST × ŠS FERI 2026. Na noč čarovnic Lea vstopi v preklet VHS-posnetek. Igralec upravlja predvajanje kasete: previjanje vrača hišo v preteklost, Lea pa ostane na mestu. Odmevi neuspehov postanejo namigi in del ugank.

## Struktura repozitorija

| Mapa | Vsebina |
| --- | --- |
| `README.md` | Ta opis |
| `Build/` | Windows različica igre (prenos `LostInTape.exe`, glej `Build/README.md`) |
| `Source/game/` | Godot 4.7.2 projekt igre |
| `Source/assets/` | Izvorne grafike, prompti in manifesti, iz katerih so narejeni sprajti v igri |
| `Source/build.sh` | Skripta za izvoz Web, macOS in Windows različic |

## Dokumentacija

Dokumentacijo bo ekipa dodala naknadno. [Avtorji in viri assetov](Source/game/CREDITS.md).

## Zagon iz projekta na Windows

1. Prenesite oziroma klonirajte repozitorij in odprite Godot 4.7.2, standardno različico brez .NET.
2. Uvozite `Source/game/project.godot`.
3. Počakajte na uvoz grafik in zvokov, nato pritisnite **F5**. Glavna scena je `Source/game/rewind/main.tscn`.
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

Prenos: [LostInTape-windows.zip](https://github.com/evasim27/GameJam2026/releases/latest/download/LostInTape-windows.zip) (GitHub Release, ker `.exe` presega GitHubovo omejitev 100 MB na datoteko). ZIP razširite in zaženite `LostInTape.exe`; podatki igre so vgrajeni v `.exe`. Podrobnosti so v [`Build/README.md`](Build/README.md).

Končni paket je treba preizkusiti na drugem Windows računalniku.

## Video in predstavitev

Video in predstavitev še nista priložena. Za oddajo je zahtevan 30-sekundni MP4 dejanskega igranja v pokončnem formatu 1080 × 1920 z imenom `Ekipa_LostInTape_Video.mp4`. Povezavo do videa dodajte sem, ko bo pripravljen. Predstavitev in video se oddajata tudi skupaj kot `Ekipa_LostInTape_Predstavitev_Video.zip` po navodilih organizatorjev.

## Viri in AI

Projekt vključuje AI-podprto kodo, besedila in grafiko ter zunanje assete. Podrobnosti, avtorji, licence in odprte postavke so v dokumentaciji ter `Source/game/CREDITS.md`. Pri filmski sliki Billyja dovoljenje za javno distribucijo ni pridobljeno; za Jigsawov glas in dva VHS-posnetka je treba dopolniti izvor ter pogoje uporabe pred oddajo.
