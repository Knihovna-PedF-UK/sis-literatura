-- initialize sqlite
local sqlite3 = require "lsqlite3"

local database = {}
local db 

function database.init(db_name)
  -- Init database
  db = sqlite3.open(db_name)
  -- initialize db
  local status = db:exec([[
  CREATE TABLE alma (
  id INTEGER PRIMARY KEY,
  callno TEXT NOT NULL,
  citation TEXT
  );

  CREATE TABLE sis (
  id INTEGER PRIMARY KEY,
  class TEXT NOT NULL,
  alma_id INTEGER DEFAULT NULL,
  citation TEXT,
  FOREIGN KEY (alma_id) REFERENCES alma(id) ON DELETE CASCADE
  );

  CREATE TABLE candidates (
  alma_id INTEGER NOT NULL,
  sis_id INTEGER NOT NULL,
  FOREIGN KEY (alma_id) REFERENCES alma(id),
  FOREIGN KEY (sis_id) REFERENCES sis(id),
  UNIQUE (alma_id, sis_id)
  );
  ]])

  if status ~= sqlite3.OK then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

-- use prepared statement to save citations into database
local stmt = db:prepare 'insert into publications values(?,?,?);'

function database.insert_citation(callno, mmsid, citation)
  stmt:reset()
  stmt:bind(1, mmsid)
  stmt:bind(2, callno)
  stmt:bind(3, citation)
  if not stmt:step() == sqlite3.DONE then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

return database
