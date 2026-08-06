import ../src/duckdb

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
