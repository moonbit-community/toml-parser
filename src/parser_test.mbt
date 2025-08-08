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

///| Tests for uncovered parser error conditions
test "test parser expect method failure" {
  @json.inspect(try? parse_no_loc("key = [missing_bracket"), content={
    "Err": { "$tag": "Failure", "0": "Expected value" },
  })
}

///|
test "test parser EOF handling in peek" {
  @json.inspect(try? parse_no_loc(""), content={ "Ok": ["TomlTable", {}] })
}

///|
test "test parser EOF handling in advance" {
  @json.inspect(try? parse_no_loc("key ="), content={
    "Err": { "$tag": "Failure", "0": "Expected value" },
  })
}

///|
test "test inline table with string keys" {
  @json.inspect(try? parse_no_loc("table = {\"string key\" = \"value\"}"), content={
    "Ok": [
      "TomlTable",
      { "table": ["TomlTable", { "string key": ["TomlString", "value"] }] },
    ],
  })
}

///|
test "test inline table invalid syntax" {
  @json.inspect(try? parse_no_loc("table = {key value}"), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected Equals, but found Identifier(\"value\")",
    },
  })
}

///|
test "test inline table missing comma or closing brace" {
  @json.inspect(try? parse_no_loc("table = {key = \"value\" invalid}"), content={
    "Err": { "$tag": "Failure", "0": "Expected ',' or '}' in inline table" },
  })
}

///|
test "test table header with string name" {
  @json.inspect(try? parse_no_loc("[\"table name\"]\nkey = \"value\""), content={
    "Ok": [
      "TomlTable",
      { "table name": ["TomlTable", { "key": ["TomlString", "value"] }] },
    ],
  })
}

///|
test "test table header invalid name" {
  @json.inspect(try? parse_no_loc("[123]\nkey = \"value\""), content={
    "Err": { "$tag": "Failure", "0": "Expected table name" },
  })
}

///|
test "test duplicate table redefinition" {
  @json.inspect(
    try? parse_no_loc("[table]\nkey1 = \"value1\"\n[table]\nkey2 = \"value2\""),
    content={
      "Ok": [
        "TomlTable",
        {
          "table": [
            "TomlTable",
            {
              "key1": ["TomlString", "value1"],
              "key2": ["TomlString", "value2"],
            },
          ],
        },
      ],
    },
  )
}

///|
test "test table name conflicts with existing value" {
  @json.inspect(
    try? parse_no_loc("table = \"string\"\n[table]\nkey = \"value\""),
    content={
      "Err": {
        "$tag": "Failure",
        "0": "Table name conflicts with existing value",
      },
    },
  )
}

///| Tests for inline table edge cases  
test "test empty inline table" {
  @json.inspect(try? parse_no_loc("empty = {}"), content={
    "Ok": ["TomlTable", { "empty": ["TomlTable", {}] }],
  })
}

///|
test "test nested inline tables" {
  @json.inspect(try? parse_no_loc("table = {inner = {key = \"value\"}}"), content={
    "Ok": [
      "TomlTable",
      {
        "table": [
          "TomlTable",
          { "inner": ["TomlTable", { "key": ["TomlString", "value"] }] },
        ],
      },
    ],
  })
}

///|
test "test inline table with multiple key types" {
  @json.inspect(try? parse_no_loc("mixed = {\"quoted\" = 1, unquoted = 2}"), content={
    "Ok": [
      "TomlTable",
      {
        "mixed": [
          "TomlTable",
          { "quoted": ["TomlInteger", "1"], "unquoted": ["TomlInteger", "2"] },
        ],
      },
    ],
  })
}

///|
test "test inline table with array values" {
  @json.inspect(
    try? parse_no_loc("table = {arr = [1, 2, 3], str = \"test\"}"),
    content={
      "Ok": [
        "TomlTable",
        {
          "table": [
            "TomlTable",
            {
              "arr": [
                "TomlArray",
                [
                  ["TomlInteger", "1"],
                  ["TomlInteger", "2"],
                  ["TomlInteger", "3"],
                ],
              ],
              "str": ["TomlString", "test"],
            },
          ],
        },
      ],
    },
  )
}
