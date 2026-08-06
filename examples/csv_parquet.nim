import std/os
import ../src/duckdb

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
