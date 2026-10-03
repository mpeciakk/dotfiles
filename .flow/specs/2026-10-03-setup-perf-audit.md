# Audyt setupu Claude Code — 2026-10-03

## Werdykt

Tokeny idą głównie na ponowne czytanie kontekstu z cache (54–67% ważonego kosztu), więc najwięcej daje zmniejszanie stałego prefiksu każdego żądania i pilnowanie, żeby sesje nie rosły do 500–970K. Drugie duże źródło jest ukryte: podsumowania postępu agentów w tle (agent_summary) kosztują około 8–12% list-$ i nie widać ich w transkryptach. Cały pakiet odzyskuje według modelu około 25% zużycia limitu w tygodniu z dużym workflow i około 30% w zwykłym tygodniu pipeline'u, czyli 1,2–1,4 okna 5-godzinnego tygodniowo (±4–5 pkt). Procentów z pojedynczych ustaleń nie sumuj (wyszłoby fałszywe 33–43%). Przelicznik: okno 5 h ≈ 205 $ list (190–215), tydzień ≈ 1 230–1 245 $; Sonnet 5.5 ≈ 0,75× Opusa 5.5 na tym miksie (cache read kosztuje tyle samo). UWAGA: plik raportu nie powstał, bo harness zablokował narzędzie Write dla subagenta; cała treść jest w tych polach.

## Bazowy kontekst

