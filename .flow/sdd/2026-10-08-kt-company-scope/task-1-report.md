# Task 1 report — stream.py questions

Status: DONE. Commit 9253915 "test: knowledge-transfer harness — extract the questions a session put to the user".

## Implemented
`questions(paths)` in `EV/stream.py` (after `subagent_tools`): prints `<basename>: <line>` for every `?`-containing line of each `type=="result"` event's `result` string, and for every `input.questions[].question` of `AskUserQuestion` tool_use blocks (newlines -> space). Added `import os`, a `questions` branch in `main()`, a docstring usage line and the extended `sys.exit` usage. Missing path: `events()` raises, not caught -> non-zero exit. `EV/questions-test.sh` created verbatim from the brief.

## TDD evidence
RED — `bash EV/questions-test.sh` (before touching stream.py):
```
usage: stream.py agent-results <subagent_type> <jsonl>... | subagent-tools <jsonl>...
FAIL five questions (3 result lines with ?, 2 AskUserQuestion)
FAIL result line kept whole, file prefix
FAIL AskUserQuestion newline folded
ok   line without ? is not a question
ok   missing file -> non-zero exit
2 passed, 3 failed        (exit=1)
```
Expected: subcommand absent -> usage error, 0 lines; the two negative checks hold vacuously (as the brief predicts).

GREEN — `bash questions-test.sh && bash stream-test.sh && bash check-package-test.sh`:
`5 passed, 0 failed`, `6 passed, 0 failed`, `8 passed, 0 failed`, exit 0, output pristine.

## Step 5 — real session output (not committed)
`python3 -I EV/stream.py questions ~/.claude/projects/-home-m-work-edge-vibecoding/fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl`: exit 0, 16 lines (the count the brief expects). Includes the router question, `Od 2026-09-28 był jakiś run?` and `…Pakiet jest dla Ernesta?`. Verbatim (file prefix `fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl:` on each line):

```
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Kto przejmuje edge-vibecoding (agenci konfigurujący VisionSOM-iMX93 przez ansible)?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Co odbiorca ma umieć po lekturze?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Tryb: zakładam `projekt` (to repo, pakiet w docs/kt/). Zgadza się?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Dodatkowe materiały (dokumenty, czaty, linki) do uwzględnienia?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Odbiorca: git na tej maszynie ma użytkownika „Ernest”, commity są od mpeciakk. Pakiet jest dla Ernesta?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: herdr: w repo nie ma źródła ani instalacji. Hipoteza: to Twoje/prywatne narzędzie i następca potrzebuje dostępu do jego repo. Jak jest?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Stanowisko reflashu: hipoteza — jedno RPi w labie, do którego wchodzisz po SSH, z płytką podpiętą FTDI (konsola) + USB (ums), obraz debian-6g.wic.zst pobrany od SoMLabs. Co się zgadza, co poprawić (host/adres RPi, skąd obraz, gdzie leży plik ~/.somlabs-root — tylko położenie)?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Sieć: hipoteza — 10.100.100.205 to rezerwacja DHCP na routerze labu, który Ty administrujesz; kolejna płytka wymaga dopisania jej MAC tam. Kto/gdzie?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: herdr w repo firmowym i RPi: hipoteza — herdr jest w org GitHub animativpl (jak edge-vibecoding), a RPi ma stałą nazwę/adres w sieci biura. Podasz nazwę repo herdr i adres/nazwę RPi?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Run referencyjny A2 (2026-09-28): hipoteza — repo runu leży tylko lokalnie pod ~/runs/… (synchronizowane? ~/runs nie jest w mutagenie) i nie jest nigdzie wypchnięte. Gdzie jest i czy następca go dostanie?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Proces rozwoju: .flow/{specs,plans,sdd} to wynik Twoich prywatnych skilli (brainstorming → plan z red-teamem → subagenci → review gałęzi). Hipoteza: następca nie ma tych skilli i ma zachować tylko konwencję (design record → plan → wpis D w spec.md → testy), a wydanie = push na dev. Zgadza się?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Dostępy i eskalacja: hipoteza — następca potrzebuje zaproszenia do org animativpl, własnego dostępu do Claude Code (konto firmowe), a jedyną osobą z wiedzą jesteś Ty (mpeciak@animativ.pl). Kto daje dostępy i czy jest kontakt w SoMLabs?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: reflash.py: §13.2 p.13 mówi, że krok „nowe klucze SSH hosta” (commit 9c09e78) nie był jeszcze uruchomiony na RPi. Hipoteza: nadal nie był — wpisuję go jako dług do sprawdzenia na pierwszym reflashu. Zgadza się?
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Jak reflash.py trafia na RPi? Hipoteza: kopiujesz tools/reflash.py na RPi (scp) i odpalasz tam `python3 reflash.py [--image …]` po SSH; pyserial i bmaptool są już zainstalowane na RPi.
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Od 2026-09-28 był jakiś run? Hipoteza: nie — więc `claude-sonnet-5` w fw/roles.py (implementer, code-reviewer) jest niesprawdzone wobec obecnych modeli i trafia do Długu jako „sprawdź przy pierwszym starcie”.
fe78e66c-a145-48dc-8711-4f836c2dbb77.jsonl: Hasełko vaulta i Claude Code: hipoteza — następca tworzy własny plik z hasłem vaulta (vault runu jest na razie pusty, nic nie dziedziczy), a Claude Code loguje się kontem firmowym przez OAuth, nie kluczem API. Zgadza się?
```

## Files changed
- `.flow/specs/2026-10-08-knowledge-transfer-evidence/stream.py` (modified)
- `.flow/specs/2026-10-08-knowledge-transfer-evidence/questions-test.sh` (new)

## Self-review
Matches the brief; only those two files committed; `.flow/sdd/` untracked and left alone. No nested claude run.

## Concerns
- Source (a) prints the whole line when `?` appears anywhere in it (as the brief's test requires). The real-session output came entirely from source (b) (AskUserQuestion); source (a) is covered only by the synthetic test.
- An AskUserQuestion entry without a `question` key prints an empty text after the prefix (unspecified in the brief; left as is).
