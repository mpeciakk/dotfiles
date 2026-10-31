# Przegląd setupu Claude Code – 31.10.2026 (pc)

## Werdykt

Setup jest przerośnięty w dwóch miejscach: w implementacji przez osobnego subagenta na każde zadanie i w obowiązkowym test-first. Review gałęzi w świeżym kontekście znalazło w cinemancerze najwięcej bugów (18 z 27) i warto go zostawić. Pewność: średnia. Dane własne obejmują jeden projekt i 5 dni, a research to głównie preprinty i dane dostawcy. Zdanie zmieniłby pomiar parami: ta sama klasa zadania zrobiona jedną sesją daje więcej commitów `fix` w ciągu 7 dni niż pipeline.

## 1. Dane własne

### Cinemancer: testy

Projekt powstał między 27 a 31.10.2026. W tym czasie: 133 commity, 1941 testów, ok. 10 tys. wierszy kodu i ok. 18,8 tys. wierszy testów.

Klasyfikacja 251 przebiegów z porażką testów w 61 transkryptach:

| klasa | przypadki |
|---|---|
| czerwona faza TDD na nowych testach | 104 |
| złapana regresja (istniejący test, poprawiony kod) | **2**, obie to pomyłki subagenta naprawione w tej samej minucie |
| istniejący test przepisany pod zamierzoną zmianę | 21 przypadków, ok. 49 testów w 5 dni |
| niestabilne testy lub środowisko | 16, z czego 13 przez jeden test zegarowy (`Deck.reduced` „≤300 ms”) |
| celowe mutacje przez agenta | 21 |

Commity `fix`: 27 z 29 naprawia bug, który przeszedł przez zielone testy. 18 z nich znalazło review gałęzi (słowo „przegląd” w tytule, sprawdzone w gicie), jeden produkcja. Rodzaje: stan UI (10), logika i semantyka promptów kuratora (9), zewnętrzne API (3), dane D1 (3), CLI (2).

Mutation testing `api` (StrykerJS, 10 największych plików, 58% mutantów):

- Mutation score wynosi **86,5%**: w pokrytym kodzie testy łapią większość wstrzykniętych błędów.
- 246 z 806 testów zabija wszystkie mutanty, które zabija cały zestaw. Nadmiar siedzi w `curator.test` (131 testów bez unikalnego trafienia), `profile.test` (74), `feedback-routes.test` (50) i `tmdb-title.test` (33).
- Mimo to przeżywają ważne mutanty: kolejność listy z kuratora (`b.score - a.score` → `+`), granice (`votes < NICHE_VOTES` → `<=`), budowanie promptu LLM (ok. 46), ścieżka błędu dla złego JSON-a (400).

Wniosek: testy nie są bezwartościowe, tylko liczne i powtarzalne. Łapią pomyłki przy edycji, a nie błędne zrozumienie wymagań; to drugie łapie review. Koszt utrzymania (49 przepisanych testów w 5 dni) i tokenów jest wysoki. Argument przeciw: projekt ma 5 dni, a testy regresyjne zwracają się przy refaktorach po miesiącach.

Szczegóły: `mutation-analysis.txt`. Pełne raporty Strykera leżą w `/tmp/cinemancer-mut/api/reports/` i znikną po restarcie.

### Koszt skilli (Stats w `/plugin`, 7 dni, pc)

| skill | tokeny | użycia |
|---|---|---|
| requesting-code-review | 107,7M | 69 |
| subagent-driven-development | 85,6M | 83 |
| writing-plans | 51,1M | 94 |
| using-git-worktrees | 26,3M | 83 |
| development-workflow | 20,3M | 124 |

Liczby to tokeny przypisane skillowi, a w jednym runie aktywnych jest kilka skilli naraz, więc się pokrywają i nie wolno ich sumować. Ranking jest wiarygodny: review i implementacja dominują. Rozbicie bez nakładania się daje `/usage` albo wtyczka `session-report`. Skill `test-driven-development` użyto 3 razy, ostatnio 75 dni temu. Test-first wymusza `agents/implementer.md:54-56` i ładuje skill przez `skills:` we frontmatterze. 49 skilli z wtyczek i synchronizacji claude.ai nie użyto ani razu. Opisy większości z nich (ok. 100–200 tokenów każdy) trafiają do każdej tury.

