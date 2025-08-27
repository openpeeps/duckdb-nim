# Nim bindings for DuckDB.
#
# This module implements High-level API based on `pkg/db_connector`
# for connecting to and interacting with DuckDB databases.
#
# (c) 2025 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/duckdb-nim

import std/[strutils, strformat]
import duckdb/bindings

import pkg/bigints
import pkg/db_connector/db_common

export db_common

#
# Connections
#
type
  DuckDBInstance* = duckdb_database
    ## Represents a DuckDB database instance.

  DuckDBConnection* = duckdb_connection
    ## Represents a connection to a DuckDB database.

  DuckDBConnectionError* = object of CatchableError
  DuckDBQueryError* = object of CatchableError

const
  DuckDBSuccess* = 0
    ## Indicates a successful operation.
  
  DuckDBError* = -1
    ## Indicates an error occurred during an operation.

#
# Utils
#
proc uuidToString(val: duckdb_uhugeint): string =
  ## Converts a duckdb_uhugeint to a UUID string (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  let
    hi = val.upper
    lo = val.lower
    # Compose the UUID fields from the 128 bits
    time_low = (hi shr 32) and 0xFFFFFFFF'u64
    time_mid = (hi shr 16) and 0xFFFF'u64
    time_hi_and_version = hi and 0xFFFF'u64
    clock_seq = (lo shr 48) and 0xFFFF'u64
    node = lo and 0xFFFFFFFFFFFF'u64
  result = &"{time_low:08x}-{time_mid:04x}-{time_hi_and_version:04x}-{clock_seq:04x}-{node:012x}"


#
# High-level API
#
proc open*(path: string): DuckDBInstance =
  ## Open a database at the specified path.
  assert path.len > 0, "Path cannot be empty"
  if DuckDBSuccess != duckdb_open(path.cstring, result.addr):
    raise newException(DuckDBConnectionError, "Failed to open database at: " & path)

proc connect*(db: DuckDBInstance): DuckDBConnection =
  ## Connect to the DuckDB database instance.
  var conn: DuckDBConnection
  if DuckDBSuccess != duckdb_connect(db, conn.addr):
    raise newException(DuckDBConnectionError, "Failed to connect to database")
  return conn

proc close*(db: var DuckDBConnection) =
  ## Close a database
  duckdb_close(db.addr)

proc disconnect*(conn: var DuckDBConnection) =
  ## Disconnect from the DuckDB connection.
  duckdb_disconnect(conn.addr)

proc exec*(conn: DuckDBConnection, sql: SQLQuery) =
  ## Execute a SQL query on the DuckDB connection.
  var res: duckdb_result
  if DuckDBSuccess != duckdb_query(conn, sql.cstring, res.addr):
    raise newException(DuckDBQueryError, "Failed to execute SQL query: " & sql.string)

proc tryExec*(conn: DuckDBConnection, sql: SQLQuery): bool =
  ## Try to execute a SQL query and return true if successful, false otherwise.
  var res: duckdb_result
  if DuckDBSuccess == duckdb_query(conn, sql.cstring, res.addr):
    duckdb_destroy_result(res.addr)
    return true
  else:
    return false

type
  DuckDBValue* = object
    ## Represents a value in a DuckDB row.
    case `type`: DuckDBType
    of DUCKDB_TYPE_BOOLEAN:
      booleanValue: bool
    of DUCKDB_TYPE_TINYINT:
      tinyIntValue: int8
    of DUCKDB_TYPE_SMALLINT:
      smallIntValue: int16
    of DUCKDB_TYPE_INTEGER:
      integerValue: int32
    of DUCKDB_TYPE_BIGINT:
      bigIntValue: int64
    of DUCKDB_TYPE_UTINYINT:
      uTinyIntValue: uint8
    of DUCKDB_TYPE_USMALLINT:
      uSmallIntValue: uint16
    of DUCKDB_TYPE_UINTEGER:
      uIntegerValue: uint32
    of DUCKDB_TYPE_UBIGINT:
      uBigIntValue: uint64
    of DUCKDB_TYPE_FLOAT:
      floatValue: float32
    of DUCKDB_TYPE_DOUBLE:
      doubleValue: float64
    of DUCKDB_TYPE_TIMESTAMP, DUCKDB_TYPE_DATE, DUCKDB_TYPE_TIME:
      dateValue: string # FIXME: Use a proper date/time type
    of DUCKDB_TYPE_INTERVAL:
      intervalValue: string
    of DUCKDB_TYPE_HUGEINT:
      hugeIntValue: BigInt
    of DUCKDB_TYPE_UHUGEINT:
      uHugeIntValue: BigInt
    of DUCKDB_TYPE_VARCHAR, DUCKDB_TYPE_BLOB:
      stringValue: string
    of DUCKDB_TYPE_DECIMAL:
      decimalValue: string
    of DUCKDB_TYPE_ENUM:
      enumValue: string
    of DUCKDB_TYPE_LIST, DUCKDB_TYPE_STRUCT, DUCKDB_TYPE_MAP:
      listValue: seq[DuckDBValue]
    of DUCKDB_TYPE_ARRAY:
      arrayValue: seq[DuckDBValue]
    of DUCKDB_TYPE_UUID:
      uuidValue: string
    of DUCKDB_TYPE_UNION:
      unionValue: seq[DuckDBValue]
    of DUCKDB_TYPE_BIT:
      bitValue: seq[bool]
    of DUCKDB_TYPE_TIME_TZ, DUCKDB_TYPE_TIMESTAMP_TZ:
      timeValue: string
    else: discard # FIXME todo - handle other types

