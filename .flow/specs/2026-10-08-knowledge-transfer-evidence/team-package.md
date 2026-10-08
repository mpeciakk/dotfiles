# kolejka-sms: przekazanie projektu

## 0. Jak czytać, stan na

- Stan na: 2026-10-08, commit `1519789`.
- Pakiet zawiera to, czego nie ma w repo: pułapki, objawy, kontakty. Opis projektu jest w specu.
- Sekcje 7 i 10 czytaj w całości. Sekcja 11 mówi, czego nie potwierdzono.
- Skrót `wg speca` oznacza twierdzenie ze [spec.md](../../spec.md), którego pakiet nie sprawdzał.

## 1. Co to robi

kolejka-sms przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. Pełny opis: [spec.md](../../spec.md).

## 2. Mapa systemu

Architekturę opisuje [spec.md, sekcja 2](../../spec.md). W repo są tylko:

- [app.py](../../app.py): szkielet Flaska, dwie linie.
- [worker.py](../../worker.py): stałe `BATCH = 50` i `RETRY_ON = (429,)` oraz pętla ze snem 10 s. Kodu wysyłki nie ma.
- [deploy.sh](../../deploy.sh): wdrożenie.
- [.env.example](../../.env.example): jedna zmienna, `SMSAPI_TOKEN`.

Na serwerze `sms1` działają dwie jednostki systemd: `kolejka-sms` i `kolejka-sms-worker`.

## 3. Uruchomienie i zmiany

- Wdrożenie: `./deploy.sh prod` (z [README](../../README.md)).
- Skrypt robi dwie rzeczy: rsync całego katalogu do `sms1:/srv/kolejka-sms/` z wyjątkiem `.env`, potem `systemctl restart kolejka-sms` przez ssh.
- Skrypt ignoruje argument `prod`. Każde wywołanie trafia na `sms1`.
- Skrypt nie restartuje `kolejka-sms-worker`. Czy restart `kolejka-sms` go obejmuje, nie wiadomo (sekcja 11).
- Logi: `journalctl -u kolejka-sms` (z README).
- Testów, CI ani pliku z zależnościami w repo nie ma.
- Piątek: nie wdrażaj (sekcja 7).

## 4. Decyzje i dlaczego

- D1 (SQLite zamiast Redisa) i D2 (identyfikatory całkowite zamiast UUID): [spec.md, sekcja 3](../../spec.md).
- Historia D2: migracja `76c9620`, cofnięta w `f685e0d`.
- Ponawianie przy 429: commit `42c8bd3`.

## 5. Dług i otwarte ryzyka

- Brak alertu, gdy outbox ma ponad 1000 zleceń oczekujących (wg speca).
- Ponawiania 429 nie uruchamiano na produkcji (wg speca).
- Kod nie zawiera tego, co opisuje spec (sekcja 11).

## 6. Gdzie stanąłem, jak odtworzyć środowisko

- Ostatnie zmiany w repo: ponawianie 429 (`42c8bd3`) i adnotacja w specu (`1519789`). Sprawdzenie ponawiania na produkcji pozostaje otwarte.
- Zmienna środowiskowa: `SMSAPI_TOKEN` (szablon w `.env.example`). Skąd wziąć wartość: sekcja 9.
- Aplikacja importuje Flask. Pełnej listy zależności w repo nie ma. Jak uruchomić lokalnie, nie ustalono (sekcja 11).

## 7. Pułapki i obejścia

1. **Piątek 23:00, backup.**
   - Cron `backup-sms` blokuje bazę na ok. 40 minut. Worker gubi wtedy zlecenia.
   - Obejście: w piątki nie wdrażamy.
2. **Poniedziałek po nocy z niedzieli.**
   - Serwer `sms1` restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek.
   - Worker sam nie wstaje. Objaw: zlecenia nie są wysyłane, bo wysyła je worker.
   - Obejście: `systemctl start kolejka-sms-worker`.
3. **Token SMSAPI wygasa co 90 dni.**
   - Objaw: bramka zwraca 401.
   - Token odnawia się w panelu SMSAPI. Ostatnio odnowiono go 2026-08-01.
   - Gdzie token leży: sekcja 9.
4. **UUID zamiast identyfikatorów całkowitych.**
   - Nie wprowadzaj. Bramka obcina pole referencji do 20 znaków (wg speca). Migracja została już raz cofnięta.
5. **Ponawianie przy 429.**
   - W `worker.py` jest tylko stała `RETRY_ON = (429,)`. Wg speca ponawiania nie uruchamiano na produkcji, więc jego działanie jest nieznane.
