import ../src/duckdb

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
