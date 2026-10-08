# kolejka-sms: przekazanie projektu

## 0. Jak czytać

Stan na 2026-10-08, commit `1519789`. Dokument opisuje to, czego nie ma w repo: pułapki, obejścia i objawy awarii. Czytaj od sekcji 5 (pułapki), a przed poniedziałkiem przeczytaj ją w całości.

Autor przekazania jest nieosiągalny przez ok. dwa tygodnie od 2026-10-08. Wszystko, czego dokument nie wie, stoi w sekcji „Luki". Tego, co tam jest, nikt nie potwierdził.

## 1. Co to robi i dla kogo

Usługa przyjmuje zlecenia SMS przez HTTP i wysyła je przez bramkę SMSAPI, a kolejkę trzyma w SQLite. Opis, architektura i decyzje: [`spec.md`](../../spec.md).

## 2. Mapa systemu

- `app.py` (Flask) i `worker.py` w repo to szkielety. Kodu tabeli `outbox`, obsługi HTTP ani wysyłki do bramki w repo nie ma (stan na `1519789`).
- Serwer: `sms1`, katalog `/srv/kolejka-sms/`.
- Dwie jednostki systemd: `kolejka-sms` (wymienia ją README i `deploy.sh`) oraz `kolejka-sms-worker` (worker, wymieniona tylko tutaj).
- Baza: plik `outbox.db`. Jego ścieżki nie znam (Luki).

## 3. Jak zmieniać

- Wdrożenie: `./deploy.sh prod`. Skrypt kopiuje repo na `sms1:/srv/kolejka-sms/` przez rsync (bez `.env`) i restartuje `kolejka-sms`.
- Skrypt ignoruje argument `prod` i nie restartuje `kolejka-sms-worker`. Czy po wdrożeniu trzeba go restartować ręcznie, nie wiem (Luki).
- Skrypt nie blokuje wdrożeń w piątek. Pilnujesz tego sam (sekcja 5).
- Testów ani CI w repo nie ma.
- Logi: `journalctl -u kolejka-sms` (README).

## 4. Decyzje i dług

- Decyzje D1 (SQLite zamiast Redisa) i D2 (identyfikatory całkowite, bez UUID): [`spec.md`, sekcja 3](../../spec.md).
- Dług, który zna spec (sekcja 4): brak alertu przy ponad 1000 oczekujących zleceń w outboxie oraz nietestowane na produkcji ponawianie 429.
- Dług spoza specu: ręczny VACUUM raz w miesiącu i brak blokady wdrożeń w piątki.

## 5. Pułapki i obejścia

1. **W piątki nie wdrażamy.** Cron `backup-sms` o 23:00 blokuje bazę na ok. 40 minut. Worker gubi wtedy zlecenia.
2. **Po restarcie `sms1` worker nie wstaje sam.** Serwer restartuje się w nocy z niedzieli na poniedziałek po aktualizacjach jądra. Uruchom worker: `systemctl start kolejka-sms-worker`. Pierwsza rzecz w poniedziałek rano: sprawdź, czy działa.
3. **Token SMSAPI wygasa co 90 dni.** Ostatnie odnowienie: 2026-08-01. Objaw wygaśnięcia: bramka zwraca 401. Odnawia się go w panelu SMSAPI.
4. **`outbox.db` puchnie.** Raz w miesiącu ktoś robi na niej ręcznie VACUUM.
5. **Nie próbuj UUID jako identyfikatorów.** Bramka obcina pole referencji do 20 znaków, więc migrację cofnięto (commity `76c9620` i `f685e0d`).
6. **Ponawianie 429 to na razie tylko stała.** `worker.py` definiuje `RETRY_ON = (429,)`, ale żaden kod jej nie używa. Na produkcji tego nie uruchamiano.

## 6. Eskalacja: kto co wie

Autor przekazania zna całość, ale przez dwa tygodnie go nie ma. Kto jeszcze zna SMSAPI albo `sms1` i do kogo iść przy awarii bramki, nie wiem (Luki). Czas ma znaczenie: wygaśnięcie tokenu może wypaść w tym okresie (Luki).

## 7. Dostępy: gdzie, nie jakie

