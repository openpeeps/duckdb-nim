# Nim bindings for DuckDB.
# This module implements low-level bindings to the DuckDB C API.
#
# (c) 2025 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/duckdb-nim

{.passL:"-L/opt/local/lib -lduckdb", passC:"-I /opt/local/include".}

const ext =
  when defined(linux):
    "so"
  elif defined(windows):
    "dll"
  else:
    "dylib"

type
  DuckDBType* {.size: sizeof(cint).} = enum
    ## Represents the various data types supported by DuckDB.
    ## For more information, see:
    ## https://duckdb.org/docs/stable/clients/c/types
    DUCKDB_TYPE_INVALID = 0,
    DUCKDB_TYPE_BOOLEAN = 1,
    DUCKDB_TYPE_TINYINT = 2,
    DUCKDB_TYPE_SMALLINT = 3,
    DUCKDB_TYPE_INTEGER = 4,
    DUCKDB_TYPE_BIGINT = 5,
    DUCKDB_TYPE_UTINYINT = 6,
    DUCKDB_TYPE_USMALLINT = 7,
    DUCKDB_TYPE_UINTEGER = 8,
    DUCKDB_TYPE_UBIGINT = 9,
    DUCKDB_TYPE_FLOAT = 10,
    DUCKDB_TYPE_DOUBLE = 11,
    DUCKDB_TYPE_TIMESTAMP = 12,
    DUCKDB_TYPE_DATE = 13,
    DUCKDB_TYPE_TIME = 14,
    DUCKDB_TYPE_INTERVAL = 15,
    DUCKDB_TYPE_HUGEINT = 16,
    DUCKDB_TYPE_UHUGEINT = 32,
    DUCKDB_TYPE_VARCHAR = 17,
    DUCKDB_TYPE_BLOB = 18,
    DUCKDB_TYPE_DECIMAL = 19,
    DUCKDB_TYPE_TIMESTAMP_S = 20,
    DUCKDB_TYPE_TIMESTAMP_MS = 21,
    DUCKDB_TYPE_TIMESTAMP_NS = 22,
    DUCKDB_TYPE_ENUM = 23,
    DUCKDB_TYPE_LIST = 24,
    DUCKDB_TYPE_STRUCT = 25,
    DUCKDB_TYPE_MAP = 26,
    DUCKDB_TYPE_ARRAY = 33,
    DUCKDB_TYPE_UUID = 27,
    DUCKDB_TYPE_UNION = 28,
    DUCKDB_TYPE_BIT = 29,
    DUCKDB_TYPE_TIME_TZ = 30,
    DUCKDB_TYPE_TIMESTAMP_TZ = 31

{.push, importc, header:"duckdb.h", dynlib: "duckdb." & ext.}
type
  duckdb_instance_cache* = pointer
  duckdb_database* = pointer
  duckdb_config* = pointer
  duckdb_connection* = pointer
  duckdb_client_context* = pointer
  duckdb_value* = pointer
  
  duckdb_state* = cint

  duckdb_query_progress_type* = cint
  idx_t* = uint64
  duckdb_data_chunk* = pointer
  duckdb_result_type* = cint

proc duckdb_create_instance_cache*(): duckdb_instance_cache
proc duckdb_get_or_create_from_cache*(instance_cache: duckdb_instance_cache, path: cstring, out_database: ptr duckdb_database, config: duckdb_config, out_error: ptr cstring): duckdb_state
proc duckdb_destroy_instance_cache*(instance_cache: ptr duckdb_instance_cache)
proc duckdb_open*(path: cstring, out_database: ptr duckdb_database): duckdb_state
proc duckdb_open_ext*(path: cstring, out_database: ptr duckdb_database, config: duckdb_config, out_error: ptr cstring): duckdb_state
proc duckdb_close*(database: ptr duckdb_database)
proc duckdb_connect*(database: duckdb_database, out_connection: ptr duckdb_connection): duckdb_state
proc duckdb_interrupt*(connection: duckdb_connection)
proc duckdb_query_progress*(connection: duckdb_connection): duckdb_query_progress_type
proc duckdb_disconnect*(connection: ptr duckdb_connection)
proc duckdb_connection_get_client_context*(connection: duckdb_connection, out_context: ptr duckdb_client_context)
proc duckdb_client_context_get_connection_id*(context: duckdb_client_context): idx_t
proc duckdb_destroy_client_context*(context: ptr duckdb_client_context)
proc duckdb_library_version*(): cstring
proc duckdb_get_table_names*(connection: duckdb_connection, query: cstring, qualified: bool): duckdb_value

# Configuration API
proc duckdb_create_config*(out_config: ptr duckdb_config): duckdb_state
proc duckdb_config_count*(): csize_t
proc duckdb_get_config_flag*(index: csize_t, out_name: ptr cstring, out_description: ptr cstring): duckdb_state
proc duckdb_set_config*(config: duckdb_config, name: cstring, option: cstring): duckdb_state
proc duckdb_destroy_config*(config: ptr duckdb_config)

# Query
type
  duckdb_result* {.bycopy.} = object # opaque struct, actual fields not needed for FFI
  duckdb_type* = DuckDBType
  duckdb_statement_type* = cint
  duckdb_logical_type* = pointer
  duckdb_error_type* = cint

