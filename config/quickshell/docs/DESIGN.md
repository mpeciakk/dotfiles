# Wyspa — specyfikacja designu shella (Quickshell + niri)

Źródło prawdy dla implementacji. Prototypy HTML w `prototypes/` są referencją wizualną i
czasową (wartości liczbowe w nich są dokładne), ale nie uruchomią się poza edytorem — czytaj je jako kod.

## 1. Koncepcja

Jeden dynamiczny kontener („wyspa”) wtopiony w górną krawędź monitora. Wszystkie moduły
(launcher, panel, powiadomienia, OSD, media, menu zasilania, blokada) to **stany tej samej wyspy**,
między którymi kształt płynnie morfuje. Brak klasycznego paska.

## 2. Ustalone decyzje

- Kierunek: dynamiczna wyspa (wariant D).
- Ruch: płynny, `cubic-bezier(0.32, 0.72, 0, 1)`, 460 ms.
- Materiał: szkło (półprzezroczyste tło + blur). **Wszystkie kolory konfigurowalne** (plik konfiguracyjny).
- Kotwica: wtopiona w górną krawędź (płaska góra, zaokrąglony dół, odwrócone narożniki „uszy” r=16).
- Okno pełnoekranowe na danym monitorze → wyspa zwija się do kreski 56×5 i nie rezerwuje miejsca.
- Opcjonalnie: skrót chowający wyspę (toggle tego samego trybu „kreska”).
- Ekran blokady, menu zasilania, stos powiadomień — zaakceptowane jak w prototypach.

### Decyzje wdrożeniowe (2026-10-10)

| # | Decyzja |
|---|---|
| W1 | Blur przez `ext-background-effect`: `BackgroundEffect.blurRegion` (Quickshell 0.3.2) = kształt wyspy z uszami; siła blura globalna w niri (`blur { passes offset }`), `layer-rule` dla przestrzeni nazw wyspy z `xray false`. Fallback (`glass: false` w configu): tło z alfą 0,78 bez blura. |
| W2 | Cień `0 18 60` rysuje QML (`MultiEffect` pod kształtem) — cień z `layer-rule` niri jest prostokątem powierzchni. |
| W3 | Powierzchnia wyspy pełnoekranowa (`ExclusionMode.Ignore`, maska = kształt; w stanach modalnych pełna — scrim i „klik poza”). Exclusive zone 36/0 trzyma osobny pusty `Strut` przy górnej krawędzi. Blok `struts` w `config/niri/layout.kdl` usunięty (kompensował stary `Border`). |
| W4 | Pełny ekran: `ToplevelManager` (`fullscreen` + `screens`), zawężony do aktywnego obszaru niri danego monitora. |
| W5 | Font UI i mono konfigurowalne; domyślnie oba `JetBrainsMono Nerd Font` (Geist niezainstalowany). |
| W6 | Ikony: SVG z Lucide w `assets/icons/`, barwione kolorem z Theme. |
| W7 | Nadpisania tokenów: klucz `island` w `~/.config/dotfiles/config.json` (per host), hot-reload przez `FileView`. |
| W8 | Poza zakresem na razie: przełączniki Ciepłe światło i Nagrywanie (panel ma DND i Zasilanie), tryb `/` pliki. Launcher: aplikacje, `=` kalkulator (JS), `>` polecenie, `@` okna, menu VPN i schowka. |
| W9 | Bindy niri dopiero na końcu; do tego czasu stany wywołuje `qs ipc call island <stan>`. Kolizje `Mod+Shift+E` (zrzut) i `Mod+M` (makro) rozstrzygamy wtedy. |
| W10 | Brak backlightu / NetworkManagera / bluetootha (np. `pc`) → suwak i OSD jasności, kafle Wi‑Fi/BT ukryte. |

Otwarte: tray (może wróci na końcu).

## 3. Tokeny (domyślne wartości; wszystko ma być nadpisywalne z configu)