| Komponent | Tokeny | Kontrolowalne | Pokrętło |
|---|---|---|---|
| [sesja główna, mediana 49,0K laptop / 51,4K pc, baseline.py od 09-27] Schemat narzędzia Artifact | ~11,7K (szac., 34 155 znaków przy 2,94 zn/tok) | tak | enableArtifact: false (A1) albo disallowedTools: Artifact u agentów |
| [główna] Pozostałe 13 schematów narzędzi wbudowanych | ~11,2K | częściowo | permissions.deny: ["ReportFindings","ShareOnboardingGuide"] (−1,25K, A6) |
| [główna] Listing skilli (63–74 pozycje, 26–28K znaków) | ~9,4K | tak | skillOverrides: synced −3,1K (G1c-2), bundled −1,8K (D5); plugin cloudflare −2,0K (G2/A4) |
| [główna] Globalny CLAUDE.md (8 254 znaki PL) | ~4,3K | tak | przeniesienie sekcji tylko dla głównego wątku (B2/D3, decyzja) |
| [główna] Nazwy odroczonych narzędzi MCP (125) | ~2,9K | tak | deniedMcpServers (G3), Chrome off (G4), plugin cloudflare |
| [główna] Instrukcje serwerów MCP (Docs 1 893, ClickUp 1 247, Chrome 1 022 znaki) | ~1,8K | tak | deniedMcpServers; nie CLAUDE_CODE_MAX_MCP_DESCRIPTION_LENGTH |
| [główna] Listing agentów | ~1,5K | częściowo | CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1 (−0,35K) |
| [główna] Sekcja systemowa Claude in Chrome | ~1,4K | tak | claudeInChromeDefaultEnabled=false w ~/.claude.json każdej maszyny |
| [główna] 3 zawsze ładowane schematy Claude Docs | ~0,6K | tak | deniedMcpServers {serverName: "claude.ai Claude Docs"} |
| [główna] Pamięć, gitStatus, środowisko, auto mode, reszta promptu systemowego | ~4,4K | nie warto | – (pamięć używana; includeGitInstructions odradzone) |
| [\subagent pipeline, Sonnet 5.5 implementer, mediana 40,6K] Schematy narzędzi (9) | 16,5K, w tym Artifact 11,8K | tak | disallowedTools/tools: we frontmatterze agents/*.md |
| [\subagent] Listing skilli (27,8K znaków) | 11,1K | tak | Skill w disallowedTools (D1) albo allowlista tools: (B1); skills: preload działa bez Skill |
| [\subagent] CLAUDE.md + MEMORY.md | 3,9K | częściowo | B2/D3 (decyzja); omitClaudeMd odradzone dla implementera/fixera |
| [\subagent] Prompt systemowy agenta | 2,7K | nie | – |
| [\subagent] Nazwy odroczonych narzędzi | 2,3K | tak | allowlista MCP w tools: |
| [\subagent] Prompt dispatchu, preload TDD, hand-back | 2,4K | nie | – |
| [\subagent] Inne załączniki i tekst hooków | 2,0K | marginalnie | usunięcie przypomnienia cbm z SubagentStart (J6, ~0,1K) |

## Rekomendacje

### Szybkie wygrane (config, minuty) — duże pokrętła

**Wyłącz podsumowania agentów w tle** (G1a-1, G2d-1, G2d-2)
- Zmiana: W env /home/m/dotfiles/.claude/settings.json: "CLAUDE_CODE_FORK_SUBAGENT": "0". W subagent-driven-development/SKILL.md (dispatch) i requesting-code-review/SKILL.md:51 dopisz 'dispatch z run_in_background: true', bo parametr wraca i model mógłby blokować sesję.
- Oszczędność: 8,1% (12,0% bez dnia audytu) zużycia, ~92 $/tydz.; agent_summary ~8–12% list-$ (G2d-1 obniżył do 7–8%, odrzucone po ważeniu cen)
- Pomiar po: Po runie SDD: cost-state/lastModelUsage minus transkrypty na modelu subagenta → ~0 (dziś ~28% widocznych reads)
- Ryzyko: Znika żywa linia postępu agentów i typ fork (nieużywany od 09-19); pokrętło nieudokumentowane, sprawdzać po aktualizacji
- Pewność: wysoka (mechanizm), średnia (kwota, replay) · maszyna: obie · nakład: trivial

**Okno autokompakcji 300K zacommitowane w repo** (F1, G2a-1, G2a-3)
- Zmiana: Klucz "autoCompactWindow": 300000 w settings.json; na pc usunąć niezacommitowane env CLAUDE_CODE_AUTO_COMPACT_WINDOW (ma pierwszeństwo i blokuje /autocompact). Długie sesje projektowe: claude --autocompact 600k.
- Oszczędność: 3,7% (5,4%) zużycia; ~17% kosztu głównego wątku laptopa (37% tokenów laptopa od 09-28 poszło przy >267K, do 751K)
- Pomiar po: baseline.py: preTokens kompakcji na laptopie ~267K
- Ryzyko: Kompakcja przy ~267K, pauza p50 87 s, utrata dosłownej historii; subagenci dziedziczą okno
- Pewność: wysoka · maszyna: laptop (pc ma to już niezacommitowane) · nakład: trivial

**Ukryj nieużywane skille z claude.ai i plugin cowork** (G1c-2, G1c-1, G1, A2, D2, G1c-5, G1c-6)
- Zmiana: skillOverrides z pełnymi nazwami: off dla anthropic-skills:cloudflare, cloudflare-email-service, cloudflare-one, workers-best-practices, wrangler, google-workspace, import-memory; user-invocable-only dla the-humanizer; name-only dla docs, pdf, docx, pptx, xlsx. enabledPlugins: "cowork-plugin-management@synced": false. Nie syncClaudeAiSkills:false.
- Oszczędność: ~3,3K tokenów na sesję/subagenta z listingiem; 1,8% (1,6%)
- Pomiar po: Świeży transkrypt: 5 gołych linii '- anthropic-skills:…', listing krótszy o ~9,2K znaków
- Ryzyko: Brak; nic nie kasowane, 0 wywołań w historii
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Zablokuj nieużywane konektory claude.ai** (G3, A3)
- Zmiana: "deniedMcpServers": [{"serverName":"claude.ai Claude Docs"},{"serverName":"claude.ai Canva"},{"serverName":"claude.ai Microsoft 365"}]; ClickUp zostaje
- Oszczędność: ~1,6K na transkrypt, 0,7%; znika instrukcja 'zrób dokument FIRST'
- Pomiar po: claude mcp list na obu maszynach; brak mcp__claude_ai_Claude_Docs__* w nowym transkrypcie
- Ryzyko: Brak Claude Docs z Claude Code (0 użyć); nazwy muszą się zgadzać co do znaku
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Ogranicz bundled skille** (D5, A9)
- Zmiana: skillOverrides: name-only dla dataviz, update-config, artifact-capabilities, artifact-diagramming, artifact-design, schedule, loop; user-invocable-only dla code-review, simplify, security-review, keybindings-help, fewer-permission-prompts, init. Nie disableBundledSkills.
- Oszczędność: ~1,8K, 1,1%
- Pomiar po: /context w świeżej sesji
- Ryzyko: Słabsze automatyczne dobieranie przy niejasnych promptach
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Szybkie wygrane (config, minuty) — drobne pokrętła

**Usuń martwe narzędzia ReportFindings i ShareOnboardingGuide** (A6)
- Zmiana: "permissions": {"deny": ["ReportFindings","ShareOnboardingGuide"]} (gołe nazwy)
- Oszczędność: −1,25K na żądanie, ~1% cache reads; działa też u subagentów
- Pomiar po: /context bez tych narzędzi
- Ryzyko: Wbudowane /code-review drukuje tekstem
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Wyłącz wbudowane Explore i Plan** (D8, A6)
- Zmiana: env CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1; najpierw usuń wiersz Explore z development-workflow/SKILL.md:98
- Oszczędność: ~0,35K + znika zdanie pchające do Explore wbrew cbm-first
- Pomiar po: agent_listing_delta bez Explore/Plan
- Ryzyko: Brak (Explore 1 użycie od 08-25)
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Wyłącz podpowiedzi następnego promptu** (H1, G1a-3, F2)
- Zmiana: "promptSuggestionEnabled": false; awaySummaryEnabled zostaje
- Oszczędność: ≤1% (nie 7%)
- Pomiar po: brak ghost-textu
- Ryzyko: Akceptowane w 0,7–0,8% promptów
- Pewność: średnia · maszyna: obie · nakład: trivial

**Odetnij Artifact (i Skill u recenzentów) od agentów pipeline'u** (A1, D1)
- Zmiana: task-reviewer/branch-reviewer/plan-red-team: disallowedTools: Edit, Write, NotebookEdit, Artifact, Skill; implementer/fixer: disallowedTools: Artifact. Agent zostaje red-teamowi i branch-reviewerowi.
- Oszczędność: ~139M z 226M tokenów A1 na 8 dni; −9,8K na dispatch recenzenta (Skill)
- Pomiar po: Brak skill_listing i Artifact w nowym transkrypcie recenzenta
- Ryzyko: Brak (Artifact 0 użyć u agentów; Skill 1/540 u recenzentów); zbędne przy globalnym enableArtifact:false
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Napraw martwe klucze effort** (H2, G2a-4, F6, H6)
- Zmiana: modelSettings: "claude-opus-5-5": high, "claude-sonnet-5-5": wybrany poziom; usunąć claude-sonnet-5, claude-fable-5-1 i top-level effortLevel (działa tylko dla legacy); poprawić README.md:36 i development-workflow/SKILL.md:77,92
- Oszczędność: poprawność; Sonnet 5.5 działa dziś na medium na obu maszynach, Opus 5.5 high na pc / medium na laptopie
- Pomiar po: pole effort w nowym transkrypcie
- Ryzyko: high na Sonnecie = więcej tokenów myślenia
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Poprawki błędów — ciche błędy działające teraz

**Laptop: nieaktualny indeks gita w harmonii udaje rollback** — ODRZUCONE 2026-10-03: rozbieżność wynika z równoległej pracy na pc (sync .git przez mutagen), nie z błędu (C8)
- Zmiana: git -C ~/projects/harmonia reset -q, potem git status --porcelain puste; nie dla zs1; strukturalnie strażnik w flow-guard na git commit (indeks bez ścieżek z HEAD obecnych w working tree)
- Oszczędność: zapobiega skasowaniu 104 plików i cofnięciu 33 przy commicie na laptopie
- Pomiar po: git diff --cached --stat puste
- Ryzyko: Brak teraz (working tree = HEAD); nie robić równolegle z gitem na pc
- Pewność: wysoka · maszyna: laptop · nakład: trivial

**Uzgodnij rozjechany settings.json pc/laptop** (G2a-2, H3, G2c-2)
- Zmiana: Na pc git diff .claude/settings.json, zdecydować per kawałek, commit; laptop: zacommitować/odrzucić model, agentPushNotifEnabled, skipWorkflowUsageWarning, pull; zacommitować jawne "model": "sonnet" (bez klucza domyślny Opus 5.5 1M); na Opusa przełączać 's' w /model albo claude --model opus
- Oszczędność: warunek, by każda inna zmiana settings trafiła na obie maszyny
- Pomiar po: git status czysty na obu
- Ryzyko: Konflikt przy pull, jeśli bez commitu; nie gita równolegle
- Pewność: wysoka · maszyna: obie · nakład: small

**Usuń martwy augmenter Grep|Glob** (J5, C3, B8)
- Zmiana: Usuń blok PreToolUse Grep|Glob (settings.json:19-28) i hooks/cbm-code-discovery-gate, dotter deploy, popraw README.md:56-57; nie przepinać na Bash
- Oszczędność: poprawność dokumentacji; przepięcie kosztowałoby 2 s CPU na wyszukiwanie
- Pomiar po: brak wpisu w settings; reinstalacja cbm może go przywrócić
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Skille każą uruchamiać komendy odrzucane przez strażnik worktree** (E4, B6)
- Zmiana: flow-state przyjmuje worktree=. branch=. base=HEAD; poprawić podpowiedź hooks/flow-state:262-263; task-brief/review-package biorą plan i bazę z flow-state; check-ignore przed EnterWorktree; literalne komendy w using-git-worktrees:57-63,79-85, SDD:81-85,97-100, requesting-code-review:27-41
- Oszczędność: ~4 round tripy (~30 s) na run, ~1% tokenów głównego wątku; 57 odmów w 15 sesjach od 09-28
- Pomiar po: 0 odmów 'isolated in the worktree' w nowym runie
- Ryzyko: Zmiany skryptów wymagają testów
- Pewność: wysoka · maszyna: obie · nakład: small

**WakaTime na laptopie bez klucza API od 11 dni** (C1, C7)
- Zmiana: Przenieść api_key/api_url do ~/.config/wakatime/.wakatime.cfg (poza gitem), sprawdzić pc; opcjonalnie wakatime-cli w ~/.local/bin
- Oszczędność: poprawność (zero heartbeatów); −26% CPU pluginu z dowiązaniem
- Pomiar po: brak 'api key not found' w ~/.config/wakatime/wakatime.log
- Ryzyko: Brak auto-update CLI przy dowiązaniu
- Pewność: wysoka · maszyna: laptop (sprawdzić pc) · nakład: trivial

### Poprawki błędów — dane i konfiguracja, które się psują

**Retencja 30 dni kasuje transkrypty na obu maszynach** (G2d-5, I2, B7)
- Zmiana: "cleanupPeriodDays": 90 we wspólnym settings.json; przed ~10-21 rozstrzygnąć eksperyment plan-granularity na czystych oknach
- Oszczędność: zachowanie dowodów; najstarszy transkrypt główny 2026-09-03 13:48
- Pomiar po: transkrypty starsze niż 30 dni zostają
- Ryzyko: +0,4–0,5 GB/mies. przez sirius; sekrety żyją dłużej
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Martwe serwery MCP w vaulcie** (G6, G1f-4)
- Zmiana: Przekazać sesji vaulta: gmail, spotify, warframe dokończyć albo usunąć z ~/obsidian/.mcp.json; google-maps usunąć (podwójny start); enableAllProjectMcpServers → jawna lista
- Oszczędność: ~200 tok szumu na sesję vaulta, ~100 MiB PSS, mniej martwych procesów
- Pomiar po: brak 'failed to connect' w sesji vaulta
- Ryzyko: Konfiguracja vaulta należy do sesji vaulta
- Pewność: wysoka · maszyna: obie · nakład: small

**pc: trzecia kopia skilli Cloudflare i frontend-design** (A7, G7)
- Zmiana: Na pc ls -la ~/.claude/skills, usunąć katalogi niebędące symlinkami dotfiles; /status i znaleźć override frontend-design
- Oszczędność: ~1K tok, mniej wypychania innych skilli z przyciętego listingu
- Pomiar po: listing pc bez nieprefiksowanego wrangler
- Ryzyko: Brak
- Pewność: średnia · maszyna: pc · nakład: trivial

**Reguły analizy transkryptów** (F7, I4, G1b-7)
- Zmiana: Output subagentów od 2.1.280 liczyć z cost-state albo z korektą (~3× zaniżony); okna po timestamp, nie mtime; rozdzielać konta A i B
- Oszczędność: poprawność analiz
- Pomiar po: –
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Średnie (hooki, agenci, skille) — agenci pipeline'u

**Allowlisty tools: dla agentów pipeline'u** (B1, G5, D1, G2d-3)
- Zmiana: implementer/fixer: tools: Bash, Read, Edit, Write, ToolSearch, Monitor, TaskStop, WebFetch, WebSearch, mcp__claude-in-chrome__*, mcp__plugin_context7_context7__*, mcp__codebase-memory-mcp__*, mcp__plugin_cloudflare_cloudflare-docs__* + skills: test-driven-development; recenzenci/red-team bez Edit/Write, Agent dla red-teamu i branch-reviewera; linia o polszczyźnie w szablonie briefu
- Oszczędność: margines 1,5% (2,2%) po szybkich wygranych; samodzielnie 4,9–7,2%; pierwsze żądanie 40,6K → 15–22K
- Pomiar po: brak skill_listing/agent_listing_delta, pierwsze żądanie ~15–22K
- Ryzyko: Utrata Skill (polszczyzna przez Read); każde nowe narzędzie dopisywać ręcznie
- Pewność: wysoka · maszyna: obie · nakład: small

**Recenzent sam buduje pakiet diffu** (E3)
- Zmiana: Kontroler podaje BASE/HEAD; task-reviewer.md:36-43, branch-reviewer.md:27-33: pierwszy krok review-package, exit 4 = BLOCKED, nigdy APPROVED; usunąć krok 5 SDD i krok 2 requesting-code-review
- Oszczędność: ~2,5% kosztu głównego wątku w SDD
- Pomiar po: jedno żądanie kontrolera mniej na recenzję
- Ryzyko: Strażnik pustego zakresu zależy od recenzenta
- Pewność: wysoka · maszyna: obie · nakład: small

**Nazwane triggery dla recenzenta na Opusie** (B3)
- Zmiana: SDD/SKILL.md:116-117: auth/sekrety/niezaufane wejście, współbieżność, migracje, publiczne API; spec-sync i docs na Sonnecie; re-review dziedziczy model
- Oszczędność: ~1 $/dzień
- Pomiar po: udział Opusa w task review
- Ryzyko: Trudny diff bez triggera traci Opusa
- Pewność: średnia · maszyna: obie · nakład: trivial

**Usuń przypomnienie cbm z SubagentStart** (J6, C5, D9)
- Zmiana: Usunąć wpis settings.json:92-95; prompt-context-test:143-145 ma sprawdzać brak
- Oszczędność: ~0,1K na agenta; tekst wymienia nieistniejące Grep/Glob
- Pomiar po: brak przypomnienia w transkrypcie subagenta
- Ryzyko: Brak (treść dociera przez CLAUDE.md)
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Popraw rule 2 w CLAUDE.md** (J7, J2)
- Zmiana: Grep/Glob → grep/find przez Bash; konwencja nazwy projektu (home-m-projects-harmonia, także w worktree); zostaje 'brak indeksu → index_repository'
- Oszczędność: 14 z 21 błędów cbm to złe nazwy projektu
- Pomiar po: mniej list_projects i błędów project not found
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Średnie (hooki, agenci, skille) — hooki i status line

**Filtr if dla flow-guard na Bash** (C2)
- Zmiana: settings.json:40-46: "if": "Bash(*worktree add*)" + asercja w flow-guard-test
- Oszczędność: −82–86% spawnów Pythona, 30–40 ms blokady na każde z 1 000–7 000 wywołań/dzień
- Pomiar po: ls bez hooka, worktree add nadal blokowany
- Ryzyko: Złożone komendy i tak odpalają hook
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Leniwy import traceback w prompt-context** (C4)
- Zmiana: Usunąć linię 20, import w except
- Oszczędność: −12–18 ms na prompt i start subagenta
- Pomiar po: prompt-context-test
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Status line: limity i kontekst absolutny** (G1b-5, F4, F3)
- Zmiana: Segment rate_limits.five_hour/seven_day (used_percentage, resets_at lokalnie), kolory ≥70/≥90%; kontekst z context_window.total_input_tokens: <150K zielony, <300K żółty, ≥300K czerwony
- Oszczędność: 0 tokenów; widoczność limitu i kosztu kontekstu
- Pomiar po: raz zrzucić payload na każdej maszynie (konto Team)
- Ryzyko: Szerszy pasek
- Pewność: wysoka · maszyna: obie · nakład: small

**Opcjonalnie GIT_OPTIONAL_LOCKS=0 w statusline** (C6)
- Zmiana: env w git() w hooks/statusline
- Oszczędność: higiena
- Pomiar po: –
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Średnie (hooki, agenci, skille) — procesy na laptopie

**Watcher cbm per projekt** (J1, J8)
- Zmiana: /mcp → wyłącz codebase-memory-mcp w /home/m/obsidian i ~/work/knowledge-base (osobno na każdej maszynie), restart daemona; nie wyłączać watchera globalnie
- Oszczędność: ~5,7% rdzenia na obserwowany projekt; daemon 14–23% rdzenia
- Pomiar po: delta /proc/<pid>/stat daemona przez 60 s
- Ryzyko: Brak cbm w projektach bez użycia
- Pewność: wysoka · maszyna: laptop · nakład: trivial

**Mutagen force-poll dla cc-projects** (I1, I3)
- Zmiana: bin/mutagen-sessions:75: --watch-mode=force-poll --watch-polling-interval=30 (+ ignore '*.jsonl.wakatime'); wdrożenie maszyna po maszynie bez sesji, z preflightem rsync -rcni
- Oszczędność: daemon 3,6–6% → ~1–1,5% rdzenia; koniec 41 przepisań archiwum/min
- Pomiar po: mutagen sync list -l: Force Poll / 30 s
- Ryzyko: Opóźnienie do 60 s, flush przed szybką zmianą maszyny; recreate może zrobić konflikty
- Pewność: wysoka (mechanizm), niska wartość tokenowa · maszyna: obie · nakład: small

**Bezczynne panele na baterii** (G1f-1, G1f-3)
- Zmiana: Zamykać panele bezczynne >1 h, wznawiać claude --resume <id>; nie sesję vaulta
- Oszczędność: ~0,5–1,3% rdzenia i 200–430 MiB na panel
- Pomiar po: –
- Ryzyko: Utrata scrollbacku; procesy w tle sesji
- Pewność: średnia · maszyna: laptop · nakład: trivial

### Średnie (hooki, agenci, skille) — przepływ runu

**/clear na granicy runów** (E2)
- Zmiana: finishing: po flow-state clear ostatnia linia '/clear, /model opus, potem gotowe zlecenie następnego punktu i gdzie zapisany'; triage development-workflow: przy zakończonym runie i kontekście >120K poprosić o handoff
- Oszczędność: ~3% samodzielnie, ~0,4% po F1; 10/29 runów startowało z 131–412K, projekty na Sonnecie
- Pomiar po: 0 nowych runów w tym samym pliku sesji po finish
- Ryzyko: Dodatkowy krok użytkownika
- Pewność: wysoka · maszyna: obie · nakład: trivial

