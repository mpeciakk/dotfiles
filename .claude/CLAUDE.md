# Workflow (domyślny dla wszystkich projektów)

Kolejność: brainstorming → grilling (jeśli plan wymaga rozkruszenia) →
codebase-design/domain-modeling → writing-plans → TDD →
executing-plans/subagentów → systematic-debugging → verification → review → simplify.

Zasady:
1. Skille procesowe (brainstorming, systematic-debugging, TDD) PRZED domenowymi.
2. Nawigacja po kodzie — cbm MCP PRZED Grep/Read. Szukasz symbolu/funkcji/klasy →
   search_graph; kto-co-woła / łańcuch wywołań → trace_path; źródło symbolu →
   get_code_snippet; struktura projektu → get_architecture. Grep/Glob/Read tylko do
   tekstu, configów i plików nie-kodu (oraz zawsze Read przed edycją pliku).
3. Każda biblioteka/API → context7 (/docs), nie zgaduj z pamięci.
4. Nic nie jest „zrobione" bez uruchomienia i dowodu.

Dyscyplina kodu (Karpathy — zawsze; przy trywialnych zadaniach zdrowy rozsądek):
- Prostota: minimum kodu rozwiązujące problem; nic ponad to, o co proszono; bez
  abstrakcji dla kodu użytego raz, bez nieproszonej elastyczności/konfigurowalności,
  bez obsługi niemożliwych przypadków. Jak 200 linii da się w 50 — przepisz.
- Zmiany chirurgiczne: ruszaj tylko to, co wynika z zadania (każda zmieniona linia ma
  wprost wynikać z prośby); nie „ulepszaj" sąsiedniego kodu/komentarzy/formatowania,
  nie refaktoruj tego, co nie jest zepsute, trzymaj istniejący styl; martwy kod zgłoś,
  nie usuwaj — usuń tylko to, co Twoja zmiana osierociła.
- Nie zgaduj: nazwij założenia, pokaż warianty zamiast cicho wybierać, zaproponuj
  prostsze podejście gdy istnieje, dopytaj gdy niejasne.

Pełny opis: ~/.claude/AGENTIC-WORKFLOW.md (pełne guidelines: skill karpathy-guidelines)
