# Skill knowledge-transfer (2026-10-08)

Dotfiles nie mają żywego `spec.md`, więc ten rekord niesie zarówno decyzję,
jak i deliberację (tak jak `2026-10-03-setup-perf-audit-design.md`). Źródła:
plane.so (6 kategorii wiedzy, proces w 6 krokach), TalentLMS (identyfikuj →
priorytetyzuj → zbierz → przekaż → oceń), Wikipedia (tacit/explicit, SECI,
absorptive capacity), SoftwareMill (głównie marketing, mało konkretu). bit.ai
nieczytelne (zepsuty łańcuch certyfikatów TLS) — szablonu nie odtwarzano
z pamięci.

## Problem

Wiedza o projekcie, która ginie przy przekazaniu, to wiedza ukryta: pułapki,
obejścia, objawy awarii, „dlaczego tak, a nie inaczej”, do kogo eskalować.
`spec.md` (writing-specs) mówi, czym projekt jest, rekordy `.flow/specs` —
dlaczego zapadły decyzje, `handoff` — jak agent ma kontynuować sesję. Żaden
nie jest pisany pod konkretnego człowieka-odbiorcę ani nie sprawdza, że
odbiorca da sobie radę.

## Decyzje

| # | Decyzja | Odrzucone warianty i dlaczego |
|---|---|---|
| D29 | Skill `knowledge-transfer`: Claude wydobywa wiedzę (repo + wywiad) i składa **datowany snapshot pod odbiorcę** `docs/kt/YYYY-MM-DD-<profil>.md`. Profile: `następca`, `ja-później`, `support` (osoba półtechniczna). Tryb `projekt` (skan repo) albo `temat` (bez repo, ścieżka wyjścia obowiązkowa, `~/obsidian` wyłączony — do vaulta tylko wskaźnik). Przebieg: intake → skan → ✋ inwentarz z priorytetami + 5–8 scenariuszy z kluczem → wywiad tylko na lukach (każde pytanie z hipotezą z repo) → pakiet → cold-reader (≤ 2 rundy łatania, reszta do sekcji „Luki”) → ✋ końcowa = commit samego pakietu. KT czyta spec, nigdy go nie edytuje; sprzeczność spec–repo idzie do „Luk” i raportu. Sekrety: tylko miejsce, nigdy wartość. Polski przez `polszczyzna`, dla `support` prosty język. Sekcje per profil: macierz w SKILL.md (wariant A) | Claude konsumuje pakiet, by samemu się wdrożyć / oba kierunki / Claude prowadzi sesje uczące — użytkownikowi potrzebny jest dokument dla człowieka. Dwa osobne skille projekt/temat — ten sam proces, temat to projekt bez skanu. Katalog-pakiet `docs/kt/<profil>/` — więcej plików do utrzymania bez zysku. Żywy `docs/onboarding` — rozjeżdża się ze specem; snapshot z datą i SHA nie kłamie o swoim wieku. Pakiet poza repo — brak śladu przekazania. Wywiad najpierw (jak writing-specs) — droższy czas użytkownika; bez środkowej bramki — zły dobór treści wychodzi dopiero w gotowym pakiecie. Pełne szablony w `profiles.md` (wariant B) — opłaca się dopiero przy > ~50 liniach na profil. Odbiorca „uczeń” i „klient” — poza zakresem (użytkownik ich nie wskazał) |
| D30 | Weryfikacja: agent `kt-cold-reader` z `tools: TodoWrite`, bez `mcpServers`, pakiet wklejony w prompt **bez kluczy odpowiedzi**; „nie wiem z pakietu” albo zgadywanie = luka. Model: Haiku dla `support`, Sonnet dla `następca` i `ja-później`. Wyjątek od D12: tu cała rola agenta polega na tym, że nie ma narzędzi | `general-purpose` jako cold-reader — ma Read/Bash, odpowie z kodu i test przestaje mierzyć kompletność pakietu. `tools: []` — Claude Code odmawia startu („would be spawned with zero tools”, code.claude.com/docs/en/errors.md). Sama sekcja „Sprawdź się” bez subagenta — luki wychodzą dopiero u człowieka. Model recenzenta ≥ autora (development-workflow) — nie dotyczy, to zastępca odbiorcy, nie recenzent. Agenda sesji/follow-upu z odbiorcą — poza zakresem |

## Poza zakresem

- Sprawdzanie czytelności dla człowieka: cold-reader mierzy kompletność, nie
  przyswajalność; tę pokrywa prosty język i sekcja „Sprawdź się” dla odbiorcy.
- Aktualizacja starych pakietów — snapshot się nie aktualizuje, robi się nowy.

## Do sprawdzenia w implementacji

- Czy `TodoWrite` jest dostępny subagentom w bieżącej wersji Claude Code;
  jeśli nie, agent nie wystartuje i trzeba wskazać inne nieszkodliwe narzędzie.

## Testy skilla (baseline wg writing-skills)

Oczekiwane porażki agenta bez skilla, poproszonego o „dokument przekazania”:
przepisuje treść speca zamiast wiedzy ukrytej i linków; oddaje pakiet bez
weryfikacji; wpisuje dane uwierzytelniające do sekcji dostępów.
