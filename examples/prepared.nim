import ../src/duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

conn.exec(sql"CREATE TABLE users (id INTEGER, name VARCHAR);")
conn.exec(sql"INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Carol');")

# Prepare a statement with a parameter placeholder
var stmt: duckdb_prepared_statement
if DuckDBSuccess != duckdb_prepare(conn, sql"SELECT * FROM users WHERE name = ?;".cstring, stmt.addr):
  raise newException(DuckDBQueryError, "Failed to prepare statement")

# Bind the parameter and execute
if DuckDBSuccess != duckdb_bind_varchar(stmt, 1, "Bob".cstring):
  raise newException(DuckDBQueryError, "Failed to bind parameter")

var res: duckdb_result
if DuckDBSuccess == duckdb_execute_prepared(stmt, res.addr):
  for i in 0 ..< duckdb_row_count(res.addr):
    var row: Row
    for j in 0 ..< duckdb_column_count(res.addr):
      row.add(getDuckDBValue(res.addr, j, i))
    echo row
  duckdb_destroy_result(res.addr)

duckdb_destroy_prepare(stmt.addr)
conn.disconnect()
db.close()