proc getDuckDBValue*(res: ptr duckdb_result, j, i: idx_t): DuckDBValue =
  ## Get a DuckDBValue from the result set.
  let `type` = duckdb_column_type(res, j)
  case `type`
  of DUCKDB_TYPE_BOOLEAN:
    result = DuckDBValue(`type`: `type`, booleanValue: duckdb_value_boolean(res, j, i))
  of DUCKDB_TYPE_TINYINT:
    result = DuckDBValue(`type`: `type`, tinyIntValue: duckdb_value_int8(res, j, i))
  of DUCKDB_TYPE_SMALLINT:
    result = DuckDBValue(`type`: `type`, smallIntValue: duckdb_value_int16(res, j, i))
  of DUCKDB_TYPE_INTEGER:
    result = DuckDBValue(`type`: `type`, integerValue: duckdb_value_int32(res, j, i))
  of DUCKDB_TYPE_BIGINT:
    result = DuckDBValue(`type`: `type`, bigIntValue: duckdb_value_int64(res, j, i))
  of DUCKDB_TYPE_UTINYINT:
    result = DuckDBValue(`type`: `type`, uTinyIntValue: duckdb_value_uint8(res, j, i))
  of DUCKDB_TYPE_USMALLINT:
    result = DuckDBValue(`type`: `type`, uSmallIntValue: duckdb_value_uint16(res, j, i))
  of DUCKDB_TYPE_UINTEGER:
    result = DuckDBValue(`type`: `type`, uIntegerValue: duckdb_value_uint32(res, j, i))
  of DUCKDB_TYPE_UBIGINT:
    result = DuckDBValue(`type`: `type`, uBigIntValue: duckdb_value_uint64(res, j, i))
  of DUCKDB_TYPE_FLOAT:
    result = DuckDBValue(`type`: `type`, floatValue: duckdb_value_float(res, j, i))
  of DUCKDB_TYPE_DOUBLE:
    result = DuckDBValue(`type`: `type`, doubleValue: duckdb_value_double(res, j, i))
  of DUCKDB_TYPE_TIMESTAMP, DUCKDB_TYPE_DATE, DUCKDB_TYPE_TIME:
    # let dstr = duckdb_value_string(res, j, i)
    # result = DuckDBValue(`type`: `type`, dateValue: $cast[cstring](dstr.data))
    discard
  of DUCKDB_TYPE_INTERVAL:
    # let dstr = duckdb_value_string(res, j, i)
    # result = DuckDBValue(`type`: `type`, intervalValue: $cast[cstring](dstr.data))
    discard
  of DUCKDB_TYPE_HUGEINT:
    # Not implemented: duckdb_value_int128
    # result = DuckDBValue(`type`: `type`, hugeIntValue: BigInt(0))
    discard
  of DUCKDB_TYPE_UHUGEINT:
    # Not implemented: duckdb_value_uint128
    # result = DuckDBValue(`type`: `type`, uHugeIntValue: BigInt(0))
    discard
  of DUCKDB_TYPE_VARCHAR:
    result = DuckDBValue(`type`: `type`, stringValue: $(duckdb_value_varchar(res, j, i)))
  of DUCKDB_TYPE_BLOB:
    discard
    # result = DuckDBValue(`type`: `type`, stringValue: $(duckdb_value_blob(res, j, i)))
  of DUCKDB_TYPE_DECIMAL:
    # let dstr = duckdb_value_string(res, j, i)
    # result = DuckDBValue(`type`: `type`, decimalValue: $cast[cstring](dstr.data))
    discard
  of DUCKDB_TYPE_ENUM:
    # let dstr = duckdb_value_string(res, j, i)
    # result = DuckDBValue(`type`: `type`, enumValue: $cast[cstring](dstr.data))
    discard
  of DUCKDB_TYPE_LIST, DUCKDB_TYPE_STRUCT, DUCKDB_TYPE_MAP:
    discard # Not implemented. Cast to Varchar then parse JSON
  of DUCKDB_TYPE_ARRAY:
    result = DuckDBValue(`type`: `type`, arrayValue: @[]) # Not implemented
  of DUCKDB_TYPE_UUID:
    result = DuckDBValue(`type`: `type`)
    if duckdb_value_is_null(res, j, i):
      return # result is already initialized with default values
    # let uuidVal = duckdb_value_uhugeint(res, j, i)
    # echo $(duckdb_value_varchar(res, j, i))
    # echo uuidVal
    # result.uuidValue = uuidToString(uuidVal)
  of DUCKDB_TYPE_UNION:
    result = DuckDBValue(`type`: `type`, unionValue: @[]) # Not implemented
  of DUCKDB_TYPE_BIT:
    result = DuckDBValue(`type`: `type`, bitValue: @[]) # Not implemented
  of DUCKDB_TYPE_TIME_TZ, DUCKDB_TYPE_TIMESTAMP_TZ:
    # let dstr = duckdb_value_string(res, j, i)
    # result = DuckDBValue(`type`: `type`, timeValue: $cast[cstring](dstr.data))
    discard
  else:
    raise newException(DuckDBQueryError, "Unsupported DuckDB type: " & $`type`)

