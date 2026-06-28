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

Pełny opis: ~/.claude/AGENTIC-WORKFLOW.md
