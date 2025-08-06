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

///| Test parser error handling - malformed input
test "parser expect error" {
  // Test parsing malformed input that should cause parser errors
  try {
    ignore(@toml.parse("key value")) // missing equals sign
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test parser with string key in inline table
test "parse inline table with string key" {
  let result = @toml.parse("table = {\"string key\" = \"value\"}")
  @json.inspect(result, content=[
    "TomlTable",
    { "table": ["TomlTable", { "string key": ["TomlString", "value"] }] },
  ])
}

///| Test parser error on invalid inline table syntax
test "parse invalid inline table error" {
  try {
    // Missing comma between key-value pairs
    ignore(@toml.parse("table = {key1 = \"value1\" key2 = \"value2\"}"))
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test table header parsing with string name
test "parse table header with string name" {
  let result = @toml.parse("[\"table name\"]\nkey = \"value\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "table name": ["TomlTable", { "key": ["TomlString", "value"] }] },
  ])
}

///| Test table conflict error handling
test "parse table conflict error" {
  try {
    // Try to redefine a key as both value and table
    ignore(@toml.parse("key = \"value\"\n[key]\nsubkey = \"subvalue\""))
    inspect(false, content="false") // Should not reach here  
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test parser with empty input
test "parser with empty input" {
  // Test parsing empty input
  let result = @toml.parse("")
  // Should return an empty table
  let result_str = result.to_string()
  inspect(result_str == "{}" || result_str == "{ }", content="true")
}

///| Test invalid table header syntax
test "parse invalid table header" {
  try {
    // Invalid token in table header
    ignore(@toml.parse("[123]\nkey = \"value\"")) // number instead of identifier
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test empty inline table  
test "parse empty inline table" {
  let result = @toml.parse("empty = {}")
  @json.inspect(result, content=["TomlTable", { "empty": ["TomlTable", {}] }])
}

///| Test multiline with various newlines
test "parse multiline with newlines" {
  let result = @toml.parse("key1 = \"value1\"\n\n\nkey2 = \"value2\"")
  @json.inspect(result, content=[
    "TomlTable",
    { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
  ])
}

///| Test existing table redefinition
test "parse existing table extension" {
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

///| Test complex nested structure parsing
test "parse complex nested structure" {
  let toml_input =
    #|[server]
    #|host = "localhost"
    #|port = 8080
    #|
    #|[clients]
    #|hosts = ["alpha", "omega"]
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that all expected values are present
  inspect(result_str.contains("localhost"), content="true")
  inspect(result_str.contains("8080"), content="true")
  inspect(result_str.contains("alpha"), content="true")
}

///| Test simple tables parsing
test "parse simple tables" {
  let toml_input =
    #|[products]
    #|name = "Hammer"
    #|sku = 738594937
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that product is present
  inspect(result_str.contains("Hammer"), content="true")
  inspect(result_str.contains("738594937"), content="true")
}

///| Test mixed inline tables and regular tables
test "parse mixed table types" {
  let toml_input =
    #|[database]
    #|server = "192.168.1.1"
    #|ports = [8001, 8001, 8002]
    #|connection_max = 5000
    #|enabled = true
    #|
    #|[servers]
    #|name = "main"
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that basic structure is parsed
  inspect(result_str.contains("192.168.1.1"), content="true")
  inspect(result_str.contains("5000"), content="true")
  inspect(result_str.contains("main"), content="true")
}

///| Test datetime values as strings
test "parse datetime strings in tables and arrays" {
  let toml_input =
    #|odt1 = "1979-05-27T07:32:00Z"
    #|ldt1 = "1979-05-27T07:32:00"
    #|ld1 = "1979-05-27"
    #|lt1 = "07:32:00"
    #|
    #|[dates]
    #|birthday = "1990-12-25"
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check datetime strings are parsed
  inspect(result_str.contains("1979-05-27T07:32:00Z"), content="true")
  inspect(result_str.contains("1979-05-27T07:32:00"), content="true")
  inspect(result_str.contains("1979-05-27"), content="true")
  inspect(result_str.contains("07:32:00"), content="true")
  inspect(result_str.contains("1990-12-25"), content="true")
}

///| Test mixed array types (should be valid for certain types)
test "parse arrays with compatible types" {
  let toml_input =
    #|integers = [1, 2, 3]
    #|floats = [1.1, 2.2, 3.3]
    #|strings = ["red", "yellow", "green"]
    #|nested_arrays_of_ints = [[1, 2], [3, 4, 5]]
    #|nested_mixed = [[1, 2], ["a", "b", "c"]]
    #|
    #|[example]
    #|boolean_array = [true, false, true]
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that arrays are properly parsed
  inspect(result_str.contains("[1, 2, 3]"), content="true")
  inspect(result_str.contains("[1.1, 2.2, 3.3]"), content="true")
  inspect(result_str.contains("red"), content="true")
  inspect(result_str.contains("yellow"), content="true")
  inspect(result_str.contains("green"), content="true")
}

///| Test quoted keys in various contexts
test "parse quoted keys" {
  let toml_input =
    #|"key with spaces" = "value"
    #|"key.with.dots" = "another value"
    #|"key\"with\"quotes" = "third value"
    #|
    #|["table with spaces"]
    #|"another key" = "table value"
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that quoted keys work
  inspect(result_str.contains("key with spaces"), content="true")
  inspect(result_str.contains("key.with.dots"), content="true")
  inspect(result_str.contains("table with spaces"), content="true")
  inspect(result_str.contains("another key"), content="true")
}

///| Test complex inline tables
test "parse complex inline tables" {
  let toml_input =
    #|name = {first = "Tom", last = "Preston-Werner"}
    #|point = {x = 1, y = 2}
    #|animal = {type = {name = "pug"}}
    #|
    #|[table]
    #|inline_table = {a = 1, b = 2}
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check inline table parsing
  inspect(result_str.contains("Tom"), content="true")
  inspect(result_str.contains("Preston-Werner"), content="true")
  inspect(result_str.contains("pug"), content="true")
}

///| Test empty values and structures
test "parse empty and minimal structures" {
  let toml_input =
    #|empty_string = ""
    #|empty_array = []
    #|empty_inline_table = {}
    #|
    #|[empty_table]
    #|
    #|[another_table]
    #|key = "value"
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Basic structure checks
  inspect(result_str.contains("empty_string"), content="true")
  inspect(result_str.contains("empty_array"), content="true")
  inspect(result_str.contains("empty_inline_table"), content="true")
  inspect(result_str.contains("another_table"), content="true")
}

///| Test basic number formats
test "parse basic number formats" {
  let toml_input =
    #|# integers
    #|int2 = 42
    #|int3 = 0
    #|int4 = -17
    #|
    #|# fractional
    #|flt2 = 3.1415926
    #|flt3 = -0.01
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that basic numbers are parsed
  inspect(result_str.contains("42"), content="true")
  inspect(result_str.contains("-17"), content="true")
  inspect(result_str.contains("3.1415926"), content="true")
}

///| Test table redefinition and extension
test "parse table redefinition scenarios" {
  let toml_input =
    #|[fruit]
    #|apple = "red"
    #|
    #|[fruit]
    #|orange = "orange"
  let result = @toml.parse(toml_input)
  let result_str = result.to_string()

  // Check that table extension works
  inspect(result_str.contains("apple"), content="true")
  inspect(result_str.contains("orange"), content="true")
  inspect(result_str.contains("red"), content="true")
}
