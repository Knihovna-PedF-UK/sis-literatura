-- here I am playing with numlua methods
unpack = table.unpack
require "numlua"
local search = require "src.search"
local calc_distance = search.calc_distance
local clean_sis = search.clean_sis
local clean_alma = search.clean_alma
local make_ngrams = search.make_ngrams
local make_vectors = search.make_vectors
local cosine_dist = search.cosine_dist
local tokenize = search.tokenize



local a = matrix{2,1,0,3}
local b = matrix{0,3,0,0}
local c = matrix{2,0,1,2}


-- pokus s maticema
-- local m = matrix.concat(a,b,c)
local m = matrix {
{2,1,0,3},
{0,3,0,0},
{2,0,1,2}
}
m:list()

-- 
local second = matrix{{4},{2},{3}}

-- zkouším třídění pole
local indices = matrix.sort(second:copy(), false, true)
print "********"
-- 
indices:list()
-- kopírujeme řádky do sloupců
second = second:spread(2,4)

print "--------------"
second:list()


print "--------------"
local xxx = matrix.div(m,  second)
xxx:list()

local s = matrix.sum(matrix.col(m,2))

local x = matrix.sum(m:get(1))

local tf = function(m,docno,word)
  local doc = m:get(docno)
  return doc[word] / doc:sum()
end

local log = math.log

local idf = function(m, word)
  local N = m:size()
  -- local df = matrix.sum(matrix.col(m,word))
  local df = matrix.fold(matrix.col(m,word), function(init, n) local init = init or 0 if n > 0 then return init + 1 else return init end end)
  return log((N+1)/(df+1))
end

local tf_idf = function(m, docno, word)
  return tf(m, docno,word) * idf(m,word)
end


print(tf_idf(m, 1,1))

-- tohle můžeme využít na sečtení počtu opakování tokenu v dokumentu
local f = stat.factor {12,34,44,44,12,34,11}

for k,v in ipairs(f()) do
  print(k,v, (#f)[k])
end


print "*************"
-- takhle inicalizujeme vektor a nastavíme hodnotu
local aaa = matrix.zeros(33,1) 
aaa:set(12,43)