**Wpisać reguły zamiast wskaźników** (E8)
- Zmiana: Brainstorming krok 3: każde pytanie z rekomendacją; writing-plans:253: reguła drobnych zastrzeżeń z red-team.md
- Oszczędność: jakość; grill-gate.md czytany w 7% przypadków
- Pomiar po: –
- Ryzyko: Dwie wersje tekstu do synchronizacji
- Pewność: średnia · maszyna: obie · nakład: trivial

**Bez drugiego wklejania Global Constraints** (E5, E6)
- Zmiana: SDD:209 i task-reviewer.md:19-21: brief już je zawiera, nazwać tylko dotyczące diffu
- Oszczędność: mały, czysta duplikacja
- Pomiar po: –
- Ryzyko: Brak
- Pewność: wysoka · maszyna: obie · nakład: trivial

### Strukturalne (CLAUDE.md, pipeline)

**Sekcje CLAUDE.md tylko dla głównego wątku** (B2, D3)
- Zmiana: Hook SessionStart (B2) albo output style z keep-coding-instructions: true (D3); albo tylko dopisek '(dotyczy głównego wątku)' przy zasadzie 5
- Oszczędność: 1,4–2,9K na subagenta, ~1,2% zużycia
- Pomiar po: styl/hook w głównej sesji, brak w subagencie, cache_read pierwszego żądania nie spada
- Ryzyko: Odwraca D1 ze speca ADHD; utrata ramy OVERRIDE; output style znika bez dotter deploy
- Pewność: średnia · maszyna: obie · nakład: small

