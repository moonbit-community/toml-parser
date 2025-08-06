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

///| Test parser error handling - EOF when expected token
test "parser expect EOF error" {
  try {
    let _result = @toml.parse("key = ")
    fail("Should have thrown parse error")
  } catch {
    msg => inspect(msg.to_string().contains("Expected"), content="true")
  }
}

///| Test parser error handling - wrong token in expect
test "parser expect wrong token error" {
  try {
    let _result = @toml.parse("key \"value\"") // Missing =
    fail("Should have thrown parse error")
  } catch {
    msg => inspect(msg.to_string().contains("Expected"), content="true")
  }
}

///| Test parser error handling - string key in inline table
test "string key in inline table" {
  let result = @toml.parse("table = {\"string_key\" = \"value\"}")
  @json.inspect(result, content=[
    "TomlTable",
    { "table": ["TomlTable", { "string_key": ["TomlString", "value"] }] },
  ])
}

///| Test parser error handling - invalid key in inline table
test "invalid key in inline table error" {
  try {
    let _result = @toml.parse("table = {123 = \"value\"}") // Invalid key
    fail("Should have thrown parse error")
  } catch {
    msg => inspect(msg.to_string().contains("Expected key"), content="true")
  }
}

///| Test parser error handling - invalid separator in inline table
test "invalid separator in inline table error" {
  try {
    let _result = @toml.parse("table = {key = \"value\" ; other = \"val\"}") // Invalid separator
    fail("Should have thrown parse error")
  } catch {
    msg =>
      // Just check that an error was thrown, the exact message may vary
      inspect(msg.to_string().length() > 0, content="true")
  }
}

///| Test parser error handling - string table name
test "string table name" {
  let result = @toml.parse("[\"string.table\"]\nkey = \"value\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "string.table": ["TomlTable", { "key": ["TomlString", "value"] }] },
  ])
}

///| Test parser error handling - invalid table name
test "invalid table name error" {
  try {
    let _result = @toml.parse("[123]\nkey = \"value\"") // Invalid table name
    fail("Should have thrown parse error")
  } catch {
    msg =>
      inspect(msg.to_string().contains("Expected table name"), content="true")
  }
}

///| Test parser error handling - conflicting table and value
test "conflicting table and value error" {
  try {
    let _result = @toml.parse("key = \"value\"\n[key]\nother = \"val\"") // Conflict
    fail("Should have thrown parse error")
  } catch {
    msg => inspect(msg.to_string().contains("conflicts"), content="true")
  }
}

///| Test parser with existing table
test "parser with existing table" {
  let result = @toml.parse(
    "[table]\nkey1 = \"value1\"\n[table]\nkey2 = \"value2\"",
  )
  @json.inspect(result, content=[
    "TomlTable",
    {
      "table": [
        "TomlTable",
        { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
      ],
    },
  ])
}

///| Test parser peek and advance at EOF
test "parser operations at EOF" {
  // Test with empty input to trigger EOF paths
  let result = @toml.parse("")
  @json.inspect(result, content=["TomlTable", {}])
}

///| Test parser with only newlines
test "parser with only newlines" {
  let result = @toml.parse("\n\n\n")
  @json.inspect(result, content=["TomlTable", {}])
}
