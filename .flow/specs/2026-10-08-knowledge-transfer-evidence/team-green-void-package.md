# kolejka-sms: przekazanie projektu (następca)

## 0. Jak czytać

Stan na 8 października 2026 r., commit `1519789` (gałąź `main`). Dokument opisuje tylko to, czego nie znajdziesz w repo: pułapki, obejścia, dostępy i luki. Autor jest niedostępny przez dwa tygodnie od tej daty, więc sekcja 9 („Luki") mówi, czego nie wie ani on, ani ten dokument.

Zacznij od sekcji 6 („Pułapki") i 9 („Luki"). Zajmą kilka minut i chronią przed najdroższymi błędami.

## 1. Co to robi i dla kogo

Usługa przyjmuje zlecenia SMS przez HTTP i wysyła je przez bramkę SMSAPI z kolejki w SQLite. Pełny opis: [`spec.md`](../../spec.md).

## 2. Mapa systemu

- Cel, architektura, decyzje D1 i D2, punkty otwarte: [`spec.md`](../../spec.md).
- Kod: `app.py` (Flask), `worker.py` (pętla wysyłki). **W repo oba pliki są prawie puste**, patrz sekcja 9, pozycja 1.
- Wdrożenie i logi: [`README.md`](../../README.md), [`deploy.sh`](../../deploy.sh).
- Serwer: `sms1`, katalog `/srv/kolejka-sms/`.
- Jednostki systemd na `sms1`: `kolejka-sms` (restartuje ją `deploy.sh`) i `kolejka-sms-worker` (osobna).

## 3. Jak zmieniać

- Wdrożenie: `./deploy.sh prod`. Skrypt kopiuje repo przez `rsync` na `sms1:/srv/kolejka-sms/` z pominięciem `.env`, potem restartuje jednostkę `kolejka-sms` przez `ssh`.
- Argument `prod` jest ignorowany. Skrypt zawsze wdraża na `sms1`.
- Wzór zmiennych: `.env.example` (jedna zmienna, `SMSAPI_TOKEN`).
- Testów ani CI w repo nie ma. Sposób lokalnego uruchomienia nie jest opisany.
- **W piątki nie wdrażamy** (sekcja 6, pułapka 1).

## 4. Decyzje

Szczegóły i uzasadnienia: tabela w [`spec.md`](../../spec.md), sekcja 3. Jedna decyzja kosztuje najwięcej, gdy ktoś o niej zapomni: identyfikatory zostają całkowite (D2, patrz pułapka 4).

## 5. Dług i otwarte ryzyka

- Brak alertu, gdy outbox przekracza 1000 oczekujących zleceń (spec, sekcja 4).
- Ponawianie przy 429 (`42c8bd3`) nie było uruchamiane na produkcji (spec, sekcja 4).
- Token SMSAPI wygasa co 90 dni i odnawia się go ręcznie (pułapka 3).

## 6. Pułapki i obejścia

1. **Piątek, 23:00: backup blokuje bazę.** Cron `backup-sms` blokuje bazę na około 40 minut, a worker gubi w tym czasie zlecenia. Dlatego w piątki nie wdrażamy.
2. **Noc z niedzieli na poniedziałek: `sms1` się restartuje** po aktualizacjach jądra, a worker sam nie wstaje. Uruchom go na `sms1`: `systemctl start kolejka-sms-worker`.
3. **Bramka zwraca 401: wygasł token SMSAPI.** Token wygasa co 90 dni. Odnawia się go w panelu SMSAPI, ostatnio 1 sierpnia 2026 r. Token leży w 1Password (sekcja 8). Jak nowa wartość trafia na serwer, nie zostało opisane: `deploy.sh` pomija `.env` (luka 6).
4. **Nie wracaj do UUID.** Migrację na UUID cofnięto (`f685e0d`, wcześniej `76c9620`), bo bramka obcina pole referencji do 20 znaków. Powód leży po stronie bramki, nie kodu.
5. **Ponawianie 429 nie jest sprawdzone.** W `worker.py` jest `RETRY_ON = (429,)`. Nikt nie widział tego na produkcji.
6. **`deploy.sh` restartuje tylko `kolejka-sms`.** Czy to wystarczy, żeby worker (`kolejka-sms-worker`) zaczął pracować na nowym kodzie, nie jest potwierdzone (sekcja 9, pozycja 2).

## 7. Eskalacja: kto co wie

- Awarie dłuższe niż 30 minut zgłaszasz Ernestowi na Signalu, nie mailem. Postępowania przy krótszych awariach nikt nie opisał (luka 5).
- Autor tego dokumentu zna projekt, ale od 8 października 2026 r. nie odpowiada przez dwa tygodnie.
- Informacje o infrastrukturze są w firmowej bazie wiedzy. Nazwa ani adres nie zostały podane (sekcja 9).
- Osoby od bramki SMSAPI i od `sms1`: nieznane (sekcja 9).

## 8. Dostępy: gdzie

- Token SMSAPI: 1Password, sejf „Ops", wpis „SMSAPI". `.env` leży poza repo (`.gitignore`), a `deploy.sh` go pomija.
- Serwer: `ssh sms1` (tak działa `deploy.sh`). Kto nadaje dostęp, nie jest opisane.
- Panel SMSAPI: kto ma konto, nie jest opisane.

## 9. Luki

1. **Repo wygląda na szkielet.** Spec opisuje tabelę `outbox`, SQLite, pobieranie do 50 zleceń co 10 sekund i wysyłkę do bramki. W kodzie jest tylko `Flask(__name__)` w `app.py` oraz pętla `sleep(10)` ze stałymi `BATCH = 50` i `RETRY_ON` w `worker.py`. Autor nie odpowiedział, gdzie jest właściwy kod. Zanim zaczniesz coś zmieniać, ustal to.
2. **Czy `deploy.sh` restartuje worker?** Skrypt restartuje `kolejka-sms`. Worker to osobna jednostka. Autor nie potwierdził, czy pierwsza uruchamia drugą.
3. **Staging.** Autor nie wie, czy istnieje inne środowisko niż `sms1`.
4. **Plik SQLite i backup.** Nieznana ścieżka bazy oraz miejsce i sposób przywracania kopii z crona `backup-sms`.
5. **Kontakt awaryjny.** Znany jest tylko Ernest, na Signalu, dla awarii dłuższych niż 30 minut. Nie wiadomo, czy jest osiągalny w czasie nieobecności autora, ani kogo wołać przy krótszych awariach, awarii bramki SMSAPI czy `sms1`.
6. **Odnowienie tokenu.** Autor podał: wygasa co 90 dni, ostatnio odnowiony 1 sierpnia 2026 r. Z tego **wyliczono**, że kolejny termin to około 30 października 2026 r. (nie potwierdzone, sprawdź w panelu). Nie wiadomo, kto ma dostęp do panelu, ani jak wygląda odnowienie krok po kroku, ani jak nowa wartość trafia na `sms1`.
7. **Ponawianie 429.** Limity bramki i oczekiwane zachowanie (backoff, liczba prób) nie są znane.
8. **Alert outboxu.** Nie ma alertu, a sposób sprawdzenia liczby zleceń w kolejce nie został opisany.
9. **Logi workera.** README podaje `journalctl -u kolejka-sms`. Czy log workera jest w tej jednostce, czy w `kolejka-sms-worker`, nie wiadomo.
10. **Częstość restartów `sms1`.** Autor opisał restart po aktualizacjach jądra, w nocy z niedzieli na poniedziałek. Jak często do niego dochodzi, nie wiadomo.
11. **Firmowa baza wiedzy.** Autor wspomniał, że opisuje ona infrastrukturę. Link nie został podany.

## 10. Sprawdź się

1. **Wdrażasz zmianę na produkcję. Co dokładnie robi `./deploy.sh prod`?**
   Kopiuje repo `rsync`-iem do `sms1:/srv/kolejka-sms/` bez `.env`, potem przez `ssh` restartuje jednostkę `kolejka-sms`. Argument `prod` jest ignorowany. Czy worker też się restartuje, nie wiadomo (luka 2).
2. **Bramka zwraca 401. Co to znaczy i co robisz?**
   Najpewniej wygasł token SMSAPI (wygasa co 90 dni). Odnawiasz go w panelu SMSAPI. Aktualny token jest w 1Password (sejf „Ops", wpis „SMSAPI"). Kto ma dostęp do panelu i jak nowa wartość trafia na serwer, nie wiadomo (luka 6).
3. **Kolega z zespołu proponuje identyfikatory UUID. Co odpowiadasz?**
   Nie. Migracja była już cofnięta (`f685e0d`), bo bramka obcina pole referencji do 20 znaków (D2 w spec).
4. **Piątek, 15:00. Jest pilna poprawka. Co robisz?**
   Nie wdrażasz w piątek. Cron `backup-sms` blokuje bazę około 40 minut od 23:00, a worker gubi wtedy zlecenia.
5. **Poniedziałek rano. `sms1` restartował się w nocy i SMS-y nie wychodzą. Pierwszy krok?**
   Uruchom worker na `sms1`: `systemctl start kolejka-sms-worker`. Po restarcie po aktualizacjach jądra nie wstaje sam.
6. **Bramka zwraca 429. Co wiesz z pakietu?**
   W `worker.py` jest `RETRY_ON = (429,)`, ale ponawianie nigdy nie było uruchomione na produkcji. Limitów bramki ani oczekiwanego zachowania pakiet nie podaje (luka 7).
7. **Outbox ma 3000 zleceń. Skąd się o tym dowiesz?**
   Nie dowiesz się automatycznie: alertu nie ma (spec, sekcja 4). Sposób sprawdzania rozmiaru kolejki pakiet nie opisuje (luka 8).
8. **W `worker.py` nie widzisz wysyłki ani SQLite. Co robisz?**
   Nie zgadujesz. Repo wygląda na szkielet, autor nie wskazał, gdzie jest właściwy kod (luka 1). Katalog `/srv/kolejka-sms/` na `sms1` to miejsce, do którego `deploy.sh` kopiuje repo. Porównaj jego zawartość z repo.
9. **Usługa nie działa od 45 minut. Kogo i jak zawiadamiasz?**
   Ernesta, na Signalu, nie mailem (awaria dłuższa niż 30 minut). Czy Ernest jest osiągalny w czasie nieobecności autora, nie wiadomo (luka 5).