proc duckdb_query*(connection: duckdb_connection, query: cstring, out_result: ptr duckdb_result): duckdb_state
proc duckdb_destroy_result*(result: ptr duckdb_result)
proc duckdb_column_name*(result: ptr duckdb_result, col: idx_t): cstring
proc duckdb_column_type*(result: ptr duckdb_result, col: idx_t): duckdb_type
proc duckdb_result_statement_type*(result: duckdb_result): duckdb_statement_type
proc duckdb_column_logical_type*(result: ptr duckdb_result, col: idx_t): duckdb_logical_type
proc duckdb_column_count*(result: ptr duckdb_result): idx_t
proc duckdb_row_count*(result: ptr duckdb_result): idx_t
proc duckdb_rows_changed*(result: ptr duckdb_result): idx_t
proc duckdb_column_data*(result: ptr duckdb_result, col: idx_t): pointer
proc duckdb_nullmask_data*(result: ptr duckdb_result, col: idx_t): ptr bool
proc duckdb_result_error*(result: ptr duckdb_result): cstring
proc duckdb_result_error_type*(result: ptr duckdb_result): duckdb_error_type
proc duckdb_result_get_chunk*(result: duckdb_result, chunk_index: idx_t): duckdb_data_chunk
proc duckdb_result_is_streaming*(result: duckdb_result): bool
proc duckdb_result_chunk_count*(result: duckdb_result): idx_t
proc duckdb_result_return_type*(result: duckdb_result): duckdb_result_type

type
  duckdb_hugeint* {.bycopy.} = object
    lower*: uint64
    upper*: int64
  
  duckdb_uhugeint* {.bycopy.} = object
    lower*: uint64
    upper*: uint64
  
  duckdb_decimal* {.bycopy.} = object
    value*: duckdb_hugeint
    width*: uint8
    scale*: uint8
  
  duckdb_date* = int32
  duckdb_time* = int64
  duckdb_timestamp* = int64

  duckdb_interval* {.bycopy.} = object
    months*: int32
    days*: int32
    micros*: int64
  
  duckdb_string* {.bycopy.} = object
    data*: cstring
    size*: uint32

  duckdb_blob* {.bycopy.} = object
    data*: pointer
    size*: uint64

proc duckdb_value_boolean*(result: ptr duckdb_result, col, row: idx_t): bool
proc duckdb_value_int8*(result: ptr duckdb_result, col, row: idx_t): int8
proc duckdb_value_int16*(result: ptr duckdb_result, col, row: idx_t): int16
proc duckdb_value_int32*(result: ptr duckdb_result, col, row: idx_t): int32
proc duckdb_value_int64*(result: ptr duckdb_result, col, row: idx_t): int64
proc duckdb_value_hugeint*(result: ptr duckdb_result, col, row: idx_t): duckdb_hugeint
proc duckdb_value_uhugeint*(result: ptr duckdb_result, col, row: idx_t): duckdb_uhugeint
proc duckdb_value_decimal*(result: ptr duckdb_result, col, row: idx_t): duckdb_decimal
proc duckdb_value_uint8*(result: ptr duckdb_result, col, row: idx_t): uint8
proc duckdb_value_uint16*(result: ptr duckdb_result, col, row: idx_t): uint16
proc duckdb_value_uint32*(result: ptr duckdb_result, col, row: idx_t): uint32
proc duckdb_value_uint64*(result: ptr duckdb_result, col, row: idx_t): uint64
proc duckdb_value_float*(result: ptr duckdb_result, col, row: idx_t): float32
proc duckdb_value_double*(result: ptr duckdb_result, col, row: idx_t): float64
proc duckdb_value_date*(result: ptr duckdb_result, col, row: idx_t): duckdb_date
proc duckdb_value_time*(result: ptr duckdb_result, col, row: idx_t): duckdb_time
proc duckdb_value_timestamp*(result: ptr duckdb_result, col, row: idx_t): duckdb_timestamp
proc duckdb_value_interval*(result: ptr duckdb_result, col, row: idx_t): duckdb_interval
proc duckdb_value_varchar*(result: ptr duckdb_result, col, row: idx_t): cstring
proc duckdb_value_string*(result: ptr duckdb_result, col, row: idx_t): duckdb_string
proc duckdb_value_varchar_internal*(result: ptr duckdb_result, col, row: idx_t): cstring
proc duckdb_value_string_internal*(result: ptr duckdb_result, col, row: idx_t): duckdb_string
proc duckdb_value_blob*(result: ptr duckdb_result, col, row: idx_t): duckdb_blob
proc duckdb_value_is_null*(result: ptr duckdb_result, col, row: idx_t): bool

type
  duckdb_string_t* = object
    data*: array[12, byte] # DuckDB inlines short strings, 12 bytes is typical for duckdb_string_t

proc duckdb_malloc*(size: csize_t): pointer
proc duckdb_free*(`ptr`: pointer)
proc duckdb_vector_size*(): idx_t
proc duckdb_string_is_inlined*(str: duckdb_string_t): bool
proc duckdb_string_t_length*(str: duckdb_string_t): uint32
proc duckdb_string_t_data*(str: ptr duckdb_string_t): cstring

type
  duckdb_date_struct* = object
    year*: int32
    month*: int8
    day*: int8
  duckdb_time_struct* = object
    hour*: int8
    min*: int8
    sec*: int8
    micros*: int32
  duckdb_time_tz* = int64
  duckdb_time_tz_struct* = object
    hour*: int8
    min*: int8
    sec*: int8
    micros*: int32
    offset*: int32
  duckdb_timestamp_struct* = object
    date*: duckdb_date_struct
    time*: duckdb_time_struct
  duckdb_timestamp_s* = int64
  duckdb_timestamp_ms* = int64
  duckdb_timestamp_ns* = int64

