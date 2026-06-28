# Agentic workflow — development aplikacji tym zestawem

Zestaw opiera się na **superpowers** (szkielet procesu) + **codebase-memory-mcp**
(nawigacja po kodzie) + **context7** (aktualne docsy) + kilku skillach designowych
Matta i wyspecjalizowanych agentach VoltAgent. Poniżej kolejność, w jakiej powinny grać.

## Pętla główna: pomysł → wdrożenie

### 1. Zrozum / zaprojektuj (PRZED kodem)
- `brainstorming` (superpowers) — doprecyzowanie intencji i wymagań.
- `grilling` — gdy plan trzeba realnie rozkruszyć (stress-test założeń).
- `codebase-design` — projektowanie „deep modules": interfejsy, seamy, testowalność.
- `domain-modeling` — ustalenie języka domeny + ADR-y dla decyzji.
- `codebase-memory` (cbm MCP) — orientacja w istniejącym kodzie: kto co woła,
  zależności, dead code, kandydaci do refaktoru. ZAWSZE przed eksploracją kodu.

### 2. Zaplanuj
- `writing-plans` (superpowers) — zamiana ustaleń w plan z krokami.
- Plan trzymaj w jednym oknie kontekstu z etapem 1 (bez kompaktowania w środku).

### 3. Zbuduj
- `test-driven-development` (superpowers) — najpierw test, potem kod. Domyślnie.
- `executing-plans` / `subagent-driven-development` — realizacja kroków planu;
  zadania niezależne oddawaj subagentom.
- `dispatching-parallel-agents` — gdy 2+ zadań nie ma wspólnego stanu.
- `using-git-worktrees` — izolacja pracy równoległej / ryzykownej.
- `context7` (`/docs`) — gdy dotykasz biblioteki/frameworka: pobierz aktualną
  dokumentację zamiast polegać na pamięci modelu.

### 4. Zweryfikuj i domknij
- `systematic-debugging` (superpowers) — każdy bug/awaria PRZED proponowaniem fixa.
- `verification-before-completion` — uruchom i potwierdź dowodami, zanim powiesz „gotowe".
- `requesting-code-review` → `/code-review` (wbudowany) — review diffu.
- `receiving-code-review` — rzetelna obsługa uwag (nie ślepe wdrażanie).
- `/simplify` (wbudowany) — czyszczenie pod kątem prostoty/reuse.
- `finishing-a-development-branch` — merge / PR / sprzątanie.

## Agenci specjalistyczni — wołaj punktowo, nie zawsze
Uzupełniają pętlę tam, gdzie trzeba domenowej głębi (każdy = osobny kontekst):
- `architect-reviewer` — ocena decyzji architektonicznych na poziomie makro.
- `security-engineer` + `penetration-tester` — para: budowa zabezpieczeń + szukanie dziur.
- `performance-engineer` — wąskie gardła, profilowanie, skalowanie.
- `docker-expert` + `devops-engineer` — konteneryzacja, CI/CD, deploy.
- `test-automator` — budowa frameworka testów / integracja z CI.
- `docs-researcher` (context7) — pobranie docsów bez zaśmiecania głównego kontekstu.

## Utrzymanie kodu (poza feature-workiem)
- `improve-codebase-architecture` — skan pod „deepening opportunities" + raport,
  potem `/grilling` po wybranym kandydacie.

## Higiena kontekstu
- `handoff` — gdy okno się zapełnia lub rozgałęziasz: kompresja do dokumentu,
  którym startujesz świeżą sesję (most między oknami kontekstu).
- `karpathy-guidelines` — w tle: chirurgiczne zmiany, bez nadmiarowej komplikacji.

## Zasady przekrojowe
1. Skille PROCESOWE (brainstorming, systematic-debugging, TDD) idą PRZED domenowymi.
2. cbm MCP do nawigacji po kodzie; Grep/Glob/Read do tekstu, configów, plików nie-kodu.
3. context7 do każdej biblioteki/API — nie zgaduj z pamięci.
4. Najpierw zrozum i zaplanuj w jednym kontekście, potem implementuj świeżo per zadanie.
5. Nic nie jest „zrobione" bez uruchomienia i dowodu (verification-before-completion).
