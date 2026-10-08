# kolejka-sms: przekazanie dla supportu

## 0. Jak to czytać

Dokument dla Kasi z supportu, która od poniedziałku 12 października 2026 r. utrzymuje usługę. Zna Linuksa i SSH, nie programuje. Stan na 8 października 2026 r., commit `42c8bd3`. Tego, czego nie wiemy na pewno, szukaj w sekcji „Luki" na końcu. Sekcja „Sprawdź się" ma scenariusze do przećwiczenia.

Sekcje 1–3 przeczytaj teraz, resztę przy pierwszej awarii.

## 1. Co to robi i dla kogo

Usługa przyjmuje zlecenia wysyłki SMS i wysyła je przez bramkę SMSAPI. Pełny opis: [spec.md](../../spec.md).

## 2. Trzy rzeczy do zrobienia najpierw

1. **Poniedziałek rano:** sprawdź, czy działa worker, czyli proces wysyłający SMS-y. Serwer `sms1` restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek, a worker po restarcie sam nie wstaje. Jeśli nie działa: `systemctl start kolejka-sms-worker` na `sms1`.
2. **Przed piątkiem 30 października 2026 r.:** upewnij się, że ktoś odnowił token SMSAPI (patrz sekcja 5). Według danych z 8 października wygasa ok. 30 października.
3. **Pamiętaj, że Ernest jest nieosiągalny przez dwa tygodnie.** Zastępcy nie wyznaczono (sekcja 6 i „Luki").

## 3. Pułapki

| Pułapka | Co robić |
|---|---|
| W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut. Worker gubi wtedy zlecenia. | W piątki nie wdrażamy. |
| Serwer `sms1` restartuje się w nocy z niedzieli na poniedziałek po aktualizacjach jądra. Worker nie wstaje sam. | `systemctl start kolejka-sms-worker`. |
| Token SMSAPI wygasa co 90 dni. | Odnowienie: sekcja 5. |
| Wdrożenie (`deploy.sh`) nie przenosi pliku `.env`. | Token na serwerze jest ustawiany osobno, wdrożenie go nie zmienia. |
| Ktoś proponuje identyfikatory UUID zamiast liczb. | Nie. Bramka obcina pole referencji do 20 znaków. Migrację wdrożono 2 lipca 2026 r. i cofnięto następnego dnia (spec, decyzja D2). |
| Brak alertu, gdy w kolejce czeka ponad 1000 zleceń. | Nikt Cię nie powiadomi. Szczegóły w sekcji 4 i w „Lukach". |

## 4. Objawy awarii i jak je rozpoznać

| Objaw | Prawdopodobna przyczyna | Co robisz |
|---|---|---|
| SMS-y nie wychodzą, a w logach bramka zwraca **401** | Wygasł token SMSAPI | Sekcja 5 |
| SMS-y nie wychodzą, to poniedziałek po nocnych aktualizacjach | Worker nie wstał po restarcie serwera | `systemctl start kolejka-sms-worker` |
| SMS-y zginęły w piątek między 23:00 a ok. 23:40 | Kopia zapasowa blokowała bazę, worker gubił zlecenia | Zgłoś, które zlecenia przepadły (nie wiemy, jak je odtworzyć: „Luki") |
| W logach pojawia się **429** | Bramka prosi o zwolnienie tempa. Usługa ma ponawiać przy 429 (zmiana z 20 sierpnia 2026 r.) | 429 to nie wygasły token (ten daje 401). Jeśli SMS-y nie wychodzą dłużej niż 30 minut, eskaluj (sekcja 6) |
| Po wdrożeniu usługa działa, ale nic nie wysyła | Najpierw sprawdź workera (czy po wdrożeniu działa `kolejka-sms-worker`; czy wdrożenie go restartuje, nie wiadomo, „Luki"). Wdrożenie nie zmienia tokenu, więc token nie zniknął przez wdrożenie. Jeśli bramka zwraca 401, token po prostu wygasł | Sprawdź workera, potem logi na 401. Przy 401: sekcja 5 |
| Usługa w ogóle nie odpowiada | Proces padł | Sekcja 5, restart |

Logi usługi: `journalctl -u kolejka-sms` na `sms1`.

## 5. Runbooki

Wszystkie komendy wykonujesz na serwerze `sms1` przez SSH.

**Restart usługi:** `systemctl restart kolejka-sms`. To ta sama komenda, której używa wdrożenie. Worker to osobna jednostka: `kolejka-sms-worker`.

**Start workera:** `systemctl start kolejka-sms-worker`.

**Wdrożenie:** `./deploy.sh prod` z repozytorium. Nigdy w piątek. Czy masz wdrażać Ty, nie ustalono („Luki").

**Odnowienie tokenu SMSAPI:** token odnawia się w panelu SMSAPI. Ostatnio odnowiono go 1 sierpnia 2026 r. Co 90 dni to ok. 30 października 2026 r., a to piątek. Aktualny token leży w 1Password, sejf „Ops", wpis „SMSAPI". Kto odnawia, jak wprowadzić nowy token na serwer i czy po tym trzeba restartu: nie opisano („Luki").

**Rollback wdrożenia:** w repozytorium nie ma żadnej procedury („Luki").

## 6. Eskalacja

- **Awaria dłuższa niż 30 minut:** zgłoś Ernestowi na Signalu. Nie mailem.
- **Ernest jest nieosiągalny przez dwa tygodnie od wyjazdu.** Nikt nie jest wyznaczony na zastępstwo („Luki"). Zanim wyjedzie, ustal to z szefem.

## 7. Dostępy (gdzie, nie jakie)

| Co | Gdzie |
|---|---|
| Serwer `sms1` | SSH (dostęp Kasi: do potwierdzenia, „Luki") |
| Token SMSAPI | 1Password, sejf „Ops", wpis „SMSAPI" |
| Panel SMSAPI | konto firmowe (kto ma login: „Luki") |

## 8. Sprawdź się

Odpowiedzi poniżej. Najpierw odpowiedz sama.

1. Klient pisze, że SMS-y nie dochodzą od godziny. Co sprawdzasz i komu eskalujesz?
   - Odpowiedź: Logi (`journalctl -u kolejka-sms` na `sms1`): 401 oznacza wygasły token. Brak workera po poniedziałkowym restarcie oznacza `systemctl start kolejka-sms-worker`. Awaria ponad 30 minut: Ernest na Signalu. Ernest będzie nieosiągalny, zastępcy brak, więc to luka.
2. Programista proponuje UUID jako identyfikatory. Co odpowiadasz?
   - Odpowiedź: Nie. Bramka obcina referencję do 20 znaków. Migrację już próbowano i cofnięto (D2).
3. Po wdrożeniu usługa działa, ale nic nie wysyła. Gdzie szukasz?
   - Odpowiedź: Wdrożenie nie przenosi `.env`, a token jest ustawiany osobno. Sprawdź, czy bramka zwraca 401 (token) i czy działa worker. Token: 1Password, „Ops", „SMSAPI". Dokładne miejsce tokenu na serwerze nie jest potwierdzone.
4. W logach jest dużo 429. Czy to wygasły token?
   - Odpowiedź: Nie. Wygasły token to 401. 429 oznacza, że bramka prosi o zwolnienie, a usługa ponawia przy 429. Eskaluj, gdy SMS-y nie wychodzą ponad 30 minut.
5. Ktoś pyta, ile zleceń czeka w kolejce. Skąd to weźmiesz?
   - Odpowiedź: Pakiet tego nie mówi. Alertu przy 1000 zleceń nie ma. Sposób sprawdzenia to luka.
6. Piątek, 22:50. Trzeba wdrożyć poprawkę. Co robisz?
   - Odpowiedź: Nie wdrażasz. W piątki nie wdrażamy: o 23:00 backup blokuje bazę na ok. 40 minut, a worker gubi wtedy zlecenia.
7. Dziś 28 października. Co ważnego zbliża się w tym tygodniu?
   - Odpowiedź: Token SMSAPI wygasa ok. 30 października (piątek); ostatnio odnowiony 1 sierpnia 2026 r., 90 dni. Odnawia się go w panelu SMSAPI. Kto to robi, jest luką.

## 9. Luki

Nie wiemy tego na pewno. Do uzupełnienia, nie zgadywać.

1. **Zastępstwo za Ernesta.** Eskalacja idzie do Ernesta na Signalu, a on jest nieosiągalny przez dwa tygodnie. Pytanie o zastępcę zostało bez odpowiedzi.
2. **Odnowienie tokenu.** Data 30 października 2026 r. to wyliczenie z „90 dni" i daty 1 sierpnia, nie odczyt z panelu. Nie wiadomo, kto odnawia, jak wprowadzić token na serwer ani czy trzeba restartu. W piątek wdrożeń unikamy, a 30 października to piątek.
3. **Kto wdraża i jak cofnąć wdrożenie.** Nie ustalono, czy Kasia wdraża. W repozytorium nie ma rollbacku.
4. **Czy `deploy.sh` restartuje workera.** Skrypt restartuje tylko `kolejka-sms`. Worker to osobna jednostka `kolejka-sms-worker`.
5. **Logi workera.** README podaje tylko `journalctl -u kolejka-sms`. Czy worker loguje osobno, nie wiadomo.
6. **Długość kolejki.** Nie ma potwierdzonego sposobu sprawdzenia ani alertu (spec, punkty otwarte).
7. **Ponawianie przy 429.** W kodzie jest tylko stała. Nie wiadomo, ile razy i co przy porażce.
8. **Zlecenia zgubione w piątkowym oknie backupu.** Nie wiadomo, jak je odtworzyć ani kto o tym decyduje.
9. **Kto wysyła zlecenia.** Pytanie o systemy-klientów zostało bez odpowiedzi („Nie wiem"), więc nie wiadomo, kogo informować o awarii.
10. **Dostępy Kasi** do `sms1`, panelu SMSAPI i sejfu „Ops" nie potwierdzono.
11. **Spec kontra repo.** Spec opisuje Flaska, tabelę `outbox` i workera pobierającego do 50 zleceń co 10 sekund. W repozytorium `app.py` i `worker.py` to kilkulinijkowe szkielety bez logiki wysyłki i bez zapisu do kolejki. Albo właściwy kod leży gdzie indziej, albo spec wyprzedza repo. Spec nie wspomina też o backupie, wygasaniu tokenu ani nocnych restartach.
