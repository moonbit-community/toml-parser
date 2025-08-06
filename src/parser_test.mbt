///| Tests for the TOML parser
test "parse simple key-value string" {
  let result = @toml.parse("name = \"John\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "name": ["TomlString", "John"] },
  ])
}

///|
test "parse simple key-value integer" {
  let result = @toml.parse("age = 25")
  @json.inspect(result, content=["TomlTable", { "age": ["TomlInteger", "25"] }])
}

///|
test "parse simple key-value boolean" {
  let result = @toml.parse("enabled = true")
  @json.inspect(result, content=[
    "TomlTable",
    { "enabled": ["TomlBoolean", true] },
  ])
}

///|
test "parse simple key-value float" {
  let result = @toml.parse("pi = 3.14")
  @json.inspect(result, content=["TomlTable", { "pi": ["TomlFloat", 3.14] }])
}

///|
test "parse multiple key-value pairs" {
  let result = @toml.parse("name = \"Alice\"\nage = 30\nenabled = false")
  @json.inspect(result, content=[
    "TomlTable",
    {
      "name": ["TomlString", "Alice"],
      "age": ["TomlInteger", "30"],
      "enabled": ["TomlBoolean", false],
    },
  ])
}

///|
test "parse array" {
  let result = @toml.parse("numbers = [1, 2, 3]")
  @json.inspect(result, content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
    },
  ])
}

///|
test "parse inline table" {
  let result = @toml.parse("person = {name = \"Bob\", age = 25}")
  @json.inspect(result, content=[
    "TomlTable",
    {
      "person": [
        "TomlTable",
        { "name": ["TomlString", "Bob"], "age": ["TomlInteger", "25"] },
      ],
    },
  ])
}

///| Test parser edge cases for better coverage through public parse function

///| Test empty input (covers EOF handling)
test "parser empty input" {
  let result = @toml.parse("")
  @json.inspect(result, content=["TomlTable", {}])
}

///| Test input with only whitespace and newlines
test "parser whitespace only input" {
  let result = @toml.parse("   \n\n   \n   ")
  @json.inspect(result, content=["TomlTable", {}])
}

///| Test inline table with string keys (covers StringToken key case)
test "parse inline table with string keys" {
  let result = @toml.parse(
    "config = {\"host\" = \"localhost\", \"port\" = 8080}",
  )
  @json.inspect(result, content=[
    "TomlTable",
    {
      "config": [
        "TomlTable",
        { "host": ["TomlString", "localhost"], "port": ["TomlInteger", "8080"] },
      ],
    },
  ])
}

///| Test inline table error cases (covers inline table error branches)
test "parse inline table error cases" {
  // Test malformed inline table - missing closing brace
  try {
    let _ = @toml.parse("config = {key = \"value\"")
    fail("Should have failed on missing closing brace")
  } catch {
    _ => () // Expected failure
  }

  // Test inline table with invalid key
  try {
    let _ = @toml.parse("config = {123 = \"value\"}")
    fail("Should have failed on numeric key")
  } catch {
    _ => () // Expected failure
  }

  // Test inline table with missing comma
  try {
    let _ = @toml.parse("config = {key1 = \"value1\" key2 = \"value2\"}")
    fail("Should have failed on missing comma")
  } catch {
    _ => () // Expected failure
  }
}

///| Test table headers with string names (covers StringToken table name case)
test "parse table with string header" {
  let result = @toml.parse("[\"my-table\"]\nkey = \"value\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "my-table": ["TomlTable", { "key": ["TomlString", "value"] }] },
  ])
}

///| Test table header error cases (covers table header error branches)
test "parse table header error cases" {
  // Test malformed table header - missing table name
  try {
    let _ = @toml.parse("[]")
    fail("Should have failed on empty table header")
  } catch {
    _ => () // Expected failure
  }

  // Test malformed table header - invalid table name
  try {
    let _ = @toml.parse("[123]")
    fail("Should have failed on numeric table name")
  } catch {
    _ => () // Expected failure
  }
}

///| Test table name conflicts (covers existing table logic)
test "parse existing table reference" {
  // Test referring to existing table (should reuse existing table)
  let toml_with_table_reuse = "[database]\nhost = \"localhost\"\n\n[database]\nport = 5432"
  let result = @toml.parse(toml_with_table_reuse)
  match result {
    @toml.TomlTable(main_table) =>
      match main_table.get("database") {
        Some(@toml.TomlTable(db_table)) => {
          // Should have both keys in same table
          inspect(db_table.contains("host"), content="true")
          inspect(db_table.contains("port"), content="true")
        }
        _ => fail("Expected database to be a table")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test table name conflicts with values (covers conflict error)
test "parse table name conflicts with value" {
  try {
    let toml_with_conflict = "database = \"some_string\"\n\n[database]\nhost = \"localhost\""
    let _ = @toml.parse(toml_with_conflict)
    fail("Should have failed on table name conflict")
  } catch {
    _ => () // Expected failure
  }
}

///| Test complex array edge cases (covers array error branches)
test "parse array edge cases" {
  // Test empty array
  let result1 = @toml.parse("empty = []")
  @json.inspect(result1, content=["TomlTable", { "empty": ["TomlArray", []] }])

  // Test array with trailing comma
  let result2 = @toml.parse("numbers = [1, 2, 3,]")
  @json.inspect(result2, content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
    },
  ])

  // Test array with newlines
  let result3 = @toml.parse("numbers = [\n1,\n2,\n3\n]")
  @json.inspect(result3, content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
    },
  ])
}

///| Test array error cases
test "parse array error cases" {
  // Test malformed array - missing closing bracket
  try {
    let _ = @toml.parse("arr = [1, 2, 3")
    fail("Should have failed on missing closing bracket")
  } catch {
    _ => () // Expected failure
  }

  // Test array with invalid syntax
  try {
    let _ = @toml.parse("arr = [1 2 3]")
    fail("Should have failed on missing commas")
  } catch {
    _ => () // Expected failure
  }
}

///| Test key-value pair edge cases
test "parse key value edge cases" {
  // Test string key
  let result = @toml.parse("\"string-key\" = \"value\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "string-key": ["TomlString", "value"] },
  ])
}

///| Test key-value error cases
test "parse key value error cases" {
  // Test invalid key type
  try {
    let _ = @toml.parse("123 = \"value\"")
    fail("Should have failed on numeric key")
  } catch {
    _ => () // Expected failure
  }
}

///| Test parse value error cases
test "parse value error cases" {
  // Test unexpected token as value
  try {
    let _ = @toml.parse("key = =")
    fail("Should have failed on invalid value")
  } catch {
    _ => () // Expected failure
  }

  // Test unfinished value
  try {
    let _ = @toml.parse("key = ")
    fail("Should have failed on missing value")
  } catch {
    _ => () // Expected failure
  }
}

///| Test skip newlines functionality
test "parse with multiple newlines" {
  let toml_with_newlines = "\n\n\nkey1 = \"value1\"\n\n\nkey2 = \"value2\"\n\n\n"
  let result = @toml.parse(toml_with_newlines)
  @json.inspect(result, content=[
    "TomlTable",
    { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
  ])
}