6. **Przepustowość.**
   - Paczka to 50 zleceń, pętla śpi 10 s. Limitu bramki nie znamy. Nie wyliczaj z tego SMS-ów na minutę.

## 8. Kto co wie, eskalacja

- Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem.
- Właściciela konta SMSAPI i systemów, które zgłaszają zlecenia, nie podano (sekcja 11).

## 9. Dostępy projektu

- Token SMSAPI: 1Password, sejf „Ops”, wpis „SMSAPI”.
- `deploy.sh` nie kopiuje `.env`, więc plik z tokenem leży osobno na serwerze. Jego ścieżki nie potwierdzono.
- Dostęp do `sms1` i pozostała infrastruktura firmowa: `docs.internal.animativ.dev`.

## 10. Sprawdź się

1. Kolega chce wdrożyć zmianę w piątek o 22:30. Czy może?
   - **Odpowiedź:** Nie. W piątki nie wdrażamy. O 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut i worker gubi zlecenia.
2. W poniedziałek rano zlecenia nie są wysyłane. Co sprawdzasz i robisz?
   - **Odpowiedź:** Czy `sms1` restartował się w nocy po aktualizacji jądra. Worker sam nie wstaje: `systemctl start kolejka-sms-worker`.
3. Bramka zwraca 401. Co to znaczy i gdzie szukasz rozwiązania?
   - **Odpowiedź:** Token SMSAPI wygasa co 90 dni (ostatnio odnowiony 2026-08-01). Odnawia się go w panelu SMSAPI. Token jest w 1Password, sejf „Ops”, wpis „SMSAPI”.
4. Ktoś proponuje UUID jako identyfikatory zleceń. Co odpowiadasz?
   - **Odpowiedź:** Nie. Bramka obcina pole referencji do 20 znaków (wg speca). Migracja `76c9620` została cofnięta w `f685e0d`.
5. Bramka zwróciła 429. Czy ponawianie zadziała?
   - **Odpowiedź:** Nie wiadomo. W `worker.py` jest tylko stała `RETRY_ON`. Wg speca ponawiania nie uruchamiano na produkcji.
6. Awaria trwa 50 minut. Komu i jak ją zgłaszasz?
   - **Odpowiedź:** Ernestowi, na Signalu. Nie mailem.
7. Ile SMS-ów na minutę wyśle worker?
   - **Odpowiedź:** Pakiet tego nie mówi. Paczka to 50 zleceń, pętla śpi 10 s, limitu bramki nie znamy.
8. Uruchamiasz `./deploy.sh staging`. Gdzie trafi kod?
   - **Odpowiedź:** Na `sms1:/srv/kolejka-sms/`. Skrypt ignoruje argument, więc to zawsze produkcja. `.env` nie jest kopiowany.

## 11. Luki

- **Spec a kod.** Spec opisuje tabelę outbox, pobieranie 50 zleceń co 10 s i wysyłkę do bramki. W repo tego kodu nie ma: `app.py` ma dwie linie, a `worker.py` tylko stałe i pętlę ze snem. Gdzie działa rzeczywisty kod, nie ustalono.
- **Restart workera.** Nie wiadomo, czy `systemctl restart kolejka-sms` obejmuje `kolejka-sms-worker`. Nie wiadomo też, gdzie czytać logi workera (README podaje tylko `kolejka-sms`).
- **Zaległość w kolejce.** Autor przekazania nie wie, jak dziś zauważa się zaległość przy braku alertu.
- **Odnowienie tokenu.** Nie opisano kroków odnowienia w panelu ani tego, gdzie wpisać nowy token (1Password, `.env` na `sms1`). Nie podano daty następnego odnowienia.
- **Cron backupu.** Nie podano, gdzie jest zdefiniowany `backup-sms` (przypuszczalnie `sms1`, bez potwierdzenia).
- **Restart po nocy z niedzieli.** Nie podano, czy aplikacja (`kolejka-sms`) wstaje sama po restarcie serwera.
- **Właściciele.** Nie podano właściciela konta SMSAPI ani systemów zgłaszających zlecenia.
- **Środowisko lokalne.** Nie ma listy zależności ani opisu uruchomienia lokalnego.
- **Ernest.** Nie podano kontaktu poza imieniem i kanałem (Signal). Autor przekazania jest nieosiągalny przez dwa tygodnie (stan na 2026-10-08); zastępstwa nie ustalono.
