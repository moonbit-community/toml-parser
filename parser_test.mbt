///|
/// Tests for the TOML parser
test "parse simple key-value string" {
  let result = @toml.parse(
    (
      #|name = "John"
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "name": TomlString("John") })
    ),
  )
}

///|
test "parse simple key-value integer" {
  let result = @toml.parse(
    (
      #|age = 25
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "age": TomlInteger(25) })
    ),
  )
}

///|
test "parse simple key-value boolean" {
  let result = @toml.parse(
    (
      #|enabled = true
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "enabled": TomlBoolean(true) })
    ),
  )
}

///|
test "parse simple key-value float" {
  let result = @toml.parse(
    (
      #|pi = 3.14
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "pi": TomlFloat(3.14) })
    ),
  )
}

///|
test "parse multiple key-value pairs" {
  let multiple_kvp_toml =
    #|name = "Alice"
    #|age = 30
    #|enabled = false
    #|
  let result = @toml.parse(multiple_kvp_toml)
  debug_inspect(
    result,
    content=(
      #|TomlTable(
      #|  {
      #|    "name": TomlString("Alice"),
      #|    "age": TomlInteger(30),
      #|    "enabled": TomlBoolean(false),
      #|  },
      #|)
    ),
  )
}

///|
test "parse array" {
  let result = @toml.parse(
    (
      #|numbers = [1, 2, 3]
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "numbers": TomlArray([TomlInteger(1), TomlInteger(2), TomlInteger(3)]) })
    ),
  )
}

///|
test "parse inline table" {
  let inline_table_toml =
    #|person = {name = "Bob", age = 25}
    #|
  let result = @toml.parse(inline_table_toml)
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "person": TomlTable({ "name": TomlString("Bob"), "age": TomlInteger(25) }) })
    ),
  )
}

///|
/// Tests for uncovered parser error conditions
test "test parser expect method failure" {
  debug_inspect(
    try? @toml.parse("key = [missing_bracket"),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 8 }, end: { line: 1, column: 23 } }"))
    ),
  )
}

///|
test "test parser EOF handling in peek" {
  debug_inspect(
    try? @toml.parse(""),
    content=(
      #|Ok(TomlTable({}))
    ),
  )
}

///|
test "test parser EOF handling in advance" {
  debug_inspect(
    try? @toml.parse("key ="),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 6 }, end: { line: 1, column: 6 } }"))
    ),
  )
}

///|
test "test parser rejects dash-starting identifier as value" {
  debug_inspect(
    try? @toml.parse("key = -abc"),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 7 }, end: { line: 1, column: 11 } }"))
    ),
  )
}

///|
test "test inline table with string keys" {
  debug_inspect(
    try? @toml.parse("table = {\"string key\" = \"value\"}"),
    content=(
      #|Ok(TomlTable({ "table": TomlTable({ "string key": TomlString("value") }) }))
    ),
  )
}

///|
test "test inline table invalid syntax" {
  debug_inspect(
    try? @toml.parse("table = {key value}"),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Expected '=' at { start: { line: 1, column: 14 }, end: { line: 1, column: 19 } }"))
    ),
  )
}

///|
test "test inline table missing comma or closing brace" {
  debug_inspect(
    try? @toml.parse("table = {key = \"value\" invalid}"),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Expected ',' or '}' in inline table at { start: { line: 1, column: 24 }, end: { line: 1, column: 31 } }"))
    ),
  )
}

///|
test "test table header with string name" {
  let string_table_name_toml =
    #|["table name"]
    #|key = "value"
    #|
  debug_inspect(
    try? @toml.parse(string_table_name_toml),
    content=(
      #|Ok(TomlTable({ "table name": TomlTable({ "key": TomlString("value") }) }))
    ),
  )
}

///|
test "test table header numeric name" {
  let numeric_table_name_toml =
    #|[123]
    #|key = "value"
    #|
  debug_inspect(
    try? @toml.parse(numeric_table_name_toml),
    content=(
      #|Ok(TomlTable({ "123": TomlTable({ "key": TomlString("value") }) }))
    ),
  )
}

///|
test "test exponent-like bare keys" {
  let exponent_like_keys_toml =
    #|10e-1 = "a"
    #|10e1 = "b"
    #|-e-1 = "c"
    #|-10e-1 = "d"
    #|
  debug_inspect(
    try? @toml.parse(exponent_like_keys_toml),
    content=(
      #|Ok(TomlTable({ "10e-1": TomlString("a"), "10e1": TomlString("b"), "-e-1": TomlString("c"), "-10e-1": TomlString("d") }))
    ),
  )
}

///|
test "test exponent-like bare table headers" {
  let exponent_like_table_names_toml =
    #|[10e-1]
    #|value = "a"
    #|[10e1]
    #|value = "b"
    #|[-e-1]
    #|value = "c"
    #|[-10e-1]
    #|value = "d"
    #|
  debug_inspect(
    try? @toml.parse(exponent_like_table_names_toml),
    content=(
      #|Ok(TomlTable({ "10e-1": TomlTable({ "value": TomlString("a") }), "10e1": TomlTable({ "value": TomlString("b") }), "-e-1": TomlTable({ "value": TomlString("c") }), "-10e-1": TomlTable({ "value": TomlString("d") }) }))
    ),
  )
}

///|
test "test duplicate table redefinition" {
  let duplicate_table_toml =
    #|[table]
    #|key1 = "value1"
    #|[table]
    #|key2 = "value2"
    #|
  debug_inspect(
    try? @toml.parse(duplicate_table_toml),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: Duplicate table definition: [table] at { start: { line: 3, column: 8 }, end: { line: 4, column: 1 } }"))
    ),
  )
}

