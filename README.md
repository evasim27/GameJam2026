# Lost in Tape

Enoigralska 2D grozljiva ugankarska igra za GameJam BEST × ŠS FERI 2026. Na noč čarovnic Lea vstopi v preklet VHS-posnetek. Igralec upravlja predvajanje kasete: previjanje vrača hišo v preteklost, Lea pa ostane na mestu. Odmevi neuspehov postanejo namigi in del ugank.

## Struktura repozitorija

| Mapa | Vsebina |
| --- | --- |
| `README.md` | Ta opis |
| `Documentation/` | Dokumentacija igre (PDF) |
| `Build/` | Windows različica igre: `LostInTape.exe` (Git LFS) |
| `Source/game/` | Godot 4.7.2 projekt igre |
| `Source/assets/` | Izvorne grafike, prompti in manifesti, iz katerih so narejeni sprajti v igri |
| `Source/build.sh` | Skripta za izvoz Web, macOS in Windows različic |

## Dokumentacija

[Dokumentacija (PDF)](Documentation/Ženeva_LostInTape_Dokumentacija.pdf). [Avtorji in viri assetov](Source/game/CREDITS.md).

## Zagon iz projekta na Windows

1. Prenesite oziroma klonirajte repozitorij in odprite Godot 4.7.2, standardno različico brez .NET.
2. Uvozite `Source/game/project.godot`.
3. Počakajte na uvoz grafik in zvokov, nato pritisnite **F5**. Glavna scena je `Source/game/rewind/main.tscn`.
4. Vključite zvok; piski in opozorila pomagajo pri ugankah.

Igra se odpre v začetnem meniju. **PLAY** zažene uvod, **MUTE / UNMUTE** pa izklopi oziroma vklopi vso glasbo in zvočne učinke tudi med igro. Gumba lahko izberete z miško ali puščicama gor/dol in potrdite z Enter oziroma preslednico.

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

Izvršljiva različica je v [`Build/LostInTape.exe`](Build/LostInTape.exe). Prenesite jo in zaženite; podatki igre so vgrajeni v `.exe`, druge datoteke niso potrebne. Datoteka je shranjena z Git LFS (223 MB). Rezervni prenos: [LostInTape-windows.zip](https://github.com/evasim27/GameJam2026/releases/latest/download/LostInTape-windows.zip). Podrobnosti so v [`Build/README.md`](Build/README.md).

## Video in predstavitev

[Predstavitev (PPTX)](Ženeva_LostInTape_Predstavitev.pptx) · [Gameplay video (MP4)](Ženeva_LostInTape_Video.mp4)

## Viri in AI

Projekt vključuje AI-podprto kodo, besedila in grafiko ter zunanje assete. Podrobnosti, avtorji, licence in odprte postavke so v dokumentaciji ter `Source/game/CREDITS.md`.
