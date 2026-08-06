import ../src/duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

conn.exec(sql"""
  CREATE TABLE IF NOT EXISTS users (
    id   INTEGER,
    name VARCHAR,
    age  INTEGER
  );
""")

conn.exec(sql"INSERT INTO users VALUES (1, 'Alice', 30), (2, 'Bob', 25), (3, 'Carol', 35);")

let res = conn.getAllRows(sql"SELECT * FROM users ORDER BY id;")
echo "columns: ", res.columns
for row in res.rows:
  echo row

conn.disconnect()
db.close()
