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
- Kotwica: wtopiona w górną krawędź (płaska góra, zaokrąglony dół, odwrócone narożniki „uszy” r=16). Obrys biegnie po całej sylwetce razem z uszami (bez górnej krawędzi), więc wyspa wychodzi z krawędzi ekranu.
- Okno pełnoekranowe na danym monitorze → wyspa zwija się do kreski 56×5 i nie rezerwuje miejsca.
- Opcjonalnie: skrót chowający wyspę (toggle tego samego trybu „kreska”).
- Ekran blokady, menu zasilania, stos powiadomień — zaakceptowane jak w prototypach.

### Decyzje wdrożeniowe (2026-10-10)

| # | Decyzja |
|---|---|
| W1 | Blur przez `ext-background-effect`: `BackgroundEffect.blurRegion` (Quickshell 0.3.2) = kształt wyspy z uszami; siła blura i saturacja globalnie w niri (`blur { passes 3; offset 5; saturation 2.0 }`), `layer-rule` dla przestrzeni nazw `wyspa` tylko z `xray false` (bez `blur true` i bez `saturation`: w regule warstwy działałyby na całej pełnoekranowej powierzchni, gdy powłoka nie ustawia regionu — w trybie kreski nad grą podbijały saturację całego ekranu; naprawione 2026-10-11). Poziomy szkła zmieniają w locie tylko tło i kafle. Fallback (`glass: false` w configu): tło z alfą 0,78 bez blura. |
| W2 | Cień rysuje QML (`MultiEffect` pod kształtem) — cień z `layer-rule` niri jest prostokątem powierzchni. Pełny (ciemny `0 12 36` @38%, jasny `0 10 30` neutralny @16% — zmniejszone 2026-10-11, fioletowy cień jasnego motywu dawał poświatę) od wysokości 160 px (`sizes.shadowFullH`); niższa wyspa ma cień proporcjonalnie mniejszy i słabszy (spoczynek 36 px ≈ 0,23), zmienia się razem z morfingiem. |
| W3 | Powierzchnia wyspy pełnoekranowa (`ExclusionMode.Ignore`, maska = kształt; w stanach modalnych pełna — scrim i „klik poza”). Exclusive zone 36/0 trzyma osobny pusty `Strut` przy górnej krawędzi. Blok `struts` w `config/niri/layout.kdl` usunięty (kompensował stary `Border`). |
| W4 | Pełny ekran: `ToplevelManager` (`fullscreen` + `screens`), zawężony do aktywnego obszaru niri danego monitora. |
| W5 | Font UI i mono konfigurowalne; domyślnie oba `JetBrainsMono Nerd Font` (Geist niezainstalowany). |
| W6 | Ikony: ścieżki Lucide (dane `d` na siatce 24) w `lib/icons.js`, rysowane `Shape` + `PathSvg` kolorem z Theme. |
| W7 | Nadpisania tokenów: klucz `island` w `~/.config/dotfiles/config.json` (per host), hot-reload przez `FileView`. |
| W8 | Poza zakresem na razie: przełączniki Ciepłe światło i Nagrywanie (panel ma DND i Zasilanie), tryb `/` pliki. Launcher: aplikacje, `=` kalkulator (JS), `>` polecenie, `@` okna, menu VPN i schowka. |
| W9 | Bindy niri dopiero na końcu; do tego czasu stany wywołuje `qs ipc call island <stan>`. Kolizje `Mod+Shift+E` (zrzut) i `Mod+M` (makro) rozstrzygamy wtedy. |
| W10 | Brak backlightu / NetworkManagera / bluetootha (np. `pc`) → suwak i OSD jasności, kafle Wi‑Fi/BT ukryte. |
| W11 | Launcher uruchamia wszystko (aplikacje, `>` polecenie, polecenia menu, `wl-copy`) przez `uwsm app --` (`lib/launch.js`, `Apps.launch` / `Apps.run`): każdy proces dostaje własny scope w `app-graphical.slice`, więc restart `quickshell.service` (zabija całą swoją cgroupę) ich nie zabija; wcześniej `execDetached` zostawiał je w cgroupie powłoki (zmienione 2026-10-11). Aplikacja z poprawnym Desktop Entry ID idzie po ID (uwsm czyta `Path=` i `Terminal=`; terminal z `config/xdg-terminals.list` → `kitty.desktop` — bez tej listy uwsm brał pierwszy wpis TerminalEmulator, na `pc` `kitty-open.desktop`, który tylko otwiera pliki); ID spoza reguły uwsm (np. wpis Steama „Big Walk”) idzie po sparsowanej komendzie z `workingDirectory`. Sesja na `pc` i `laptop` jest pod uwsm. Maski w `~/dotfiles/applications/` (`Hidden=true`) muszą mieć `Type=Application` i `Name=`: bez nich Quickshell 0.3.2 ich nie czyta (wpis zostaje na liście), a uwsm odrzuca je przy starcie. |
| W12 | Blokada i odblokowanie grane na nakładce (2026-10-11): protokół `ext-session-lock` nie pokazuje okien, dopóki sesja jest zablokowana, a powierzchnia zasłonięta blokadą nie dostaje od niri nowych klatek — przy odblokowaniu niri pokazuje jej ostatnią klatkę. Dlatego obie drogi gra nakładka `LockOverlay.qml` w oknie wyspy każdego ekranu (już istnieje, pełnoekranowe, warstwa Overlay, poza maską wejścia; osobne okno potrzebowało ~170 ms do pierwszej klatki), sterowana fazą `IslandState.lockPhase` (`in` → `locked` → `back`, bez przejścia przez pustą fazę). Blokowanie: po żądaniu nakładka gra całe wejście nad oknami (tapeta wjeżdża i się rozmywa, wyspa gaśnie, a z jej miejsca rośnie karta, wchodzi treść i dodatki) i dopiero po nim (`lib/lock.js` `lockInMs`, ~0,82 s) zakłada się blokada, której powierzchnia od pierwszej klatki wygląda tak samo (bez własnej animacji) — sesja jest więc naprawdę zablokowana ~0,8 s po `Mod+L` (decyzja użytkownika: płynność). Od 2026-10-11 żądanie blokady najpierw zamyka wyspę, a w fazie `in` jej okno przechwytuje klawiaturę i kursor: wpisane wtedy znaki przepadają, a kliki nie trafiają w okna (wcześniej klawisze szły do okna, więc hasło wpisane zaraz po `Mod+L` mogło trafić do terminala). Nakładka zostaje pod blokadą; jej ostatnia klatka to wygląd blokady. Odblokowanie: blokada schodzi od razu po haśle (`lock.handoffMs` 0), nakładka gra powrót: treść i dodatki gasną, karta leci w górę i przy krawędzi zamienia zaokrąglone rogi na uszy wyspy (`dock()`, ten sam kształt co wyspa), tapeta zanika od 240 ms, od 420 ms karta przenika się z wyspą (`IslandState.lockHides`). Stan blokady dla wiązań to własne `lockOn` w `Lock.qml`: `WlSessionLock.locked` w Quickshell 0.3.2 nie zgłasza odblokowania (wiązania zostają na `true`). |
| W13 | Tło blokady to tapeta, lekko rozmyta (blur 12 / jasny 10, scale 1.08), bez zmiany saturacji i jasności (2026-10-11). Zrzut ekranu sprzed blokady (jak dawniej `swaylock -S`) był wdrożony i odrzucony tego samego dnia: dokładał ~0,1 s przed blokadą, a wyspa musiała znikać przed zrzutem (inaczej po odblokowaniu karta leciała na wyspę ze zrzutu). |
| W14 | Blokada przed uśpieniem (2026-10-11): odblokowany shell trzyma inhibitor logind `sleep` w trybie `delay` i nasłuchuje `PrepareForSleep`. Przed każdym uśpieniem (klapa, Uśpij, `systemctl suspend`) zakłada blokadę od razu, bo logind czeka najwyżej 5 s: wejście z W12 gra z zerowym czasem, a blokada idzie po pierwszej klatce nakładki, więc po wybudzeniu powrót gra jak w W12. Inhibitor puszcza, gdy blokada jest `secure`, a po wybudzeniu bierze go znowu. Zawsze włączone, bez klucza w configu. |
| W15 | Powiadomienia według protokołu (2026-10-11): podmiana (`replaces_id`) cicho aktualizuje kartę i przenosi ją na górę, bez nowego toastu i bez zmiany licznika. Karta znika, gdy aplikacja zamknie powiadomienie. Powiadomienie `transient` (np. zrzut ekranu z niri) pokazuje tylko toast, nie trafia do centrum ani do licznika. |
| W16 | Odrzucone hasło: linia statusu karty pokazuje komunikaty PAM z tej próby (np. pam_faillock: konto zablokowane, zostało N minut), a bez nich stały tekst. Licznik faillocka zostaje wspólny z `system-auth` (2026-10-11). |