**Dispatch na pierwszym planie** (E1, G1a-2, G1e-4, F9)
- Zmiana: Tylko po FORK_SUBAGENT=0: run_in_background:false dla implementera, recenzentów, fixera, wymuszone w flow-guard; pilot na jednym runie
- Oszczędność: ~3% zużycia (jedno żądanie z pełnym kontekstem mniej na dispatch)
- Pomiar po: task_loop: ~6 → ~4 żądania kontrolera na czyste zadanie
- Ryzyko: Sesja zajęta, Esc anuluje implementera; ctrl+b
- Pewność: średnia · maszyna: obie · nakład: medium

**Red-team xhigh vs high: replay** (B4, G1e-2)
- Zmiana: plan-red-team-high z effort: high; replay 5–6 archiwalnych planów (w tym 2 RETHINK) w worktree na commicie planu; przełączyć tylko jeśli łapie wszystkie blokujące
- Oszczędność: ~4 min mniej czekania na bramce planu (mediana 12,1 min)
- Pomiar po: porównanie zastrzeżeń parami
- Ryzyko: Koszt 10–12 przebiegów Opusa; słabszy jedyny przedwykonawczy gate
- Pewność: niska · maszyna: obie · nakład: small

**Workflow: modele i effort per etap** (G1d-1, G1d-2, G1d-3, G1d-4, G1d-5, G1d-6, B5, G1b-4)
- Zmiana: Przy zlecaniu: opts.model 'sonnet' + effort 'high' dla zwiadu/researchu, 'opus' dla curate/dedup/critic/syntezy; weryfikatory po porównaniu pół na pół; nawyk/notatka w pamięci, nie CLAUDE.md; na pc opcjonalnie CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS=6 per sesja
- Oszczędność: ~18–20% kosztu runu, 35–39% z lekkim typem agenta
- Pomiar po: model/effort w transkryptach agentów workflow
- Ryzyko: Sonnet na etapach osądu słabszy; workflow 3 razy w 67 dni
- Pewność: średnia · maszyna: obie · nakład: small

