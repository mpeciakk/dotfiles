# kolejka-sms: przekazanie dla Kasi (support)

## 0. Jak to czytać

Stan na 8 października 2026, repozytorium na commicie `42c8bd3`. Dokument opisuje to, czego nie widać w kodzie. Po zmianach w repo lub na serwerze może być nieaktualny.

Oznaczenia: zdanie bez dopisku pochodzi od Ernesta albo z repo. Dopisek „(niepotwierdzone)" znaczy, że wniosek wyciągnięto z kodu i nikt go nie sprawdził. Czego nie wiadomo, stoi w sekcji „Luki" na końcu.

Od poniedziałku utrzymujesz usługę. Cel: wiesz, jak ją wdrożyć, jak rozpoznać typową awarię i kiedy wołać Ernesta.

## 1. Co to robi i dla kogo

Usługa przyjmuje zlecenia SMS przez HTTP i wysyła je przez bramkę SMSAPI. Zlecenia czekają w kolejce w bazie SQLite, a worker wysyła je paczkami. Pełny opis: [spec.md](../../spec.md).

## 2. Objawy awarii i co robić

| Objaw | Przyczyna | Działanie |
|---|---|---|
| W poniedziałek rano SMS-y nie wychodzą | Serwer `sms1` restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek. Worker sam nie wstaje. | Uruchom workera: `systemctl start kolejka-sms-worker` |
| Bramka zwraca błąd 401 | Token SMSAPI wygasł. Wygasa co 90 dni. | Odnów token w panelu SMSAPI (patrz sekcja 4) |
| Brakuje SMS-ów z piątkowej nocy po 23:00 | Cron `backup-sms` blokuje bazę na ok. 40 minut. Worker gubi wtedy zlecenia. | Nic nie naprawisz w trakcie. Jak odzyskać zgubione zlecenia, nie wiadomo (Luki) |
| Bramka zwraca błąd 429 | Bramka odrzuca część żądań. Worker ponawia wysyłkę po 429. | Ile razy i jak często, nie wiadomo (Luki) |
| Kolejka rośnie | Brak alertu przy ponad 1000 zleceń oczekujących (spec.md, punkty otwarte). Nikt cię nie powiadomi. | Jak sprawdzić długość kolejki, nie wiadomo (Luki) |

Logi: `journalctl -u kolejka-sms`. Dla workera analogicznie `journalctl -u kolejka-sms-worker` (niepotwierdzone).

## 3. Wdrożenie

1. Nie wdrażaj w piątki. W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut, a worker gubi wtedy zlecenia.
2. Z katalogu repo uruchom `./deploy.sh prod`.
3. Skrypt kopiuje pliki na serwer `sms1` do `/srv/kolejka-sms/`, pomija plik `.env` i restartuje usługę `kolejka-sms`.

Argument `prod` nic nie zmienia: skrypt go nie czyta i zawsze wdraża na `sms1`. README opisuje to tak, jakby argument wybierał środowisko.

Worker to osobna usługa, `kolejka-sms-worker`. Skrypt jej nie restartuje (niepotwierdzone, czy restart `kolejka-sms` ją pociąga). Po wdrożeniu sprawdź, czy worker działa.

Rollback: nie opisano (Luki).

## 4. Token SMSAPI

- Token wygasa co 90 dni. Odnawia się go w panelu SMSAPI.
- Ostatnio odnowiony 1 sierpnia 2026. Z tej daty wychodzi wygaśnięcie około 30 października 2026 (wyliczone, niepotwierdzone). Sprawdź datę w panelu.
- Po wygaśnięciu bramka zwraca 401 i SMS-y nie wychodzą.
- Co zrobić z nowym tokenem po odnowieniu, nie opisano. Wg repo token trafia do zmiennej `SMSAPI_TOKEN` z pliku `.env`, a deploy tego pliku nie kopiuje (Luki).

## 5. Pułapki

