# Wdrożenie audytu wydajności setupu (2026-10-03)

Dotfiles nie mają żywego `spec.md`, więc ten rekord niesie zarówno decyzje, jak
i deliberację (tak jak `2026-09-27-review-cost-cuts-design.md`). Dowody, liczby
i identyfikatory ustaleń (A1, B3, G1a-1…) są w
`2026-10-03-setup-perf-audit.md` (audyt na laptopie, 224 agentów, 128 ustaleń).

## Problem

Pierwsze żądanie sesji głównej to ~49K (laptop) / ~51K (pc) tokenów, subagenta
pipeline'u ~40K. 54–67% ważonego kosztu to odczyty cache, więc stały prefiks
i rozrost sesji (do 500–970K) decydują o zużyciu. Do tego ukryte żądania
`agent_summary` (~8–12%) i koszty CPU hooków na laptopie.

## Decyzje

| # | Decyzja | Odrzucone warianty i dlaczego |
|---|---|---|
| D1 | Niezacommitowane zmiany `settings.json` na pc są odrzucane (`git checkout`), wszystko ustalamy od zera tutaj | Wklejenie diffu z pc i ocena per kawałek — wolniej, a zmiany nie były potrzebne; commit „jak jest” — wniósłby nieocenione env autokompakcji blokujące `/autocompact` |
| D2 | `"model": "sonnet"` jawnie w repo | `opus` / brak klucza (niejawnie Opus 5.5 1M) — drożej (~1,33×) i rozjazd z polityką pipeline'u |
| D3 | `modelSettings`: `claude-sonnet-5-5` i `claude-opus-5-5` na high; martwe klucze i top-level `effortLevel` usunięte | medium — tak działa dziś, ale przypadkiem (martwe klucze), bez porównania; xhigh z README — najdroższe bez dowodu |
| D4 | Bez `skipWorkflowUsageWarning`; `agentPushNotifEnabled: false` | `permissions.ask: ["Workflow"]` — nieprzetestowane w auto mode i ultracode |
| D5 | `CLAUDE_CODE_FORK_SUBAGENT=0` + „dispatch z `run_in_background: true`” w SDD i requesting-code-review | Pilot na jednym runie — mechanizm potwierdzony przez obu weryfikatorów; klucz nieudokumentowany, sprawdzać po aktualizacjach |
| D6 | `autoCompactWindow: 500000` | 300000 (rekomendacja audytu) — użytkownik woli rzadsze kompakcje kosztem części oszczędności |
| D7 | `skillOverrides`: 13 skilli z claude.ai i 13 bundled (off / name-only / user-invocable-only); `cowork-plugin-management@synced: false` | `syncClaudeAiSkills: false` — przenosi pliki do `.trash`; `disableBundledSkills` — zabiera claude-api, nie ukrywa synced |
| D8 | `deniedMcpServers`: Claude Docs, Canva, M365; `permissions.deny`: ReportFindings, ShareOnboardingGuide | Blokada ClickUp — używany w 6/160 sesji |
| D9 | `enableArtifact: false` globalnie + `disallowedTools: Artifact` u agentów | Tylko agenci — główny wątek dalej płaci ~11,7K/żądanie za narzędzie użyte raz na 160 sesji |
| D10 | Claude in Chrome zostaje domyślnie włączony | Off + `--chrome` — <1% zużycia, a pipeline w harmonii sam weryfikuje UI |
| D11 | Plugin Cloudflare off globalnie, włączany w `settings.local.json` repo, które go używają | Tylko MCP na poziomie użytkownika — skille znikłyby też tam, gdzie są używane |
| D12 | `disallowedTools: Skill` u wszystkich pięciu agentów; brief wskazuje polszczyznę przez Read | Pełne allowlisty `tools:` — większy zysk, ale każde nowe narzędzie trzeba dopisać w pięciu plikach, inaczej agent cicho go nie dostaje |
| D13 | Usunięty augmenter cbm `Grep\|Glob` i przypomnienie cbm z SubagentStart; `if: "Bash(*worktree*)"` dla flow-guard; leniwy traceback w prompt-context; `GIT_OPTIONAL_LOCKS=0` w statusline | Naprawa ścieżki augmentera — `hook-augment` spala ~2 s CPU na wyszukiwanie; łączenie hooków SubagentStart — kilka ms za ryzyko |
| D14 | Plugin WakaTime wyłączony | Naprawa klucza API — statystyki z Claude Code nie są używane (11 dni awarii bez zauważenia) |
| D15 | `cleanupPeriodDays: 90` | 60 / 30 + archiwum — 90 trzyma dane eksperymentów do grudnia |
| D16 | `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`, wiersz Explore usunięty z development-workflow; `promptSuggestionEnabled: false` | — |
| D17 | E4: flow-state przyjmuje `worktree=. branch=. base=HEAD`; task-brief/review-package biorą plan i bazę ze stanu; literalne komendy w skillach | Tylko tekst skilli — dłuższe i kruche komendy |
| D18 | Recenzenci sami uruchamiają `review-package`; exit 4 = BLOCKED, nigdy APPROVED | — |
| D19 | Opus dla task-reviewera: nazwane wyzwalacze (auth/sekrety/niezaufane wejście, współbieżność, migracje/format danych, publiczne API) lub diff >~400 zmienionych linii; re-review dziedziczy model | Same wyzwalacze — trudny duży diff bez wyzwalacza tracił Opusa |
| D20 | Reguła 2 w CLAUDE.md: grep/find przez Bash, konwencja nazwy projektu cbm | — |
| D21 | Sekcje CLAUDE.md tylko dla głównego wątku zostają; przy regule 5 dopisek „(dotyczy głównego wątku)” | Hook SessionStart i output style — ~1,2% zysku, odwraca D1 ze speca ADHD, którego argumenty (przetrwanie kompakcji, zasięg output style'u) stoją |
| D22 | Status line: segmenty limitów 5 h / 7 d i bezwzględnego kontekstu; bez kwoty w dolarach (subskrypcja) | — |
| D23 | `/clear` na granicy runów: ostatnia linia finishing + triage przy kontekście >~120K | — |
| D24 | E5/E6 (bez drugiego wklejania Global Constraints) i E8 (reguły wpisane zamiast wskaźników) | — |
| D25 | Eksperyment plan-granularity zamknięty: plany w wariancie środkowym zostają, override Haiku działa | Pełne porównanie okien — konfundery (Sonnet 5.5, review-cost-cuts) rozmywają wynik |
| D26 | Mutagen `cc-projects`: force-poll 30 s + ignore `*.jsonl.wakatime` (ręcznie, maszyna po maszynie) | — |
| D27 | Watcher cbm off w `~/obsidian` i `~/work/knowledge-base` przez `/mcp` (ręcznie, obie maszyny) | Watcher off globalnie — graf laptopa nie widziałby zmian z pc |
| D28 | Skrypt pomiarowy `bin/claude-baseline` z regułami analizy (F7) w nagłówku | — |

## Odrzucone w całości

- **Dispatch na pierwszym planie (E1)** — sprzeczny z D5.
- **Reguła o modelach per etap workflow (G1d)** — użytkownik nie chce.
- **Plan rozbity na pliki per task** — subagenci już dostają jeden task przez
  `task-brief`; cały plan czytają tylko red-team (107/107) i branch-reviewer
  (96/119), którzy go potrzebują; implementer/fixer/task-reviewer dotykają
  pliku planu w 10–15% dispatchy, przyczyna niezbadana.
- **C8 (indeks harmonii na laptopie)** — rozbieżność to równoległa praca na pc.
- Pozostałe z sekcji „Czego nie robić” raportu (TTL cache, fast mode,
  `omitClaudeMd`, `bashOutputMaxChars` itd.).

## Poza zakresem

- **Replay red-teamu xhigh vs high (B4)** — punkt otwarty; protokół: wariant
  `plan-red-team-high` na 5–6 archiwalnych planach (w tym 2 RETHINK),
  przełączenie tylko jeśli łapie wszystkie blokujące.
- **pc**: usunięcie kopii skilli Cloudflare z `~/.claude/skills` i override
  `frontend-design` (A7) — ręcznie.
- **Vault**: martwe serwery MCP w `~/obsidian/.mcp.json` (G6) — sesja vaulta.
- Zamykanie bezczynnych paneli na baterii (G1f) — nawyk.
