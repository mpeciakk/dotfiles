---
name: polszczyzna
description: Pisanie i redagowanie polskiego tekstu przeznaczonego dla ludzi — dokumentacja, spec.md, README, komunikaty błędów i UI, maile, opisy commitów i PR-ów, raporty, oferty. Łączy normę (ortografia RJP od 2026, interpunkcja, fleksja, składnia) ze standardem prostego języka (BLUF, krótkie zdania, strona czynna) i wycinaniem fraz zdradzających tekst generowany. Nie używaj do kodu, cytatów, tekstów literackich ani do zwykłej rozmowy w czacie.
---

# Polszczyzna

Tekst ma być **poprawny** (norma), **zrozumiały przy pierwszym czytaniu** (prosty język) i **nie brzmieć jak wygenerowany** (brak manier modelu). W tej kolejności: błąd poprawiasz zawsze, prostotę stosujesz prawie zawsze, maniery tniesz na końcu.

## Kiedy to stosować

Stosuj, gdy powstaje polski tekst, który ktoś przeczyta jako produkt: dokumentacja, `spec.md`, README, komentarz do PR-a, opis commitu, komunikat błędu, tekst UI, mail, raport, oferta, post.

Nie stosuj: w kodzie i identyfikatorach, w cytatach i tekstach cudzych (błąd w cytacie oznacz `(sic!)`), w tekstach prawnych w ścisłym sensie (umowa, akt notarialny), w literaturze i świadomej stylizacji, w zwykłej rozmowie w czacie.

## Zasada nadrzędna: trzy werdykty

Każda uwaga do tekstu dostaje **dokładnie jedną** etykietę. Nigdy nie nazywaj preferencji błędem.

- **[BŁĄD]** — forma spoza normy, poprawiasz zawsze. `wziąść`, `poszłem`, `przekonywujący`, `odnośnie czegoś`, `za wyjątkiem`, brak przecinka przed `że`.
- **[WARIANT]** — poprawne w normie użytkowej (mowa, cytat, luźna wypowiedź), niepoprawne we wzorcowej. Poprawiasz w tekstach oficjalnych, zostawiasz w cytowanej mowie. `widzę tą firmę`, `zjadłem kotleta`, `póki co`, `w nawiązaniu do`, `pod rząd`.
- **[STYL]** — poprawne w obu normach, zmieniasz z innego powodu: szablon urzędowy, wyraz modny, rozwlekłość, maniera modelu. `w chwili obecnej`, `tylko i wyłącznie`, `realizować`, `poprzez` zamiast `przez`.

Test: jeśli nie masz źródła, najwyżej [STYL], nigdy [BŁĄD]. Częstość nie zmienia werdyktu — ani „wszyscy tak mówią”, ani „mnie to razi”.

## 1. Architektura tekstu

- **BLUF** — wniosek w pierwszym zdaniu albo pierwszym akapicie. Czytelnik ma móc przerwać po nim i nadal wiedzieć, o co chodzi.
- **Kontekst just-in-time** — tylko tyle, ile potrzeba do następnego kroku. Test akapitu: da się go pominąć i nadal wykonać zadanie? Wytnij albo przenieś niżej.
- **Od znanego do nowego** — nowe pojęcie kotwicz w znanym. Nigdy dwie nieznane rzeczy w jednym zdaniu. Wewnątrz zdania: znane na początku, nowe na końcu.
- **Zdanie tematyczne** — akapit otwiera zdanie, które mówi, o czym ten akapit jest. Reszta je rozwija. Jeden akapit = jeden wątek. Nagłówki bez kropki na końcu.

## 2. Składnia

