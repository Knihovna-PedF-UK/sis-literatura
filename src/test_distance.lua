
local search = require "src.search"
local database = require "src.database"
local calc_distance = search.calc_distance
local original = "BLAŽEK, B. Tváří v tvář obrazovce. Praha: SLON, 1995. ISBN 978-80-00-00000-8"
local clean_sis = search.clean_sis
local clean_alma = search.clean_alma
local make_ngrams = search.make_ngrams
local make_vectors = search.make_vectors
local cosine_dist = search.cosine_dist
local tokenize = search.tokenize



local searches = [[
Blažek, Bohuslav, 1942-2004. Tváří v tvář obrazovce /. 1995
Blažek, Zdeněk, 1905-1988. Dvojsměrná alterace v harmonickém myšlení /. 1949
Blažek, Jaroslav. Přehled chemického názvosloví /. 1995
Blažek, Vlastimil, 1878-1950. Mozart 1787-1937 Praha /. [1937?]1937
Blažek, Miroslav, 1916-1983. Sídla v Československu : nástin vývoje sídel a jejich územní organisace /. 1951
Blažek, František, 1815-1900. Cvičení v harmonisování a kontrapunktování : (dodatek k nauce o harmonii) /. 1878
Blažek, Vlastimil, 1878-1950. Bohemica v Lobkovském zámeckém archivu v Roudnici n./L. /. 1936
Blažek, Bohuslav,. Víc než pomoc sobě : svépomocné skupiny v České republice /. 1994
Blažek, Bohuslav, 1942-2004. Krása a bolest : úloha tvořivosti, umění a hry v životě trpících a postižených /. 1985
Blažek, Zdeněk, 1905-1988. Tři zpěvy podzimu : zpěv a klavír : op. 46 /. 1958
Blažek, Filip, 1974-. Typokniha : průvodce tvorbou tiskovin /. 2020
Blažek, Petr. Delikvence : analýza produktů činnosti delikventní subkultury jako diagnostický a resocializační nástroj /. 2019
Blažek, Radek. Publikace s uvolněnými úlohami z mezinárodního šetření PISA 2015 : úlohy z přírodovědné gramotnosti a metodika tvorby interaktivních úloh /. 2017
Blažek, Vlastimil, 1878-1950. Bertramka /. 1934Dt2548
Blažek, Radek. Publikace s uvolněnými úlohami z mezinárodního šetření PISA : úlohy z přírodovědné gramotnosti pro základní školy a víceletá gymnázia /. 2019
Blažek, Bohuslav, 1942-2004. Venkov, města, média /. 1998
Blažek, Matyáš, 1844-1896. Mluvnice jazyka českého. 1879
Blažek, Jaroslav. Současné chemické názvosloví /. 1978
Blažek, Vratislav, 1925-1973. Příliš štědrý večer : komedie o prologu, třech obrazech a epilogu /. 1961Be6554
Blažek, Bohuslav, 1942-2004. Zprávy z babylónské věže /. 1984
Blažek, Matyáš, 1844-1896. Spůsobové básnictví a jejich literatura : jakožto úvod do dějin literatury /. 1877
Blažek, Miroslav, 1916-1983. Hospodářský zeměpis Československa : učební text pro jedenáctileté střední školy, školy pedagogické a odborné /. 1954Ar304
Blažek, František, 1815-1900. Theoreticko-praktická nauka o harmonii : pro školu a dům /. 1866
Blažek, Zdeněk, 1905-1988. Čtyři skladby pro housle a klavír, op. 48 : violino = Vier Stücke für Violine und Klavier /. 1976
Blažek, Matyáš, 1844-1896. Věcné vyučování ve škole obecné /. 1880Ar1463
Blažek, Jaroslav, 1925-. Algebra a teoretická aritmetika. 1984F27259Sc2090/4a
Blažek, Bohuslav, 1942-2004. Mezi vědou a nevědou /. 1978
Toman, Marek, 1967-. Odsunuté děti / scénáře a texty: Marek Toman, editor Jan Blažek ; nakreslili: Jakub Bachorík, Magdalena Rutová, Stanislav Setinský, Františka Loubat, Jindřich Janíček. 20212Be290
Blažek, Miroslav, 1916-1983. Zeměpis pro 4. třídu gymnasií a pro 3. třídu vyšších hospodářských škol /. 1950Ar229a
Blažek, Roman. Nebezpečí sekt /. 2002
Blažek, Vilém, 1900-1974. Čtvero instruktivních skladbiček, op. 25 piano /. 1973
Blažek, Jaroslav, 1925-. Algebra a teoretická aritmetika. 1979Sc2090/1i
Blažek, Jaroslav, 1925-. Algebra a teoretická aritmetika. 1985
Blažek, Zdeněk, 1905-1988. Maličkosti : instruktivní skladbičky : pianoforte. 1984F27259Sc2090
Blažek, Petr, 1973-. Fakta a lži o komunismu : co byla normalizace /. 2022
Blažek, Zdeněk, 1905-1988. V zamyšlení Žertem (klavír 3. ročník) /. 1973
Blažek, Zdeněk, 1905-1988. Písničky na dobrou noc 10 instruktivních klavírních skladbiček pro nejmenší na čtyři ruce /. 1972
Blažek, Jaroslav. Přehled chemického názvosloví /. 1988
Blažek, Jaroslav, 1925-. Algebra a teoretická aritmetika. 1983Sc2090/3b
Blažek, Zdeněk, 1905-1988. Dětem : [cyklus klavírních skladbiček pro děti] : piano 2 ms. 1982
Blažek, Radek. Mezinárodní šetření PISA 2015 : národní zpráva : přírodovědná gramotnost /. 2016
Blažek, Radek. Národní zpráva PISA 2015 : národní zpráva : týmové řešení problému : dotazníkové šetření /. [2017]2017
Blažek, Radek. Mezinárodní šetření PISA 2018 : národní zpráva /. 2019
Blažek, Jaroslav, 1925-. Algebra a teoretická aritmetika. 1983Sc2090F26751/1chch
Blažek, Zdeněk, 1905-1988. Dětem : cyklus klavírních skladbiček pro malé přátele : piano 2 mns /. [1940]1940
Blažek, Jaroslav. Přehled chemického názvosloví /. 1986
Blažek, Zdeněk, 1905-1988. III. smyčcový kvartet pro dvoje housle, violu a violoncello, op. 53. 1959
Blažek, Miroslav, 1916-1983. Hospodářský zeměpis Sovětského svazu a Československa : pro jedenáctý postupný ročník všeobecně vzdělávacích škol pro školy pedagogické a hospodářské /. 1955Ar298
Blažek, Jiří, 1939-1986. Třídnické hodiny jako prostředek výchovné práce /. 1959C587Dt997
Blažek, Petr, 1973-. Jan Palach '69 /. 2009
Blažek, Zdeněk, 1905-1988. Maličkosti : instruktivní skladbičky : piano. 1973
Blažek, Jaroslav. Chemie pro studijní obory SOŠ a SOU nechemického zaměření /. 1999
Blažek, Matyáš, 1844-1896. Mluvnice jazyka českého : pro školy střední a ústavy učitelské. 1880Ar1463Ar750
]]