Otwarte: tray (może wróci na końcu).

## 3. Tokeny (domyślne wartości; wszystko ma być nadpisywalne z configu)

| Token | Wartość |
|---|---|
| `island.bg` | `rgba(16,14,26,0.62)` + blur 24 px, saturate 1.5 |
| `island.ring` | obrys 1 px `rgba(255,255,255,0.07)` po sylwetce z uszami |
| `island.shadow` | `0 12 36 rgba(10,6,20,0.38)` (skalowany wysokością, zob. W2) |
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

### 3a. Jasny motyw — „przygaszony dzień” (w planie)

Ten sam układ, kształty i ruch; podmieniane wyłącznie tokeny. Szkło w kolorze mgły (nie biel), tekst grafitowy, akcent przyciemniony do kontrastu ≥ 4.5:1 (na kaflach i szkle „subtelne”; na gołym szkle „ciekłe” nad ciemną tapetą mniej, zob. 3b).

| Token | Ciemny | Jasny |
|---|---|---|
| `island.bg` | `#100E1A` @ 62% | `#E6E2EC` @ 80% (blur 24, saturate 1.3) |
| `island.ring` | obrys `rgba(255,255,255,0.07)` | obrys `rgba(255,255,255,0.3)` |
| `island.shadow` | `0 12 36 rgba(10,6,20,0.38)` | `0 10 30 rgba(20,16,30,0.16)` |
| `surface` (kafle) | `#17161F` | `#EFECF3` |
| `card` / zaznaczenie | `#1F1E2A` | `#F3F1F6` |
| `chip` / kbd | `#2C2A39` | `#DDD9E5` |
| `fg` | `#ECEAF2` | `#1E1B2A` |
| `fg.muted` | `#A29DB3` | `#48435C` (`fg.dim` `#5C5770`) |
| `track` | `#2C2A39` | `#CFCADA` (wypełnienie suwaka = `fg`) |
| `accent` | `#B9A7F5` | `#4E3A9E` |
| `onAccent` | `#121118` | `#FFFFFF` |
| `danger` | `#F2A7B8` | `#B4405E` |
| Blokada: tapeta | blur 12 | blur 10 |

