import std/[unittest, os]

import ../src/duckdb

var db: DuckDBInstance
var dbCon: DuckDBConnection

suite "database basics":
  test "can open database":
    db = duckdb.open("duckdb_test.db")
    check db != nil

  test "can connect to database":
    dbCon = db.connect()
    check dbCon != nil

suite "queries":
  test "create table users":
    dbCon.exec(sql"CREATE TABLE IF NOT EXISTS users (id INTEGER, name VARCHAR);")

  test "insert data into users":
    dbCon.exec(sql"INSERT INTO users VALUES (1, 'alice'), (2, 'bob');")

  test "select data from users":
    let res = dbCon.getAllRows(sql"SELECT * FROM users;")
    check res.rows.len == 2
    check res.columns == @["id", "name"]
    for row in res.rows:
      check row[0].kind == DUCKDB_TYPE_INTEGER
      check row[0].integerValue in @[1, 2]
      check row[1].kind == DUCKDB_TYPE_VARCHAR
      check row[1].stringValue in @["alice", "bob"]

  test "select data from json file":
    let res = dbCon.getAllRows(sql"SELECT * FROM read_json('tests/data/01.json');")
    check res.rows.len == 2
    check res.columns == @["username", "email"]
    
    for row in res.rows:
      check row[0].kind == DUCKDB_TYPE_VARCHAR
      check row[0].stringValue in @["alice", "bob"]
      check row[1].kind == DUCKDB_TYPE_VARCHAR
      check row[1].stringValue in @["alice@example.com", "bob@example.com"]

suite "cleanup":
    dbCon.disconnect()
    db.close()
    removeFile("duckdb_test.db")