///|
test "test table name conflicts with existing value" {
  let conflicting_table_toml =
    #|table = "string"
    #|[table]
    #|key = "value"
    #|
  debug_inspect(
    try? @toml.parse(conflicting_table_toml),
    content=(
      #|Err(Failure("parser.mbt:189:20-189:70@bobzhang/toml FAILED: ExpectedTable(\"table\", \"string\") at { start: { line: 2, column: 8 }, end: { line: 3, column: 1 } }"))
    ),
  )
}

///|
/// Tests for inline table edge cases  
test "test empty inline table" {
  debug_inspect(
    try? @toml.parse("empty = {}"),
    content=(
      #|Ok(TomlTable({ "empty": TomlTable({}) }))
    ),
  )
}

///|
test "test nested inline tables" {
  debug_inspect(
    try? @toml.parse("table = {inner = {key = \"value\"}}"),
    content=(
      #|Ok(TomlTable({ "table": TomlTable({ "inner": TomlTable({ "key": TomlString("value") }) }) }))
    ),
  )
}

///|
test "test inline table with multiple key types" {
  debug_inspect(
    try? @toml.parse("mixed = {\"quoted\" = 1, unquoted = 2}"),
    content=(
      #|Ok(TomlTable({ "mixed": TomlTable({ "quoted": TomlInteger(1), "unquoted": TomlInteger(2) }) }))
    ),
  )
}

///|
test "test inline table with array values" {
  debug_inspect(
    try? @toml.parse("table = {arr = [1, 2, 3], str = \"test\"}"),
    content=(
      #|Ok(
      #|  TomlTable(
      #|    {
      #|      "table": TomlTable(
      #|        {
      #|          "arr": TomlArray([TomlInteger(1), TomlInteger(2), TomlInteger(3)]),
      #|          "str": TomlString("test"),
      #|        },
      #|      ),
      #|    },
      #|  ),
      #|)
    ),
  )
}

///|
/// Test dotted key notation - simple case
test "dotted key notation simple" {
  let result = @toml.parse(
    (
      #|a.b.c = "value"
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "a": TomlTable({ "b": TomlTable({ "c": TomlString("value") }) }) })
    ),
  )
}

///|
/// Test dotted key notation - multiple values
test "dotted key notation multiple" {
  let dotted_multiple_toml =
    #|a.b.c = "value1"
    #|a.b.d = "value2"
    #|a.e = "value3"
    #|f = "value4"
    #|
  debug_inspect(
    @toml.parse(dotted_multiple_toml),
    content=(
      #|TomlTable(
      #|  {
      #|    "a": TomlTable(
      #|      {
      #|        "b": TomlTable({ "c": TomlString("value1"), "d": TomlString("value2") }),
      #|        "e": TomlString("value3"),
      #|      },
      #|    ),
      #|    "f": TomlString("value4"),
      #|  },
      #|)
    ),
  )
}

///|
/// Test dotted key notation - different data types
test "dotted key notation data types" {
  let dotted_types_toml =
    #|server.host = "localhost"
    #|server.port = 8080
    #|server.enabled = true
    #|server.timeout = 30.5
    #|server.tags = ["web", "api"]
    #|
  debug_inspect(
    @toml.parse(dotted_types_toml),
    content=(
      #|TomlTable(
      #|  {
      #|    "server": TomlTable(
      #|      {
      #|        "host": TomlString("localhost"),
      #|        "port": TomlInteger(8080),
      #|        "enabled": TomlBoolean(true),
      #|        "timeout": TomlFloat(30.5),
      #|        "tags": TomlArray([TomlString("web"), TomlString("api")]),
      #|      },
      #|    ),
      #|  },
      #|)
    ),
  )
}

///|
/// Test dotted key notation - quoted keys
test "dotted key notation quoted keys" {
  let result = @toml.parse(
    (
      #|"first.part"."second.part" = "value"
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "first.part": TomlTable({ "second.part": TomlString("value") }) })
    ),
  )
}

///|
/// Test dotted key notation - integer keys
test "dotted key notation integer keys" {
  let result = @toml.parse(
    (
      #|1.2.3 = "numeric path"
    ),
  )
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "1": TomlTable({ "2": TomlTable({ "3": TomlString("numeric path") }) }) })
    ),
  )
}

///|
/// Test dotted key notation - conflict with table headers
test "dotted key notation table conflict" {
  let conflict_toml =
    #|a.b = "dotted"
    #|[a]
    #|c = "table"
    #|
  debug_inspect(
    @toml.parse(conflict_toml),
    content=(
      #|TomlTable({ "a": TomlTable({ "b": TomlString("dotted"), "c": TomlString("table") }) })
    ),
  )
}

///|
/// Test dotted key notation - deep nesting
test "dotted key notation deep nesting" {
  let result = @toml.parse(
    (
      #|a.b.c.d.e.f = "deep"
    ),
  )
  // TODO:
  // TOML::to_string is not really  good, 
  debug_inspect(
    result,
    content=(
      #|TomlTable({ "a": TomlTable({ "b": TomlTable({ "c": TomlTable({ "d": TomlTable({ "e": TomlTable({ "f": TomlString("deep") }) }) }) }) }) })
    ),
  )
}

///|
#skip("this is a bug to be fixed")
test "complex dotted keys" {
  let data =
    #|  [x]
    #|server."port number".8080.config = 3
    #|
  // TODO: fix
  debug_inspect(try? @toml.parse(data), content="")
}