Przełączanie: tryb ręczny / wg pory dnia (wschód–zachód) / wg jasności tapety. Zmiana = przenikanie kolorów 600 ms (`ColorAnimation`), bez morfingu kształtu. `Theme.qml` trzyma dwa zestawy i właściwość `mode`.

### 3b. Poziomy szkła (`Theme.glassLevel`, domyślnie „ciekłe” — do potwierdzenia)

| Poziom | Tło wyspy (ciemny / jasny) | Blur | Kafle wewnątrz |
|---|---|---|---|
| subtelne | `#100E1A`@62% / `#E6E2EC`@80% | 24, sat 1.5 | pełne (`#17161F` / `#EFECF3`) |
| mocne | `#100E1A`@40% / `#E8E4EE`@58% | 36, sat 1.8 | białe @6% / @42% |
| ciekłe | `#161224`@28% / `#EAE6F0`@44% | 44, sat 2.0, jasność 1.05 | białe @7% / @40% |

Bez połysku (usunięty 2026-10-11): gradient i wewnętrzna poświata rozjaśniały wyspę od krawędzi do środka i bieliły tekst w jasnym motywie, a dodatkowe obrysy dawały twardą jasną ramkę. Jedyną krawędzią szkła jest `island.ring` nad treścią, po całej sylwetce z uszami.
Kafle przy mocnym/ciekłym szkle są półprzezroczyste — nie zabijają efektu. Czytelność pilnuje automatyczne podbicie alfy tła wg luminancji (liniowej, Rec. 709) tapety pod wyspą: ciemna wyspa nad tapetą jaśniejszą niż 0,7 dostaje +0,2, jasna nad tapetą ciemniejszą niż 0,25 dostaje +0,18 (ciekłe 44% → 62%: szkło dalej prześwituje, a ciemniejsze `fg.muted` i `accent` mają na gołym szkle ok. 4:1 nad obecną tapetą, ok. 3:1 nad czarną; na kaflach ≥ 4,5:1).

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
- Stara treść — wyjście: opacity 80 ms, krzywa `0.2, 0, 0, 1` (szybki start: treść znika, zanim kształt urośnie), scale → 0.94 w 160 ms, blur → 6 px.
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

**Blokada** (`WlSessionLock`, PAM) — wyspa zjeżdża z krawędzi do karty 460×360 na środku (nad oknami, przed założeniem blokady — W12); pod nią tapeta, lekko rozmyta (W13): blur 12 px, scale 1.08, bez zmiany saturacji i jasności (700 ms); okna znikają. Karta: zegar 88 px, data, pole hasła (avatar z inicjałem, input, przycisk →), linia statusu, na dole bateria / Wi‑Fi / **tylko liczba** powiadomień (bez treści). Dodatkowo: mini odtwarzacz na dole ekranu, przyciski Uśpij/Wyłącz w prawym dolnym rogu. Błąd: shake 380 ms (±10/8/6/3 px) + obwódka `danger`. Sukces: odwrotny morfing do `rest` (cień karty gaśnie, przy dokowaniu wyrastają uszy: od 420 ms przez 200 ms), okna wracają z opóźnieniem 240 ms (tapeta zanika przez 420 ms) — przez przekazanie na nakładkę (W12).
Uwaga: lock surface to osobna powierzchnia i sama się nie animuje — „zjazd” wyspy i powrót gra nakładka w oknie wyspy (W12).

