local sqlite3 = require "lsqlite3"

kpse.set_program_name "luatex"
local readalma = require "src.readalma"

local db_name = arg[1]

local function help()
  print "usage:"
  print "  texlua src/almatosql.lua db_name.sql alma_data.xml"
end

if not db_name then
  help()
  os.exit()
end

local db = sqlite3.open(db_name)


db:close()
