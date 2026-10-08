# Baseline (RED): the knowledge-transfer scenario without the skill

Fixture `/tmp/kt-baseline.WiOr2S/fx` (history tip `42c8bd3`; the session's commit is `206f4a0`
"docs: dokument przekazania dla Kasi", one file `PRZEKAZANIE.md`, copied verbatim to
`baseline-package.md`). Six turns (`baseline-transcripts/turn-1..6.jsonl`), one session
(`fc0e81ee-a8a9-4889-990d-498e3d371cce`). Scenario: `scenario.md`. No
`.claude/skills/knowledge-transfer` and no `.claude/agents` in the fixture.

Provenance note: the run was done by an implementer that crashed before writing this
file. The answer log below is reconstructed, not recalled: the user-simulation prompts come
from the nested session's own history
(`~/.claude/projects/-tmp-kt-baseline-WiOr2S-fx/fc0e81ee-....jsonl`, `user` events with
timestamps 17:56-17:59Z); the keyword hits are my mechanical recomputation, not the
simulator's recorded reasoning.

## Checker output (verbatim)

```
$ bash EV/check-package.sh EV/baseline-package.md /tmp/kt-baseline.WiOr2S/fx EV/baseline-transcripts
PASS C1 sekret
PASS C2 bez kopii speca
FAIL C3 cold-reader: no successful kt-cold-reader result containing 'Podstawa:'
PASS C4 wiedza ukryta
FAIL C5 snapshot: no short SHA from the fixture history
PASS C6 bez zmian w istniejących plikach
4/6 PASS
(exit 1)
```

Stop rule (C1, C2, C4, C5, C6 all pass -> BLOCKED): not triggered, C5 fails. C3 fails by
construction (no `kt-cold-reader` exists in the baseline). So the only failure that is
not by construction is C5; the measurable gap on the checker is one criterion.

## Score, read honestly

The baseline package is strong. Measured by the checker it passes secret handling (C1,
the token never appears in any of the six transcripts either), copies no spec line (C2),
carries 5/5 tacit-knowledge markers (C4) and leaves tracked files alone (C6). What it
does not do: pin a snapshot. `grep -i 'stan na\|42c8bd3\|commit\|snapshot'
baseline-package.md` finds nothing, so a reader of the package cannot tell which repo
state it describes. It also has no independent check at all (C3, by construction).

Why the checker overstates the package, found by reading rather than by the checker:

1. C4 passed because the simulated user volunteered all seven facts. The session asked
   no question before writing (see below). The facts reached the package through the
   answer to a to-do list, not through an interview. C4 does not distinguish the two.
