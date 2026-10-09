# kolejka-sms: dokument przekazania

## 0. Jak czytać

Opisuje commit 1519789.

**Cel:** po lekturze czytelnik przejmuje utrzymanie i rozwój kolejka-sms. Wdraża zmianę na produkcję, sprawdza, czy usługa działa, i dopisuje zmianę w kodzie.

Co czytać, zależnie od potrzeby:

- **Przejęcie obsługi:** sekcje 1, 2, 3, 5, 6, 8.
- **Rozwój:** sekcje 1, 2, 3, 7 i [spec](../../spec.md).
- **Diagnoza awarii:** sekcje 6, 8, potem 2.

Sekcja 9 ("Luki") wymienia, czego pakiet nie wie. Przeczytaj ją przed pierwszym wdrożeniem.

## 1. Cel i granice

Inne systemy zgłaszają do kolejka-sms SMS-y do wysłania, wywołując jej interfejs HTTP. Usługa trzyma je w bazie SQLite i przekazuje do bramki SMSAPI, która dostarcza wiadomości.

Usługa nie ma alertów, nie ma ponawiania sprawdzonego na produkcji i nie rozdziela ruchu na kilka serwerów. Pracuje na jednym serwerze, `sms1`.

## 2. Jak to działa

Przepływ zlecenia wygląda tak (wg [speca, sekcja 2](../../spec.md#2-architektura)):

1. Klient wysyła zlecenie HTTP do procesu webowego (`app.py`, Flask).
2. Proces zapisuje zlecenie w tabeli `outbox` w SQLite.
3. Osobny proces, worker (`worker.py`), budzi się co 10 sekund. Pobiera z `outbox` do 50 zleceń i wysyła je do bramki SMSAPI.
4. Gdy bramka zwróci 429, worker ma ponowić wysyłkę. W kodzie jest na to stała `RETRY_ON = (429,)`.

Na `sms1` działają usługi systemd. Znamy dwie nazwy: `kolejka-sms-worker` (jej start jest obejściem po restarcie serwera) i `kolejka-sms` (ją restartuje skrypt wdrożenia i z niej README każe czytać logi). Który proces stoi za którą usługą i czy `kolejka-sms` obejmuje workera, nie wiadomo (sekcja 9).

Zlecenia numeruje się liczbami całkowitymi. UUID wypróbowano i wycofano: jest dłuższy, a bramka przycina referencję do 20 znaków (D2, [spec, sekcja 3](../../spec.md#3-decyzje)).

## 3. Stan projektu

- **Kod w repo to szkielet.** `app.py` zawiera tylko utworzenie obiektu Flask, bez tras. `worker.py` zawiera pętlę z `sleep(10)` oraz stałe `BATCH = 50` i `RETRY_ON = (429,)`. Nie ma w nim tabeli `outbox`, wysyłki do SMSAPI ani obsługi 429. Spec opisuje więcej, niż robi kod z tego commita. Autor nie wyjaśnił tej różnicy (sekcja 9).
- **Ponawianie 429:** wg speca nie uruchamiano go na produkcji.
- **Alert na rozmiar kolejki:** brak. Nikt nie dostaje powiadomienia, gdy `outbox` ma ponad 1000 zleceń oczekujących.
- **Testy:** repo ich nie zawiera. Nie ma też pliku z zależnościami.
- **Backup:** w piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut. W tym czasie worker gubi zlecenia.
- **Restart serwera:** `sms1` restartuje się po aktualizacjach jądra, w nocy z niedzieli na poniedziałek. Worker sam nie wstaje.

## 4. Środowisko i dostępy

- Python z Flask. Lista zależności nie jest w repo (sekcja 9).
- `rsync` i `ssh` do uruchomienia [`deploy.sh`](../../deploy.sh).
- Konfiguracja to jedna zmienna, `SMSAPI_TOKEN` (wzór: [`.env.example`](../../.env.example)). Skrypt wdrożenia pomija plik `.env`, więc nie trafia on na serwer przez wdrożenie. Gdzie dokładnie leży na `sms1`, nie potwierdzono (sekcja 9).
- Token SMSAPI leży w 1Password, w sejfie „Ops”, we wpisie „SMSAPI”.
- Dostęp do `sms1`, 1Password i panelu SMSAPI: [docs.internal.animativ.dev](https://docs.internal.animativ.dev).

## 5. Typowe zadanie krok po kroku

Zadanie: wdrożyć zmianę na produkcję i sprawdzić, że usługa działa.

1. **Sprawdź dzień.** W piątki nie wdrażamy (backup o 23:00 blokuje bazę). Sukces: dziś nie jest piątek.
2. **Porównaj `/srv/kolejka-sms/` na `sms1` z repo, zanim uruchomisz skrypt.** Skrypt nadpisuje tam pliki obecne w repo. Repo zawiera szkielet, więc gdy na `sms1` leży pełniejszy kod, wdrożenie go zastąpi (sekcja 9, pierwszy bloker). Sukces: wiesz, że pliki na serwerze nie są nowsze niż w repo.
3. **Uruchom `./deploy.sh prod`** na maszynie operatora, w katalogu repo. Skrypt kopiuje pliki na `sms1:/srv/kolejka-sms/` (z wyjątkiem `.env`) i restartuje usługę `kolejka-sms`. Sukces: skrypt kończy się bez błędu.
4. **Sprawdź logi** na `sms1`: `journalctl -u kolejka-sms`. Sukces: brak błędów po restarcie.
5. **Sprawdź workera** na `sms1`: `systemctl status kolejka-sms-worker`. Sukces: stan `active`. Gdy usługa nie działa, uruchom ją: `systemctl start kolejka-sms-worker`.

Po każdej nocy z niedzieli na poniedziałek po aktualizacji jądra wykonaj krok 5. Wtedy worker nie wstaje sam.

## 6. Awarie i obejścia

| Objaw | Przyczyna | Obejście |
|---|---|---|
| Bramka zwraca 401 | Token SMSAPI wygasa co 90 dni. Datę wygaśnięcia pokazuje panel SMSAPI. | Odnów token w panelu SMSAPI i zapisz nowy w 1Password. Stosuj, gdy masz dostęp do panelu. Jak nowy token trafia do `.env` na `sms1`, nie wiemy (sekcja 9). Gdy nie masz dostępu do panelu, zgłoś awarię zgodnie z sekcją 8. |
| SMS-y nie wychodzą po nocy z niedzieli na poniedziałek | `sms1` zrestartował się po aktualizacji jądra, a worker nie wstaje sam. | Na `sms1` wykonaj `systemctl start kolejka-sms-worker`. Stosuj, gdy `systemctl status` pokazuje, że worker nie działa. Gdy worker znów się zatrzyma, nie powtarzaj startu w pętli. Zajrzyj w logi i zgłoś awarię. |
| Zlecenia z piątkowej nocy zniknęły | Backup (`backup-sms`, piątek 23:00, ok. 40 minut) blokuje bazę, a worker w tym czasie gubi zlecenia. | Brak znanego obejścia ani sposobu odzyskania zleceń (sekcja 9). Backup działa w piątki niezależnie od wdrożeń. |
| Bramka ucina referencję zlecenia | Pole referencji ma w bramce 20 znaków. | Używaj identyfikatorów całkowitych, nie UUID (D2). |
| Odpowiedź 429 z bramki | Kod zawiera tylko stałą `RETRY_ON = (429,)`. Wg speca ponawiania 429 nie uruchamiano na produkcji. | Nie zakładaj, że ponawianie działa. Zgłoś problem, gdy zlecenia przepadają po 429. |
| `outbox` rośnie ponad 1000 zleceń | Alertu nie ma. | Brak znanego sposobu sprawdzenia (sekcja 9). |

## 7. Rozwój

Przykład: zmiana rozmiaru paczki workera.

1. Zmień `BATCH` w [`worker.py`](../../worker.py). Paczka 50 to rozmiar wysyłki workera, a nie limit bramki. Limitu bramki pakiet nie zna.
2. Repo nie ma testów. Test zmiany trzeba przygotować samemu, a zakres sprawdzenia na produkcji lub w środowisku testowym ustalić z zespołem (sekcja 9).
3. Wdróż zgodnie z sekcją 5, nie w piątek.

Decyzje: D1 (SQLite zamiast Redisa) i D2 (identyfikatory całkowite) są w [specu, sekcja 3](../../spec.md#3-decyzje). Nie zmieniaj ich bez powodu. D2 wynika z ograniczenia bramki, a D1 z jednego serwera.

## 8. Kto co wie

- **Awarie dłuższe niż 30 minut** zgłasza się Ernestowi na Signalu, nie mailem.
- **Dostępy, 1Password, serwer `sms1`:** [docs.internal.animativ.dev](https://docs.internal.animativ.dev).
- **Odnowienie tokenu SMSAPI:** wg autora opisane w tej bazie wiedzy.
- **Zastępca Ernesta, właściciel konta SMSAPI i inne osoby znające projekt:** nieznani (sekcja 9).

## 9. Luki

Blokery:

- **Kod w repo to szkielet, a spec opisuje działającą usługę.** Skutek: nie wiadomo, gdzie jest rzeczywisty kod (inna gałąź, inne repo, serwer `sms1`) i co dokładnie działa na produkcji. Do czasu ustalenia: wdrażaj tylko zmiany z tego repo po sprawdzeniu zawartości `/srv/kolejka-sms/` na `sms1`, bo `deploy.sh` nadpisuje pliki z repo.
- **Nie wiemy, czy restart `kolejka-sms` obejmuje workera (`kolejka-sms-worker`).** Skutek: po wdrożeniu worker może dalej działać na starym kodzie. Do czasu ustalenia: po każdym wdrożeniu sprawdź `systemctl status kolejka-sms-worker`.
- **Brak sposobu na liczbę zleceń oczekujących w `outbox`.** Skutek: nie sprawdzisz progu 1000 ani nie ocenisz skutków backupu. Nie znamy ścieżki pliku SQLite ani komendy. Do czasu ustalenia: poproś autora o ścieżkę albo znajdź ją w konfiguracji na `sms1`.

Pozostałe:

- **Docelowe zachowanie ponawiania 429 jest nieznane** (liczba prób, odstęp, co robić po ich wyczerpaniu). Skutek: nie zaimplementujesz ani nie sprawdzisz ponawiania. Do czasu ustalenia: potraktuj ponawianie jako niedziałające.
- **Nie wiemy, jak nowy token SMSAPI trafia na `sms1`.** Znamy tylko miejsce zapisu w 1Password. Skutek: po odnowieniu tokenu nie wiesz, co zmienić na serwerze. Do czasu ustalenia: sprawdź `.env` na `sms1` (zmienna `SMSAPI_TOKEN`) i zapytaj autora.
- **Brak sposobu odzyskania zleceń zgubionych podczas backupu.** Skutek: utracone zlecenia przepadają. Do czasu ustalenia: zakładaj, że zlecenia z okna backupu (piątek 23:00, ok. 40 minut) mogą przepaść, i zgłoś to nadawcom zleceń.
- **Nieznana jest lokalizacja crona `backup-sms`** i to, czy da się przesunąć jego okno. Skutek: nie zmienisz godziny backupu. Do czasu ustalenia: planuj pracę z oknem piątek 23:00 (ok. 40 minut).
- **Brak listy zależności i testów.** Skutek: środowisko lokalne budujesz po omacku. Do czasu ustalenia: zacznij od Pythona i Flask, resztę dopisz z kodu na `sms1`.
- **Właściciel konta SMSAPI, zastępca Ernesta i inne osoby znające projekt nie zostały wskazane.** Skutek: gdy Ernest jest niedostępny, awarie dłuższe niż 30 minut nie mają adresata, a nie wiesz, kto odnawia token poza Twoim dostępem. Do czasu ustalenia: sprawdź w docs.internal.animativ.dev, a o zastępcę zapytaj przełożonego.
- **Limit przepustowości bramki SMSAPI jest nieopisany.** Rozmiar paczki 50 to wartość z kodu, a nie limit bramki. Skutek: nie wiesz, o ile możesz zwiększyć `BATCH`. Do czasu ustalenia: nie zmieniaj `BATCH` bez uzgodnienia z zespołem.
- **Nie wiadomo, czy logi workera są w `journalctl -u kolejka-sms`, czy w osobnej usłudze (`kolejka-sms-worker`).** Skutek: możesz nie zobaczyć błędów workera. Do czasu ustalenia: sprawdzaj oba polecenia: `journalctl -u kolejka-sms` i `journalctl -u kolejka-sms-worker`.

## 10. Sprawdź się

### Scenariusze

1. Ktoś proponuje UUID jako identyfikator zlecenia. Co odpowiadasz?
   **Odpowiedź:** Nie. Bramka obcina referencję do 20 znaków, więc identyfikatory są całkowite (D2, cofnięta migracja).
2. W piątek o 15:00 chcesz wdrożyć poprawkę. Robisz to?
   **Odpowiedź:** Nie. W piątki nie wdrażamy: o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut i worker gubi zlecenia.
3. W poniedziałek rano SMS-y nie wychodzą. Co sprawdzasz najpierw?
   **Odpowiedź:** Czy worker działa (`systemctl status kolejka-sms-worker` na `sms1`). Po nocy z niedzieli na poniedziałek po aktualizacji jądra sam nie wstaje. Start: `systemctl start kolejka-sms-worker`.
4. Bramka zwraca 401. Skąd się to bierze i gdzie szukasz tokenu?
   **Odpowiedź:** Token SMSAPI wygasa co 90 dni. Odnawia się go w panelu SMSAPI. Token leży w 1Password, sejf „Ops”, wpis „SMSAPI”. Jak trafia na serwer, pakiet nie wie.
5. Działa ponawianie 429 na produkcji?
   **Odpowiedź:** Pakiet nie wie. Wg speca nie uruchamiano go na produkcji, a w kodzie jest tylko stała. (Zalicza `NIE WIEM Z PAKIETU`.)
6. Ile zleceń czeka w `outbox`? Jak to sprawdzić?
   **Odpowiedź:** Pakiet nie zna komendy ani ścieżki pliku SQLite. (Zalicza `NIE WIEM Z PAKIETU`.)
7. Awaria trwa 45 minut. Komu i jak ją zgłaszasz?
   **Odpowiedź:** Ernestowi, na Signalu, nie mailem (awarie dłuższe niż 30 minut).
8. Czy `./deploy.sh prod` restartuje workera?
   **Odpowiedź:** Pakiet nie wie. Skrypt restartuje usługę `kolejka-sms`. Czy obejmuje ona workera, nie wiadomo. (Zalicza `NIE WIEM Z PAKIETU`.)

### Zadania praktyczne

1. Wdróż zmianę `BATCH` na produkcję zgodnie z sekcją 5 i potwierdź, że worker działa.
2. Po nocy po aktualizacji jądra sprawdź, czy kolejka-sms działa, i przywróć workera, jeśli stoi.
3. Przygotuj plan odnowienia tokenu SMSAPI i wskaż, co trzeba ustalić przed jego wykonaniem.
