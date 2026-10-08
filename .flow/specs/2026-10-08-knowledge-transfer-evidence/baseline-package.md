# kolejka-sms — przekazanie projektu

Od poniedziałku 12 października 2026 r. utrzymuje to Kasia (support). Dokument zakłada, że Kasia zna Linuksa i SSH, ale nie programuje. Opisuje to, co potwierdza repo i poprzedni opiekun. Luki są w sekcji 9.

## 1. Pierwsze, co robisz w poniedziałek

Serwer `sms1` restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek. Worker po restarcie sam nie wstaje, więc SMS-y mogą stać od nocy.

1. Połącz się: `ssh sms1`.
2. Sprawdź worker: `systemctl status kolejka-sms-worker`.
3. Jeśli nie działa, uruchom go: `systemctl start kolejka-sms-worker`.
4. Sprawdź, że wysyła: `journalctl -u kolejka-sms-worker -n 50`.

Powtarzaj to w każdy poniedziałek rano.

## 2. Co to jest

Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. Zlecenia czekają w kolejce w bazie SQLite (`outbox.db`, tabela `outbox`).

## 3. Jak to działa

- `app.py` (Flask) przyjmuje zlecenia i zapisuje je do `outbox`. Działa jako usługa `kolejka-sms`.
- `worker.py` co 10 sekund pobiera do 50 zleceń i wysyła je do bramki. Działa jako osobna usługa `kolejka-sms-worker`.
- Gdy bramka odpowie kodem 429 (za dużo zapytań), worker ponawia wysyłkę.
- Limit przepustowości: 50 SMS-ów na 10 sekund, czyli ok. 300 na minutę. Dłuższa kolejka czeka.

## 4. Gdzie to działa

- Serwer: `sms1`, katalog `/srv/kolejka-sms/`.
- Token bramki: zmienna `SMSAPI_TOKEN` w pliku `.env` na serwerze. Plik nie jest w repo i `deploy.sh` go nie kopiuje.
- Źródło tokenu: 1Password, sejf „Ops”, wpis „SMSAPI”. Nie wklejaj tokenu do czatu, maila ani repo.

## 5. Codzienne czynności

1. Logi aplikacji: `ssh sms1 journalctl -u kolejka-sms`.
2. Logi workera: `ssh sms1 journalctl -u kolejka-sms-worker`. Dodaj `-f`, żeby śledzić na żywo.
3. Stan usług: `ssh sms1 systemctl status kolejka-sms kolejka-sms-worker`.
4. Restart: `ssh sms1 systemctl restart kolejka-sms` (lub `kolejka-sms-worker`).
5. Wdrożenie: `./deploy.sh prod` z katalogu repo. Skrypt kopiuje pliki na `sms1` (bez `.env`) i restartuje usługę `kolejka-sms`.

`deploy.sh` restartuje tylko `kolejka-sms`, nie worker. Zmiana w `worker.py` zadziała dopiero po `systemctl restart kolejka-sms-worker`. To wniosek z treści skryptu. Potwierdź go przy pierwszym wdrożeniu.

## 6. Zadania cykliczne

| Kiedy | Co | Co zrobić |
|---|---|---|
| Piątek 23:00 | Cron `backup-sms` blokuje bazę na ok. 40 minut. Worker gubi wtedy zlecenia. | **W piątki nie wdrażaj.** Nie restartuj usług i nie rób VACUUM w tym oknie. |
| Co 90 dni | Token SMSAPI wygasa. Bramka zwraca wtedy kod 401. | Odnów token w panelu SMSAPI, wpisz nowy do 1Password i do `.env` na `sms1`, zrestartuj `kolejka-sms-worker`. Ostatnie odnowienie: 1 sierpnia 2026 r. Następne wygasa **30 października 2026 r. (piątek)**. Odnów go wcześniej, najlepiej w środę 28 października. |
| Co miesiąc | `outbox.db` puchnie. | Ręczne `VACUUM` na bazie. |
| Noc niedziela → poniedziałek | Restart `sms1` po aktualizacjach jądra. | Uruchom worker (sekcja 1). |

Jeśli w logach pojawia się masowo kod 401, token wygasł. To pierwsza rzecz do sprawdzenia przy awarii wysyłki.

## 7. Awarie

Awarię dłuższą niż 30 minut zgłaszasz Ernestowi na Signalu. Nie mailem.

## 8. Decyzje w mocy i znane problemy

Pełna lista decyzji jest w `spec.md`. Dwie najważniejsze:

- **SQLite zamiast Redisa.** Jeden serwer, bez dodatkowej usługi do utrzymania.
- **Identyfikatory całkowite, nie UUID.** Migrację na UUID cofnięto, bo bramka obcina pole referencji do 20 znaków. Nie wracaj do UUID bez sprawdzenia tego limitu.

Znane problemy:

- Nic nie alarmuje, gdy w `outbox` czeka ponad 1000 zleceń. Do czasu dodania alertu sprawdzaj długość kolejki ręcznie.
- Podczas piątkowego backupu worker gubi zlecenia (sekcja 6).
- Worker po restarcie serwera nie startuje sam (sekcja 1).

Uwaga o stanie kodu: na dziś `app.py` tworzy tylko obiekt Flask, a `worker.py` ma stałe `BATCH` i `RETRY_ON` oraz pętlę z `sleep(10)`. Opis w sekcji 3 pochodzi ze `spec.md`. Repo nie zawiera jeszcze logiki, którą ten opis zakłada.

## 9. Do uzupełnienia przed przekazaniem

Tego nie da się ustalić z repo ani z dotychczasowych ustaleń.

1. **Dostęp SSH** do `sms1`: kto go nadaje Kasi i do kiedy?
2. **Dostęp do 1Password** (sejf „Ops”) i do panelu SMSAPI: kto je nadaje? Bez nich Kasia nie odnowi tokenu 30 października.
3. **Ścieżka `outbox.db`** na serwerze, gotowe polecenie `VACUUM` i zapytanie liczące zlecenia oczekujące.
4. **Kontakt na czas nieobecności**: Ernest na Signalu — czy jest osiągalny w tych dwóch tygodniach? Jeśli nie, kto go zastępuje?
5. **Zakres**: co Kasia robi sama (restart, logi, token, VACUUM), a co eskaluje.