proc duckdb_from_date*(date: duckdb_date): duckdb_date_struct
proc duckdb_to_date*(date: duckdb_date_struct): duckdb_date
proc duckdb_is_finite_date*(date: duckdb_date): bool
proc duckdb_from_time*(time: duckdb_time): duckdb_time_struct
proc duckdb_create_time_tz*(micros: int64, offset: int32): duckdb_time_tz
proc duckdb_from_time_tz*(micros: duckdb_time_tz): duckdb_time_tz_struct
proc duckdb_to_time*(time: duckdb_time_struct): duckdb_time
proc duckdb_from_timestamp*(ts: duckdb_timestamp): duckdb_timestamp_struct
proc duckdb_to_timestamp*(ts: duckdb_timestamp_struct): duckdb_timestamp
proc duckdb_is_finite_timestamp*(ts: duckdb_timestamp): bool
proc duckdb_is_finite_timestamp_s*(ts: duckdb_timestamp_s): bool
proc duckdb_is_finite_timestamp_ms*(ts: duckdb_timestamp_ms): bool
proc duckdb_is_finite_timestamp_ns*(ts: duckdb_timestamp_ns): bool

# Hugeint Helpers
proc duckdb_hugeint_to_double*(val: duckdb_hugeint): float64
proc duckdb_double_to_hugeint*(val: float64): duckdb_hugeint

# Unsigned Hugeint Helpers
proc duckdb_uhugeint_to_double*(val: duckdb_uhugeint): float64
proc duckdb_double_to_uhugeint*(val: float64): duckdb_uhugeint

# Decimal Helpers
proc duckdb_double_to_decimal*(val: float64, width: uint8, scale: uint8): duckdb_decimal
proc duckdb_decimal_to_double*(val: duckdb_decimal): float64

type
  duckdb_prepared_statement* = pointer

#
# Prepared Statements
#
proc duckdb_prepare*(
  connection: duckdb_connection,
  query: cstring,
  out_prepared_statement: ptr duckdb_prepared_statement
): duckdb_state
proc duckdb_destroy_prepare*(prepared_statement: ptr duckdb_prepared_statement)
proc duckdb_prepare_error*(prepared_statement: duckdb_prepared_statement): cstring
proc duckdb_nparams*(prepared_statement: duckdb_prepared_statement): idx_t
proc duckdb_parameter_name*(prepared_statement: duckdb_prepared_statement, index: idx_t): cstring
proc duckdb_param_type*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t): duckdb_type
proc duckdb_param_logical_type*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t): duckdb_logical_type
proc duckdb_clear_bindings*(prepared_statement: duckdb_prepared_statement): duckdb_state
proc duckdb_prepared_statement_type*(statement: duckdb_prepared_statement): duckdb_statement_type

#
# Bind Values to Prepared Statements
#
proc duckdb_bind_value*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_value): duckdb_state
proc duckdb_bind_parameter_index*(prepared_statement: duckdb_prepared_statement, param_idx_out: ptr idx_t, name: cstring): duckdb_state
proc duckdb_bind_boolean*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: bool): duckdb_state
proc duckdb_bind_int8*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: int8): duckdb_state
proc duckdb_bind_int16*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: int16): duckdb_state
proc duckdb_bind_int32*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: int32): duckdb_state
proc duckdb_bind_int64*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: int64): duckdb_state
proc duckdb_bind_hugeint*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_hugeint): duckdb_state
proc duckdb_bind_uhugeint*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_uhugeint): duckdb_state
proc duckdb_bind_decimal*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_decimal): duckdb_state
proc duckdb_bind_uint8*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: uint8): duckdb_state
proc duckdb_bind_uint16*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: uint16): duckdb_state
proc duckdb_bind_uint32*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: uint32): duckdb_state
proc duckdb_bind_uint64*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: uint64): duckdb_state
proc duckdb_bind_float*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: float32): duckdb_state
proc duckdb_bind_double*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: float64): duckdb_state
proc duckdb_bind_date*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_date): duckdb_state
proc duckdb_bind_time*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_time): duckdb_state
proc duckdb_bind_timestamp*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_timestamp): duckdb_state
proc duckdb_bind_timestamp_tz*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_timestamp): duckdb_state
proc duckdb_bind_interval*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: duckdb_interval): duckdb_state
proc duckdb_bind_varchar*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: cstring): duckdb_state
proc duckdb_bind_varchar_length*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, val: cstring, length: idx_t): duckdb_state
proc duckdb_bind_blob*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t, data: pointer, length: idx_t): duckdb_state
proc duckdb_bind_null*(prepared_statement: duckdb_prepared_statement, param_idx: idx_t): duckdb_state

#
# Execute Prepared Statements
#
proc duckdb_execute_prepared*(prepared_statement: duckdb_prepared_statement, out_result: ptr duckdb_result): duckdb_state
proc duckdb_execute_prepared_streaming*(prepared_statement: duckdb_prepared_statement, out_result: ptr duckdb_result): duckdb_state

type
  duckdb_extracted_statements* = pointer

# Extract Statements
proc duckdb_extract_statements*(
  connection: duckdb_connection,
  query: cstring,
  out_extracted_statements: ptr duckdb_extracted_statements
): idx_t

proc duckdb_prepare_extracted_statement*(
  connection: duckdb_connection,
  extracted_statements: duckdb_extracted_statements,
  index: idx_t,
  out_prepared_statement: ptr duckdb_prepared_statement
): duckdb_state

