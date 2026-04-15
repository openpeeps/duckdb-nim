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


Check the [tests](https://github.com/openpeeps/duckdb-nim/blob/main/tests/test1.nim) for more examples.


_more runnable examples soon..._


### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/duckdb-nim/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/duckdb-nim/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright OpenPeeps & Contributors &mdash; All rights reserved.