## 7. Architektura

Katalog `config/quickshell/`. Dotter wdraża go do `~/.config/quickshell` plik po pliku. Opis pracy z kodem: `config/quickshell/CLAUDE.md`.

```
shell.qml            ShellRoot: Lock, a na każdy ekran (Variants) Wallpaper, Strut i Island;
                     odwołuje się do leniwych singletonów, żeby ruszyły przy starcie
Theme.qml            singleton: tokeny z lib/theme.js + config hosta (FileView, hot-reload),
                     tryb i poziom szkła, IPC `theme`
IslandState.qml      singleton: maszyna stanów, timery, OSD, tryb linii, IPC `island`
Island.qml           PanelWindow per ekran (pełnoekranowa, maska = kształt, w stanach modalnych pełna), region blura
IslandShape.qml      jedna ścieżka z uszami, animowana wymiarami, plus cień i obrys (ring)
IslandContent.qml    warstwy stanów (`sources`), płynne przenikanie
Strut.qml            pusta powierzchnia z exclusive zone (36 px, w trybie linii 0)
Wallpaper.qml        tapeta per ekran
Lock.qml             WlSessionLock + PAM; LockOverlay.qml (w oknie wyspy) gra wejście i powrót blokady;
                     LockPreview.qml pokazuje kartę bez blokowania (zrzuty)
states/              Rest, Osd, Toast, Center, Launcher, Control, Media, Power, PowerDone, LockCard
components/          Icon, MiniPlayer, PowerActions (jedyna bramka poleceń zasilania i blokady)
services/            Niri, Fullscreen, Apps, Menus, Notifs, Audio, Brightness, Network, Battery,
                     Players, Time, AutoTheme
lib/                 czysty JS (`.pragma library`), testowany w node: theme, island, niri, fullscreen,
                     notifs, power, lock, slider, fuzzy, calc, icons, autotheme, launch
menus/               skrypty menu launchera (schowek, VPN)
tests/               testy node, smoke (`tests/smoke/*.sh`), `shot.sh`, `niri-validate.sh`
```

Zasady:

- Wszystkie liczby i kolory UI pochodzą z `Theme`. Pilnuje tego `tests/no-magic.test.mjs`.
- Nowy stan to cztery zmiany: wiersz geometrii w `lib/theme.js`, wpis w `PRIORITY` w `lib/island.js`, wpis w `IslandContent.sources` i plik `states/X.qml`.
- Skróty niri wołają `qs ipc call island <funkcja>`. Cel `island` ma funkcje `open`, `toggle`, `close`, `hide`, `launcherMenu`, `lock`, `unlock`. Cele `theme` i `notifs` służą do ustawiania motywu i do testów.
- Blur robi shell przez `ext-background-effect`. `layer-rule` dla `wyspa` w `config/niri/window_rules.kdl` ma tylko `xray false` (W1).
- Polecenia zasilania i blokada przechodzą przez jedną bramkę (`PowerActions.perform()`, `Lock.engageLock()`). W trybie testowym (`WYSPA_TEST=1`) bramka tylko loguje.
- Natywne moduły Quickshell: Pipewire (głośność), Mpris (media), Notifications (serwer powiadomień), UPower (bateria), Pam, Bluetooth, Networking. Jasność czyta sysfs i ustawia przez `brightnessctl`.

## 8. Prototypy

| Plik | Co pokazuje |
|---|---|
| `WyspaLive.dc.html` | morfing między stanami, materiał, kotwice (wtopiona/pływająca/chowana) |
| `WyspaRuch.dc.html` | choreografia, krzywe, tabela stanów |
| `Kotwica.dc.html` | porównanie kotwic i uzasadnienie |
| `LockLive.dc.html` | ekran blokady i przejścia |
| `PowerLive.dc.html` | menu zasilania z przytrzymaniem |
| `NotifLive.dc.html` | toasty, licznik, centrum, grupowanie, DND |
| `JasnyMotyw.dc.html` | jasny motyw: panel, launcher, blokada, tabela tokenów |

Logika (timery, rozmiary, krzywe) jest w bloku `<script type="text/x-dc">` na końcu każdego pliku.