- **Zdanie ≤ 20 słów.** Przy 25+ znajdź najbliższy spójnik (`i`, `oraz`, `ponieważ`, `który`, `że`) i postaw tam kropkę. Jedno zdanie = jedna myśl.
- **Mieszaj długości.** Trzy zdania tej samej długości z rzędu to metronom.
- **Strona czynna z żywotnym podmiotem.** `Zespół wdrożył X`, nie `X zostało wdrożone`. Nazwij, kto działa.
- **Czasownik zamiast rzeczownika odczasownikowego.** `wdrożyliśmy`, nie `dokonaliśmy wdrożenia`; `sprawdź`, nie `dokonaj sprawdzenia`. Kontrola: policz `-anie`, `-enie`, `-cie`, `został*`, `-ąc`. Dużo trafień → przepisz.
- **Imiesłów na `-ąc` ma ten sam podmiot co zdanie główne** i czynność równoczesną; `-łszy`, `-wszy` — wcześniejszą. `Wchodząc do firmy, powitał mnie zarząd` to **[BŁĄD]**.
- **Twierdząco zamiast przecząco.** `Zapłać w terminie`, nie `Nie spóźnij się z opłatą`.
- **Osobowo.** `my`/`ja` zamiast form bezosobowych; do odbiorcy wprost: `Pan/Pani/Państwo` albo `ty`, konsekwentnie w całym tekście.
- **Nie skracaj składni na siłę.** `przed filmem i po nim`, nie `przed i po filmie` **[BŁĄD]** — różne przyimki, różne przypadki.
- **Związek zgody.** `część zespołu korzysta`, nie `korzystają`.
- **Nazwiska odmieniaj.** `raport Kowalskiej`, `rozmowa z Nowakiem`. Nieodmienione polskie nazwisko w tekście oficjalnym to **[BŁĄD]**, nie uprzejmość.

## 3. Zwięzłość

Zwięzłość to nie krótkość. Krótkie zdanie może być rozwlekłe, długie może być zwarte. Chodzi o to, żeby **każde słowo pracowało** — zdanie nie ma zbędnych wyrazów tak, jak rysunek nie ma zbędnych linii.

**Konstrukcja analityczna → czasownik.** Najproduktywniejsze cięcie w polszczyźnie. Czasownik posiłkowy (`dokonać`, `przeprowadzić`, `podejmować`, `poddawać`, `ulec`, `składać`, `udzielać`, `posiadać`) plus rzeczownik odczasownikowy to zawsze jeden czasownik:

`dokonać analizy` → `przeanalizować` · `przeprowadzić badanie` → `zbadać` · `podejmować decyzję` → `decydować` · `poddawać dyskusji` → `dyskutować` · `ulec uszkodzeniu` → `uszkodzić się` · `udzielić informacji` → `poinformować` · `składać podpis` → `podpisywać` · `posiadać wiedzę` → `wiedzieć` · `zadawać pytanie` → `pytać` · `zostać poinformowanym` → `dowiedzieć się`

**Pleonazm → jeden wyraz.** `okres czasu` → `czas` · `w miesiącu lipcu` → `w lipcu` · `w dniu dzisiejszym` → `dzisiaj` · `cofać się do tyłu` → `cofać się` · `wracać z powrotem` → `wracać` · `najbardziej optymalny` → `optymalny` · `moja osobista opinia` → `moja opinia` · `maksymalny limit` → `limit` · `miasto Warszawa` → `Warszawa` · `dwie alternatywy` → `alternatywa`. Pełna lista: `references/norma.md`.

**Wata do wycięcia bez zamiennika.** `w celu` → `żeby` · `w przypadku gdy` → `gdy` · `z uwagi na fakt, że` → `bo` · `w zakresie` → wytnij · `w ramach` → wytnij · `jeśli chodzi o` → wytnij · `należy zauważyć, że` → wytnij · `który jest` → wytnij (`funkcja, która jest odpowiedzialna za` → `funkcja odpowiedzialna za`).

**Paralelizm.** Człony współrzędne mają tę samą budowę gramatyczną. Dotyczy punktów listy, kroków instrukcji, nagłówków sekcji, komórek w kolumnie tabeli i członów w zdaniu. Złamany paralelizm czyta się jak potknięcie, nawet gdy każdy człon z osobna jest poprawny.

- ❌ `Rozpakuj archiwum`, `zmiana nazwy pliku`, `żeby otworzyć w przeglądarce`
- ✅ `Rozpakuj archiwum`, `zmień nazwę pliku`, `otwórz w przeglądarce`

Ta sama rola = ta sama forma. Jeśli pierwszy punkt zaczyna się czasownikiem w trybie rozkazującym, wszystkie zaczynają się czasownikiem w trybie rozkazującym.

**Akcent na końcu zdania.** Pozycja końcowa jest w polszczyźnie najmocniejsza, a szyk masz swobodny — korzystaj z tego. Słowo, na którym ma zostać czytelnik, stawiaj na końcu, nie w środku.

