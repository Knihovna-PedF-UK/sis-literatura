-- tohle byl pokus, jak udělat 
local sqlite3 = require "lsqlite3"

kpse.set_program_name "luatex"
local readalma = require "src.readalma"

local db_name = arg[1]
local xml = arg[2]

local function help()
  print "!!!! do not use, fulltex search in sqlite doesn't work really well for this use case !!!!!"
  print "create a new database and insert data from alma for full text search"
  print "usage:"
  print "  texlua src/almatosql.lua db_name.sql alma_data.xml"
end



if not db_name or not xml then
  help()
  os.exit()
end


-- initialize db
-- we delete everything every time
os.remove(db_name)
local db = sqlite3.open(db_name)
-- initialize db
local status = db:exec([[
CREATE TABLE publications (
id INTEGER PRIMARY KEY AUTOINCREMENT,
callno TEXT NOT NULL,
citation TEXT
);

CREATE VIRTUAL TABLE publications_fts USING fts5(
id UNINDEXED,
callno UNINDEXED, 
citation, 
content='publications', 
content_rowid='id',
tokenize="trigram"
);

CREATE TRIGGER publications_ai AFTER INSERT ON publications
BEGIN
INSERT INTO publications_fts (rowid, callno, citation)
VALUES (new.id, new.callno, new.citation);
END;
]])

if status ~= sqlite3.OK then
  print("ERROR: " .. db:errmsg())
  os.exit()
end



-- use prepared statement to save citations into database
local stmt = db:prepare 'insert into publications values(?,?,?);'

local function insert_citation(callno, mmsid, citation)
  stmt:reset()
  stmt:bind(1, mmsid)
  stmt:bind(2, callno)
  stmt:bind(3, citation)
  if not stmt:step() == sqlite3.DONE then
    print("ERROR: " .. db:errmsg())
  end
end

-- make citation for the current record, and insert it to the db
local function alma_process(record)
-- for id, record in pairs(alma_data) do 
  local name = (record.author or ""):gsub("[0-9].*$", ""):gsub(",%s*$","")
  local title = (record.title or ""):gsub("%s*/%s*$", "")
  local year = record.year 
  local citation = table.concat({name, title, year}, ". "):gsub("%.%s*%.", "."):gsub("^%.%s*", "")
  print(record.sysno, citation, record.callno)
  insert_citation(record.callno, record.sysno, citation)
end
  
-- this can take long time
local alma_data = readalma.load(xml,alma_process)
-- end


db:close()
