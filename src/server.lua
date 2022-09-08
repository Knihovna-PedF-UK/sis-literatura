local restserver = require "src.restserver"
local database   = require "src.database"
local h5tk = require "h5tk"

local template = [[<!DOCTYPE html>
<html><head><meta charset="utf-8" /><title>${title}</title>
<style type="text/css">
body {max-width:65ch;margin:1em auto;}
</style>
</head><body>
<h1>${title}</h1>
${content}
</body>
</html>
]]

local h = h5tk.init()
local db_name = arg[1]
database.init(db_name)
local server = restserver:new():port(8080)


local function expand(tpl, variables)
  return tpl:gsub("%$%{(.-)%}", variables)
end

local function print_candidates(result)
  local t = {}
  for _, v in ipairs(result.candidates) do
    table.insert(t, h.tr{h.td {h.a {href="/match/" .. v.id, v.citation}}, h.td{v.callno}})
  end
  return h.table{ 
    h.tr{h.th {"Autor + název"}, h.th {"Signatura"}},
    t 
  }
end




local function get_candidates(id)
  local result, msg = database.find_citation(id)
  if not result  then
    return expand(template, {title = "Chyba", content = h.p {msg}})
  end
  local content = h.section {
    h.h2{"Citace ze SIS"}, 
    h.p { result.citation }, 
    h.p {h.b {"Předmět: "}, result.class},
    h.p {h.a {href="/nomatch/" .. result.id, "Není shoda"}, " / " , h.a{href="/nobook/" .. result.id, "Není kniha"},
    print_candidates(result)
  }
  }
  return expand(template, {title = "Spáruj citace", content = content})
end

server:add_resource("", {
  {
    method = "GET",
    path = "/",
    produces = "text/html",
    handler = function()
      print "Load page"
      local page = get_candidates()
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },
})

server:enable("restserver.xavante"):start()
