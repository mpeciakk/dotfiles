# kolejka-sms — dokument przekazania

## 0. Jak czytać

Opisuje commit 1519789.

**Cel:** po lekturze umiesz wdrożyć usługę, zdiagnozować awarię wysyłki i wprowadzić typową zmianę w workerze.

- Przejmujesz utrzymanie: sekcje 1–3, potem 5 i 6.
- Rozwijasz kod: sekcje 2, 7 i 9. Kod w repo różni się od speca, więc zacznij od sekcji 9.
- Diagnozujesz awarię: sekcja 6, potem 8.

Sekcja 9 („Luki") zawiera rzeczy, których pakiet nie wie. Przeczytaj ją, zanim zaufasz którejkolwiek innej sekcji.

## 1. Cel i granice

Usługa ma przyjmować zlecenia SMS przez HTTP i wysyłać je przez bramkę SMSAPI. Zlecenia czekają w kolejce w SQLite. Usługa nie wysyła SMS-ów inną drogą niż SMSAPI i nie używa zewnętrznego brokera kolejek. Repo nie zawiera dziś działającej implementacji tego zadania (zob. sekcja 2 i [Luki](#9-luki)).

## 2. Jak to działa

Wg [speca (sekcja 2)](../../spec.md#2-architektura) przepływ ma trzy etapy:

1. Klient wysyła zlecenie HTTP do procesu Flask z [app.py](../../app.py).
2. Proces zapisuje zlecenie w tabeli `outbox` w SQLite.
3. Proces z [worker.py](../../worker.py) budzi się co 10 sekund, bierze z `outbox` najwyżej 50 zleceń i wysyła je do bramki SMSAPI. Bramka zwraca kody HTTP; 429 oznacza, że trzeba ponowić wysyłkę.

**Kod tego przepływu nie realizuje.** `app.py` tworzy tylko obiekt Flask, bez żadnej trasy. `worker.py` ma stałe `BATCH = 50` i `RETRY_ON = (429,)`, ale pętla tylko czeka 10 sekund. Nigdzie nie ma tabeli `outbox`, połączenia z SQLite ani wywołania SMSAPI. Spec traktuj więc jako zamiar, nie opis działającego kodu. Szczegóły w [Lukach](#9-luki).

Na serwerze `sms1` działają według użytkownika dwie jednostki systemd: `kolejka-sms` i `kolejka-sms-worker`. Które z procesów uruchamia każda z nich, pakiet nie wie.

Dwie zasady projektowe, które obowiązują niezależnie od stanu kodu ([spec, sekcja 3](../../spec.md#3-decyzje)):

- Kolejką jest SQLite (D1), bo wszystko działa na jednym serwerze.
- Identyfikatory są liczbami całkowitymi (D2). Bramka obcina pole referencji do 20 znaków, więc migrację na UUID cofnięto.

## 3. Stan projektu

- Repo to szkielet (sekcja 2). Brak testów, brak listy zależności (np. `requirements.txt`).
- Wg speca ponawiania odpowiedzi 429 nie uruchamiano na produkcji. W kodzie jest tylko stała `RETRY_ON`.
- Wg speca nie ma alertu, gdy w `outbox` czeka ponad 1000 zleceń.
- Plik `ids.py`, którego dotyczył cofnięty commit z UUID, nie istnieje w repo.
- Wdrożenie: [deploy.sh](../../deploy.sh). Logi wg [README](../../README.md): `journalctl -u kolejka-sms`.

## 4. Środowisko i dostępy

- Do wdrożenia potrzebujesz `rsync`, `ssh` i dostępu do hosta `sms1` pod tą nazwą (używa jej `deploy.sh`).
- Python i Flask. Wersji i listy zależności repo nie podaje.
- Token SMSAPI: 1Password, sejf „Ops", wpis „SMSAPI". Szablon zmiennych to [.env.example](../../.env.example) (zmienna `SMSAPI_TOKEN`). Plik `.env` jest w `.gitignore`, a `deploy.sh` go nie kopiuje.
- Dostępy do serwerów, sejfów, VPN i sieci opisuje baza wiedzy `docs.internal.animativ.dev`.

## 5. Typowe zadanie krok po kroku

Zadanie: wdrożyć zmianę z lokalnej kopii repo na `sms1`.

1. **Sprawdź dzień.** Nie wdrażaj w piątek (powód w sekcji 6). Gdzie: u siebie.
2. **Sprawdź, że zmiany są w katalogu roboczym.** Skrypt kopiuje cały katalog roboczy, także to, czego nie zacommitowano. Gdzie: u siebie.
3. **Uruchom `./deploy.sh prod` z katalogu głównego repo.** Skrypt ignoruje argument `prod` i zawsze wysyła na `sms1`: `rsync` do `/srv/kolejka-sms/` (z wyłączeniem `.env`), potem `systemctl restart kolejka-sms` przez `ssh`. Gdzie: u siebie. Sukces: skrypt kończy się bez błędu `rsync` i `ssh`.
4. **Sprawdź stan jednostek na `sms1`:** `systemctl status kolejka-sms` i `systemctl status kolejka-sms-worker`. Gdzie: `sms1`. Sukces: obie `active (running)`. Skrypt restartuje tylko `kolejka-sms`. Czy nowy kod workera zaczyna działać po deployu, pakiet nie wie ([Luki](#9-luki)).
5. **Obejrzyj logi:** `journalctl -u kolejka-sms`. Gdzie: `sms1`. Co jest sukcesem (brak trasy kontrolnej, brak testu dymnego w repo), pakiet nie wie.

## 6. Awarie i obejścia

| Objaw | Przyczyna | Obejście | Kiedy stosować / kiedy stop |
|---|---|---|---|
| Po poniedziałkowej nocy nic się nie wysyła | `sms1` restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek, a worker sam nie wstaje | Na `sms1`: `systemctl start kolejka-sms-worker` | Stosuj, gdy worker nie działa po restarcie serwera. Gdy jednostka po starcie znów pada, stop-warunek nieznany ([Luki](#9-luki)); awarię trwającą ponad 30 minut zgłoś według sekcji 8. |
| Bramka zwraca 401 | Token SMSAPI wygasa co 90 dni | Odnów token w panelu SMSAPI | Stosuj przy 401. Co zrobić z nowym tokenem (1Password, `.env` na serwerze, restart), nie wiadomo ([Luki](#9-luki)). |
| Zlecenia znikają w piątek około 23:00 | Cron `backup-sms` blokuje bazę na ok. 40 minut, a worker w tym czasie gubi zlecenia | Nie wdrażaj w piątki | Blokada dzieje się co piątek niezależnie od wdrożeń; reguła chroni tylko przed wdrożeniem w tym oknie. Jak odzyskać zgubione zlecenia i jak je chronić, nie wiadomo ([Luki](#9-luki)). |
| Bramka zwraca 429 | Przekroczone limity bramki (wartości limitów nieznane) | Brak. Kod ma tylko stałą `RETRY_ON`, a spec mówi, że ponawiania nie uruchamiano na produkcji | Brak sprawdzonej procedury i stop-warunku ([Luki](#9-luki)). |
| `outbox` rośnie ponad 1000 | Nic o tym nie alarmuje | Brak opisanego sposobu | Jak sprawdzać długość kolejki, nieznane ([Luki](#9-luki)). |

## 7. Rozwój

Przykład: zmiana wielkości paczki wysyłanej przez worker.

1. Zmień stałą `BATCH` w [worker.py](../../worker.py).
2. Testów w repo nie ma, więc zautomatyzowanej weryfikacji brak. Czy potrzebny jest run na prawdziwej bramce lub środowisku testowym i jak go zrobić, pakiet nie wie ([Luki](#9-luki)). Limit bramki nie jest nigdzie zapisany; wielkość paczki w kodzie nie jest dowodem na limit.
3. Wdróż według sekcji 5 (nie w piątek).

Zmiany dotykające identyfikatorów muszą trzymać się decyzji D2 ([spec, sekcja 3](../../spec.md#3-decyzje)). Wybór SQLite zamiast Redisa to D1 w tej samej sekcji.

## 8. Kto co wie

- Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem.
- Kto jeszcze zna projekt, kto jest właścicielem konta SMSAPI i do kogo iść przy awarii krótszej niż 30 minut, pakiet nie wie ([Luki](#9-luki)).
- Dostępy i procedury firmowe: `docs.internal.animativ.dev`.

## 9. Luki

Blokery:

- **Kod nie zgadza się ze specem.** Jest szkielet: brak tras HTTP, `outbox`, SQLite, wywołania SMSAPI i `ids.py`. Skutek: nie wiadomo, co faktycznie działa na `sms1`; nie da się zweryfikować przepływu z sekcji 2. Do czasu ustalenia: sprawdź na `sms1`, co leży w `/srv/kolejka-sms/` i co uruchamiają obie jednostki; nie polegaj na kodzie z repo jako na odzwierciedleniu produkcji.
- **Zachowanie przy 429 nieznane.** Skutek: brak procedury ani stop-warunku przy limicie bramki. Do czasu ustalenia: traktuj 429 jako nieobsłużone; awarię trwającą ponad 30 minut zgłoś według sekcji 8.
- **Odnowienie tokenu opisane tylko do panelu.** Nie wiadomo, gdzie wpisać nowy token (1Password, `.env` na serwerze), czy potrzebny jest restart, ani gdzie zobaczyć datę wygaśnięcia. Skutek: nie dokończysz odnowienia bez zgadywania. Do czasu ustalenia: odnów w panelu SMSAPI i dopytaj osobę z sekcji 8.
- **Brak zastępcy dla Ernesta.** Skutek: gdy Ernest jest niedostępny, pakiet nie wskazuje, kogo wołać. Do czasu ustalenia: brak zastępcy w pakiecie; ustal go w zespole.

Pozostałe:

- **Czy `deploy.sh` restartuje worker.** Skrypt restartuje tylko `kolejka-sms`, a `kolejka-sms-worker` to osobna jednostka. Skutek: po zmianie `worker.py` nie wiadomo, czy działa nowy kod. Do czasu ustalenia: po deployu sprawdź `systemctl status kolejka-sms-worker`.
- **Lokalizacja pliku SQLite i sposób sprawdzenia długości `outbox`.** Skutek: nie zauważysz kolejki powyżej 1000. Do czasu ustalenia: sprawdzaj ręcznie na `sms1` po ustaleniu ścieżki.
- **Zgubione zlecenia z okna backupu.** Nie wiadomo, czy da się je odzyskać ani czy reguła „nie w piątki" dotyczy całego dnia, czy tylko okna po 23:00. Skutek: nie wiesz, co robić po utracie. Do czasu ustalenia: nie wdrażaj w piątki w ogóle.
- **Weryfikacja zmian.** Brak testów w repo i opisu testu dymnego po deployu. Skutek: nie wiesz, że zmiana działa. Do czasu ustalenia: sprawdź logi `journalctl` po wdrożeniu.
- **Gdzie `.env` leży na `sms1`, logi jednostki workera, wersje Pythona i Flaska, lista zależności.** Skutek: nie odtworzysz środowiska od zera. Do czasu ustalenia: odczytaj z działającej instalacji na `sms1`.
- **Właściciel konta SMSAPI.** Skutek: nie wiesz, kogo prosić o zmianę w panelu. Do czasu ustalenia: ustal to w zespole.

## 10. Sprawdź się

### Scenariusze

1. W poniedziałek rano zlecenia nie wychodzą, a `sms1` restartował się w nocy. Co robisz najpierw?
   *Klucz:* na `sms1` `systemctl start kolejka-sms-worker`, bo po nocnym restarcie po aktualizacjach jądra worker sam nie wstaje.
2. Ktoś chce wdrożyć w piątek po południu. Zgoda?
   *Klucz:* nie. W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut, a worker wtedy gubi zlecenia; w piątki nie wdrażamy.
3. Bramka zwraca 401. Przyczyna i działanie?
   *Klucz:* wygasł token (wygasa co 90 dni); odnowić w panelu SMSAPI. Token w 1Password, sejf „Ops", wpis „SMSAPI". Co dalej z nowym tokenem — pakiet nie wie.
4. Czy `./deploy.sh staging` wdroży na staging?
   *Klucz:* nie; skrypt ignoruje argument i zawsze wysyła na `sms1`.
5. Awaria trwa 40 minut. Komu i jak?
   *Klucz:* Ernestowi, na Signalu, nie mailem.
6. Ktoś proponuje UUID jako identyfikatory. Odpowiedź?
   *Klucz:* nie; bramka obcina pole referencji do 20 znaków, migrację cofnięto (D2).
7. W `outbox` czeka 5000 zleceń. Kto dostał alert i jak sprawdzić długość kolejki?
   *Klucz:* nikt, alertu nie ma; jak sprawdzić długość, pakiet nie wie (NIE WIEM Z PAKIETU jest poprawne).
8. Czy kod w repo co 10 sekund wysyła paczki po 50 zleceń do SMSAPI?
   *Klucz:* nie; to opis ze speca. `worker.py` tylko czeka w pętli, `app.py` nie ma tras, brak `outbox` i wywołania SMSAPI.

### Zadania praktyczne

1. Wdróż drobną zmianę w dzień roboczy i potwierdź, że obie jednostki działają.
2. Zdiagnozuj sytuację „bramka zwraca 401" i opisz, które kroki znasz, a które wymagają ustaleń.
3. Zaplanuj obsługę 429 w workerze: co już wiesz, czego brakuje, co trzeba ustalić przed napisaniem kodu.
