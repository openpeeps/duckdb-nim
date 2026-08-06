<p align="center">
  Nim SQL Driver for <a href="https://duckdb.org/">DuckDB</a> database engine<br>A fast analytical database system
</p>

<p align="center">
  <code>nimble install duckdb</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.io/duckdb-nim">API reference</a><br>
  <img src="https://github.com/openpeeps/duckdb-nim/workflows/test/badge.svg" alt="Github Actions">  <img src="https://github.com/openpeeps/duckdb-nim/workflows/docs/badge.svg" alt="Github Actions">
</p>

> [!NOTE]  
> The high-level API is still a work in progress. Please check back later for updates.

## 😍 Key Features
- [x] Low-level API for direct access to DuckDB
- [x] High-level API for easy database management
- [x] Supports SQL queries, transactions, and prepared statements
- [x] Supports reading and writing data in various formats (CSV, JSON, Parquet)
- [x] Supports DuckDB's in-memory and persistent storage modes
- [x] Cross-platform compatibility (Linux, macOS, Windows)
- [x] Easy to use with Nim's powerful type system and macros

## Examples
All examples live in the [`examples/`](https://github.com/openpeeps/duckdb-nim/blob/main/examples) directory and are runnable:

```bash
nim c -r examples/crud.nim
```

### Open a database
[`examples/open.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/open.nim)
```nim
import duckdb

# Persistent database stored on disk
var db = duckdb.open("my_database.duckdb")
var conn = db.connect()
conn.exec(sql"CREATE TABLE IF NOT EXISTS t (i INTEGER);")
conn.disconnect()
db.close()

# In-memory database (lives entirely in RAM, no file is created)
var memoryDb = duckdb.open(":memory:")
var memoryConn = memoryDb.connect()
memoryConn.exec(sql"SELECT 42;")
memoryConn.disconnect()
memoryDb.close()
```

### CRUD operations
[`examples/crud.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/crud.nim)
```nim
import duckdb

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
```

### Transactions
[`examples/transactions.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/transactions.nim)
```nim
import duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

conn.exec(sql"CREATE TABLE accounts (name VARCHAR, balance INTEGER);")
conn.exec(sql"INSERT INTO accounts VALUES ('Alice', 100);")

# Commit the change
conn.exec(sql"BEGIN TRANSACTION;")
conn.exec(sql"UPDATE accounts SET balance = balance - 20 WHERE name = 'Alice';")
conn.exec(sql"COMMIT;")

# Roll back the change
conn.exec(sql"BEGIN TRANSACTION;")
conn.exec(sql"UPDATE accounts SET balance = balance + 100 WHERE name = 'Alice';")
conn.exec(sql"ROLLBACK;")

let res = conn.getAllRows(sql"SELECT * FROM accounts;")
for row in res.rows:
  echo row # Alice is still at 80, the ROLLBACK discarded the +100

conn.disconnect()
db.close()
```

### Prepared statements
[`examples/prepared.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/prepared.nim)
```nim
import duckdb

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
```

### Read documents (JSON)
[`examples/documents.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/documents.nim)
```nim
import duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

# Query JSON documents directly with DuckDB's read_json table function
let res = conn.getAllRows(sql"SELECT * FROM read_json('tests/data/01.json');")
echo "columns: ", res.columns
for row in res.rows:
  echo row

conn.disconnect()
db.close()
```

### Read and write CSV & Parquet
[`examples/csv_parquet.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/csv_parquet.nim)
```nim
import std/os
import duckdb

var db = duckdb.open(":memory:")
var conn = db.connect()

# Write a small CSV file to disk
writeFile("people.csv", """id,name,age
1,Alice,30
2,Bob,25
3,Carol,35
""")

# Read it back with DuckDB
let csv = conn.getAllRows(sql"SELECT * FROM read_csv_auto('people.csv');")
echo "csv columns: ", csv.columns
for row in csv.rows:
  echo row

# Export the same data to Parquet, then read it back
conn.exec(sql"COPY (SELECT * FROM read_csv_auto('people.csv')) TO 'people.parquet' (FORMAT PARQUET);")

let parquet = conn.getAllRows(sql"SELECT * FROM read_parquet('people.parquet') WHERE age > 28;")
echo "parquet rows (age > 28):"
for row in parquet.rows:
  echo row

conn.disconnect()
db.close()

removeFile("people.csv")
removeFile("people.parquet")
```

### Error handling
[`examples/errors.nim`](https://github.com/openpeeps/duckdb-nim/blob/main/examples/errors.nim)
```nim
import duckdb

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
```

Check the [tests](https://github.com/openpeeps/duckdb-nim/blob/main/tests/test1.nim) for more examples.


### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/duckdb-nim/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/duckdb-nim/fork)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
