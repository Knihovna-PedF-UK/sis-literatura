
local lower = unicode.utf8.lower

local numlua = require "numlua"
local dot = matrix.dot
-- we use calculation method from https://towardsdatascience.com/understanding-cosine-similarity-and-its-application-fd42f585296a
local square = function(a) 
  local a = a
  return a^2 
end

local sqrt = math.sqrt

local function magnitude(matr)
  return sqrt(matrix.sum(matrix.map(matr, square)))
end

local function cosine_dist(a,b)
  local product = dot(a,b)
  return product / (magnitude(a) * magnitude(b))
end

-- we don't work with utf8, but it doesn't matter in this case
local slen = string.len
local sub = string.sub

local function make_ngrams(text, len)
  local len = len or 3
  local ngram = {}
  for i = 1, slen(text) - len + 1 do
    local curr = sub(text, i, i + len - 1)
    table.insert(ngram, curr)
  end
  return ngram
end

-- combine ngrams for two texts, and make matrices for them
local function make_vectors(a,b)
  --- keep track of used ngrams
  local used = {}
  local position = 0
  local update_useds = function(x)
    for _, ngram in ipairs(x) do 
      if not used[ngram] then
        position = position + 1
        used[ngram] = position
      end
    end
  end
  local create_vector = function(x)
    local counts = {}
    local t = {}
    -- count occurences of the current ngram in string
    for _, ngram in ipairs(x) do
      counts[ngram] = (counts[ngram] or 0) + 1
    end
    -- create vector
    for ngram, pos in pairs(used) do
      t[pos] = counts[ngram] or 0
    end
    return matrix(t)
  end
  -- make database of all used ngrams in both strings
  update_useds(a)
  update_useds(b)
  return create_vector(a), create_vector(b)
end

-- index
local search_table = {}

-- we give more weight to name
local name_weight = 4



local function escape_pattern(text)
  -- Escaping strings for gsub
  -- https://stackoverflow.com/a/34953646/7543474
  return text:gsub("([^%w])", "%%%1")
end

-- prepare punctuation removing tables
local puncts = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
local escape_puncts = escape_pattern(puncts)
local escaped_puntcts = string.format("[%s]+", escape_puncts)



