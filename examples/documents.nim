import ../src/duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

# Query JSON documents directly with DuckDB's read_json table function
let res = conn.getAllRows(sql"SELECT * FROM read_json('tests/data/01.json');")
echo "columns: ", res.columns
for row in res.rows:
  echo row

conn.disconnect()
db.close()