## 2. Research (październik 2026)

Zweryfikowane u źródła w tej sesji:

- **Best practices Claude Code** (code.claude.com/docs/en/best-practices), tabela „What you can stop doing”: „Handing the same task to a subagent doesn't make the answer any better. A fresh reviewer does help”. Rada „subagenci chronią kontekst” jest nieaktualna (1M kontekstu, auto-kompaktowanie). Subagent „can end up *slower*”. O review: „A reviewer that's asked to find problems will always find *something*. If you fix every finding, you end up with […] tests for cases that can't happen”.
- **Optimizing for cost and intelligence** (platform.claude.com): przy pracy będącej łańcuchem zależności „the orchestrator's model alone at lower effort came out ahead in every case measured”. Subagenci Haiku przy Opusie 5.5 obcinają koszt o 32% i trafność o ok. 4 pp, czyli są „an alternative to lowering effort, not better”. Effort na Opusie 5.5: high 95,3% za $0,29, xhigh 96,7% za $0,74.

Z raportów agentów, bez weryfikacji z mojej strony:

- Testy pisane przez agenta: liczba testów prawie nie wpływa na wynik (Chen et al., 02.2026). TDD jako procedura kosztuje 3–8,5× więcej tokenów bez różnicy w jakości (Böckeler). Ogólne „rób TDD” podnosiło odsetek regresji (TDAD). Pomagają testy, które definiuje człowiek (TDFlow).
- Review: osobna sesja recenzenta ma niewielką, nieistotną statystycznie przewagę nad autorecenzją. Najlepsze narzędzia łapią ok. 50% problemów. Zespół Claude Code robi maksymalnie 3 rundy review, wymaga dowodu `file:line`, a każdy bug z produkcji zamienia w test.
- Anthropic, 22.10: „fold subagents into your main loop”, czyli jedna pętla, procedury w skillach, a subagenta zostawia się tylko wtedy, gdy bez niego eval wypada gorzej.
- Anthropic wyciął ponad 80% system promptu Claude Code bez mierzalnej straty. Każe usuwać z promptów polecenia „verify / double-check / use a subagent to verify”.
- Plan red-team: brak jakichkolwiek danych. Najbliższy odpowiednik (advisor) daje +1,7 pp za 2,1× koszt, „at the edge of run-to-run noise”.
- Ludzie zatwierdzają 97% pytań o uprawnienia i odrzucają 39% planów. Uwaga człowieka daje najwięcej przy planie i przy dowodach.

## 3. Audyt promptów (`/doctor prompt-audit`)

Pełne raporty i 50 hunków diffu leżą w `prompt-audit/slice-{a,b,c}.md`. Wszystkie hunki przechodzą `git apply --check`, nic nie zastosowano. Każda zmiana działa we wszystkich projektach.

Najważniejsze ustalenia:

1. **Sprzeczność do rozstrzygnięcia.** `receiving-code-review:35-37` mówi, że finding sprzeczny z planem rozstrzyga użytkownik. `requesting-code-review:57-60` pozwala kontrolerowi rozstrzygnąć finding odwracalny i mieszczący się w zakresie.
2. **`writing-skills/persuasion-principles.md`** zaleca „YOU MUST” i wersaliki. Ten sam plik dalej dokumentuje 110 złamań takich reguł.
3. **`systematic-debugging`** powtarza regułę „≥3 poprawki” 5 razy wersalikami. Jego „read reference COMPLETELY” jest sprzeczne z `CLAUDE.md:17-18` (czytanie zakresami).
4. **`writing-plans/grill-gate.md`** odwołuje się do etapu ze skasowanego skilla `brainstorming`.
5. **`prompt-master`** każe wstawiać do promptów dla Claude wzorce przestarzałe na modelach 5.x (MUST/NEVER, `<thinking>`). Ma też zamrożoną listę modeli 4.x.
6. **Wtyczka codex:** agent `codex-rescue` uruchamia się sam i domyślnie pisze (`--write`). To łamie regułę „jeden piszący na drzewo”.

`plan-red-team` działa na `effort: xhigh`; audyt proponuje `high`.

## 4. Proponowany kierunek (do uzgodnienia)

