# The project CLAUDE.md block

A session without the author's `~/.claude` setup — a colleague's Claude Code —
loads the project's `CLAUDE.md` and nothing else. It does not know the spec
exists, that it must stay true, or what `.flow/` holds. This block tells it.

**When:** with every new spec, in the same commit as the spec.

**Where:** `CLAUDE.md` in the repository root, where Claude Code loads it. If the
file exists, add the block as its own sections and leave the rest untouched.

**Adapt, do not invent:**

- The spec path. Per-component specs: list each path with its component. A
  split spec: say `spec.md` is the index and the content is in
  `docs/<temat>.md`.
- Decision numbering as the spec has it. If decisions live inside sections with
  no D numbers, drop the "D1, D2…" and "DN" parts.
- Drop the lines for `.flow/` directories the repository does not have; drop
  the whole `.flow/` section if there is none.
- Polish, unless the spec is in English — then translate the block.

Keep it under 30 lines: every session in the project pays for it.

## The block

```markdown
## Dokumentacja projektu

`spec.md` opisuje, czym projekt jest teraz: cel, zakres, architekturę, decyzje
w mocy i punkty otwarte. Przeczytaj go przed zmianą i zanim zapytasz
użytkownika o coś, co spec może już rozstrzygać.

- Decyzje w mocy (D1, D2…) są tylko w specu. Zmianę sprzeczną z decyzją
  najpierw uzgodnij z użytkownikiem, potem zmień wiersz D w tym samym commicie
  co kod.
- Zmiana zachowania opisanego w specu aktualizuje spec w tym samym commicie.
  Nieaktualny spec szkodzi bardziej niż brak speca.
- Numery sekcji (§N) i decyzji (DN) są stałe, bo cytują je plany i commity.
  Nową decyzję dopisz pod następnym wolnym numerem.
- Spec opisuje stan, nie pracę: bez TODO, tasków i list błędów.
- Kod cytuj ścieżką i symbolem, nie numerem linii.

## Katalog `.flow/`

`.flow/` to warsztat autora: plany zmian przygotowane z Claude Code. To historia,
nie źródło prawdy o stanie projektu — tym jest spec.

- `.flow/plans/RRRR-MM-DD-<zmiana>.md` — plan jednej zmiany z chwili
  planowania: decyzje, taski i sekcja `## Rulings` z rozstrzygnięciami podjętymi
  w trakcie pracy. Czytaj, gdy szukasz uzasadnienia zmiany. Może opisywać stan,
  którego już nie ma.
- `.flow/specs/` — starsze zapisy projektowe i materiał dowodowy do decyzji.
- `.flow/run/`, `.flow/sdd/` — lokalny stan narzędzi autora, poza gitem.

Nie edytuj tych plików. Własnych planów w `.flow/` tworzyć nie musisz.
```
