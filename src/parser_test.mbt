///| Tests for the TOML parser
test "parse simple key-value string" {
  let result = @toml.parse("name = \"John\"").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    { "name": ["TomlString", "John"] }
  ])
}

///|
test "parse simple key-value integer" {
  let result = @toml.parse("age = 25").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    { "age": ["TomlInteger", "25"] }
  ])
}

///|
test "parse simple key-value boolean" {
  let result = @toml.parse("enabled = true").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    { "enabled": ["TomlBoolean", true] }
  ])
}

///|
test "parse simple key-value float" {
  let result = @toml.parse("pi = 3.14").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    { "pi": ["TomlFloat", 3.14] }
  ])
}

///|
test "parse multiple key-value pairs" {
  let result = @toml.parse("name = \"Alice\"\nage = 30\nenabled = false").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    {
      "name": ["TomlString", "Alice"],
      "age": ["TomlInteger", "30"],
      "enabled": ["TomlBoolean", false]
    }
  ])
}

///|
test "parse array" {
  let result = @toml.parse("numbers = [1, 2, 3]").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [
          ["TomlInteger", "1"],
          ["TomlInteger", "2"],
          ["TomlInteger", "3"]
        ]
      ]
    }
  ])
}

///|
test "parse inline table" {
  let result = @toml.parse("person = {name = \"Bob\", age = 25}").unwrap()
  @json.inspect(result, content=[
    "TomlTable",
    {
      "person": [
        "TomlTable",
        {
          "name": ["TomlString", "Bob"],
          "age": ["TomlInteger", "25"]
        }
      ]
    }
  ])
}
