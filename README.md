# Literatura ze SIS

Dostali jsme soubor s doporučenou literaturou ze SISu. Pokusím se ho zpracovat
a porovnat s literaturou z Almy.

# Metoda

Ze záznamů z Almy vytvářím index, kde každé slovo z názvů obsahuje seznam ID záznamů, které ho obsahují. Potřebuju XML získaný pomocí "Seznam jednotek dle knihovny a umístění" v analytickym dashboardu.

Ze souboru ze SIS získám seznam citací, které pak hledám v indexu. Vrací se pole, které obsahuje seznam ID dokumentů z Almy, které se našly.
Každé ID má přidělenou váhu která je: `počet shodných tokenů / počet tokenů v citaci`.

Pokud je váha prvního výsledku vyšší, než minimální práh (0.4 defaultně), bereme to jako shodu.

# Instalace

Potřebujeme knihovny Numlua, Sqlite3 a Xavante

Pro instalaci Numlua je třeba nejdřív nainstalovat tyhle balíčky:

    $ sudo dnf install lapack-devel hdf5-devel fftw-devel blas-devel

Pak můžeme nainstalovat asi tuhle verzi, která řeší kompatibilitu s novějšími verzemi Lua: https://github.com/notCalle/numlua

# Jen seznam citací 

Můžeme jen vygenerovat seznam citací z XLSX souboru ze SISu. Ten pak můžeme použít třeba v Anystyle nebo nějakym LLM pro získání strukturovanejch dat.

Použití:

     $ texlua src/getcitations.lua data/literatura_2021.xlsx | sort -u > data/citace.txt


# Použití:

    ./src/sisliteratura data/literatura_2021.xlsx data/jednotky_alma.xml data/sqlite.db  > vysledek.html

Citace obsahujou HTML kód, takže vytváříme HTML tabulku, a zároveň se data zapíšou do sqlite tabulky, která se předává ve 3. argumentu.

Zároveň ten příkaz vytvoří Sqlite databázi, která jde využít s aplikací pro párování záznamů. Ta se spouští pomocí:

     lua src/server.lua data/sqlite.db

V prohlížeči pak spustíme stránku `localhost:8080/` a  můžeme párovat záznamy.

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