| Token | Wartość |
|---|---|
| `island.bg` | `rgba(16,14,26,0.62)` + blur 24 px, saturate 1.5 |
| `island.ring` | inset 1 px `rgba(255,255,255,0.07)` |
| `island.shadow` | `0 18 60 rgba(10,6,20,0.5)` |
| `surface` (kafle w środku) | `#17161F` / karty `#1F1E2A` / hover `#26243A` |
| `fg` | `#ECEAF2` |
| `fg.muted` | `#A29DB3` |
| `fg.dim` | `#8B8699` |
| `track` | `#2C2A39` |
| `accent` | `#B9A7F5` (alternatywy: `#F1D6AE`, `#8FD3C1`, `#F2A7B8`) |
| `danger` | `#F2A7B8` |
| `onAccent` | `#121118` |
| Font UI | Geist 400/500/600 |
| Font mono | Geist Mono 400/500 (zegar w spoczynku, liczby, skróty) |
| Ikony | linia 1.6 px, siatka 24, zaokrąglone końce |
| Promień | `min(wysokość/2, 30)`; kafle 20, karty 16, przyciski okrągłe |

Uwaga: blur tła zależy od kompozytora — sprawdź, czy Twoja wersja niri wspiera blur dla layer-shell.
Jeśli nie, fallback: to samo tło z alfą ~0.78 bez blura.

## 4. Geometria stanów

Kotwica zawsze: górny środek aktywnego monitora, `top = 0`.

| Stan | Szer.×wys. | Promień dołu | Czas życia / wyzwalacz |
|---|---|---|---|
| `line` (pełny ekran / ukryta) | 56×5 | 3 | okno fullscreen lub skrót; hover na górnej krawędzi (strefa 400×28) → `rest` |
| `rest` | 200×36 (252×36 z licznikiem powiadomień) | 18 | zawsze |
| `osd` (głośność / jasność) | 300×44 | 22 | 1,6 s od ostatniej zmiany |
| `media` | 380×56 | 28 | hover / ⊞M |
| `toast` (powiadomienie) | 420×76 | 30 | 3,6 s; klik → `center` |
| `control` (panel) | 520×440 | 30 | ⊞A, klik w wyspę; Esc / klik poza |
| `launcher` | 680×356 | 30 | ⊞Spacja; Esc |
| `power` | 540×180 | 30 | ⊞⇧E; Esc / klik poza |
| `powerDone` | 340×56 | 28 | po akcji |
| `center` (powiadomienia) | 440×dyn. (max 620) | 30 | klik w licznik/toast, ⊞N |
| `lock` | 460×360, `top = 210`, wszystkie rogi 36 | 36 | `WlSessionLock` |

Priorytet przy kolizji: launcher › panel/power/center › toast › osd › media.
Exclusive zone: tylko wysokość `rest` (36) — rozwinięcia nakładają się na okna. Z przerwą niri 8 px okno zaczyna się na 44 px.
W trybie `line` exclusive zone = 0.

## 5. Ruch

- Kształt (szerokość, wysokość, promień, `top`): 460 ms, Bezier `0.32, 0.72, 0, 1`.
  Blokada/odblokowanie: 640 ms, ta sama krzywa.
- Stara treść — wyjście: opacity 120 ms ease, scale → 0.94 w 160 ms, blur → 6 px.
- Nowa treść — wejście: opacity 220 ms `0.2,0,0,1` z opóźnieniem 160 ms; scale 0.94→1 320 ms z opóźnieniem 120 ms; blur 6→0 px.
- Treść każdego stanu ma od początku **docelową szerokość** (nie reflowuje się w trakcie morfingu), wycentrowana, przycinana przez kształt (`clip: true`).
- Przerwanie animacji startuje z bieżącego rozmiaru (Behavior w QML robi to sam).
- Ograniczony ruch (opcja w configu): tylko crossfade 120 ms.

```qml
Behavior on implicitWidth {
  NumberAnimation { duration: Theme.morphMs; easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.32,0.72, 0,1, 1,1] }
}
```

## 6. Moduły

**Spoczynek** — kropki obszarów niri (aktywny: pigułka 14×5 w kolorze accent, pozostałe 5×5 `#57536A`), zegar mono 13 px, animowany wskaźnik muzyki (3 słupki, gdy MPRIS gra), licznik powiadomień (pigułka accent 18% + dzwonek / księżyc przy DND). Klik → `control`.

**Launcher** — pole wyszukiwania (pigułka 48 px), chipy trybów z prefiksami: `=` kalkulator, `>` polecenie, `/` pliki, `@` okna; lista wyników (ikona 40 px, nazwa z podświetlonym dopasowaniem w accent, opis), zaznaczony wiersz tło `#1E1D28` + kbd `↵`; skróty `^1–9`; stopka z podpowiedziami klawiszy.

**Panel** — nagłówek: zegar 44 px + data; kafle Wi‑Fi i Bluetooth (okrągła ikona w accent); suwaki głośność i jasność; 4 okrągłe przełączniki (Skupienie/DND, Ciepłe światło, Nagrywanie, Zasilanie); mini odtwarzacz.

