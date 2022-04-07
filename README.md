# Literatura ze SIS

Dostali jsme soubor s doporučenou literaturou ze SISu. Pokusím se ho zpracovat
a porovnat s literaturou z Almy.

# Metoda

Ze záznamů z Almy vytvářím index, kde každé slovo z názvů obsahuje seznam ID záznamů, které ho obsahují.

Ze souboru ze SIS získám seznam citací, které pak hledám v indexu. Vrací se pole, které obsahuje seznam ID dokumentů z Almy, které se našly.
Každé ID má přidělenou váhu která je: `počet shodných tokenů / počet tokenů v citaci`.

Pokud je váha prvního výsledku vyšší, než minimální práh (0.4 defaultně), bereme to jako shodu.



# Použití:

    ./src/sisliteratura data/literatura_2021.xlsx data/jednotky_alma.xml > vysledek.html

Citace obsahujou HTML kód, takže vytváříme HTML tabulku.

# Konfigurace

V `src/sisliteratura` můžeme nastavit hodnotu prahu

    local treshold = 0.4

V `src/readalma.lua` je mapování políček z XML souboru z Almy:

    local mapping = {
      C2 = "callno",
      C16 = "sysno",
      C17 = "author",
      C18 = "title", 
      C19 = "year"
    }

Je možné, že bude třeba mapování opravit, pokud se změní pořadí políček v tom XML exportu.

V `src/readsis.lua` může být třeba opravit čísla sloupců v XLSX souboru ze SISu:


    local class_column = 1
    local citation_column = 3

V `src/search.lua` můžeme nastavit váhu pro prvního autora:

    local name_weight = 4

