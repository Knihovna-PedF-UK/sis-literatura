package.path = "src/?.lua;" .. package.path
local restserver = require "src.restserver"
local database   = require "src.database"
local h5tk = require "h5tk"

local template = [[<!DOCTYPE html>
<html><head><meta charset="utf-8" /><title>${title}</title>
<style type="text/css">
body {max-width:75ch;margin:1em auto;}
tr {background-color: #FFF6D4; }
td {padding-bottom: 8pt;}
tr:first-child {background-color: #FF540A;}
tr:nth-child(even) {background-color: #FFE680;}
.sis-citation{border: 1px solid black; padding: 3pt;}
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
    table.insert(t, h.tr{h.td {h.a {href="/match?id=" .. result.id .. "&mid=" .. v.id, v.citation}}, h.td{v.callno}})
  end
  return h.table{ 
    h.tr{h.th {"Autor + název"}, h.th {"Signatura"}},
    t 
  }
end


local function redirect(path)
  print "redirecting"
  local tpl = [[<head>
    <meta http-equiv="Refresh" content="0; URL=${url}">
  </head>
  ]]
  -- local host = req.headers.host .. path
  return expand(tpl, path)
end



local function get_candidates(id)
  local result, msg = database.find_citation(id)
  if not result  then
    return expand(template, {title = "Chyba", content = h.p {msg}})
  end
  local content = h.section {
    h.h2{"Citace ze SIS"}, 
    h.p {class="sis-citation", result.citation }, 
    h.p {h.b {"Předmět: "}, result.class},
    h.p {h.a {href="/nomatch?id=" .. result.id, "Není shoda"}, " / " , h.a{href="/nobook?id=" .. result.id, "Není kniha", " / " .. h.a{href="/end", "Konec"}},
    print_candidates(result)
  }
  }
  return expand(template, {title = "Spáruj citace", content = content}), result
end

server:add_resource("", {
  {
    method = "GET",
    -- path = "/nomatch/([0-9]+)",
    path = "/nomatch",
    produces = "text/html",
    handler = function(par)
      local id = par.id
      print("Nomatch: " .. id or "")
      if id then
        local status, msg = database.set_sis_alma_id(id, 0)
        if not status then print(msg) end
      end
      local page = redirect("/")
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },
  {
    method = "GET",
    path = "/",
    produces = "text/html",
    handler = function()
      print "Load page"
      local page, result = get_candidates()
      if #result.candidates == 0 then
        local id = result.id
        print("No matches for this id: " .. id or "")
        if id then
          local status, msg = database.set_sis_alma_id(id, 0)
          if not status then print(msg) end
        end
        page = redirect("/")
      end
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },
  {
    method = "GET",
    -- path = "/nomatch/([0-9]+)",
    path = "/nobook",
    produces = "text/html",
    handler = function(par)
      local id = par.id
      print("Not a book: " .. id or "")
      if id then 
        local status, msg = database.set_sis_alma_id(id, -1)
        if not status then print(msg) end
      end
      local page = redirect("/")
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },
  {
    method = "GET",
    -- path = "/nomatch/([0-9]+)",
    path = "/match",
    produces = "text/html",
    handler = function(par)
      print("match: " .. par.id or "" .. " - " .. par.sid or "")
      local page = redirect("/")
      if par.id then 
        local status, msg = database.set_sis_alma_id(par.id, par.mid)
        if not status then print(msg) end
      end
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },
  {
    method = "GET",
    -- path = "/nomatch/([0-9]+)",
    path = "/end",
    produces = "text/html",
    handler = function(par)
      print("End")
      database.close()
      os.exit()
      -- local page = msg
      -- local page = "<!DOCTYPE html><body>Hello"
      return restserver.response():status(200):entity(page)
    end,
  },

  -- {
  --   method = "GET",
  --   -- path = "/nomatch/{id:[0-9]+}",
  --   path = "/nomatch",
  --   produces = "text/html",
  --   handler = function()
  --     print("Nomatch " + id)
  --     local page = redirect(restserver.request(), "/")
  --     -- local page = get_candidates()
  --     -- local page = msg
  --     -- local page = "<!DOCTYPE html><body>Hello"
  --     return restserver.response():status(200):entity(page)
  --   end,

  -- }
})

server:enable("restserver.xavante"):start()
