# Skill knowledge-transfer: stan projektu i jak działa (2026-10-09)

Dotfiles nie mają żywego `spec.md`, więc ten rekord niesie decyzję i deliberację. Zmienia D29 z `2026-10-08-knowledge-transfer-design.md` (teza „snapshot tego, czego repo nie mówi”, sekcje, reguła „linkuj zamiast streszczać”). D31 z `2026-10-08-kt-company-scope-design.md` zostaje w mocy.

Źródło zmiany: KT dla `~/work/edge-vibecoding` zrobione skillem po D31 (`docs/kt/2026-10-08.md` w tamtym repo, sesja `cdb2abff`). Użytkownik ocenił je tak:

- dokument ma dużo spraw „tu i teraz” z datami, a z definicji ma opisywać aktualny stan projektu;
- z samego dokumentu ma się dać zrozumieć, jak projekt działa, bez grzebania w repo, na płaskim poziomie;
- dokument nie zależy od maszyny ani od osoby: zrozumie go każdy pracownik, nie jest przypięty do setupu autora.

Do tego doszły uwagi recenzenta z sesji astra6 (siedem punktów i ocena ogólna).

## Decyzje

| # | Decyzja | Odrzucone warianty i dlaczego |
|---|---|---|
| D32 | **Pakiet KT to jeden dokument, z którego pracownik firmy rozumie, jak projekt działa i w jakim jest stanie, i umie wykonać cel z intake.** Opis jest płaski, własnymi słowami, z linkami w głąb. Spec zostaje źródłem prawdy. **Czas:** plik `docs/kt/YYYY-MM-DD.md` i jedna linia z SHA w sekcji 0. Poza nią w treści nie ma dat, wyników przebiegów testów, opisów runów ani stanu maszyny autora. Twierdzenie speca o tym, co niesprawdzone, wchodzi jako stan bez daty. **Niezależność:** w treści nie ma nazw maszyn autora, jego ścieżek domowych, wersji narzędzi „u mnie”, osobistych narzędzi autora jako kontekstu ani adresata-osoby. Fakty o ludziach jako stan projektu („projekt zna tylko autor”) są dozwolone. **Sekcje** idą od normalnego przebiegu do wyjątków: jak czytać → cel i granice → jak to działa → stan projektu → środowisko i dostępy → typowe zadanie krok po kroku (z miejscem wykonania) → awarie i obejścia (z warunkiem stosowania i przerwania) → rozwój (przykład typowej zmiany) → kto co wie → luki (blokery najpierw, przy każdej skutek i „do czasu ustalenia rób Z”) → sprawdź się (scenariusze dla cold readu i 2–3 zadania praktyczne). Linki względne, klikalne. Wywiad dopytuje też o kroki typowego zadania, których repo nie opisuje. | **Plik bez daty (`docs/KT.md`) albo bez pinu SHA:** bez pinu czytelnik po kilku miesiącach nie odróżni opisu od rzeczywistości, a data w nazwie pliku nie jest datą w treści. **Referencyjny run** (katalog runu, logi, wersje narzędzi z akceptacji, astra6 p.3): to historia, sprzeczna z opisem stanu. **Poziomy weryfikacji przy każdej części** (sprzęt / atrapy / niesprawdzone): dubluje „stan projektu” i ciągnie wywiad w stronę historii runów, którą D31 wyłączył. **Osoba odpowiedzialna i warunek zamknięcia KT przy luce** (astra6 p.1): robi z pakietu listę zadań autora, czyli błąd „Handed the remaining work back”. **„Skąd i jako kto połączyć się z RPi”** (astra6 p.2): infrastruktura firmowa, D31 kieruje ją do `docs.internal.animativ.dev`. **Obserwacja przejęcia przez autora** (astra6 p.7): to proces poza dokumentem; zadania praktyczne zostają w pakiecie. **Osobny `template.md` ze szkieletem pakietu:** D29 odrzucił takie rozbicie, a przy jednym odbiorcy nic nie daje. **Prosty język dla osób nietechnicznych:** „każdy” oznacza dowolnego pracownika technicznego; profil `support` odpadł w D31. |

## Poza zakresem

- Poprawki treści konkretnego KT edge-vibecoding (klucze publiczne w `authorized_keys`, tagi repo frameworka a repo runu, warunek „usuń katalog”). Pokrywa je ponowne KT nowym skillem.
- Zmiany w agencie `kt-cold-reader`.

## Weryfikacja

- RED: istniejący `2026-10-08-knowledge-transfer-evidence/team-package.md`, czyli wynik skilla sprzed D32 na fixture `kolejka-sms`. Nowy run RED nie jest potrzebny.
- GREEN: jeden run nowego skilla na tym samym fixture, przez tymczasowy `CLAUDE_CONFIG_DIR` bez osobistej kopii skilla (pułapka opisana w `stream-format.md`). Checker 6/6. Do tego:
  - zero dat poza linią z SHA;
  - sekcje w nowej kolejności;
  - każda luka ma skutek i postępowanie;
  - brak nazw hostów, ścieżek `/home/<user>` i opisu setupu autora;
  - czytaniem: „jak to działa” daje się zrozumieć bez repo.
- Prawdziwy test po merge'u: ponowne KT dla edge-vibecoding.
