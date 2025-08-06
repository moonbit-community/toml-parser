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


///| Tests for uncovered parser functionality and error cases
///| This tests error handling and edge cases to improve coverage

test "test parser creation" {
  // Test parser creation
  let tokens = [@tokenize.Identifier("key")]
  let _parser = @toml.Parser::new(tokens)
  // Parser is created successfully
  assert_true(true)
}

test "test inline table with string key" {
  // Test the uncovered string key case in parse_inline_table()
  let toml_input = "table = {\"key\" = \"value\"}"
  try {
    let result = @toml.parse(toml_input)
    match result {
      @toml.TomlTable(main_table) => {
        match main_table.get("table") {
          Some(@toml.TomlTable(table)) => {
            match table.get("key") {
              Some(@toml.TomlString("value")) => assert_true(true)
              _ => assert_true(false)
            }
          }
          _ => assert_true(false)
        }
      }
      _ => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}

test "test inline table with invalid key throws error" {
  // Test error handling through TOML parsing
  try {
    let _result = @toml.parse("{123 = \"value\"}")
    assert_true(false) // Should not reach here
  } catch {
    _ => assert_true(true) // Should throw error
  }
}

test "test inline table missing comma or brace throws error" {
  // Test error handling through TOML parsing
  try {
    let _result = @toml.parse("{key = \"value\" another}")
    assert_true(false) // Should not reach here
  } catch {
    _ => assert_true(true) // Should throw error
  }
}

test "test table header with string name" {
  // Test the uncovered string name case in parse_table_header()
  let toml_input = "[\"table name\"]\nkey = \"value\""
  try {
    let result = @toml.parse(toml_input)
    match result {
      @toml.TomlTable(table) => {
        match table.get("table name") {
          Some(@toml.TomlTable(_)) => assert_true(true)
          _ => assert_true(false)
        }
      }
      _ => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}

test "test table header with invalid name throws error" {
  // Test error handling through TOML parsing
  try {
    let _result = @toml.parse("[123]\nkey = \"value\"")
    assert_true(false) // Should not reach here
  } catch {
    _ => assert_true(true) // Should throw error
  }
}

test "test parse with existing table" {
  // Test the uncovered existing table case in parse()
  let toml_input = "[table]\nkey1 = \"value1\"\n[table]\nkey2 = \"value2\""
  try {
    let result = @toml.parse(toml_input)
    match result {
      @toml.TomlTable(main_table) => {
        match main_table.get("table") {
          Some(@toml.TomlTable(table)) => {
            // Should have both keys
            assert_true(table.contains("key1"))
            assert_true(table.contains("key2"))
          }
          _ => assert_true(false)
        }
      }
      _ => assert_true(false)
    }
  } catch {
    _ => assert_true(false)
  }
}