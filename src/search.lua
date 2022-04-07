
local lower = unicode.utf8.lower

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

local function search(text)
  local found_ids = {}
  local tokens = tokenize(text)
  -- find position of the first non numeric token
  -- it should be author's name
  local name_pos = 1
  for i, tok in ipairs(tokens) do
    if not tonumber(tok) then
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



-- add_document(1, "nazdar světe, jak se máš?")
-- add_document(2, "ahoj světe, co děláš?")
-- add_document(3, "něco úplně jinýho")

-- local results = search("ahoj světe, něco děláš")

-- for _, res in ipairs(results) do
--   print(res.id, res.weight)
-- end




return {
  tokenize = tokenize,
  add_document = add_document,
  search = search,
  strip_tags = strip_tags
}