**Zamknij eksperyment plan-granularity** (B7, I2, G1e-3)
- Zmiana: Porównać bazę 09-21 21:00–09-23 21:09 z eksperymentem 09-23 21:46–09-27 13:38 na czasie aktywnym; werdykt do speca, aktualizacja notatki i MEMORY.md
- Oszczędność: decyzja przed utratą danych (~10-21)
- Pomiar po: werdykt w specu
- Ryzyko: Konfundery (Sonnet 5.5, review-cost-cuts)
- Pewność: wysoka · maszyna: obie · nakład: small

## Czego nie robić

- **Nie zmieniaj TTL cache (FORCE_PROMPT_CACHING_5M, promptCacheTtl, subagentPromptCacheTtl 1h)** — Podział 1 h główny / 5 min subagenci jest optymalny; zmiana +16–41% kosztu (F8)
- **Nie ustawiaj CLAUDE_CODE_DISABLE_BACKGROUND_TASKS** — Zabija też Bash w tle, Monitor i ctrl+b
- **Nie ruszaj includeGitInstructions / CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS** — Na 5.5 tylko ~0,14K, zabiera gitStatus i trailer Co-Authored-By; wartość "0" wymusza instrukcje (G2b-1, G2b-2)
- **Nie obcinaj CLAUDE_CODE_MAX_MCP_DESCRIPTION_LENGTH ani bashOutputMaxChars** — Ucina reguły serwerów w połowie za 0,2%; mniejszy limit Basha wymusza ponowne odczyty (40%) za ~0,5%
- **Nie wymuszaj lekkich promptów na Haiku (CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT, CLAUDE_CODE_MODEL_CAPABILITIES)** — Wewnętrzne, kruche, zysk 0,1–0,2%
- **Nie ustawiaj crossSessionInbound hold ani nadpisania w vaulcie** — Nie oszczędza tokenów; repo może tylko zaostrzać, zablokowałoby raportowanie do vaulta (G2b-6)
- **Nie batchuj raportów do vaulta (D4) i nie ładuj INDEX.md na żądanie (A8)** — Zysk 0,1–0,3%, ryzyko utraty faktów i łamanie celowego designu
- **Nie łącz hooków SubagentStart (C5) i nie przepinaj augmentera cbm na Bash** — Kilka ms zysku vs ryzyko; hook-augment spala 2 s CPU na wyszukiwanie
- **Nie składaj komend w jedno wywołanie (B6)** — Strażnik worktree odrzuca $(...); trzeba odwrotnie (E4)
- **Nie uruchamiaj równoległych implementerów (G1e-5) ani teraz pipeliningu recenzji (G1e-1)** — Wymaga drugiego worktree blokowanego celowo przez flow-guard, daje 2–5 min na run
- **Nie odpalaj reindeksu cbm w tle (J3)** — Wolne reindeksy na pc to artefakt pomiaru (czas równoległego pytesta); w tle dodałoby turę modelu
- **Nie dziel diffu per plik u recenzenta (F5), nie przenoś Tool Routing prompt-master ani §5 polszczyzny (E7)** — Brak powtórnych odczytów do usunięcia; wskaźniki są pomijane, ryzyko jakości
- **Nie ustawiaj omitClaudeMd na implementerze/fixerze** — Utrata niezmienników prywatności z projektowego CLAUDE.md (ernest)
- **Nie wyłączaj auto-review serwera (CLAUDE_CODE_AUTO_MODE_SERVER=0) ani nie włączaj fast mode** — Lokalny klasyfikator ~1,5 s na komendę; fast mode 2× ceny
- **Nie używaj syncClaudeAiSkills:false ani disableBundledSkills** — Pierwsze przenosi pliki do .trash i blokuje wszystko; drugie zabiera claude-api i nie ukrywa skilli synced; skillOverrides wystarcza
- **Nie wyłączaj watchera cbm globalnie (J1) ani nie stosuj claudeMdExcludes globalnego CLAUDE.md w vaulcie** — Graf laptopa nie widziałby zmian z pc; vault używa pipeline'u
- **Nie podnoś autoCompactWindow ani nie dawaj Fable jako domyślnego** — Ostrzeżenie o kosztach; Fable zużywał limit ~1,1–2× szybciej niż cena list

## Kolejność wdrożenia

- 1. Laptop: git -C ~/projects/harmonia reset -q i sprawdzenie statusu (C8)
- 2. pc: uzgodnić niezacommitowany settings.json z repo, commit; laptop: pull (G2a-2)
- 3. Jeden commit config: CLAUDE_CODE_FORK_SUBAGENT=0 + linia run_in_background:true w skillach, autoCompactWindow 300000, skillOverrides (synced + bundled), cowork off, deniedMcpServers, permissions.deny, Explore/Plan off, promptSuggestionEnabled false, modelSettings 5.5, "model": "sonnet", cleanupPeriodDays 90
- 4. Frontmatter agentów: disallowedTools (Artifact, Skill u recenzentów), potem allowlisty B1 i linia o polszczyźnie w briefie
- 5. Usunięcie augmentera Grep|Glob i przypomnienia cbm, filtr if dla flow-guard, leniwy traceback
- 6. Literalne komendy w skillach i flow-state (E4), pakiet diffu u recenzenta (E3), /clear na granicy runów (E2)
- 7. Status line: rate_limits i kontekst absolutny
- 8. Rozstrzygnięcie eksperymentu plan-granularity przed ~10-21
- 9. Laptop: watcher cbm per projekt, potem mutagen force-poll
- 10. Decyzje: Artifact globalnie, Chrome, Cloudflare, B2/D3, dispatch na pierwszym planie, replay red-teamu

## Protokół pomiaru

Skrypt: /tmp/claude-1001/-home-m-dotfiles--claude/f9748903-f1c0-4838-af51-fde336b0d30c/scratchpad/review/baseline.py (tylko odczyt ~/.claude/projects, dedup po message.id, maszyna z [CTX] albo wersji; skopiuj poza /tmp, np. do ~/dotfiles/bin/). 1) Przed: `python3 baseline.py 2026-09-27 2026-10-04 > przed.txt`. Wynik z 2026-10-03: pierwsze żądanie main 49,0K laptop / 51,4K pc (p90 61K/75K), sub 35,6K / 40,6K, workflow 52,9K; 2 140M tokenów wejścia, 96,7% z cache, list $ 802 (bez korekty F7); 23 kompakcje (preTokens 167K–623K). 2) Po tygodniu: `python3 baseline.py <data wdrożenia> <data+7> > po.txt`; oczekiwane main ~36–39K bez Artifact (~44K z Artifact), sub pipeline 15–22K po B1, kompakcje na laptopie ~267K. 3) Ukryty ruch (G1a-1): dla sesji z agentami w tle porównać cost-state/lastModelUsage z sumą z transkryptów na modelu subagenta; różnica → ~0. 4) Limit: segment rate_limits w status line albo /usage; 1% okna 5 h ≈ 2,05 $ list, 1% tygodnia ≈ 12,4 $. 5) Zawsze podawać czas ekstrakcji i okno po timestamp wpisu, nie mtime (mutagen nie przenosi mtime).