proc duckdb_extract_statements_error*(
  extracted_statements: duckdb_extracted_statements
): cstring

proc duckdb_destroy_extracted*(
  extracted_statements: ptr duckdb_extracted_statements
)

type
  duckdb_pending_result* = pointer
  duckdb_pending_state* = cint
  duckdb_varint* = duckdb_hugeint
  duckdb_bit* = uint8

#
# Pending Result Interface
#
proc duckdb_pending_prepared*(prepared_statement: duckdb_prepared_statement, out_result: ptr duckdb_pending_result): duckdb_state
proc duckdb_pending_prepared_streaming*(prepared_statement: duckdb_prepared_statement, out_result: ptr duckdb_pending_result): duckdb_state
proc duckdb_destroy_pending*(pending_result: ptr duckdb_pending_result)
proc duckdb_pending_error*(pending_result: duckdb_pending_result): cstring
proc duckdb_pending_execute_task*(pending_result: duckdb_pending_result): duckdb_pending_state
proc duckdb_pending_execute_check_state*(pending_result: duckdb_pending_result): duckdb_pending_state
proc duckdb_execute_pending*(pending_result: duckdb_pending_result, out_result: ptr duckdb_result): duckdb_state
proc duckdb_pending_execution_is_finished*(pending_state: duckdb_pending_state): bool

#
# Value Interface
#
proc duckdb_destroy_value*(value: ptr duckdb_value)
proc duckdb_create_varchar*(text: cstring): duckdb_value
proc duckdb_create_varchar_length*(text: cstring, length: idx_t): duckdb_value
proc duckdb_create_bool*(input: bool): duckdb_value
proc duckdb_create_int8*(input: int8): duckdb_value
proc duckdb_create_uint8*(input: uint8): duckdb_value
proc duckdb_create_int16*(input: int16): duckdb_value
proc duckdb_create_uint16*(input: uint16): duckdb_value
proc duckdb_create_int32*(input: int32): duckdb_value
proc duckdb_create_uint32*(input: uint32): duckdb_value
proc duckdb_create_uint64*(input: uint64): duckdb_value
proc duckdb_create_int64*(val: int64): duckdb_value
proc duckdb_create_hugeint*(input: duckdb_hugeint): duckdb_value
proc duckdb_create_uhugeint*(input: duckdb_uhugeint): duckdb_value
proc duckdb_create_varint*(input: duckdb_varint): duckdb_value
proc duckdb_create_decimal*(input: duckdb_decimal): duckdb_value
proc duckdb_create_float*(input: float32): duckdb_value
proc duckdb_create_double*(input: float64): duckdb_value
proc duckdb_create_date*(input: duckdb_date): duckdb_value
proc duckdb_create_time*(input: duckdb_time): duckdb_value
proc duckdb_create_time_tz_value*(value: duckdb_time_tz): duckdb_value
proc duckdb_create_timestamp*(input: duckdb_timestamp): duckdb_value
proc duckdb_create_timestamp_tz*(input: duckdb_timestamp): duckdb_value
proc duckdb_create_timestamp_s*(input: duckdb_timestamp_s): duckdb_value
proc duckdb_create_timestamp_ms*(input: duckdb_timestamp_ms): duckdb_value
proc duckdb_create_timestamp_ns*(input: duckdb_timestamp_ns): duckdb_value
proc duckdb_create_interval*(input: duckdb_interval): duckdb_value
proc duckdb_create_blob*(data: ptr uint8, length: idx_t): duckdb_value
proc duckdb_create_bit*(input: duckdb_bit): duckdb_value
proc duckdb_create_uuid*(input: duckdb_uhugeint): duckdb_value
proc duckdb_get_bool*(val: duckdb_value): bool
proc duckdb_get_int8*(val: duckdb_value): int8
proc duckdb_get_uint8*(val: duckdb_value): uint8
proc duckdb_get_int16*(val: duckdb_value): int16
proc duckdb_get_uint16*(val: duckdb_value): uint16
proc duckdb_get_int32*(val: duckdb_value): int32
proc duckdb_get_uint32*(val: duckdb_value): uint32
proc duckdb_get_int64*(val: duckdb_value): int64
proc duckdb_get_uint64*(val: duckdb_value): uint64
proc duckdb_get_hugeint*(val: duckdb_value): duckdb_hugeint
proc duckdb_get_uhugeint*(val: duckdb_value): duckdb_uhugeint
proc duckdb_get_varint*(val: duckdb_value): duckdb_varint
proc duckdb_get_decimal*(val: duckdb_value): duckdb_decimal
proc duckdb_get_float*(val: duckdb_value): float32
proc duckdb_get_double*(val: duckdb_value): float64
proc duckdb_get_date*(val: duckdb_value): duckdb_date
proc duckdb_get_time*(val: duckdb_value): duckdb_time
proc duckdb_get_time_tz*(val: duckdb_value): duckdb_time_tz
proc duckdb_get_timestamp*(val: duckdb_value): duckdb_timestamp
proc duckdb_get_timestamp_tz*(val: duckdb_value): duckdb_timestamp
proc duckdb_get_timestamp_s*(val: duckdb_value): duckdb_timestamp_s
proc duckdb_get_timestamp_ms*(val: duckdb_value): duckdb_timestamp_ms
proc duckdb_get_timestamp_ns*(val: duckdb_value): duckdb_timestamp_ns
proc duckdb_get_interval*(val: duckdb_value): duckdb_interval
proc duckdb_get_value_type*(val: duckdb_value): duckdb_logical_type
proc duckdb_get_blob*(val: duckdb_value): duckdb_blob
proc duckdb_get_bit*(val: duckdb_value): duckdb_bit
proc duckdb_get_uuid*(val: duckdb_value): duckdb_uhugeint
proc duckdb_get_varchar*(value: duckdb_value): cstring
proc duckdb_create_struct_value*(typ: duckdb_logical_type, values: ptr duckdb_value): duckdb_value
proc duckdb_create_list_value*(typ: duckdb_logical_type, values: ptr duckdb_value, value_count: idx_t): duckdb_value
proc duckdb_create_array_value*(typ: duckdb_logical_type, values: ptr duckdb_value, value_count: idx_t): duckdb_value
proc duckdb_create_map_value*(map_type: duckdb_logical_type, keys: ptr duckdb_value, values: ptr duckdb_value, entry_count: idx_t): duckdb_value
proc duckdb_create_union_value*(union_type: duckdb_logical_type, tag_index: idx_t, value: duckdb_value): duckdb_value
proc duckdb_get_map_size*(value: duckdb_value): idx_t
proc duckdb_get_map_key*(value: duckdb_value, index: idx_t): duckdb_value
proc duckdb_get_map_value*(value: duckdb_value, index: idx_t): duckdb_value
proc duckdb_is_null_value*(value: duckdb_value): bool
proc duckdb_create_null_value*: duckdb_value
proc duckdb_get_list_size*(value: duckdb_value): idx_t
proc duckdb_get_list_child*(value: duckdb_value, index: idx_t): duckdb_value
proc duckdb_create_enum_value*(typ: duckdb_logical_type, value: uint64): duckdb_value
proc duckdb_get_enum_value*(value: duckdb_value): uint64
proc duckdb_get_struct_child*(value: duckdb_value, index: idx_t): duckdb_value
proc duckdb_value_to_string*(value: duckdb_value): cstring