local t = {}
for _,line in ipairs(searches:explode("\n")) do
  t[#t+1] = {text = line, weight = calc_distance(original, line)}
end

database.init(arg[1])
table.sort(t, function(a,b) return a.weight > b.weight end)

-- for k,v in ipairs(t) do print(v.weight, v.text) end
-- print(original)

local function text_to_ngram(text)
  local clean_text = table.concat(tokenize(text), " ")
  return make_ngrams(clean_text)
end

for i =1, 500 do
  local current = database.find_citation()
  local original = current.citation
  local orig_ngram= text_to_ngram(clean_sis(original))
  local t = {}
  for _, rec  in ipairs(current.candidates) do
    local line = rec.citation
    local alma_ngram = text_to_ngram(clean_alma(line))
    local vect_a, vect_b = make_vectors(orig_ngram, alma_ngram)
    t[#t+1] = {
      text = line, 
      -- weight = calc_distance(original, line),
      cosine = cosine_dist(vect_a, vect_b)
    }
  end
  -- table.sort(t, function(a,b) return a.weight < b.weight end)
  -- local result = t[1]
  table.sort(t, function(a,b) return a.cosine > b.cosine end)
  local cosresult = t[1]
  if cosresult then
    -- print "**********************"
    -- print(original)
    -- print(result.weight, original, result.text, cosresult.cosine, cosresult.text)
    print(cosresult.cosine, original, cosresult.text)
  end
end