type
  Row* = seq[DuckDBValue]
    ## Represents a single row of data returned from a query.

  DuckDBResult* = tuple
    ## Represents the result of a DuckDB query.
    columns: seq[string]
      ## A sequence of column names in the result set.
    rows: seq[Row]
      ## A sequence of rows, where each row is a sequence of string values.

proc `$`*(value: DuckDBValue): string =
  ## Convert a DuckDBValue to a string representation.
  result = case value.type
    of DUCKDB_TYPE_BOOLEAN:
      $value.booleanValue
    of DUCKDB_TYPE_TINYINT:
      $value.tinyIntValue
    of DUCKDB_TYPE_SMALLINT:
      $value.smallIntValue
    of DUCKDB_TYPE_INTEGER:
      $value.integerValue
    of DUCKDB_TYPE_BIGINT:
      $value.bigIntValue
    of DUCKDB_TYPE_UTINYINT:
      $value.uTinyIntValue
    of DUCKDB_TYPE_USMALLINT:
      $value.uSmallIntValue
    of DUCKDB_TYPE_UINTEGER:
      $value.uIntegerValue
    of DUCKDB_TYPE_UBIGINT:
      $value.uBigIntValue
    of DUCKDB_TYPE_FLOAT:
      $value.floatValue
    of DUCKDB_TYPE_DOUBLE:
      $value.doubleValue
    of DUCKDB_TYPE_TIMESTAMP, DUCKDB_TYPE_DATE, DUCKDB_TYPE_TIME: ""
    of DUCKDB_TYPE_INTERVAL:
      $value.intervalValue
    of DUCKDB_TYPE_HUGEINT:
      $value.hugeIntValue
    # of DUCKDB_TYPE_UHUGEINT:
      # $value.uHugeIntValue
    of DUCKDB_TYPE_VARCHAR, DUCKDB_TYPE_BLOB:
      value.stringValue
    of DUCKDB_TYPE_DECIMAL:
      value.decimalValue
    of DUCKDB_TYPE_ENUM:
      value.enumValue
    else: ""

proc toString*(value: DuckDBValue): string =
  ## Convert a DuckDBValue to a string representation.
  result = $value

proc getAllRows*(conn: DuckDBConnection, sql: SQLQuery): DuckDBResult =
  ## Execute a SQL query and return all rows as a sequence of Row objects.
  var res: duckdb_result
  if DuckDBSuccess != duckdb_query(conn, sql.cstring, res.addr):
    raise newException(DuckDBQueryError, "Failed to execute SQL query: " & sql.string)
  if duckdb_row_count(res.addr) == 0:
    duckdb_destroy_result(res.addr)
    return
  for i in 0 ..< duckdb_row_count(res.addr):
    var row: Row
    for j in 0 ..< duckdb_column_count(res.addr):
      let colName = duckdb_column_name(res.addr, j)
      if i == 0:
        # add the column name to the result columns
        # this is done only for the first row
        result.columns.add($colName)
      let v = getDuckDBValue(res.addr, j, i)
      row.add(v)
    result.rows.add(row)
  duckdb_destroy_result(res.addr)

