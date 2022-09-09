local xlsx = require "spreadsheet.spreadsheet-xlsx-reader"
local log = require "spreadsheet.spreadsheet-log"

log.level = "error"

local class_column = 1
local year_column  = 2
local citation_column = 3

local function get_isbn(line)
  return line:match("([0-9][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-][0-9%-Xx]+)")
end

local function get_citations(text)
  local text = text or ""
  local citations = {}
  -- remove this string
  text = text:gsub("_x000D_", "\n")
  text = text:gsub("_x005F", "\n")
  -- small fixes
  text = text:gsub("\r", "\n")
  -- replace sequence of nonbreaking spaces by newline
  text = text:gsub("\194\160\194\160[\194\160]+", "\n")
  -- replace sequence of spaces
  text = text:gsub("   %s+", "\n")
  -- put extra newlines after <br> tag
  text = text:gsub("<br[^>]*>", "<br />\n")
  for line in text:gmatch("([^\n]+)") do
    local i = 0
    -- count punctuation. citation should have at least three punctuations
    for x in line:gmatch("[%.%,%:]") do i = i + 1 end
    -- also if line contains isbn, it is a citation
    local isbn = get_isbn(line)
    if i > 2  or isbn then
      citations[#citations+1] = line
    end
  end
  return citations
end

local function load(filename)
  -- load xlsx file and get worksheet
  local lo, msg = xlsx.load(filename)
  if not lo then return lo, msg end
  local sheet,msg  = lo:get_sheet(1)
  if not sheet or not sheet.table then return nil, msg end
  local records = {}
  local id = 0
  -- process rows
  for k,v in pairs(sheet.table) do
    local class = v[class_column][1].value -- first cell is class id
    local year = v[year_column][1].value -- first cell is year
    -- local rec = {
    --   class = v[1][1].value, -- first cell is class id
    --   citations = {}
    -- }
    -- get list of citations
    local citations = get_citations(v[citation_column][1].value) -- third cell is list of literature
    -- add citations to record. assign unique id to each citation
    for _, cit in ipairs(citations) do
      id = id + 1
      -- print(id, cit)
      table.insert(records, {id = id, value = cit, class = class, year=year})
    end
    -- table.insert(records, rec)
  end
  return records
end


return {
  load = load
}
