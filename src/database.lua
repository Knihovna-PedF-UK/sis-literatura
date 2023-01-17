-- initialize sqlite
local sqlite3 = require "lsqlite3"

local search = require "src.search"
local calc_distance = search.calc_distance
local clean_sis = search.clean_sis
local clean_alma = search.clean_alma
local make_ngrams = search.make_ngrams
local make_vectors = search.make_vectors
local cosine_dist = search.cosine_dist
local tokenize = search.tokenize


local database = {}
local db, stmt, sis_query, candidate_query, random_citation, known_citation, citation_candidates, update_alma_id

function database.init(db_name)
  -- Init database
  db = sqlite3.open(db_name)
  
  -- initialize db
  local status = db:exec([[
  CREATE TABLE if not exists  alma (
  id INTEGER PRIMARY KEY,
  callno TEXT NOT NULL,
  citation TEXT
  );

  CREATE TABLE if not exists  sis (
  id INTEGER PRIMARY KEY,
  class TEXT NOT NULL,
  alma_id INTEGER DEFAULT NULL,
  citation TEXT,
  year INTEGER,
  FOREIGN KEY (alma_id) REFERENCES alma(id) ON DELETE CASCADE
  );

  CREATE TABLE if not exists  candidates (
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
  sis_query = db:prepare 'insert into sis values(?,?,?,?,?);'
  candidate_query = db:prepare 'insert into candidates values(?,?,?);'
  random_citation = db:prepare 'select * from sis where alma_id is null order by random() limit 1;'
  known_citation = db:prepare 'select * from sis where id=?;'
  citation_candidates = db:prepare 'select * from alma inner JOIN candidates ON alma.id = candidates.alma_id where candidates.sis_id = ?;'
  update_alma_id = db:prepare 'update sis set alma_id=? where id=?;'
  return true
end

function database.close()
  db:close()
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

function database.insert_sis(id, class, citation,year)
  sis_query:reset()
  sis_query:bind(1, id)
  sis_query:bind(2, class)
  -- alma_id should be null, so we can select records that we haven't processed yet
  sis_query:bind(3, nil)
  sis_query:bind(4, citation)
  sis_query:bind(5, year)
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

local function text_to_ngram(text)
  local clean_text = table.concat(tokenize(text), " ")
  return make_ngrams(clean_text)
end

function database.find_citation(known_id)
  -- find random SIS citation that isn't processed yet
  local record = {candidates = {}}
  local id, citation, class
  if not known_id then
    random_citation:reset()
    for row in random_citation:nrows() do
      record.id = row.id; record.citation = row.citation; record.class = row.class
    end
  else
    -- but we can also want to find related books for a particular citation
    known_citation:reset()
    known_citation:bind(1, known_id)
    -- local row = known_citation:get_named_values()
    for row in known_citation:nrows() do
      record.id = row.id; record.citation =  row.citation; record.class = row.class;
    end
  end
  -- in the end, there will be no unprocessed books, hopefully
  if not record.id then
    return nil, "All books were processed"
  end
  -- 
  citation_candidates:reset()
  citation_candidates:bind(1, record.id)
  local sis_ngrams = text_to_ngram(clean_sis(record.citation))
  -- if not citation_candidates:step() == sqlite3.DONE then
  --   return nil, "SQL ERROR: " .. db:errmsg()
  -- end
  for row in citation_candidates:nrows() do
    local curr_ngram = text_to_ngram(clean_alma(row.citation or ""))
    local vect_a, vect_b = make_vectors(sis_ngrams, curr_ngram)
    row.cosine = cosine_dist(vect_a, vect_b)
    table.insert(record.candidates, row)
  end
  if #record.candidates > 0 then
    table.sort(record.candidates, function(a,b) return a.cosine > b.cosine end)
    -- we can now test the cosine score of the candidate
    local best_candidate = record.candidates[1] or {}
    local cosine = best_candidate.cosine

    if cosine then
      if cosine > 0.7 then
        -- this is a good match, it doesn't even need a supervision  
        print("Really good match")
        print(record.id, record.citation)
        print(best_candidate.id, best_candidate.citation)
        database.set_sis_alma_id(record.id, best_candidate.id)
        return database.find_citation()
      elseif cosine < 0.20 then 
        -- we set really low number, because occasionally, it would filter
        -- out even good matches
        print("Really bad match")
        print(record.id, record.citation)
        print(best_candidate.id,best_candidate.citation)
        database.set_sis_alma_id(record.id, 0)
        return database.find_citation()
      end
    end
  end
    -- really bad match
  return record


  -- local query = "select * from sis where alma_id is null order by random() limit 1;"
  -- local candadates = "select * from alma inner JOIN candidates ON alma.id = candidates.alma_id where candidates.sis_id = ?"
end

function database.set_sis_alma_id(id, mid)
  update_alma_id:reset()
  update_alma_id:bind(1, mid)
  update_alma_id:bind(2, id)
  if not update_alma_id:step() == sqlite3.DONE then
    return nil, "SQL ERROR: " .. db:errmsg()
  end
  return true
end

return database
