# kolejka-sms — dokument przekazania

## 0. Jak czytać

Opisuje commit 1519789.

**Cel:** po lekturze umiesz przejąć utrzymanie projektu: wdrożyć zmianę, zdiagnozować awarię z logów i rozwijać kod.

Co czytać:
- **Przejmujesz obsługę:** sekcje 1–5, potem 6 i 9.
- **Rozwijasz kod:** sekcje 2, 3, 7 i 9. Zacznij od ostrzeżenia w sekcji 2: kod w repo jest szkieletem.
- **Diagnozujesz awarię:** sekcje 6, 8 i 9.

## 1. Cel i granice

Projekt ma przyjmować zlecenia SMS przez HTTP, trzymać je w kolejce w SQLite i wysyłać przez bramkę SMSAPI. Na wejściu są zlecenia wysyłki, na wyjściu wiadomości SMS wysłane przez bramkę. Projekt nie ma własnej bramki SMS, nie używa Redisa ani żadnej innej zewnętrznej kolejki, a wysyłkę zleca wyłącznie przez SMSAPI. To jest zamiar opisany w [specu, sekcja 1](../../spec.md#1-cel); aktualny stan kodu opisuje sekcja 3.

## 2. Jak to działa

Spec zakłada dwa procesy, które łączy baza SQLite:

1. **Proces HTTP** ([app.py](../../app.py), Flask) ma przyjmować zlecenia i dopisywać je do tabeli `outbox`.
2. **Worker** ([worker.py](../../worker.py)) ma co 10 sekund zabierać z `outbox` porcję do 50 zleceń i oddawać ją bramce SMSAPI. Odpowiedź 429 z bramki ma skutkować ponowieniem.

Architekturę opisuje [spec, sekcja 2](../../spec.md#2-architektura). Wybór SQLite zamiast Redisa wyjaśnia [decyzja D1](../../spec.md#3-decyzje).

**Kod tego nie robi.** W tym commicie `app.py` tworzy tylko obiekt Flask i nie ma żadnego endpointu. `worker.py` ma stałe `BATCH = 50` i `RETRY_ON = (429,)` oraz pętlę, która tylko czeka 10 sekund. Stałe nie są nigdzie użyte. Nie ma kodu SQLite, tabeli `outbox` ani wywołania SMSAPI. Spec opisuje więc zamierzoną usługę, nie działający kod. Czy działająca implementacja istnieje gdzie indziej — patrz [sekcja 9](#9-luki).

Dwie jednostki systemd na serwerze `sms1`:
- `kolejka-sms`, którą restartuje skrypt wdrożenia;
- `kolejka-sms-worker`, osobna jednostka workera.

Co dokładnie uruchamia każda z nich, repo nie mówi (patrz [sekcja 9](#9-luki)).

## 3. Stan projektu

- **Wersja:** repo nie ma numeru wersji; stan pinuje commit z sekcji 0.
- **Co jest w repo:** skrypt wdrożenia. Funkcji usługi (przyjmowanie zleceń, kolejka, wysyłka, ponawianie) w tym commicie nie ma w kodzie.
- **Ponawianie 429:** wg speca nie uruchamiano go na produkcji. W kodzie jest tylko stała `RETRY_ON`.
- **Brak alertu:** nic nie ostrzega, gdy w `outbox` czeka ponad 1000 zleceń ([spec, punkty otwarte](../../spec.md#4-punkty-otwarte)).
- **Identyfikatory:** całkowite, nie UUID. Migrację na UUID cofnięto, bo bramka obcina pole referencji do 20 znaków ([decyzja D2](../../spec.md#3-decyzje)). Nie wprowadzaj UUID ponownie.
- **Testy i zależności:** w repo nie ma testów ani listy zależności (Flask jest importowany, ale nigdzie niezadeklarowany).
- **Logi:** kod z tego commitu niczego nie loguje; w `journalctl` są tylko wpisy systemd.

## 4. Środowisko i dostępy

- **Na stanowisku:** git, `rsync`, `ssh`, Python z Flaskiem.
- **Serwer:** `sms1`. Katalog wdrożenia to `/srv/kolejka-sms/`. Dostęp do serwera i do menedżera haseł opisuje firmowa baza wiedzy `docs.internal.animativ.dev`.
- **Token SMSAPI:** jedyny sekret projektu; szablon w [.env.example](../../.env.example) ma pustą zmienną `SMSAPI_TOKEN`. Wartość leży w 1Password, sejf „Ops”, wpis „SMSAPI”. Skrypt wdrożenia pomija plik `.env`, więc go nie nadpisuje.
- **Zmiana tokena po odnowieniu:** gdzie nowa wartość ma trafić, jest w [sekcji 9](#9-luki).

## 5. Typowe zadanie krok po kroku

Zadanie: wdrożyć zmianę z repo na `sms1`.

1. **Sprawdź dzień.** W piątki nie wdrażamy (powód: sekcja 6).
2. **Operator, katalog główny repo:** uruchom [`./deploy.sh prod`](../../deploy.sh). Skrypt robi `rsync` plików (bez `.env`) do `sms1:/srv/kolejka-sms/`, a po nim `ssh sms1 systemctl restart kolejka-sms`. Sukces: skrypt kończy się bez błędu i bez komunikatu, a kod wyjścia to 0 (drugi krok idzie tylko po udanym `rsync`).
3. **`sms1`:** obejrzyj logi: `journalctl -u kolejka-sms`. Pamiętaj, że sam kod niczego nie loguje (sekcja 3), więc w logach zobaczysz głównie komunikaty systemd o starcie jednostki.
4. **Worker:** skrypt nie restartuje `kolejka-sms-worker`. Czy po wdrożeniu trzeba go restartować ręcznie, nie jest potwierdzone ([sekcja 9](#9-luki)). Zmiany w `worker.py` nie są więc pewne, dopóki tego nie ustalisz.

## 6. Awarie i obejścia

| Objaw | Przyczyna | Obejście | Kiedy stosować / kiedy przestać |
|---|---|---|---|
| Po nocy z niedzieli na poniedziałek worker nie działa | `sms1` restartuje się po aktualizacjach jądra, a worker sam nie wstaje | Na `sms1`: `systemctl start kolejka-sms-worker` | Stosuj po takim restarcie serwera. Warunek zatrzymania (np. start się nie udaje) jest nieznany — [sekcja 9](#9-luki). |
| W piątek około 23:00 zlecenia znikają | Cron `backup-sms` blokuje bazę na ok. 40 minut, a worker gubi w tym czasie zlecenia | Nie wdrażaj w piątki | Obowiązuje zawsze w piątki. Czy zgubione zlecenia da się odzyskać, jest nieznane — [sekcja 9](#9-luki). |
| Bramka zwraca 401 | Token SMSAPI wygasa co 90 dni | Odnów token w panelu SMSAPI | Stosuj po 401 z bramki. Gdzie wpisać nowy token, nieznane — [sekcja 9](#9-luki). |
| Awaria trwa dłużej niż 30 minut | — | Zgłoś ją Ernestowi na Signalu, nie mailem | Dotyczy awarii dłuższych niż 30 minut. Brak zastępcy, gdy Ernest nie odpowiada — [sekcja 9](#9-luki). |

Kod z tego commitu nie wywołuje bramki, więc 401 i 429 pochodzą z opisu zespołu i speca, nie z repo.

## 7. Rozwój

Przykład: zmiana wielkości porcji.

1. Zmień `BATCH` w [worker.py](../../worker.py). Spec podaje 50 jako zamierzoną porcję; limitu bramki żadne źródło nie podaje.
2. Testów w repo nie ma, więc nie ma czego uruchomić. Procedura sprawdzenia zmiany na prawdziwym środowisku nie jest opisana ([sekcja 9](#9-luki)).
3. Wydaj zmianę jak w sekcji 5, nie w piątek. Restart workera: patrz krok 4 w sekcji 5.

Decyzje, których nie wolno zmieniać bez powodu: [D1 i D2](../../spec.md#3-decyzje).

## 8. Kto co wie

- **Awarie dłuższe niż 30 minut:** zgłaszaj Ernestowi na Signalu, nie mailem.
- **Właściciel konta SMSAPI, osoba znająca projekt poza Ernestem, miejsce definicji crona `backup-sms`:** nieznane ([sekcja 9](#9-luki)).

## 9. Luki

Blokery:
- **Nie wiadomo, gdzie jest działająca implementacja (outbox, endpointy, wysyłka do SMSAPI).** Skutek: nie da się rozwijać usługi ani uznać jej za działającą na podstawie repo; spec opisuje coś, czego kod nie ma. Do czasu ustalenia: nie zakładaj, że spec opisuje kod; sprawdź, co faktycznie leży w `/srv/kolejka-sms/` na `sms1`.
- **Nie wiadomo, czy po wdrożeniu trzeba ręcznie restartować `kolejka-sms-worker`, ani co uruchamia jednostka `kolejka-sms`.** Skutek: nie masz pewności, czy zmiana w `worker.py` zaczęła działać. Do czasu ustalenia: sprawdź na `sms1` stan obu jednostek po wdrożeniu.
- **Nie wiadomo, gdzie wpisać nowy token SMSAPI po odnowieniu, ani kto jest właścicielem konta SMSAPI.** Skutek: po wygaśnięciu tokenu (401) nie wiesz, jak przywrócić wysyłkę. Do czasu ustalenia: wiesz tylko, że odnowienie jest w panelu SMSAPI i że wartość tokena leży w 1Password (sejf „Ops”, wpis „SMSAPI”).

Pozostałe:
- **Nie wiadomo, kiedy nie wolno włączać ponawiania 429 i co wtedy robić.** Skutek: nie ma warunku bezpieczeństwa dla tej funkcji. Do czasu ustalenia: wg speca ponawiania nie uruchamiano na produkcji; nic więcej nie wiadomo.
- **Brak warunku zatrzymania dla ręcznego startu workera.** Skutek: nie wiesz, co zrobić, gdy start się nie udaje. Do czasu ustalenia: brak opisanej procedury; jedyna znana zasada to zgłoszenie awarii dłuższej niż 30 minut (sekcja 6).
- **Nie wiadomo, czy zlecenia zgubione podczas piątkowego backupu da się odzyskać.** Skutek: nie umiesz ocenić skutków backupu. Do czasu ustalenia: nie wdrażaj w piątki.
- **Nie wiadomo, gdzie sprawdzić datę wygaśnięcia tokena SMSAPI.** Skutek: nie wiesz z wyprzedzeniem, kiedy pojawi się 401. Do czasu ustalenia: zakładaj, że odnowienie jest co 90 dni.
- **Nieznana ścieżka pliku SQLite na `sms1` i miejsce definicji crona `backup-sms`.** Skutek: nie sprawdzisz backupu ani bazy. Do czasu ustalenia: brak.
- **Brak testów i listy zależności w repo.** Skutek: nie zweryfikujesz zmiany lokalnie ani nie odtworzysz środowiska. Do czasu ustalenia: brak opisanej procedury weryfikacji.
- **Nie ma zastępcy dla Ernesta ani drugiej osoby znającej projekt.** Skutek: gdy Ernest nie odpowiada, nie masz eskalacji. Do czasu ustalenia: brak.

## 10. Sprawdź się

### Scenariusze

1. Kolega chce wrócić do UUID jako identyfikatorów. Co mu powiesz?
   - *Klucz:* Nie. Migrację cofnięto, bo bramka obcina pole referencji do 20 znaków (D2).
2. Gdzie jest wartość tokena SMSAPI i czy deploy ją nadpisuje?
   - *Klucz:* W 1Password, sejf „Ops”, wpis „SMSAPI”. Deploy pomija `.env`, więc go nie nadpisuje.
3. Czy ponawianie 429 działa?
   - *Klucz:* W kodzie jest tylko stała `RETRY_ON`, bez logiki. Wg speca nie uruchamiano go na produkcji. Kiedy nie włączać — pakiet nie wie.
4. Po nocy z niedzieli na poniedziałek worker nie działa. Co robisz?
   - *Klucz:* Na `sms1`: `systemctl start kolejka-sms-worker`.
5. Czy możesz wdrożyć w piątek?
   - *Klucz:* Nie. W piątki się nie wdraża, bo cron `backup-sms` blokuje bazę na ok. 40 minut, a worker gubi wtedy zlecenia.
6. Bramka zwraca 401. Przyczyna i dalszy krok?
   - *Klucz:* Token SMSAPI wygasa co 90 dni; odnawia się go w panelu SMSAPI. Gdzie wpisać nowy — pakiet nie wie.
7. Czy `./deploy.sh prod` restartuje workera?
   - *Klucz:* Nie, tylko jednostkę `kolejka-sms`. Czy ręczny restart `kolejka-sms-worker` jest wymagany — pakiet nie wie.
8. Czy kod w repo wysyła SMS-y do SMSAPI?
   - *Klucz:* Nie. `app.py` nie ma endpointów, a `worker.py` tylko czeka w pętli. Spec opisuje cel, nie kod.

### Zadania praktyczne

1. Przygotuj i wdróż zmianę wielkości porcji w workerze. Opisz, co sprawdzisz po wdrożeniu.
2. Awaria trwa od 50 minut. Co robisz i kogo o tym informujesz?
3. Ustal, co faktycznie działa na `sms1` w `/srv/kolejka-sms/`, i uzupełnij sekcję 9.