## Decyzje dla Ciebie

- Artifact globalnie (enableArtifact:false, 4,9–5,4% zużycia, tracisz publikowanie; ostatnie użycie 09-05) czy tylko disallowedTools u agentów?
- Effort Sonneta 5.5: medium (dziś działa, tańszy) czy high (decyzja D1 ze speca model-handoff)? xhigh z README odradzane.
- Claude in Chrome domyślnie wyłączony (~2,4K/sesję, <1% kosztu) kosztem pamiętania o --chrome, skoro pipeline w harmonii sam weryfikował UI w przeglądarce?
- Plugin Cloudflare: wariant G2 (wyłączyć plugin, MCP docs/api dodane per maszyna) czy A4 (włączać per repo z wrangler.jsonc)? ~1% zużycia.
- Sekcje CLAUDE.md tylko dla głównego wątku (B2/D3) kosztem odwrócenia D1 ze speca ADHD — tak, nie, czy tylko dopisek przy zasadzie 5?
- skipWorkflowUsageWarning: zacommitować dla spójności, czy prawdziwa bramka permissions.ask: ["Workflow"] (do przetestowania w auto mode i ultracode)?
- WakaTime: naprawić klucz API na laptopie, czy wyłączyć plugin (settings.json:114)?
- Dispatch na pierwszym planie: czy zablokowana sesja na czas runu implementera jest akceptowalna?

## Dodatek: wszystkie ustalenia