1. **Implementacja w głównej sesji** (Opus, `high`) zamiast implementera na każde zadanie. Subagenci tylko do pracy równoległej i niezależnej oraz do wyników z dużą ilością tekstu. Implementer jest dziś na Sonnecie, więc zmiana podnosi też model.
2. **Testy pod zachowanie, nie pod procedurę.** Bez obowiązkowego test-first na każde zadanie. Jeden skupiony test na każde wymaganie ze spec/planu, na granicy modułu. Każdy bug, który przeszedł, dostaje test regresyjny (dziś nowy test dodaje 22 z 29 commitów `fix`). Weryfikacja przez uruchomienie aplikacji. Testy zegarowe tylko na sztucznym zegarze.
3. **Review gałęzi zostaje, ale w ryzach:** maksymalnie 3 rundy, potem tylko nowy diff, „skip style”, pewność przy każdym findingu.
4. **Plan red-team usunięty** albo opcjonalny dla zmian ryzykownych. Bramki człowieka na planie i na dowodach, nie na krokach.
5. **Audyt promptów zastosowany po decyzji o kierunku.** Część plików zostanie przepisana albo usunięta, więc wcześniejsze łatanie byłoby stratą.
6. **Za darmo:** wtyczki cloudflare i text-to-cad włączane per projekt, nieużywane skille z claude.ai wyłączone.

Pomiar zmiany: następna funkcja w cinemancerze robiona jedną sesją, a potem porównanie tokenów i commitów `fix` w ciągu 7 dni z runami pipeline'u. To odpowiada otwartemu runowi `setup-evals-mode-a`.

Cięcie testów cinemancera: dopiero po zmierzeniu pozostałych 42% mutantów (ok. 1 godz.). Kandydaci: testy bez unikalnego trafienia w czterech plikach wymienionych w sekcji 1.

## Decyzje (31.10.2026)

- Punkty 1, 2, 3, 5 i 6 kierunku przyjęte.
- Punkt 4 odrzucony: plan red-team zostaje. Uzasadnienie użytkownika: w praktyce każdy red team wskazał w planie błędy, które zmieniły zachowanie implementacji. Przy następnych runach liczymy, ile findingów red-teamu zmieniło wiersz D i czy dotyczyły zachowania.
- Run `setup-evals-mode-a` zamknięty (`flow-state clear`). Plan `.flow/plans/2026-10-15-setup-evals-mode-a.md` zostaje w historii.
- Finding recenzenta sprzeczny z planem: rozstrzyga kontroler, jeśli zmiana jest odwracalna i w zakresie. Zakres, decyzja ze speca albo coś nieodwracalnego idzie do użytkownika. `receiving-code-review:35-37` do dostosowania.

- `.flow`: zostają `plans/`, `run/`, `specs/`. Dochodzą jako konwencja ogólna `design/`, `probes/` i `reviews/` (wzięte z cinemancera). Wypada `sdd/` razem z historycznymi plikami w repo dotfiles.
- Wymóg: run musi dać się wznowić w innej sesji i po `/clear`, tak jak dziś.
- Kompaktowanie, zatwierdzone: (1) sekcja `# Compact instructions` w CLAUDE.md; (2) hook SessionStart po `compact` i `clear` bez zmian; (3) `/clear` na granicy zadań powyżej ok. 300k, a `autoCompactWindow: 500000` zostaje jako siatka bezpieczeństwa; (4) hook filtrujący wyjście testów do porażek; (5) hook PostCompact logujący streszczenia; (6) `idleCompaction` zostaje domyślne. Żadnego z 9 linków od użytkownika nie instalujemy. Pomysł z hookiem ograniczającym Read (token-savior) czeka na pomiar po zmianie.
- Advisor, zatwierdzone: wołany raz na run przy planie lub architekturze, przy tym samym błędzie po 2 próbach naprawy i przed działaniem nieodwracalnym. Nie przed ogłoszeniem końca zadania, nie przy rutynie. `branch-reviewer` i `plan-red-team` go nie wołają. Pomiar z 7 dni: ok. 445 wywołań, z czego 3/4 od subagentów.

## Czego nie sprawdzono

- Liczby z badań zewnętrznych poza dwiema stronami Anthropic przytaczam za agentami.
- Mutation testing objął 58% mutantów `api`, bez `web` i `cli`.
- Dane z transkryptów obejmują tylko 5 dni jednego projektu.
