<p align="center">
  Nim SQL Driver For [DuckDB](https://duckdb.org/) database engine - A fast analytical database system<br>
</p>

<p align="center">
  <code>nimble install duckdb</code>
</p>

<p align="center">
  <a href="https://github.com/">API reference</a><br>
  <img src="https://github.com/openpeeps/pistachio/workflows/test/badge.svg" alt="Github Actions">  <img src="https://github.com/openpeeps/pistachio/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- [x] Low-level API for direct access to DuckDB
- [x] High-level API for easy database management
- [x] Supports SQL queries, transactions, and prepared statements
- [x] Supports reading and writing data in various formats (CSV, JSON, Parquet)
- [x] Supports DuckDB's in-memory and persistent storage modes
- [x] Cross-platform compatibility (Linux, macOS, Windows)
- [x] Easy to use with Nim's powerful type system and macros

## Examples
```nim
import duckdb

var db = open("my_database.duckdb")
var dbConn = db.connect()

dbCon.exec(sql"CREATE TABLE IF NOT EXISTS users (id INTEGER, name VARCHAR);")
dbCon.exec(sql"INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');")

for row in dbCon.getAllRows("SELECT * FROM users;"):
  echo row

dbConn.disconnect()
db.close()
```


## Data Import
DuckDB can directly connect to many popular data sources and offers several data ingestion methods that allow you to easily and efficiently fill up the database. Supported data sources include CSV, JSON and Parquet files.

```nim
import duckdb

var db = open("my_database.duckdb")
var dbCon = db.connect()

for row in dbCon.getAllRows("SELECT * FROM read_json('data.json)"):
  echo row

dbCon.disconnect()
db.close()
```

##### DuckDB List/Array
If your JSON contains a list/array, you can cast to VARCHAR to get a JSON string representation of the array.

```nim
let res = dbCon.getAllRows(sql"SELECT * EXCLUDE (fruits), fruits::VARCHAR as fruits_json FROM read_json('test.json');")
for row in res.rows:
  echo row.get("fruits_json") # print the JSON string representation of the array
```


### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](/issues)
- 👋 Wanna help? [Fork it!](/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