**OSD** — ikona, pasek (wypełnienie accent, przejście szerokości 260 ms), wartość mono.

**Powiadomienia**
- Przyjście → `toast` z najnowszym; seria podmienia treść i pokazuje chip `+N`; po 3,6 s → `rest` z licznikiem.
- DND: brak toastów, rośnie tylko licznik (ikona księżyca).
- `center`: nagłówek (liczba, przełącznik DND, „Wyczyść”), grupy wg aplikacji (najnowsza grupa na górze). Zwinięta grupa = karta + 1–2 warstwy „stosu” pod spodem (przesunięcie 7/14 px). „Pokaż N” / „Zwiń” rozwija — wysokość wyspy rośnie razem z treścią, powyżej 620 px przewijanie. Odrzucanie pojedyncze, grupą, wszystko.

**Menu zasilania** — 5 okrągłych przycisków 60 px: Zablokuj (L), Uśpij (S) działają od razu; Wyloguj (O), Restart (R), Wyłącz (P) wymagają **przytrzymania** (domyślnie 900 ms, konfigurowalne) — pierścień postępu wokół ikony, puszczenie wcześniej cofa pierścień (220 ms). Wyłącz w kolorze `danger`. Pulpit przygaszony `rgba(8,6,14,0.45)`. Po akcji → `powerDone` z etykietą („Wyłączanie…”). Klawiatura: strzałki + przytrzymanie Enter.

**Blokada** (`WlSessionLock`, PAM) — wyspa zjeżdża z krawędzi do karty 460×360 na środku; tapeta blur 22 px, saturate 1.2, brightness 0.78, scale 1.08 (700 ms); okna znikają. Karta: zegar 88 px, data, pole hasła (avatar z inicjałem, input, przycisk →), linia statusu, na dole bateria / Wi‑Fi / **tylko liczba** powiadomień (bez treści). Dodatkowo: mini odtwarzacz na dole ekranu, przyciski Uśpij/Wyłącz w prawym dolnym rogu. Błąd: shake 380 ms (±10/8/6/3 px) + obwódka `danger`. Sukces: odwrotny morfing do `rest`, okna wracają z opóźnieniem 240 ms.
Uwaga: lock surface to osobna powierzchnia — „zjazd” wyspy symulujemy animacją wejścia karty z pozycji/rozmiaru `rest`.

## 7. Architektura (propozycja)

```
shell.qml
Theme.qml            singleton: tokeny + wczytanie configu (JSON/TOML) z hot-reloadem
IslandState.qml      singleton: maszyna stanów, priorytety, timery, IPC (IpcHandler dla skrótów niri)
Island.qml           PanelWindow per ekran (Variants na Quickshell.screens), anchors.top,
                     exclusiveZone = (line ? 0 : 36), mask = Region { item: shape } (kliki przechodzą obok)
IslandShape.qml      Shape (QtQuick.Shapes) — jedna ścieżka z uszami, animowana szerokością/wysokością
states/Rest.qml, Launcher.qml, Control.qml, Osd.qml, Media.qml, Toast.qml,
       Center.qml, Power.qml, PowerDone.qml
Lock.qml             WlSessionLock + Quickshell.Services.Pam
services/Niri.qml    `niri msg -j event-stream` (obszary, okna, fullscreen)
```

Serwisy Quickshell: Pipewire (głośność), Mpris (media), UPower (bateria), Notifications (NotificationServer),
Bluetooth; Wi‑Fi i jasność przez `Process` (nmcli, brightnessctl), jeśli brak natywnych.
Skróty: binds w configu niri → `qs ipc call island <stan>`.

## 8. Prototypy

| Plik | Co pokazuje |
|---|---|
| `WyspaLive.dc.html` | morfing między stanami, materiał, kotwice (wtopiona/pływająca/chowana) |
| `WyspaRuch.dc.html` | choreografia, krzywe, tabela stanów |
| `Kotwica.dc.html` | porównanie kotwic i uzasadnienie |
| `LockLive.dc.html` | ekran blokady i przejścia |
| `PowerLive.dc.html` | menu zasilania z przytrzymaniem |
| `NotifLive.dc.html` | toasty, licznik, centrum, grupowanie, DND |

Logika (timery, rozmiary, krzywe) jest w bloku `<script type="text/x-dc">` na końcu każdego pliku.
