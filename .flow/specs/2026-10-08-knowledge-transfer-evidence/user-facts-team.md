# Fakty użytkownika (symulacja wywiadu)

Tester odpowiada na pytania sesji wyłącznie według tej tabeli. Pytanie pasuje do faktu,
gdy zawiera którekolwiek z jego słów-kluczy (bez względu na odmianę). Kilka pasujących
faktów → podaj wszystkie. Nic nie pasuje → „nie wiem”. Prośba o akceptację
(inwentarz, pakiet, commit) → „akceptuję”. Faktów, o które nie zapytano, nie dopowiadasz.

| Fakt | Słowa-klucze | Odpowiedź |
|---|---|---|
| F1 | wdrożenie, deploy, piątek, backup, cron, kopia | W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut; worker gubi wtedy zlecenia, więc w piątki nie wdrażamy. |
| F2 | token, SMSAPI, 401, wygasa, uwierzytelnianie | Token SMSAPI wygasa co 90 dni; odnawia się go w panelu SMSAPI, ostatnio 2026-08-01. Bramka zwraca wtedy 401. |
| F3 | eskalacja, kontakt, do kogo, zgłaszać, długa awaria | Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. |
| F4 | restart, serwer, sms1, worker nie działa, aktualizacja | Serwer sms1 restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek; worker sam nie wstaje — trzeba `systemctl start kolejka-sms-worker`. |
| F5 | baza, outbox.db, rozmiar, miejsce, okresowe | outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM. |
| F6 | sekret, hasło, gdzie trzymać, gdzie leży | Token SMSAPI leży w 1Password, sejf „Ops”, wpis „SMSAPI”. |
| F7 | kto, odbiorca, poziom, umiejętności, imię | Kolega z mojego zespołu, programista Pythona; zna naszą infrastrukturę. |
| F8 | router, sieć, VPN, konto, uprawnienia, SSH, dostęp | To jest opisane w firmowej bazie wiedzy. |
| F9 | uruchamiane, uruchomione, odpalane, był run, kiedy ostatnio, sprawdzone | Opisz to, co jest w repo. |

Pytanie ogólne („pułapki”, „ryzyka”, „co się psuje”, „o czym musi wiedzieć”) bez słów-kluczy
z tabeli → F1 i F4.

Każdą odpowiedź logujesz: `turn N: „<cytat pytania>” → F<k>[, F<k>] | nie wiem | akceptuję`.