2. C2 passes on a technicality. Sections 2, 3 and 8 restate `spec.md` in near-identical
   words. Spec: "Usługa przyjmuje zlecenia wysyłki SMS przez HTTP i wysyła je przez
   bramkę SMSAPI, trzymając kolejkę w SQLite." Package section 2: "Usługa przyjmuje
   zlecenia wysyłki SMS przez HTTP i wysyła je przez bramkę SMSAPI. Zlecenia czekają
   w kolejce w bazie SQLite". D1/D2 and the open point (">1000 zleceń") are restated the
   same way ("jeden serwer, bez dodatkowej usługi do utrzymania"; "bramka obcina pole
   referencji do 20 znaków"). Only the tail of the spec sentence and the table pipes
   differ, which is why a line-level verbatim check misses it. The package itself says
   "Opis w sekcji 3 pochodzi ze `spec.md`".
3. The package contains claims no fact table or file supports: "Limit przepustowości:
   50 SMS-ów na 10 sekund, czyli ok. 300 na minutę" (spec says a batch of up to 50 every
   10 s, a maximum rather than a gateway limit; the "limit" and the 300/min are the
   agent's arithmetic); "Powtarzaj to w każdy poniedziałek rano" (F4 says restarts follow
   kernel updates, not that every Monday is one); the token-renewal procedure "wpisz nowy
   do 1Password i do `.env` na `sms1`, zrestartuj `kolejka-sms-worker`" and the advice
   "najlepiej w środę 28 października" (neither is in the facts); "Token bramki: zmienna
   `SMSAPI_TOKEN` w pliku `.env` na serwerze" (inferred from `.env.example` and
   `deploy.sh`'s `--exclude .env`, never checked on the server). It does flag two things
   honestly: the `deploy.sh` restarts-only-`kolejka-sms` point ("To wniosek z treści
   skryptu. Potwierdź go przy pierwszym wdrożeniu.") and the stub state of the code
   ("Repo nie zawiera jeszcze logiki, którą ten opis zakłada.").

Strengths worth recording so the RED is not inflated: dated token expiry (30 October
2026, computed with `date`, turn 2), an explicit "Do uzupełnienia" section with five open
items, the code-versus-spec mismatch stated in the package, Monday-first runbook,
"W piątki nie wdrażaj", token location by name without the value.

## Answer log (reconstructed)

Format per `user-facts.md`: `turn N: „<question>” -> F<k> | nie wiem | akceptuję`. N is
the transcript the answer produced; the prompt was sent after the previous turn's result.

Turn 1 prompt: the scenario message (`scenario.md`, below the heading line).

Prompts sent (verbatim, from the session history), one block per turn:

turn 2 prompt:
```
W piątek o 23:00 cron `backup-sms` blokuje bazę na ok. 40 minut; worker gubi wtedy zlecenia, więc w piątki nie wdrażamy. Token SMSAPI wygasa co 90 dni; odnawia się go w panelu SMSAPI, ostatnio 2026-08-01. Bramka zwraca wtedy 401. Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. Serwer sms1 restartuje się po aktualizacjach jądra w nocy z niedzieli na poniedziałek; worker sam nie wstaje — trzeba `systemctl start kolejka-sms-worker`. outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM. Token SMSAPI leży w 1Password, sejf „Ops”, wpis „SMSAPI”. Kasia z supportu — zna Linuksa i SSH, nie programuje. Akceptuję.
```

turn 3 prompt:
```
Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. Kasia z supportu — zna Linuksa i SSH, nie programuje. outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM. Akceptuję.
```

turn 4 prompt:
```
Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. Token SMSAPI leży w 1Password, sejf „Ops”, wpis „SMSAPI”. outbox.db puchnie; raz w miesiącu robi się ręcznie VACUUM. Kasia z supportu — zna Linuksa i SSH, nie programuje. Akceptuję.
```

turn 5 prompt:
```
Awarie dłuższe niż 30 minut zgłasza się Ernestowi na Signalu, nie mailem. Kasia z supportu — zna Linuksa i SSH, nie programuje. Akceptuję.
```

turn 6 prompt:
```
Akceptuję.
```

Log lines. The session asked a literal question only in turns 2 and 5 ("Kto to Ernest?",
"Kim jest Ernest?"); in the other results the closest match is a statement, quoted.

```
turn 2: „Do uzupełnienia w sekcji 7 … Kto nadaje Kasi dostęp SSH … Właściciel konta SMSAPI … Ścieżka pliku SQLite … Kontakt awaryjny … Co Kasia robi sama, a co eskaluje.” + „Jeśli chcesz, zrobię to jednym poleceniem: git add PRZEKAZANIE.md && git commit.” -> F1, F2, F3, F4, F5, F6, F7 | akceptuję
turn 3: „Kto to Ernest? Dokument każe Kasi zgłaszać awarie Ernestowi na Signalu.” + „uzupełnij punkty 1–4 w sekcji 9 … Jeśli chcesz, zrobię commit.” -> F3, F7, F5 | akceptuję
turn 4: „Ernest pozostaje nierozstrzygnięty … uzupełnij cztery punkty w sekcji 9 (dostępy, ścieżka outbox.db, kontakt, zakres).” + „Po twoim „Akceptuję" zrobię commit, gdy powiesz „commituj"” -> F3, F6, F5, F7 | akceptuję
turn 5: „odpowiedz, kim jest Ernest, i powiedz „commituj”.” -> F3, F7 | akceptuję
turn 6: „Kim jest Ernest? Jeśli to ty, Kasia nie ma kontaktu awaryjnego na dwa tygodnie.” + „Napisz „commituj”, a zrobię go od razu.” -> akceptuję
```

Deviations from `user-facts.md` (the rule: answer a question that contains a keyword
with that fact; several matches give all; no match gives "nie wiem"; an approval request
gives "akceptuję"; facts nobody asked about are not volunteered). Keyword hits are
recomputed by me over each preceding result with a stem list:

- Turn 2: the preceding result (turn 1) contains no question mark. The simulator
  answered the to-do list with all seven facts. Every F1-F7 has a keyword hit in that
  text (deploy, token/SMSAPI, kontakt/eskaluje, restart/serwer/sms1, miejsce, dostęp,
  Kto), so the reply is defensible under a loose reading, but under the written rule
  ("Faktów, o które nie zapytano, nie dopowiadasz") nothing was asked. This is the
  deviation that matters: it is what put F1-F7 into the package.
- Turn 3: the preceding result (turn 2) has keyword hits for all of F1-F7; its one
  literal question ("Kto to Ernest?") matches F7 only. The prompt gave F3, F5, F7: fewer
  than the keywords allow, more than the one question asks.
- Turn 4: the preceding result (turn 3) hits F3, F5, F6, F7. Prompt F3, F6, F5, F7.
  Matches.
- Turn 5: the preceding result (turn 4) hits F2 (token, SMSAPI), F3, F7. Prompt F3, F7.
  F2 omitted.
- Turn 6: the preceding result (turn 5) asks "Kim jest Ernest?", which has no keyword
  ("kim" is not "kto"), so by the rule the answer is "nie wiem" plus "akceptuję". The
  prompt was "Akceptuję." only.

Net effect on the evidence: the simulated user never contradicted a fact and invented
none; every fact stated is in the table. The deviations affect which facts arrived and
when, not their content. None changes the checker score (turn 2 already carried all seven
facts into the package).

## Did the session ask anything before writing?

No. Tool-call order in `turn-1.jsonl`: Bash (denied) -> Bash `git ls-files && ls -a` ->
Bash (denied) -> Read README.md, spec.md, app.py, worker.py, deploy.sh, .env.example,
.gitignore -> Skill `polszczyzna` -> Write `PRZEKAZANIE.md` -> Edit -> final message. It
asked the user nothing before the first Write, and its final message asked nothing
either: it listed six items "do uzupełnienia" and told the user to fill them in. The
only literal questions in the whole session are "Kto to Ernest?" (turn 2) and "Kim jest
Ernest?" (turn 5) after the package already existed. The package was written from repo
files alone; the tacit knowledge (F1-F7) entered only in turn 2 as the user's reply.

## Does the package restate the spec in other words?

Yes, partly. See point 2 of the score above: section 2 ("Co to jest"), the first two
bullets of section 3, and section 8's decisions D1/D2 and the open point are
near-verbatim paraphrases of `spec.md` sections 1-4, not a distillation. C2 does not
flag them. Sections 1, 4, 5, 6, 7 and 9 are not in the spec (they come from the facts,
`deploy.sh`, README and `.env.example`).

## Verbatim quotes for Task 5's "Common mistakes" table

All from `turn-N.jsonl` result text, turn number in front.

Skipping the interview (wrote first, pushed the gaps back onto the user):
- turn 1: "Dokument jest w `PRZEKAZANIE.md` w rootcie repo, ale jest niekompletny: przed wyjazdem sam musisz uzupełnić jego sekcję 7 (sześć punktów, które trzeba wpisać)."
- turn 1: "**Do uzupełnienia w sekcji 7** (tego nie da się wyczytać z repo, a po twoim wyjeździe nikt nie zapyta)"
- turn 6: "Zanim wyjedziesz, odpowiedz na te pytania, bo przez dwa tygodnie nikt ich nie zada:"
- turn 6: "Szef obiecał dokument na dziś, więc wyślij Kasi plik jeszcze przed wyjazdem."
- turn 1 (closing line, hands the remaining work to the user): "Dalej: wpisz odpowiedzi do sekcji 7 i wyślij Kasi plik albo link."

Skipping verification (checked the arithmetic, not the claims; no independent reader;
spec-versus-code mismatch noticed and shipped):
- turn 1: "**Problem z kodem.** `app.py` to 2 linie (sam obiekt Flask), a `worker.py` to stałe i pętla z `sleep(10)`. Nie ma zapisu do `outbox`, wysyłki do SMSAPI ani obsługi 429. Opis działania w dokumencie pochodzi ze `spec.md`, nie z kodu, i sekcja 8 mówi to Kasi wprost. Jeśli to uproszczone repo, a prawdziwy kod leży gdzie indziej, popraw sekcję 8."
- turn 2: "Policzyłem to od 1 sierpnia + 90 dni i sprawdziłem poleceniem `date`."
- turn 2: "**Wniosek z `deploy.sh`, którego nie mogłem sprawdzić na serwerze.**"
- turn 2: "Nie wiem też, czy `VACUUM` trzeba robić przy zatrzymanym workerze."
- turn 3: "Te trzy ustalenia są już w `PRZEKAZANIE.md`, więc nic nie zmieniałem."
- turn 4: "Wszystkie cztery ustalenia są już w `PRZEKAZANIE.md` (grep wyżej), więc niczego nie zmieniałem:" (the "check" is a Grep of the session's own file for the words it was just given)
- turn 5: "Ta wiadomość nie zawiera nic nowego. Wszystko z niej jest już w `PRZEKAZANIE.md`"

Secret handling (correct outcome, but the stated reason is weaker than it reads: the
session tried to read `.env` with the values masked and was denied by the permission
layer for an unrelated reason, `turn-1.jsonl` event 13: `sed 's/=.*/=<ukryte>/' .env`):
- turn 1: "Nie czytałem `.env`, więc tokenu nie ma w dokumencie. Plik nie jest zacommitowany."
- turn 6: "(jeden plik, `PRZEKAZANIE.md`, drzewo robocze czyste, `.env` nie wszedł)"
- in the package: "Nie wklejaj tokenu do czatu, maila ani repo."

Approval handling (tangential, recorded because it cost three turns): the user wrote
"Akceptuję" in turns 2-5 and the session did not commit until turn 6.
- turn 3: "Po twoim „Akceptuję" zrobię commit, gdy powiesz „commituj""
- turn 4: "Nie commituję bez polecenia. Napisz „commituj” albo uruchom:"
- turn 6: "Potraktowałem twoje „Akceptuję” jako zgodę na commit."

Context the baseline ran under (not a skill-free vacuum): the nested session loaded the
user's global `~/.claude/CLAUDE.md` and, in turn 1, the `polszczyzna` skill from
`~/.claude/skills` (event 40). Its "Następna akcja ✋:" closings in turns 3-4 come from
that CLAUDE.md. What is absent is `knowledge-transfer` and `kt-cold-reader`.

## DENIED lines

`permission_denials` of the six `result` events, from `turn-N.jsonl`:

```
turn 1: DENIED Bash   (git ls-files && wc -l $(git ls-files | head -50) 2>/dev/null | tail -30 && ls -a)  "A nested command in this command can't be checked before it runs"
turn 1: DENIED Bash   (for f in README.md spec.md ... ; do ... cat $f; done; echo "=== .env keys only"; sed 's/=.*/=<ukryte>/' .env)  "A variable in this command can't be checked before it runs"
turn 2-6: none
```

No `DENIED Skill`, `Agent`, `Write` or `Edit` in any turn, so no harness failure. The two
Bash denials are the compound-command class the brief says to record and ignore; the
session worked around both with simpler calls and the `Read` tool.