- Piątek, 23:00: backup blokuje bazę, zlecenia przepadają. W piątki nie wdrażamy.
- Noc z niedzieli na poniedziałek: po restarcie serwera uruchom workera ręcznie.
- Identyfikatory zleceń zostają liczbami całkowitymi. Migrację na UUID cofnięto (commit `f685e0d`), bo bramka obcina pole referencji do 20 znaków. Jeśli ktoś proponuje UUID, odpowiedź brzmi: nie.
- `./deploy.sh prod` nie sprawdza środowiska ani dnia tygodnia. Pilnujesz tego sama.

## 6. Eskalacja

Uwaga: przez pierwsze dwa tygodnie po przekazaniu Ernest jest nieosiągalny, a zastępcy nie wskazano (Luki). Zasada poniżej dotyczy czasu, gdy Ernest jest dostępny.

Awarie dłuższe niż 30 minut zgłaszasz Ernestowi na Signalu, nie mailem.

## 7. Dostępy: gdzie, nigdy jakie

- Panel SMSAPI: odnowienie tokenu. Kto ma login, nie wiadomo (Luki).
- Serwer `sms1` przez SSH (nazwa hosta z `deploy.sh`). Czy masz dostęp, nie wiadomo (Luki).
- Token: wg repo w pliku `.env` na serwerze. Kopia i jej miejsce: nie podano (Luki). Nigdy nie wklejaj wartości tokenu do repo, maila ani czatu.

## 8. Sprawdź się

1. We wtorek masz wdrożyć poprawkę. Co robisz?
   **Odpowiedź:** Z katalogu repo `./deploy.sh prod`. Skrypt kopiuje pliki na `sms1`, pomija `.env`, restartuje `kolejka-sms`. Potem sprawdzasz workera.
2. W piątek o 22:30 szef prosi o pilny deploy.
   **Odpowiedź:** Nie wdrażasz. O 23:00 backup blokuje bazę na ok. 40 minut, a worker gubi zlecenia.
3. W poniedziałek rano SMS-y nie wychodzą, a serwer restartował się w nocy.
   **Odpowiedź:** `systemctl start kolejka-sms-worker`.
4. W logach bramka zwraca 401.
   **Odpowiedź:** Token SMSAPI wygasł (co 90 dni, ostatnio 1 sierpnia 2026). Odnawiasz go w panelu SMSAPI. Dalszy krok z nowym tokenem nie jest opisany.
5. Awaria trwa 40 minut. Komu ją zgłaszasz i jak?
   **Odpowiedź:** Ernestowi na Signalu, nie mailem. Ernest jest jednak nieosiągalny dwa tygodnie, a zastępcy brak.
6. Programista proponuje zmianę identyfikatorów na UUID.
   **Odpowiedź:** Nie. Bramka obcina referencję do 20 znaków. Migrację już raz cofnięto.
7. Klient pyta, czemu nie dostał SMS-a zleconego w piątek o 23:15.
   **Odpowiedź:** Piątkowy backup o 23:00 blokuje bazę na ok. 40 minut, a worker gubi wtedy zlecenia.

## 9. Luki

Nikt nie odpowiedział na te pytania, więc dokument ich nie rozstrzyga:

1. Kto zastępuje Ernesta przez dwa tygodnie nieobecności.
2. Jak sprawdzić długość kolejki i co robić, gdy rośnie ponad 1000.
3. Jak wygląda rollback po nieudanym wdrożeniu.
4. Gdzie jest kopia tokenu SMSAPI, kto ma login do panelu, czy masz SSH na `sms1` i jak wprowadzić odnowiony token na serwer.
5. Czy wolno ci wdrażać kod, czy tylko restartować i monitorować.
6. Ile razy i z jakim odstępem worker ponawia po 429.
7. Jak odzyskać zlecenia zgubione w piątkowym oknie backupu.
8. Czy restart `kolejka-sms` restartuje też workera oraz czy serwer restartuje się co tydzień, czy tylko po aktualizacjach jądra.
9. Na którym serwerze działa cron `backup-sms`.
10. Spec opisuje tabelę `outbox` i wysyłkę przez workera. W repo `app.py` to szkielet Flaska bez tras, a `worker.py` tylko śpi w pętli. Czy tu leży prawdziwy kod usługi, nie wiadomo.
