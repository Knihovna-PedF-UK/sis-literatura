local domobject = require "luaxml-domobject"
local xml_parser = require "luaxml-mod-xml"

-- mapping between child elements and names
local mapping = {
  C2 = "callno",
  C16 = "sysno",
  C17 = "author",
  C18 = "title", 
  C19 = "year"
}

local function load(filename)
  -- DOM object is too slow  for this, see the newload function for what we use
  local f, msg = io.open(filename, "r")
  if not f then return nil, msg end
  print "start"
  local text =f:read("*all")
  f:close()
  print "xml read"
  local dom = domobject.parse(text)
  print "dom parsed"
  local records = {}
  for _, rec in ipairs(dom:query_selector("R")) do
    local current = {}
    for _, child in ipairs(rec:get_children()) do
      if child:is_element() then
        local name = child:get_element_name()
        local mapped_name = mapping[name]
        if mapped_name then
          current[mapped_name] = child:get_text()
        end
      end
    end
    local id = current.sysno
    if id and not records[id] then
      print(id, current.callno, current.author, current.title, current.year)
      records[id] = current
    end
  end
  return records
end


-- @param filename -- ALMA XML file 
-- @param fn -- callback function that will be executed on each individual record
local function newload(filename, fn) 
  local f, msg = io.open(filename, "r")
  if not f then return nil, msg end
  local text =f:read("*all")
  f:close()
  local records = {}
  local current = {}
  local current_name 
  local handler = function()
    local obj = {}
    obj.starttag = function(self, name, attr)
      local mapped_name = mapping[name]
      if mapped_name then
        current_name = mapped_name
      else
        current_name = nil
      end
    end
    obj.endtag = function(self, name)
      if name == "R" then
        local id = current.sysno
        if id and not records[id] then
          -- print(id, current.callno, current.author, current.title, current.year)
          records[id] = current
          if fn then
            fn(current)
          end
        end
        current = {}
      end
    end
    obj.text = function(self, text)
      if current_name then
        current[current_name] = text
      end
    end
    return obj
  end
  local parser = xml_parser.xmlParser(handler())
  parser:parse(text)
  return records
end

return {
  load = newload
}