# Validity Mask Functions
proc duckdb_validity_row_is_valid*(validity: ptr uint64, row: idx_t): bool
proc duckdb_validity_set_row_validity*(validity: ptr uint64, row: idx_t, valid: bool)
proc duckdb_validity_set_row_invalid*(validity: ptr uint64, row: idx_t)
proc duckdb_validity_set_row_valid*(validity: ptr uint64, row: idx_t)

# Scalar Functions
type
  duckdb_scalar_function* = pointer
  duckdb_scalar_function_set* = pointer
  duckdb_bind_info* = pointer
  duckdb_function_info* = pointer
  duckdb_delete_callback_t* = proc (p: pointer) {.cdecl.}
  duckdb_scalar_function_bind_t* = proc (info: duckdb_bind_info) {.cdecl.}
  duckdb_scalar_function_t* = proc (info: duckdb_function_info) {.cdecl.}

proc duckdb_create_scalar_function*(): duckdb_scalar_function
proc duckdb_destroy_scalar_function*(scalar_function: ptr duckdb_scalar_function)
proc duckdb_scalar_function_set_name*(scalar_function: duckdb_scalar_function, name: cstring)
proc duckdb_scalar_function_set_varargs*(scalar_function: duckdb_scalar_function, typ: duckdb_logical_type)
proc duckdb_scalar_function_set_special_handling*(scalar_function: duckdb_scalar_function)
proc duckdb_scalar_function_set_volatile*(scalar_function: duckdb_scalar_function)
proc duckdb_scalar_function_add_parameter*(scalar_function: duckdb_scalar_function, typ: duckdb_logical_type)
proc duckdb_scalar_function_set_return_type*(scalar_function: duckdb_scalar_function, typ: duckdb_logical_type)
proc duckdb_scalar_function_set_extra_info*(scalar_function: duckdb_scalar_function, extra_info: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_scalar_function_set_bind*(scalar_function: duckdb_scalar_function, `bind`: duckdb_scalar_function_bind_t)
proc duckdb_scalar_function_set_bind_data*(info: duckdb_bind_info, bind_data: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_scalar_function_bind_set_error*(info: duckdb_bind_info, error: cstring)
proc duckdb_scalar_function_set_function*(scalar_function: duckdb_scalar_function, fn: duckdb_scalar_function_t)
proc duckdb_register_scalar_function*(con: duckdb_connection, scalar_function: duckdb_scalar_function): duckdb_state
proc duckdb_scalar_function_get_extra_info*(info: duckdb_function_info): pointer
proc duckdb_scalar_function_get_bind_data*(info: duckdb_function_info): pointer
proc duckdb_scalar_function_get_client_context*(info: duckdb_bind_info, out_context: ptr duckdb_client_context)
proc duckdb_scalar_function_set_error*(info: duckdb_function_info, error: cstring)
proc duckdb_create_scalar_function_set*(name: cstring): duckdb_scalar_function_set
proc duckdb_destroy_scalar_function_set*(scalar_function_set: ptr duckdb_scalar_function_set)
proc duckdb_add_scalar_function_to_set*(set: duckdb_scalar_function_set, fn: duckdb_scalar_function): duckdb_state
proc duckdb_register_scalar_function_set*(con: duckdb_connection, set: duckdb_scalar_function_set): duckdb_state

# Selection Vector Interface
type
  duckdb_selection_vector* = pointer
  sel_t* = uint32

proc duckdb_create_selection_vector*(size: idx_t): duckdb_selection_vector
proc duckdb_destroy_selection_vector*(vector: duckdb_selection_vector)
proc duckdb_selection_vector_get_data_ptr*(vector: duckdb_selection_vector): ptr sel_t

# Aggregate Functions
type
  duckdb_aggregate_function* = pointer
  duckdb_aggregate_function_set* = pointer
  duckdb_aggregate_state_size* = proc (): csize_t {.cdecl.}
  duckdb_aggregate_init_t* = proc () {.cdecl.}
  duckdb_aggregate_update_t* = proc () {.cdecl.}
  duckdb_aggregate_combine_t* = proc () {.cdecl.}
  duckdb_aggregate_finalize_t* = proc () {.cdecl.}
  duckdb_aggregate_destroy_t* = proc (p: pointer) {.cdecl.}

proc duckdb_create_aggregate_function*(): duckdb_aggregate_function
proc duckdb_destroy_aggregate_function*(aggregate_function: ptr duckdb_aggregate_function)
proc duckdb_aggregate_function_set_name*(aggregate_function: duckdb_aggregate_function, name: cstring)
proc duckdb_aggregate_function_add_parameter*(aggregate_function: duckdb_aggregate_function, typ: duckdb_logical_type)
proc duckdb_aggregate_function_set_return_type*(aggregate_function: duckdb_aggregate_function, typ: duckdb_logical_type)
proc duckdb_aggregate_function_set_functions*(aggregate_function: duckdb_aggregate_function, state_size: duckdb_aggregate_state_size, state_init: duckdb_aggregate_init_t, update: duckdb_aggregate_update_t, combine: duckdb_aggregate_combine_t, finalize: duckdb_aggregate_finalize_t)
proc duckdb_aggregate_function_set_destructor*(aggregate_function: duckdb_aggregate_function, destroy: duckdb_aggregate_destroy_t)
proc duckdb_register_aggregate_function*(con: duckdb_connection, aggregate_function: duckdb_aggregate_function): duckdb_state
proc duckdb_aggregate_function_set_special_handling*(aggregate_function: duckdb_aggregate_function)
proc duckdb_aggregate_function_set_extra_info*(aggregate_function: duckdb_aggregate_function, extra_info: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_aggregate_function_get_extra_info*(info: duckdb_function_info): pointer
proc duckdb_aggregate_function_set_error*(info: duckdb_function_info, error: cstring)
proc duckdb_create_aggregate_function_set*(name: cstring): duckdb_aggregate_function_set
proc duckdb_destroy_aggregate_function_set*(aggregate_function_set: ptr duckdb_aggregate_function_set)
proc duckdb_add_aggregate_function_to_set*(set: duckdb_aggregate_function_set, fn: duckdb_aggregate_function): duckdb_state
proc duckdb_register_aggregate_function_set*(con: duckdb_connection, set: duckdb_aggregate_function_set): duckdb_state

#
# Table Functions
#
type
  duckdb_table_function* = pointer

proc duckdb_create_table_function*(): duckdb_table_function
proc duckdb_destroy_table_function*(table_function: ptr duckdb_table_function)
proc duckdb_table_function_set_name*(table_function: duckdb_table_function, name: cstring)
proc duckdb_table_function_add_parameter*(table_function: duckdb_table_function, typ: duckdb_logical_type)
proc duckdb_table_function_add_named_parameter*(table_function: duckdb_table_function, name: cstring, typ: duckdb_logical_type)
proc duckdb_table_function_set_extra_info*(table_function: duckdb_table_function, extra_info: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_table_function_set_bind*(table_function: duckdb_table_function, `bind`: pointer)
proc duckdb_table_function_set_init*(table_function: duckdb_table_function, init: pointer)
proc duckdb_table_function_set_local_init*(table_function: duckdb_table_function, init: pointer)
proc duckdb_table_function_set_function*(table_function: duckdb_table_function, fn: pointer)
proc duckdb_table_function_supports_projection_pushdown*(table_function: duckdb_table_function, pushdown: bool)
proc duckdb_register_table_function*(con: duckdb_connection, fn: duckdb_table_function): duckdb_state

# Table Function Bind
proc duckdb_bind_get_extra_info*(info: duckdb_bind_info): pointer
proc duckdb_bind_add_result_column*(info: duckdb_bind_info, name: cstring, typ: duckdb_logical_type)
proc duckdb_bind_get_parameter_count*(info: duckdb_bind_info): idx_t
proc duckdb_bind_get_parameter*(info: duckdb_bind_info, index: idx_t): duckdb_value
proc duckdb_bind_get_named_parameter*(info: duckdb_bind_info, name: cstring): duckdb_value
proc duckdb_bind_set_bind_data*(info: duckdb_bind_info, bind_data: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_bind_set_cardinality*(info: duckdb_bind_info, cardinality: idx_t, is_exact: bool)
proc duckdb_bind_set_error*(info: duckdb_bind_info, error: cstring)

#
# Table Function Init
#
type
  duckdb_init_info* = pointer

proc duckdb_init_get_extra_info*(info: duckdb_init_info): pointer
proc duckdb_init_get_bind_data*(info: duckdb_init_info): pointer
proc duckdb_init_set_init_data*(info: duckdb_init_info, init_data: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_init_get_column_count*(info: duckdb_init_info): idx_t
proc duckdb_init_get_column_index*(info: duckdb_init_info, column_index: idx_t): idx_t
proc duckdb_init_set_max_threads*(info: duckdb_init_info, max_threads: idx_t)
proc duckdb_init_set_error*(info: duckdb_init_info, error: cstring)

#
# Table Function
#
proc duckdb_function_get_extra_info*(info: duckdb_function_info): pointer
proc duckdb_function_get_bind_data*(info: duckdb_function_info): pointer
proc duckdb_function_get_init_data*(info: duckdb_function_info): pointer
proc duckdb_function_get_local_init_data*(info: duckdb_function_info): pointer
proc duckdb_function_set_error*(info: duckdb_function_info, error: cstring)

#
# Replacement Scans
#
type
  duckdb_replacement_scan_info* = pointer
  duckdb_replacement_callback_t* = proc (db: duckdb_database, info: duckdb_replacement_scan_info, extra_data: pointer) {.cdecl.}

proc duckdb_add_replacement_scan*(db: duckdb_database, replacement: duckdb_replacement_callback_t, extra_data: pointer, delete_callback: duckdb_delete_callback_t)
proc duckdb_replacement_scan_set_function_name*(info: duckdb_replacement_scan_info, function_name: cstring)
proc duckdb_replacement_scan_add_parameter*(info: duckdb_replacement_scan_info, parameter: duckdb_value)
proc duckdb_replacement_scan_set_error*(info: duckdb_replacement_scan_info, error: cstring)

#
# Profiling Info
#
type
  duckdb_profiling_info* = pointer

proc duckdb_get_profiling_info*(connection: duckdb_connection): duckdb_profiling_info
proc duckdb_profiling_info_get_value*(info: duckdb_profiling_info, key: cstring): duckdb_value
proc duckdb_profiling_info_get_metrics*(info: duckdb_profiling_info): duckdb_value
proc duckdb_profiling_info_get_child_count*(info: duckdb_profiling_info): idx_t
proc duckdb_profiling_info_get_child*(info: duckdb_profiling_info, index: idx_t): duckdb_profiling_info

#
# Appender
#
type
  duckdb_appender* = pointer

proc duckdb_appender_create*(connection: duckdb_connection, schema: cstring, table: cstring, out_appender: ptr duckdb_appender): duckdb_state
proc duckdb_appender_create_ext*(connection: duckdb_connection, catalog: cstring, schema: cstring, table: cstring, out_appender: ptr duckdb_appender): duckdb_state
proc duckdb_appender_column_count*(appender: duckdb_appender): idx_t
proc duckdb_appender_column_type*(appender: duckdb_appender, col_idx: idx_t): duckdb_logical_type
proc duckdb_appender_error*(appender: duckdb_appender): cstring
proc duckdb_appender_flush*(appender: duckdb_appender): duckdb_state
proc duckdb_appender_close*(appender: duckdb_appender): duckdb_state
proc duckdb_appender_destroy*(appender: ptr duckdb_appender): duckdb_state
proc duckdb_appender_add_column*(appender: duckdb_appender, name: cstring): duckdb_state
proc duckdb_appender_clear_columns*(appender: duckdb_appender): duckdb_state
proc duckdb_appender_begin_row*(appender: duckdb_appender): duckdb_state
proc duckdb_appender_end_row*(appender: duckdb_appender): duckdb_state
proc duckdb_append_default*(appender: duckdb_appender): duckdb_state
proc duckdb_append_default_to_chunk*(appender: duckdb_appender, chunk: duckdb_data_chunk, col: idx_t, row: idx_t): duckdb_state
proc duckdb_append_bool*(appender: duckdb_appender, value: bool): duckdb_state
proc duckdb_append_int8*(appender: duckdb_appender, value: int8): duckdb_state
proc duckdb_append_int16*(appender: duckdb_appender, value: int16): duckdb_state
proc duckdb_append_int32*(appender: duckdb_appender, value: int32): duckdb_state
proc duckdb_append_int64*(appender: duckdb_appender, value: int64): duckdb_state
proc duckdb_append_hugeint*(appender: duckdb_appender, value: duckdb_hugeint): duckdb_state
proc duckdb_append_uint8*(appender: duckdb_appender, value: uint8): duckdb_state
proc duckdb_append_uint16*(appender: duckdb_appender, value: uint16): duckdb_state
proc duckdb_append_uint32*(appender: duckdb_appender, value: uint32): duckdb_state
proc duckdb_append_uint64*(appender: duckdb_appender, value: uint64): duckdb_state
proc duckdb_append_uhugeint*(appender: duckdb_appender, value: duckdb_uhugeint): duckdb_state
proc duckdb_append_float*(appender: duckdb_appender, value: float32): duckdb_state
proc duckdb_append_double*(appender: duckdb_appender, value: float64): duckdb_state
proc duckdb_append_date*(appender: duckdb_appender, value: duckdb_date): duckdb_state
proc duckdb_append_time*(appender: duckdb_appender, value: duckdb_time): duckdb_state
proc duckdb_append_timestamp*(appender: duckdb_appender, value: duckdb_timestamp): duckdb_state
proc duckdb_append_interval*(appender: duckdb_appender, value: duckdb_interval): duckdb_state
proc duckdb_append_varchar*(appender: duckdb_appender, val: cstring): duckdb_state
proc duckdb_append_varchar_length*(appender: duckdb_appender, val: cstring, length: idx_t): duckdb_state
proc duckdb_append_blob*(appender: duckdb_appender, data: pointer, length: idx_t): duckdb_state
proc duckdb_append_null*(appender: duckdb_appender): duckdb_state
proc duckdb_append_value*(appender: duckdb_appender, value: duckdb_value): duckdb_state
proc duckdb_append_data_chunk*(appender: duckdb_appender, chunk: duckdb_data_chunk): duckdb_state

#
# Table Description
#
type
  duckdb_table_description* = pointer

proc duckdb_table_description_create*(connection: duckdb_connection, schema: cstring, table: cstring, out_desc: ptr duckdb_table_description): duckdb_state
proc duckdb_table_description_create_ext*(connection: duckdb_connection, catalog: cstring, schema: cstring, table: cstring, out_desc: ptr duckdb_table_description): duckdb_state
proc duckdb_table_description_destroy*(table_description: ptr duckdb_table_description)
proc duckdb_table_description_error*(table_description: duckdb_table_description): cstring
proc duckdb_column_has_default*(table_description: duckdb_table_description, index: idx_t, `out`: ptr bool): duckdb_state
proc duckdb_table_description_get_column_name*(table_description: duckdb_table_description, index: idx_t): cstring

#
# Arrow Interface
#
type
  duckdb_arrow* = pointer
  duckdb_arrow_schema* = pointer
  duckdb_arrow_array* = pointer
  duckdb_arrow_stream* = pointer

proc duckdb_query_arrow*(connection: duckdb_connection, query: cstring, out_result: ptr duckdb_arrow): duckdb_state
proc duckdb_query_arrow_schema*(result: duckdb_arrow, out_schema: ptr duckdb_arrow_schema): duckdb_state
proc duckdb_prepared_arrow_schema*(prepared: duckdb_prepared_statement, out_schema: ptr duckdb_arrow_schema): duckdb_state
proc duckdb_result_arrow_array*(result: duckdb_result, chunk: duckdb_data_chunk, out_array: ptr duckdb_arrow_array)
proc duckdb_query_arrow_array*(result: duckdb_arrow, out_array: ptr duckdb_arrow_array): duckdb_state
proc duckdb_arrow_column_count*(result: duckdb_arrow): idx_t
proc duckdb_arrow_row_count*(result: duckdb_arrow): idx_t
proc duckdb_arrow_rows_changed*(result: duckdb_arrow): idx_t
proc duckdb_query_arrow_error*(result: duckdb_arrow): cstring
proc duckdb_destroy_arrow*(result: ptr duckdb_arrow)
proc duckdb_destroy_arrow_stream*(stream_p: duckdb_arrow_stream)
proc duckdb_execute_prepared_arrow*(prepared_statement: duckdb_prepared_statement, out_result: ptr duckdb_arrow): duckdb_state
proc duckdb_arrow_scan*(connection: duckdb_connection, table_name: cstring, arrow: duckdb_arrow_stream): duckdb_state
proc duckdb_arrow_array_scan*(connection: duckdb_connection, table_name: cstring, arrow_schema: duckdb_arrow_schema, arrow_array: duckdb_arrow_array, out_stream: ptr duckdb_arrow_stream): duckdb_state

#
# Threading Information
#
type
  duckdb_task_state* = pointer

proc duckdb_execute_tasks*(database: duckdb_database, max_tasks: idx_t)
proc duckdb_create_task_state*(database: duckdb_database): duckdb_task_state
proc duckdb_execute_tasks_state*(state: duckdb_task_state)
proc duckdb_execute_n_tasks_state*(state: duckdb_task_state, max_tasks: idx_t): idx_t
proc duckdb_finish_execution*(state: duckdb_task_state)
proc duckdb_task_state_is_finished*(state: duckdb_task_state): bool
proc duckdb_destroy_task_state*(state: duckdb_task_state)
proc duckdb_execution_is_finished*(con: duckdb_connection): bool

# Streaming Result Interface
proc duckdb_stream_fetch_chunk*(result: duckdb_result): duckdb_data_chunk
proc duckdb_fetch_chunk*(result: duckdb_result): duckdb_data_chunk

#
# Cast Functions
#
type
  duckdb_cast_function* = pointer
  duckdb_cast_mode* = cint
  duckdb_cast_function_t* = proc () {.cdecl.}
  duckdb_vector* = pointer

proc duckdb_create_cast_function*(): duckdb_cast_function
proc duckdb_cast_function_set_source_type*(cast_function: duckdb_cast_function, source_type: duckdb_logical_type)
proc duckdb_cast_function_set_target_type*(cast_function: duckdb_cast_function, target_type: duckdb_logical_type)
proc duckdb_cast_function_set_implicit_cast_cost*(cast_function: duckdb_cast_function, cost: int64)
proc duckdb_cast_function_set_function*(cast_function: duckdb_cast_function, fn: duckdb_cast_function_t)
proc duckdb_cast_function_set_extra_info*(cast_function: duckdb_cast_function, extra_info: pointer, destroy: duckdb_delete_callback_t)
proc duckdb_cast_function_get_extra_info*(info: duckdb_function_info): pointer
proc duckdb_cast_function_get_cast_mode*(info: duckdb_function_info): duckdb_cast_mode
proc duckdb_cast_function_set_error*(info: duckdb_function_info, error: cstring)
proc duckdb_cast_function_set_row_error*(info: duckdb_function_info, error: cstring, row: idx_t, output: duckdb_vector)
proc duckdb_register_cast_function*(con: duckdb_connection, cast_function: duckdb_cast_function): duckdb_state
proc duckdb_destroy_cast_function*(cast_function: ptr duckdb_cast_function)

{.pop.}