- Token SMSAPI: 1Password, sejf „Ops", wpis „SMSAPI".
- Panel SMSAPI: tam odnawia się token. Kto ma konto, nie wiem (Luki).
- `sms1`: `deploy.sh` łączy się przez alias SSH `sms1`. Czy kolega ma już dostęp, nie wiem.
- Firmowa baza wiedzy opisuje to według autora przekazania, ale bez linku. Nie wiem, co dokładnie tam jest (Luki).

## 8. Sprawdź się

1. Bramka zwraca 429. Co robi worker i czy to testowano na produkcji?
   > Nic z tym nie zrobi: w `worker.py` jest tylko stała `RETRY_ON = (429,)`, niewykorzystana. Na produkcji nie testowano.
2. Koleżanka proponuje UUID jako identyfikator zlecenia. Co odpowiadasz?
   > Nie: migrację cofnięto, bo bramka obcina pole referencji do 20 znaków (D2).
3. W outboxie czeka 3000 zleceń. Skąd się o tym dowiesz?
   > Z niczego: alertu nie ma (próg 1000 to punkt otwarty). Sprawdzasz ręcznie, a sposobu dokument nie opisuje.
4. Piątek, 15:00, masz gotową poprawkę. Wdrażasz?
   > Nie. W piątki nie wdrażamy, bo o 23:00 `backup-sms` blokuje bazę na ok. 40 minut i worker gubi zlecenia. Wdrożenie to `./deploy.sh prod`.
5. Poniedziałek rano, SMS-y nie wychodzą. Co sprawdzasz najpierw?
   > Czy worker działa: `sms1` mógł się zrestartować w nocy z niedzieli na poniedziałek, a worker sam nie wstaje. Start: `systemctl start kolejka-sms-worker`.
6. Bramka odpowiada 401. Co się stało i gdzie szukasz tokenu?
   > Token wygasł (ważny 90 dni, ostatnio odnowiony 2026-08-01). Odnawia się go w panelu SMSAPI. Token jest w 1Password, sejf „Ops", wpis „SMSAPI".
7. W piątek o 23:30 część zleceń zniknęła. Skąd to?
   > Cron `backup-sms` blokuje bazę ok. 40 minut od 23:00, a worker gubi wtedy zlecenia.

## 9. Luki

Nic z tej listy nie jest potwierdzone.

- **Ludzie.** Kto zastępuje autora, do kogo eskalować i kto ma konto w panelu SMSAPI: autor nie odpowiedział.
- **Firmowa baza wiedzy.** Autor napisał, że „to jest tam opisane", bez linku i bez wskazania, co.
- **Lokalizacja i schemat `outbox.db`.** Nie ma ich w repo ani w odpowiedziach. Repo nie zawiera też kodu outboxa i wysyłki, więc spec opisuje więcej, niż pokazuje kod.
- **Worker przy wdrożeniu.** `deploy.sh` restartuje tylko `kolejka-sms`. Czy `kolejka-sms-worker` wymaga ręcznego restartu po wdrożeniu, nie wiadomo.
- **Aplikacja po restarcie serwera.** Nie wiadomo, czy `kolejka-sms` wstaje sama.
- **Restarty `sms1`.** Wiadomo tylko: po aktualizacjach jądra, w nocy z niedzieli na poniedziałek. Częstotliwości nie znam.
- **VACUUM.** Nie wiadomo, kiedy był ostatni, jak go wykonać ani czy wolno go robić obok backupu.
- **Termin wygaśnięcia tokenu.** 90 dni od 2026-08-01 daje ok. 2026-10-30. To wyliczenie, nie fakt: sprawdź datę w panelu. Nie wiadomo też, kto odnawia token i gdzie wpisać nowy (1Password, plik `.env` na `sms1`).
- **Środowiska.** Czy `sms1` to jedyny serwer i czy `prod` to jedyne środowisko: bez odpowiedzi.
- **Pochodzenie D2 i 429.** Skąd wiadomo o obcinaniu do 20 znaków i czy ponawianie 429 wzięło się z konkretnego incydentu: bez odpowiedzi.
- **Limity bramki.** Nieznane. `BATCH = 50` to rozmiar paczki workera, nie limit bramki.
- **Logi workera.** README podaje `journalctl -u kolejka-sms`. Że worker loguje pod `kolejka-sms-worker`, tylko zakładam.
- **Spec a repo.** Spec (sekcja 2) nie wspomina o osobnej jednostce workera, piątkowym backupie, wygasaniu tokenu ani o VACUUM. Spec nie został zmieniony.