- A1 [confirmed, high] Artifact tool schema is ~24% of every main request and rides in every pipeline subagent, but was used in 1 of 160 main sessions
- A3 [confirmed, medium] claude.ai connectors add ~3.5K tokens per request: Claude Docs ~1.4K (0 calls ever), ClickUp ~2.0K (6 of 160 sessions), Canva and M365 auth stubs ~0.1K
- A4 [confirmed, medium] The Cloudflare plugin is enabled globally, adding 15 skill entries and 11 MCP tool names (~2.3K tokens) to the ~2/3 of requests that never touch Cloudflare
- A6 [confirmed, low] Two never-used built-in tools, ShareOnboardingGuide and ReportFindings, cost ~1.25K tokens per request
- A7 [confirmed, low] pc lists 15 skills laptop lacks: unprefixed copies of 14 Cloudflare skills (a third copy of wrangler and others) plus frontend-design (~1.0K tokens per request)
- A8 [rejected, low] Vault sessions start at 60-64K because CLAUDE.md imports SOUL, USER and INDEX: ~8.1K tokens of Polish on every request
- A9 [conditional, low] Other baseline parts have knobs that are not worth turning (trivia, folded)
- B1 [confirmed, high] Pipeline agents carry ~25k never-used tokens per dispatch; add per-role `tools:` allowlists
- B2 [conditional, medium] Every subagent loads the full user CLAUDE.md (8.25k chars, ~55% main-thread-only) plus project CLAUDE.md and MEMORY.md
- B3 [conditional, medium] The Opus override fires on 36% of task reviews, including docs/spec-sync diffs and fix-range re-reviews outside its stated triggers
- B4 [conditional, medium] plan-red-team is 12-19% of each run and its cost is exploration turns, not thinking; settle the deferred xhigh→high question with data
- B5 [conditional, medium] Workflow-tool agents use the built-in all-tools type; a lean agentType would cut 16-25% of workflow cost
- B6 [rejected, low] The controller spends ~15 requests per task; merge the bookkeeping Bash calls
- B7 [confirmed, low] Plan-granularity experiment: the revert criterion is not met and the open question is answered, so the memory file is stale
- C1 [conditional, medium] WakaTime plugin: 2 node+Go spawns per tool call, ~3/4 of all hook CPU, and on laptop every heartbeat fails (no api key)
- C2 [confirmed, medium] flow-guard spawns python+git on every Bash call (57.6k/month) but can only act on `git ... worktree add` (8/month)
- C4 [confirmed, low] prompt-context imports traceback eagerly: 10-17 ms of Python 3.14 imports on every prompt and subagent start, used only on crash
- C5 [rejected, low] SubagentStart forks three processes (flow-context, cbm reminder, prompt-context) that each subagent waits for
- C6 [conditional, low] Status line is cheap and event-driven; only optional trims remain (plan re-read, 3 git calls in a worktree, optional-lock hygiene)
- C7 [confirmed, low] Hook trivia: herdr 0.5 s socket wait, vault hook cost, Python flags/exec form not worth it, wakatime side effects in the synced dir
- C8 [confirmed, high] [cross-lane I, found while timing the status line] laptop's harmonia index is stale vs synced HEAD: 104 staged deletions + 33 staged reverts
- D1 [conditional, high] Pipeline subagents get the full skill listing and agent listing but almost never use Skill or Agent
- D3 [conditional, medium] About two-thirds of the global CLAUDE.md applies only to the main thread but loads into every subagent
- D4 [rejected, medium] Each vault report wakes the vault session and costs ~255K units there
- D5 [confirmed, low] 17 bundled skill descriptions cost ~2.7K tokens; about 12 are never used
- D7 [conditional, low] Why obsidian (vault) sessions start at 43-64K tokens
- D8 [confirmed, low] Agent listing: built-in Explore and Plan are unused; the custom agent descriptions are fine
- D9 [conditional, low] Smaller items: trigger overlap, cbm restated four times, MEMORY.md, duplicate CLAUDE.md in dotfiles worktrees, harness agents
- E1 [conditional, high] Background (async) pipeline dispatches cost one wasted full-context main-thread turn each
- E2 [confirmed, high] A new run starts inside the previous run's session because nothing asks for /clear at the run boundary
- E3 [confirmed, medium] The controller spends one full-context request per review just to build the diff package
- E4 [confirmed, medium] The harness's worktree-isolation guard refuses shell blocks that the skills prescribe
- E5 [conditional, low] The execution session re-reads the whole plan, which the brief mechanism already delivers
- E6 [conditional, low] Pipeline skill bodies are 5-7% of main-thread input, with ~3.3k tokens of duplicated rules and stale copies restored after /compact
- E7 [rejected, low] Rarely loaded large skills: high cost per load, small total
- E8 [conditional, low] On-demand reference files are mostly not read, so their rules are not in context
- F1 [confirmed, high] Main sessions grow to ~967K before compacting; pin autoCompactWindow at 300K
- F3 [conditional, low] Multi-day main sessions pay a full context rewrite after every break longer than 1 h
- F4 [conditional, low] Status line shows context as % of a 1M window, so 300K reads as a green 30%
- F5 [rejected, low] Tool output growth is mostly file reading; persisted outputs get read back in full
- F7 [confirmed, medium] Subagent transcripts on 2.1.280+ record about a third of the real output tokens
- F8 [confirmed, low] The prompt-cache TTL split is already optimal: keep 1 h for main, 5 min for subagents
- F9 [conditional, low] Small fixed context adders: token-countdown reminders, async-agent boilerplate, hook text
- G1 [confirmed, medium] claude.ai-synced skills and the synced Cowork plugin load in every session and subagent; nobody has ever used them in Claude Code
- G2 [confirmed, medium] The Cloudflare plugin lists 15 skill entries that are almost never invoked; only its docs/api MCP servers are actually used
- G3 [confirmed, medium] claude.ai connectors Claude Docs (never used), Canva and Microsoft 365 (unauthenticated) ride in every session and subagent; ClickUp is used only from main sessions
- G4 [conditional, medium] Claude in Chrome is on by default on both machines but used in ~4% of main sessions
- G5 [conditional, low] Pipeline agents inherit every connector (the deferred 'tools: on agents' lane): ~25% of their opening prompt is MCP/plugin context they never use
- G6 [confirmed, low] Vault project (~/obsidian) spawns MCP servers that can never connect, and announces the failures to every vault session and its subagents
- G8 [conditional, low] Trivia: auth stubs, leftover local-scope servers and dead allow rules, unused plugin caches
- H1 [confirmed, medium] Prompt suggestions (and away recaps) fire hidden full-context side requests after almost every main-thread turn
- H2 [confirmed, medium] Effort settings are dead keys: Sonnet 5.5 runs at medium everywhere; Opus 5.5 at high on pc but medium on laptop
- H3 [conditional, medium] Uncommitted "model": "opus" makes every new laptop session Opus 5.5, because /model and /effort rewrite the git-tracked dotfiles settings
- H5 [conditional, low] Every non-allowlisted Bash call waits ~0.45 s (about 1 s last week) for server-side auto-mode review; a narrow read-only allowlist skips the wait
- H6 [conditional, low] Config trivia: no-op env var, dead allow rules, stale model names
- I1 [confirmed, medium] cc-projects mutagen session runs a full sync cycle on almost every transcript append (43/min measured); mutagen is the top CPU process on laptop
- I2 [conditional, medium] The 30-day transcript sweep is deleting the plan-granularity baseline before the comparison: 13 of 37 pre-experiment runs are gone by 2026-10-09
- I3 [conditional, low] Orphan *.jsonl.wakatime files are never swept: 764 orphans keep 195 of 301 project dirs alive and are synced for nothing
- I4 [conditional, low] Mutagen does not carry mtimes: the receiving machine re-stamps transcripts, which skews /resume order and any mtime-based analysis
- J1 [conditional, medium] cbm file watcher keeps ~15% of one laptop core busy, mostly polling projects that never use cbm (vault, dotfiles, knowledge-base)
- J2 [conditional, medium] Net value: the cbm layer is barely used and roughly token-neutral, so narrow it to main-thread work on code repos instead of pipeline-wide
- J3 [rejected, medium] Explicit reindexes block the main thread: 18.4 min since Sep 1, and on pc a harmonia reindex now takes 86-102 s
- J4 [conditional, medium] cbm version and config drift between pc and laptop; the 0.11.0 installer would re-add the SessionStart reminder removed on 2026-09-23 plus 3 agents and a skill
- J5 [confirmed, low] The PreToolUse Grep|Glob augmenter is dead on both machines, and fixing its path would not revive it
- J6 [conditional, low] Subagents carry about 450 tokens of cbm surface per request but almost never use it; the SubagentStart reminder is ineffective and out of date
- J7 [conditional, low] Rule 2 wording causes avoidable failed calls: it names nonexistent Grep/Glob tools and gives no project-name convention
- J8 [conditional, low] Laptop index cache holds 272 MB, mostly stale and worktree DBs, which also bloats list_projects output
- G1a-1 [confirmed, high] Background-agent progress summaries (agent_summary forks) cost about 10% of all usage. CLAUDE_CODE_FORK_SUBAGENT=0 turns them off
- G1a-2 [conditional, high] E1's foreground dispatch (run_in_background:false) cannot work in the default config, and F9's 'verified' is a false positive. It only works together with CLAUDE_CODE_FORK_SUBAGENT=0
- G1a-3 [confirmed, medium] F2/H1 credit hidden traffic to prompt suggestions and away recaps, but those explain at most about 30% of it. The prompt-suggestion saving is at most about $55 list, not about $257
- G1b-1 [conditional, high] Weekly limit is at 88% with ~11 h to its reset; at this audit's pace it runs out around 13:30-15:00Z today
- G1b-2 [confirmed, high] The limit meter is TTL-aware list-$ with the F7 output fix: 5-hour window ≈ $205, week ≈ $1,245 (≈6.1 five-hour windows)
- G1b-3 [conditional, high] Ranked by freed headroom: F1 leads for main-heavy windows, the fixed-prefix bundle is the only lever that helps every window, and H1 shrinks to ~1%
- G1b-4 [conditional, high] The last three 5-hour hits had three different drivers: oversized Sonnet 5 main threads (09-17), five concurrent heavy sessions on pc and laptop (09-25), and this audit's Opus 5.5 workflow (10-02)
- G1b-5 [confirmed, medium] The status line ignores rate_limits; show 5-hour and weekly utilization from the payload
- G1b-6 [confirmed, low] Fable 5.1 used the limits about 3× faster than its list price; keep it out of the default and agent model policy
- G1b-7 [confirmed, low] Limit accounting must separate the user's second account; several gap-critic facts were misattributed
- G1c-1 [confirmed, medium] skillOverrides does hide claude.ai-synced skills at runtime, so the 'docs say no' premise behind A2/D2/G1 is wrong
- G1c-2 [confirmed, medium] Per-skill design: 7 off, humanizer user-only, 5 name-only, synced cowork plugin disabled. It keeps 99% of the sync-off saving and deletes nothing.
- G1c-3 [confirmed, low] Reconciled size: 3.39K tok per transcript today (A2/D2 right), 3.0K window average (G1 right); 1.6-1.8% of total weighted usage, not 2.3%
- G1c-4 [confirmed, low] Route side effects: skillOverrides only hides; syncClaudeAiSkills:false trashes files only from user settings; claude.ai toggles cannot remove pdf/docx/pptx/xlsx
- G1c-5 [conditional, low] the-humanizer competes with polszczyzna and would inject about 15.5K tokens of English-only rules if it is picked by mistake
- G1c-6 [confirmed, low] The five synced Cloudflare skills are exact duplicates and can be hidden; the plugin's own 15 Cloudflare skills cannot be touched by skillOverrides
- G1c-7 [conditional, low] New synced skills arrive unhidden: per-skill overrides need a periodic check
- G1d-1 [conditional, high] Workflow agents inherit the session model: all 291 ran Opus 5.5; Sonnet for finder/verify stages cuts 15-26% per run, 35-52% together with B5's lean agent type
- G1d-2 [conditional, medium] Workflow agents inherit the session effort: xhigh on pc (/effort ultracode on 2.1.281) and max on laptop (/effort max)
- G1d-3 [conditional, medium] Verification is 20-59% of run cost; a second verifier lens rarely changed the outcome, and every run-size guard is off
- G1d-4 [conditional, medium] On pc the workflow concurrency cap is 4 (6-CPU i5-8600): harmonia spent 70 agent-hours queued
- G1d-5 [conditional, medium] Agents that block on long local jobs re-write their whole context when the 5-minute cache expires: 27% of the ernest run
- G1d-6 [conditional, low] Workflow scripts paste whole upstream results into every downstream prompt: 156k tokens of raw research per ernest architect
- G1e-1 [conditional, high] Pipeline review N with implementer N+1. This is the biggest active-time lever (about 19-33% of the task loop); start with the dependency-gated variant
- G1e-2 [conditional, medium] Red-team waiting is on the present user's critical path, and xhigh thinking takes about 72% of red-team request time. A/B test effort high before switching
- G1e-3 [confirmed, medium] 74% of run wall-clock is waiting on the user, and stage spans include those waits. Judge speed changes on active time
- G1e-4 [conditional, medium] Async dispatch adds no wall time, but its turn-closing request is 22-23% of implement-stage controller requests
- G1e-5 [confirmed, low] Parallel implementers in separate worktrees are not worth it: up to 13-17% with a cheap merge, and P2 gets comparable gains with one writer
- G1e-6 [confirmed, low] Haiku for paste-ready tasks is not a speed lever any more; Sonnet 5.5 is as fast
- G1f-1 [conditional, medium] Every idle herdr pane with Claude Code costs about 1.3% of a core, 300-430 MiB and about 150 wakeups/s. Panes that sit idle for more than an hour bring no cache benefit
- G1f-2 [conditional, medium] The Bun/mimalloc 'mi-scavenger' thread takes about 1% of a core in every Claude process all the time: 70-86% of idle CPU and 26-33% of all Claude CPU
- G1f-3 [conditional, medium] Session memory grows with conversation volume, not with time. An orchestrator that ran many subagents holds about 1.5 GiB until it exits
- G1f-4 [conditional, low] The always-on obsidian vault session keeps 6 node/npm MCP processes (~258 MiB RSS + ~300 MiB swap): google-maps runs twice and every npx server doubles its process count
- G1f-5 [conditional, low] While Claude works, the shared animation clock wakes the main thread every 16 ms in the focused pane and every 32 ms in unfocused ones. prefersReducedMotion would stop it
- G1f-6 [needs-other-fix, low] Each session's codebase-memory-mcp stdio child polls a parent-death watchdog every 10 ms (~99 wakeups/s), ~525 wakeups/s for 5 sessions
- G1f-7 [conditional, low] Keep tui 'fullscreen'. Its default mouse mode enables any-motion tracking (DECSET 1003), so pointer movement over a pane wakes Claude; this was not measured
- G2a-1 [confirmed, high] laptop has no auto-compact cap: F1's 300K window is net-new there and already proven on pc
- G2a-2 [conditional, medium] pc runs a diverged, uncommitted settings.json; other lanes' settings advice assumes one shared file
- G2a-3 [confirmed, medium] Auto-compact knob facts in 2.1.284: docs-research Q11 ('NOT found') is wrong
- G2a-4 [conditional, low] Effort in force differs from settings intent: sonnet-5-5 runs at medium and laptop sonnet-5 at high, not xhigh
- G2b-1 [rejected, low] includeGitInstructions removes ~2.2K tokens only on Haiku 4.5; on Opus 5.5 and Sonnet 5.5 it removes ~0.14K plus gitStatus. Not worth flipping
- G2b-2 [confirmed, low] CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS=0 does not disable git instructions: the env var is tri-state
- G2b-3 [rejected, low] The real lever behind the git block is the lean/full tool prompt split; Haiku 4.5 always gets the full set
- G2b-4 [conditional, low] Bash output cap: the knob is bashOutputMaxChars, not BASH_MAX_OUTPUT_LENGTH. Lowering it has an upper bound of 1-2% but mostly cuts deliberate reads
- G2b-5 [confirmed, low] CLAUDE_CODE_MAX_MCP_DESCRIPTION_LENGTH: only Claude Docs (1,893) and ClickUp (1,247) instructions exceed 1,024; the cap saves ≈0.2% and truncates them mid-text
- G2b-6 [rejected, low] crossSessionInbound has no token-saving mode: 'hold' only defers vault turns, 'refuse' ends vault reporting
- G2c-1 [conditional, medium] skipWorkflowUsageWarning was written when the user approved this audit's own Workflow resume on laptop. The warning never shows a cost, and any approval switches it off for good
- G2c-2 [conditional, low] "model": "sonnet" came from /model; 18 automatic default writes to the git-tracked file in 13 days, against the 09-23 decision to drop the pin
- G2c-3 [conditional, low] agentPushNotifEnabled came from the server's notification preference when Remote Control connected. It costs nothing measurable and does not act on agent completions
- G2c-4 [confirmed, low] worktree.baseRef "head", theme, tui, skipDangerousModePermissionPrompt and crossSessionInbound are committed and deliberate; none need changes
- G2d-1 [rejected, high] G1a-1 headline does not reproduce: agent_summary forks are ~7-8% of list $, not 10.0% (and ~9-10% on 2.1.280+, not 12.8%)
- G2d-2 [confirmed, medium] G1b-3 overstates the G1a lever inside the limit windows: the 10-02 windows were 77-81% workflow agents, which get no summaries
- G2d-3 [confirmed, medium] A1 and B1 reproduce: Artifact is 11.6-11.8K tokens per request, and pipeline agents carry 25-29K never-used tokens per dispatch
- G2d-4 [confirmed, low] G1b-2 reproduces: one 5-hour window ≈ $203-210 list with the published F7. F7's 1.10 chars/token is miscalibrated, but every variant stays within ±15%
- G2d-5 [confirmed, medium] Transcripts are being auto-deleted at 30 days (cleanupPeriodDays unset), and the deletion propagates to both machines through mutagen: the audit's own evidence is eroding
- G2e-1 [confirmed, high] The whole package saves about 25% of metered usage (31.6% outside the audit-workflow day), not the 33-43% you get by summing per-finding numbers
- G2e-2 [conditional, high] Sequential marginals: G1a-1 8.1%, A1 4.9%, F1 3.7%, G1c-2 1.8%, B1 1.5%; E2 drops from 3.9% to 0.4% once F1 is in
- G2e-3 [confirmed, high] Split by session class: main sessions -19.5%, pipeline subagents -47% (summaries included), Workflow agents only -11%
- G2e-4 [confirmed, medium] By machine: laptop -22.8% (-32.9% without the audit workflow), pc -30.0%
- G2e-5 [confirmed, medium] Lever-size verification: prefix sizes were measured from each transcript's own attachments; G1a-1, F1 and E2 are modelled
- G2e-6 [confirmed, medium] What the package leaves on the table: the remaining hidden helper traffic, Workflow-agent model choice and E1 are not in these numbers