local function tokenize(text)
  -- local text = text or ""
  local t = {}
  for word in text:gmatch("([^%s^%,^%.]+)") do
    word = word:gsub(escaped_puntcts, "")
    if word ~= "" then
      t[#t+1] = lower(word)
    end
  end
  return t
end


local function add_document(id, text)
  local tokens = tokenize(text)
  -- add document id to the search_table for each token
  for _, tok in ipairs(tokens) do
    local current = search_table[tok] or {}
    current[id] = true
    search_table[tok] = current
  end
end

ulen = utf8.len
local function is_name(tok)
  if tonumber(tok) then return false end
  if ulen(tok) < 3 then return false end
  return true
end

local function search(text)
  local found_ids = {}
  local tokens = tokenize(text)
  -- find position of the first non numeric token
  -- it should be author's name
  local name_pos = 1
  for i, tok in ipairs(tokens) do
    if is_name(tok) then
      name_pos = i
      break
    end
  end
  for i, tok in ipairs(tokens) do
    -- find all records that contain this token
    local documents = search_table[tok] or {}
    for id, _ in pairs(documents) do
      local count = found_ids[id] or 0
      -- give more weight to the author name
      if i == name_pos then
        count = count + name_weight
      else
        count = count + 1
      end
      found_ids[id] = count
    end
  end
  local results = {}
  -- now weight results
  for id, count in pairs(found_ids) do
    results[#results+1] = {id = id, weight = count / #tokens}
  end
  table.sort(results, function(a,b) return a.weight > b.weight end)
  return results

end


local function strip_tags(text)
  return text:gsub("<[^>]->", "")
end


--[[
    Function: EditDistance
    Finds the edit distance between two strings or tables. Edit distance is the minimum number of
    edits needed to transform one string or table into the other.
    
    Parameters:
    
        s - A *string* or *table*.
        t - Another *string* or *table* to compare against s.
        lim - An *optional number* to limit the function to a maximum edit distance. If specified
            and the function detects that the edit distance is going to be larger than limit, limit
            is returned immediately.
            
    Returns:
    
        A *number* specifying the minimum edits it takes to transform s into t or vice versa. Will
            not return a higher number than lim, if specified.
            
    Example:
        :EditDistance( "Tuesday", "Teusday" ) -- One transposition.
        :EditDistance( "kitten", "sitting" ) -- Two substitutions and a deletion.
        returns...
        :1
        :3
            
    Notes:
    
        * Complexity is O( (#t+1) * (#s+1) ) when lim isn't specified.
        * This function can be used to compare array-like tables as easily as strings.
        * The algorithm used is Damerau–Levenshtein distance, which calculates edit distance based
            off number of subsitutions, additions, deletions, and transpositions.
        * Source code for this function is based off the Wikipedia article for the algorithm
            <http://en.wikipedia.org/w/index.php?title=Damerau%E2%80%93Levenshtein_distance&oldid=351641537>.
        * This function is case sensitive when comparing strings.
        * If this function is being used several times a second, you should be taking advantage of
            the lim parameter.
        * Using this function to compare against a dictionary of 250,000 words took about 0.6
            seconds on my machine for the word "Teusday", around 10 seconds for very poorly 
            spelled words. Both tests used lim.
            
    Revisions:
        v1.00 - Initial.
]]


local ulen = utf8.len
local ucodepoint = utf8.codepoint
local min = math.min
local max = math.max

-- modified version from this gist: https://gist.github.com/Nayruden/427389
function edit_distance( s, t, lim )
    local s_len, t_len = ulen(s), ulen(t) -- Calculate the sizes of the strings or arrays
    if lim and math.abs( s_len - t_len ) >= lim then -- If sizes differ by lim, we can stop here
        return lim
    end
    
    -- Convert string arguments to arrays of ints (ASCII values)
    if type( s ) == "string" then
        s = { ucodepoint( s, 1, s_len ) }
    end
    
    if type( t ) == "string" then
        t = { ucodepoint( t, 1, t_len ) }
    end
    
    -- local min = math.min -- Localize for performance
    local num_columns = t_len + 1 -- We use this a lot
    
    local d = {} -- (s_len+1) * (t_len+1) is going to be the size of this array
    -- This is technically a 2D array, but we're treating it as 1D. Remember that 2D access in the
    -- form my_2d_array[ i, j ] can be converted to my_1d_array[ i * num_columns + j ], where
    -- num_columns is the number of columns you had in the 2D array assuming row-major order and
    -- that row and column indices start at 0 (we're starting at 0).
    
    for i=0, s_len do
        d[ i * num_columns ] = i -- Initialize cost of deletion
    end
    for j=0, t_len do
        d[ j ] = j -- Initialize cost of insertion
    end
    
    for i=1, s_len do
        local i_pos = i * num_columns
        local best = lim -- Check to make sure something in this row will be below the limit
        for j=1, t_len do
            local add_cost = (s[ i ] ~= t[ j ] and 1 or 0)
            local val = min(
                d[ i_pos - num_columns + j ] + 1,                               -- Cost of deletion
                d[ i_pos + j - 1 ] + 1,                                         -- Cost of insertion
                d[ i_pos - num_columns + j - 1 ] + add_cost                     -- Cost of substitution, it might not cost anything if it's the same
            )
            d[ i_pos + j ] = val
            
            -- Is this eligible for tranposition?
            if i > 1 and j > 1 and s[ i ] == t[ j - 1 ] and s[ i - 1 ] == t[ j ] then
                d[ i_pos + j ] = min(
                    val,                                                        -- Current cost
                    d[ i_pos - num_columns - num_columns + j - 2 ] + add_cost   -- Cost of transposition
                )
            end
            
            if lim and val < best then
                best = val
            end
        end
        
        if lim and best >= lim then
            return lim
        end
    end
    
    return d[ #d ]
end

-- like
local function calc_distance(sis, alma)
  -- clean both records first
  local clean_sis = sis:gsub("ISBN", ""):gsub("[0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-]?[0-9%-]?[0-9%-]?[0-9%-]?", "")
  clean_sis = clean_sis:gsub("[0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-]", "")
  -- odstraň vydání
  clean_sis = clean_sis:gsub("[0-9]%.?%s*vyd[ání]?", "")
  clean_sis = clean_sis:gsub("[Vv]yd[ání]?%.? [0-9]", "")
  -- odstraň strany
  clean_sis = clean_sis:gsub("[0-9]+%s*s%.", "")
  -- zkus odstranit vydavatele
  clean_sis = clean_sis:gsub("[^%.]+:[^%.]-([0-9]+)", "%1")
  -- remove auhtor year from the first part of citation
  local clean_alma = alma:gsub("^([^%.]+)", function(author) 
    return author:gsub("[0-9].*", "") 
  end)
  local token_sis = table.concat(tokenize(clean_sis))
  local token_alma = table.concat(tokenize(clean_alma))
  local length_diff = ulen(token_sis) - ulen(token_alma)
  local distance = edit_distance(token_sis, token_alma) 
  -- print(token_sis, token_alma)
  return(distance / ulen(token_sis) )
end

-- add_document(1, "nazdar světe, jak se máš?")
-- add_document(2, "ahoj světe, co děláš?")
-- add_document(3, "něco úplně jinýho")

-- local results = search("ahoj světe, něco děláš")

-- for _, res in ipairs(results) do
--   print(res.id, res.weight)
-- end
--
-- calc_distance("Němec, Zbyněk a kol. Asistence ve vzdělávání žáků se sociálním znevýhodněním. Vyd. 1. Praha: Nová škola, 2014. 138 s. ISBN 978-80-903631-9-9.", "xxx")



-- calc_distance(original, "Blažek, Bohuslav, 1942-2004. Tváří v tvář obrazovce /. 1995")
return {
  tokenize = tokenize,
  add_document = add_document,
  search = search,
  strip_tags = strip_tags,
  edit_distance = edit_distance,
  calc_distance = calc_distance
}


