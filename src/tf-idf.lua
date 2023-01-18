unpack = table.unpack
require "numlua"


local a = matrix{2,1,0,3}
local b = matrix{0,3,0,0}
local c = matrix{2,0,1,2}



local m = matrix.concat(a,b,c)
m:list()

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

local lower = string.lower

local function tokenize(text)
  local tokens = {}
  for word in text:gmatch("(%a+)") do
    table.insert(tokens, lower(word))
  end
  -- print(table.concat(tokens, " "))
  return tokens
end

local function make_index(documents)
  -- keep current token number 
  local last_word = 0
  local number_of_documents = #documents
  -- mapping from words to token numbers
  local index = {}
  local backindex = {}
  -- tokens and number of documents where they occured
  local token_counts = {}
  -- helper table, where documents with tokens and their counts will be kept
  local doc_helper = {}
  for docno, text in ipairs(documents) do
    local tokens = tokenize(text) 
    local doc_tokens = {}
    local no_of_words = #tokens
    for _, tok in ipairs(tokens) do
      -- get token number
      local tok_no = index[tok] 
      if not tok_no then
        -- if word doesn't have token number, assign a new one
        last_word = last_word + 1
        tok_no = last_word
        index[tok] = tok_no
        backindex[tok_no] = tok
      end
      -- count occurences of token in the current doc
      local count = doc_tokens[tok_no] 
      if not count then
        -- update number of documents where token was used
        token_counts[tok_no] = (token_counts[tok_no] or 0)  + 1
        count = 0
      end
      doc_tokens[tok_no] = count + 1
    end
    -- count term frequency
    local term_frequencies = {}
    for tok_no, count in pairs(doc_tokens) do
      term_frequencies[tok_no] = count / no_of_words
    end
    doc_helper[docno] = term_frequencies
  end
  -- process the document subtotals and count tf_idf for all tokens
  local tf_idfs = {}
  for docno, term_frequencies in ipairs(doc_helper) do
    local row = {}
    -- loop over all terms in the current doc, and calculate tf_idf
    for tok_no, tf in pairs(term_frequencies) do
      -- calculate tf_idf and save it under token number in the current document
      row[tok_no] = tf * log((number_of_documents + 1)/ ((token_counts[tok_no] or 0) + 1))
    end
    tf_idfs[docno] = row
  end
  return index, tf_idfs
  

end

local function search(text, tf_idfs, index)
  local text = text or ""
  local tokens = tokenize(text)
  local tok_numbers = {}
  for _, token in ipairs(tokens) do
    table.insert(tok_numbers, index[token]) 
  end
  local matches = {}
  -- loop over all documents and calculate sum of matched tokens tf_idfs
  for docno, counts in ipairs(tf_idfs) do
    local count = 0
    for _, tok_no in ipairs(tok_numbers) do
      -- try to find the current token in the document
      count = count + (counts[tok_no] or 0)
    end
    matches[#matches+1] = {count = count, doc = docno}
  end
  -- sort 
  table.sort(matches, function(a,b)
    return a.count > b.count
  end)
  return matches
end



local text = [[
Numeric Lua is a numerical package for the Lua programming language. It includes support for complex numbers, multidimensional matrices, random number generation, fast Fourier transforms, and special functions. Most of the routines are simple wrappers for well known numerical libraries: complex numbers and part of the extended math modules come from C99; other special functions, including statistical functions, are adapted from Netlib's SLATEC and DCDFLIB; random number generation is based on Takuji Nishimura and Makoto Matsumoto's Mersenne Twister generator as the "engine" (uniform deviates) and Netlib's RANLIB for the remaining deviates; fast Fourier transforms are implemented from FFTW; and the matrix package draws most of its numeric intensive routines from Netlib's ubiquitous BLAS and LAPACK packages.

Numeric Lua tries to maintain Lua's minimalist approach by providing bare-bone wrappers to the numerical routines. The user can use the outputs for further computations and is then fully responsible for the results. Other Lua features are also available, such as OO simulation through metamethods and functional facilities. A basic API is provided in order to promote extensibility. Also, check numlua.seeall for a quick way to start using Numeric Lua.

Numeric Lua is licensed under the same license as Lua -- the MIT license -- and so can be freely used for academic and commercial purposes.
]]




local documents = text:explode(".")
local index, tf_idfs = make_index(documents)

local matches = search("also, check numlua", tf_idfs, index)

for k,v in ipairs(matches) do
  print(v.count, documents[v.doc])
end

-- print(tf(m, 2,2))
-- print(idf(m, 2))
print(tf_idf(m,2,2))
print(tf_idf(m,3,3))