- Słabo: `Jedna kara kosztuje 5 sekund, o czym trzeba pamiętać przy liczeniu.`
- Mocno: `Przy liczeniu pamiętaj o jednym: kara kosztuje 5 sekund.`

**Konkret zamiast oceny.** Rzeczownik i czasownik konkretny biją przymiotnik oceniający. `wzrost o 12%` zamiast `znaczący wzrost`, `odpowiedź w 40 ms` zamiast `szybka odpowiedź`, `trzy pliki` zamiast `kilka plików`. Przymiotnik oceniający bez liczby obok — usuń przymiotnik albo znajdź liczbę.

**Przebieg tnący.** Po napisaniu przejdź tekst drugi raz, wyłącznie po to, żeby skracać. Zdrowy cel to **15–20% krócej** bez straty treści. Jeśli nie da się wyciąć nic, prawdopodobnie czytasz za pobieżnie.

## 4. Interpunkcja

**Przecinek stawiasz:** przed zdaniem podrzędnym niezależnie od szyku (`Wiem, że zdąży`; `Zanim wdrożymy, przetestujemy`); z obu stron wtrącenia; przed `a`, `ale`, `lecz`, `jednak`, `natomiast`, `zaś`, `więc`, `dlatego`, `zatem`, `czyli`, `to znaczy`; między jednorodnymi częściami bez spójnika; przy powtórzonym spójniku (`i szybko, i tanio`); przy imiesłowach na `-ąc`, `-łszy`, `-wszy`; przy wołaczu.

**Przecinka nie stawiasz:** przed pojedynczym `i`, `oraz`, `lub`, `albo`, `bądź`, `czy`, `ani`; przed `a` łącznym i w `między… a…`; między przydawkami nierównorzędnymi (`stary drewniany dom`); między dwoma sąsiadującymi spójnikami (`a gdy skończymy, wdrożymy`); przed porównaniem bez orzeczenia (`prosty jak drut`) — ale przed zdaniem porównawczym z orzeczeniem tak (`szybciej, niż zdąży się zaparzyć kawa`).

**Spójniki zestawione** biorą przecinek przed całością: `mimo że`, `chyba że`, `dlatego że`, `tym bardziej że`, `podczas gdy`, `tak że`, `podobnie jak`. Ale gdy `tak`/`wtedy` wprowadza zdanie podrzędne, przecinek je rozdziela: `Zrób tak, aby nie zepsuć`.

**Myślnik jest poprawnym polskim znakiem** z ośmioma funkcjami (m.in. wydzielanie wtrąceń, człon domyślny: `Rano kawa, wieczorem – herbata`). Twierdzenie, że pauza w polskim tekście to anglicyzm, jest nieprawdziwe. Ale modele go nadużywają, więc: używaj oszczędnie i świadomie, nie jako domyślnej pauzy retorycznej — masz przecinek, dwukropek, kropkę i nawias. Kształt (`—` albo `–`) konsekwentny w całym tekście, ze spacjami po obu stronach. **Półpauza bez spacji** w zakresach: `9.00–17.00`, `5–10%`, `Paryż–Dakar`. **Dywiz `-` to nie myślnik** — łączy człony (`biało-czerwony`, `ZUS-em`).

**Reszta:** cudzysłów `„ ”`, wewnętrzny `» «`, kropka po cudzysłowie zamykającym; wielokropek jako jeden znak `…`; dwukropek przed wyliczeniem zapowiedzianym, nie przed dwoma członami z `i`; pytajnik tylko gdy pytające jest zdanie nadrzędne (`Nie wiem, czy zdążę` — bez pytajnika); kropki nie stawiasz po wykrzykniku, pytajniku ani wielokropku.

## 5. Ortografia — zmiany obowiązujące od 1 stycznia 2026

Reforma RJP (komunikat z 10.05.2024 ze zmianą z 07.11.2025) zmieniła **tylko pisownię konwencjonalną, nie interpunkcję**. Najczęściej potrzebne:

- Mieszkańcy miast i dzielnic **wielką literą**: `Łodzianin`, `Warszawianin`, `Mokotowianin`.
- Cząstki `-bym`, `-byś`, `-by` **rozdzielnie ze spójnikami**: `czy by nie spróbować`, `albo by został`.
- `Nie-` z imiesłowami odmiennymi **zawsze łącznie**: `nieprzeszkolony`, `niewdrożony`, `nieopisany`.
- `Nie-` z przymiotnikami i przysłówkami **łącznie w każdym stopniu**: `niemiły`, `niemilszy`, `nienajlepiej`.
- Przymiotniki od nazw osobowych **małą literą**: `dramat szekspirowski`, `koncepcja kartezjańska`.
- Obiekty przestrzeni publicznej z wyrazem rodzajowym **wielką**: `Plac Zbawiciela`, `Most Poniatowskiego`. **`Ulica` zawsze małą**: `ulica Piotrkowska`.
- Lokale: `Kino Charlie`, `Hotel pod Różą`, `Restauracja Veganic`.
- Przedrostki, które istnieją też jako osobne wyrazy, wolno rozdzielnie: `superpomysł` lub `super pomysł`, `ekożywność` lub `eko żywność`.
- Wyraz gatunkowy przed nazwą **małą** — `jezioro Śniardwy`, `cieśnina Bosfor` (punkt o wielkiej literze wycofano w 2025).

Reszta list: `references/norma.md`.

## 6. Słownictwo

Wytnij cztery grupy i jedną formułę:

- **Kancelaryzmy:** `niniejszym`, `w nawiązaniu do`, `w przedmiotowej sprawie`, `na dzień dzisiejszy`, `w chwili obecnej`, `aczkolwiek`.
- **Archaizmy:** `iż` → `że`, `albowiem` → `ponieważ`, `posiadać` → `mieć`, `takowy`, `tudzież`.
- **Wyrazy modne:** `dedykowany`, `implementacja`, `realizować`, `aktualnie`, `generalnie`, `obligatoryjny`, `szereg`, `optymalny`, `rekomendacja`, `w temacie`.
- **Kalki:** `odnośnie czegoś` → `co do` **[BŁĄD]**, `za wyjątkiem` → `z wyjątkiem` **[BŁĄD]**, `w pierwszym rzędzie` → `przede wszystkim` **[BŁĄD]**, `z dużej litery` → `wielką literą` **[BŁĄD]**, `wiodący` → `główny` **[BŁĄD]**, `w oparciu o dane` → `na podstawie danych` **[BŁĄD]**, `adresować problem` → `zająć się problemem` **[STYL]**, `wydaje się być` → `wydaje się` **[STYL]**.
- **Puste formuły — usuń, nie zastępuj:** `Pragnę nadmienić, że…`, `Uprzejmie informuję…`, `Chciałem zapytać…`, `W trosce o najwyższą jakość…`.

**Pleonazmy [BŁĄD]:** `cofać się do tyłu`, `potencjalne możliwości`, `najbardziej optymalny`, `wzajemna kooperacja`.

**Wyjątek dla tekstu technicznego:** terminologia branżowa zostaje. `commit`, `deploy`, `branch`, `merge`, `endpoint`, `cache` to nazwy rzeczy, nie kalki do tępienia — jedna nazwa ma stale oznaczać to samo. Tępisz anglicyzmy tam, gdzie istnieje zwykły polski odpowiednik i nic nie tracisz: `call` → `spotkanie`, `feedback` → `informacja zwrotna`, `procesować` → `przetwarzać`. Nie upraszczaj kosztem precyzji.

Pełna tabela z werdyktami i źródłami: `references/norma.md`.

## 7. Maniery modelu — wycinasz zawsze

**Frazy:** `Warto zauważyć, że…`, `Należy podkreślić…`, `Kluczowe jest…`, `Co ciekawe…`, `Tak naprawdę…`, `Bez wątpienia`, `Niewątpliwie`, `po prostu`, `dosłownie`, `zasadniczo`, `W dzisiejszych czasach…`, `W dobie…`, `Podsumowując…`, `Co więcej…`, `Ponadto…`, `Jak już wspomnieliśmy…`.

