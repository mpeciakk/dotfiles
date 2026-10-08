# Skill knowledge-transfer: zakres firmowy (2026-10-08)

Dotfiles nie mają żywego `spec.md`, więc ten rekord niesie decyzję i deliberację. Zmienia D29 i D30 z `2026-10-08-knowledge-transfer-design.md`.

Źródło zmiany: pierwszy prawdziwy przebieg skilla, czyli KT dla `~/work/edge-vibecoding` (sesja `fe78e66c`, 2026-10-08). Użytkownik wskazał w nim pięć błędów:

- każde KT dotyczy repo firmowego;
- pakiet ma opisywać fakty, a nie dopytywać, kiedy i jak coś uruchamiano;
- nie ma dopytywać o dostęp do routera i podobne rzeczy, bo opisuje je firmowa dokumentacja;
- odbiorca to zawsze inny pracownik firmy;
- zamiast profili ma być jeden odbiorca, czyli pracownik albo ja później.

Z 11 pytań wywiadu 6 dotyczyło infrastruktury firmowej albo historii uruchomień.

## Decyzje

| # | Decyzja | Odrzucone warianty i dlaczego |
|---|---|---|
| D31 | **KT dotyczy zawsze repo firmowego Animativ. Odbiorca to pracownik firmy albo autor później.** Jest jeden odbiorca, bez profili, bez trybu `temat` i bez pytania o imię. Wywiad nie pyta o infrastrukturę firmową (sieć, router, konta, dostępy, password manager): pakiet ma na nią jedną linię z odesłaniem do bazy wiedzy `docs.internal.animativ.dev`. Wywiad nie pyta też o historię uruchomień. Pakiet opisuje mechanizm tak, jak stoi w kodzie, a twierdzenia speca o tym, co sprawdzono, cytuje jako twierdzenia speca. Cold-reader zawsze na Sonnecie. Zmienia D29 (profile, tryby, macierz sekcji) i model z D30. | **Skill przeszukuje `~/work/knowledge-base`** i linkuje stronę albo wpisuje brak do „Luk”: linki nie prowadziłyby donikąd, ale każde KT kosztowałoby więcej pracy. Użytkownik wybrał „poza zakresem”, bo luki w bazie wiedzy to robota dla bazy wiedzy. Na dziś (2026-10-08) baza ma pod `infrastruktura/` tylko Cloudflare, więc część odesłań nie trafi jeszcze w treść. **Pytanie tylko o dostępy projektowe**: granica „projektowe czy firmowe” jest rozmyta; RPi labu z edge-vibecoding to firmowy sprzęt. **Profile z domyślnym `następca`**: różnica między następcą a autorem później nie uzasadnia macierzy, a `support` nie występuje w praktyce. **Zostawienie trybu `temat`**: każde KT dotyczy firmowego repo. **Zostawienie pytań o historię uruchomień**: w edge-vibecoding takie pytanie złapało nieprawdę w specu. Spec w §13.2 p.13 mówił „nie uruchomione”, a użytkownik odpowiedział „Działa, sprawdzone”. Użytkownik przyjął ten koszt świadomie: pakiet oznacza takie twierdzenia jako twierdzenia speca, zamiast je potwierdzać. |

## Poza zakresem

- Uzupełnianie firmowej bazy wiedzy o sieć biura, router i dostępy. To osobna robota w `~/work/knowledge-base`.
- Zmiany w agencie `kt-cold-reader` poza wyborem modelu przy dispatchu.

## Weryfikacja

Dotychczasowy dowód GREEN (`2026-10-08-knowledge-transfer-evidence/green.md`) testował profil `support`, który ta decyzja usuwa. Nowy przebieg:

- harness ze scenariuszem „projekt przejmuje kolega z zespołu” na tym samym fixture `kolejka-sms` (ma `sms1`, SSH i 1Password „Ops” jako przynętę na pytania o infrastrukturę);
- checker 6/6;
- przeczytany transkrypt: zero pytań o infrastrukturę firmową i o historię uruchomień.

Po merge'u prawdziwym testem jest ponowne KT dla `edge-vibecoding`.
