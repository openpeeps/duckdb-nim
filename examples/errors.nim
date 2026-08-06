import ../src/duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

# tryExec returns true on success, false on failure
if not conn.tryExec(sql"CREATE TABLE t (i INTEGER);"):
  echo "create failed"

if not conn.tryExec(sql"THIS IS NOT VALID SQL;"):
  echo "expected: invalid statement rejected"

# exec raises DuckDBQueryError on failure
try:
  conn.exec(sql"SELECT * FROM does_not_exist;")
except DuckDBQueryError as e:
  echo "caught: ", e.msg

conn.disconnect()
db.close()
