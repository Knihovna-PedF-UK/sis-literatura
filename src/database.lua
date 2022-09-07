-- initialize sqlite
local sqlite3 = require "lsqlite3"

local database = {}
local db, stmt, sis_query, candidate_query

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
  weight REAL,
  FOREIGN KEY (alma_id) REFERENCES alma(id),
  FOREIGN KEY (sis_id) REFERENCES sis(id),
  UNIQUE (alma_id, sis_id)
  );
  ]])

  if status ~= sqlite3.OK then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  -- use prepared statement to save citations into database
  stmt = db:prepare 'insert into alma values(?,?,?);'
  sis_query = db:prepare 'insert into sis values(?,?,?,?);'
  candidate_query = db:prepare 'insert into candidates values(?,?,?);'
  return true
end


function database.insert_citation(mmsid, callno, citation)
  stmt:reset()
  stmt:bind(1, mmsid)
  stmt:bind(2, callno)
  stmt:bind(3, citation)
  if not stmt:step() == sqlite3.DONE then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

function database.insert_sis(id, class, citation)
  sis_query:reset()
  sis_query:bind(1, id)
  sis_query:bind(2, class)
  sis_query:bind(3, citation)
  sis_query:bind(4, nil)
  if not sis_query:step() == sqlite3.DONE then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

function database.insert_candidate(alma_id, sis_id, weight)
  candidate_query:reset()
  candidate_query:bind(1, alma_id)
  candidate_query:bind(2, sis_id)
  candidate_query:bind(3, weight)
  if not candidate_query:step() == sqlite3.DONE then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

return database