**Struktury:**
1. Binarny kontrast — `To nie X, to Y`, `Pytanie nie brzmi X, brzmi Y`. Napisz od razu Y.
2. Negatywne listowanie — `Nie A. Nie B. To C.` Napisz C.
3. Dramatyczna fragmentacja — `X. I tyle. Tak po prostu.` Pełne zdania.
4. Retoryczny setup — `Co jeśli…?`, `Pomyśl o tym.` Postaw tezę.
5. Fałszywa sprawczość — `raport pokazuje`, `dane mówią`, `decyzja się wyłania`. Nazwij, kto zrobił.
6. Staccato trójki — `Szybko. Tanio. Skutecznie.` Dwa elementy albo jeden konkret.
7. Magiczne kwantyfikatory — `zawsze`, `nigdy`, `każdy`. Liczba albo przedział.
8. Puste zapowiedzi — `Implikacje są znaczące`. Nazwij implikację.
9. Kwotowalne puenty — jeśli zdanie brzmi jak pull-quote, przepisz je na informację.


**Czego NIE wycinać** (anglojęzyczne listy anty-slop mylą się tutaj): grzeczności biznesowej (`Dzień dobry`, `Szanowni Państwo`, `Z poważaniem`), czasowników CTA (`Sprawdź`, `Pobierz`), terminologii fachowej.

## 8. Typografia

Twarda spacja po jednoliterowych `a`, `i`, `o`, `u`, `w`, `z` — wszędzie, gdzie tekst jest składany, także na slajdach i grafikach. Polskie znaki diakrytyczne zawsze, także w wersalikach. Cudzysłów `„ ”`, apostrof `’`, wielokropek `…`. Separator dziesiętny to przecinek (`3,5 godziny`), separator tysięcy to spacja nierozdzielająca (`1 500 zł`). Jednostki ze spacją (`10 kg`), procent bez (`40%`). Bez podwójnych spacji i bez spacji przed interpunkcją. Bez Title Case w polskich nagłówkach (`Dlaczego audyt SEO to pierwszy krok`, nie `Dlaczego Audyt SEO To Pierwszy Krok`). Całych zdań nie zapisujesz wersalikami.

Liczebnik porządkowy cyfrą z kropką (`w 3. kwartale`), po cyfrach rzymskich bez (`XXI wiek`). Data cyframi z kropkami (`31.08.2026`) albo z miesiącem słownie bez kropek (`31 sierpnia 2026 r.`) — jeden wzorzec w całym dokumencie. Skróty: bez kropki, gdy zawierają ostatnią literę wyrazu (`dr`, `nr`, `zł`, `kg`); z kropką, gdy ucięto końcówkę (`prof.`, `ul.`, `np.`, `ok.`, `itd.`). Skrótowce w odmianie z łącznikiem: `ZUS-em`, `PAN-u`.

**W plain-texcie** (mail, terminal, formularz) nie używasz pogrubień markdown — gwiazdki wyświetlą się dosłownie.

## Kontrola przed oddaniem tekstu

1. Wniosek jest w pierwszym akapicie?
2. Średnia długość zdania poniżej 20 słów? Żadne nie przekracza 30?
3. Strona bierna i rzeczowniki odczasownikowe rzadkie? Żadnej konstrukcji `dokonać/przeprowadzić + rzeczownik`?
4. Człony list, kroków i nagłówków zbudowane tak samo (paralelizm)?
5. Przeszedłeś tekst drugi raz wyłącznie po to, żeby ciąć? O ile się skrócił?
6. Pierwsze zdanie to konkret, nie filler i nie preambuła?
7. Każdy przymiotnik oceniający ma obok liczbę? Jak nie ma — usuń.
8. Przecinki przed `że`, `który`, `bo`, `gdy`, `jeśli` stoją? Przed pojedynczym `i` nie stoją?
9. Cudzysłowy polskie? Twarde spacje po `a`, `i`, `o`, `u`, `w`, `z`?
10. To samo słowo nie wraca w jednym zdaniu?
11. Żadna uwaga korektorska nie nazywa preferencji błędem?

## Kiedy sprawdzić w źródle, a nie zgadywać

Przy pisowni `ó`/`u`, `rz`/`ż`, `ch`/`h` w rzadkim wyrazie, przy odmianie obcego nazwiska, przy pełnej nazwie instytucji, przy wątpliwym przecinku i **przy każdej etykiecie [BŁĄD] nadawanej po raz pierwszy**. Kolejność: Zasady pisowni i interpunkcji RJP (ze zmianą z 11.2025) → Wielki słownik ortograficzny PWN (sjp.pwn.pl/so) → Poradnia językowa PWN (sjp.pwn.pl/poradnia). Nazw własnych i cytatów nie poprawiasz.
