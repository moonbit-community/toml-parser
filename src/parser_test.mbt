///| Tests for the TOML parser
test "parse simple key-value string" {
  let result = @toml.parse(
    (
      #|name = "John"
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    { "name": ["TomlString", "John"] },
  ])
}

///|
test "parse simple key-value integer" {
  let result = @toml.parse(
    (
      #|age = 25
    ),
  )
  @json.inspect(result, content=["TomlTable", { "age": ["TomlInteger", "25"] }])
}

///|
test "parse simple key-value boolean" {
  let result = @toml.parse(
    (
      #|enabled = true
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    { "enabled": ["TomlBoolean", true] },
  ])
}

///|
test "parse simple key-value float" {
  let result = @toml.parse(
    (
      #|pi = 3.14
    ),
  )
  @json.inspect(result, content=["TomlTable", { "pi": ["TomlFloat", 3.14] }])
}

///|
test "parse multiple key-value pairs" {
  let multiple_kvp_toml =
    #|name = "Alice"
    #|age = 30
    #|enabled = false
    #|
  let result = @toml.parse(multiple_kvp_toml)
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
  let result = @toml.parse(
    (
      #|numbers = [1, 2, 3]
    ),
  )
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
  let inline_table_toml =
    #|person = {name = "Bob", age = 25}
    #|
  let result = @toml.parse(inline_table_toml)
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
    "Err": {
      "$tag": "Failure",
      "0": "Expected value at {start: {line: 1, column: 8}, end: {line: 1, column: 23}}",
    },
  })
}

///|
test "test parser EOF handling in peek" {
  @json.inspect(try? parse_no_loc(""), content={ "Ok": ["TomlTable", {}] })
}

///|
test "test parser EOF handling in advance" {
  @json.inspect(try? parse_no_loc("key ="), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected value at {start: {line: 1, column: 6}, end: {line: 1, column: 6}}",
    },
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
      "0": "Expected '=' at {start: {line: 1, column: 14}, end: {line: 1, column: 19}}",
    },
  })
}

///|
test "test inline table missing comma or closing brace" {
  @json.inspect(try? parse_no_loc("table = {key = \"value\" invalid}"), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected ',' or '}' in inline table at {start: {line: 1, column: 24}, end: {line: 1, column: 31}}",
    },
  })
}

///|
test "test table header with string name" {
  let string_table_name_toml =
    #|["table name"]
    #|key = "value"
    #|
  @json.inspect(try? parse_no_loc(string_table_name_toml), content={
    "Ok": [
      "TomlTable",
      { "table name": ["TomlTable", { "key": ["TomlString", "value"] }] },
    ],
  })
}

///|
test "test table header numeric name" {
  let numeric_table_name_toml =
    #|[123]
    #|key = "value"
    #|
  @json.inspect(try? parse_no_loc(numeric_table_name_toml), content={
    "Ok": [
      "TomlTable",
      { "123": ["TomlTable", { "key": ["TomlString", "value"] }] },
    ],
  })
}

///|
test "test duplicate table redefinition" {
  let duplicate_table_toml =
    #|[table]
    #|key1 = "value1"
    #|[table]
    #|key2 = "value2"
    #|
  @json.inspect(try? parse_no_loc(duplicate_table_toml), content={
    "Ok": [
      "TomlTable",
      {
        "table": [
          "TomlTable",
          { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
        ],
      },
    ],
  })
}

///|
test "test table name conflicts with existing value" {
  let conflicting_table_toml =
    #|table = "string"
    #|[table]
    #|key = "value"
    #|
  @json.inspect(try? parse_no_loc(conflicting_table_toml), content={
    "Err": {
      "$tag": "Failure",
      "0": "Table path conflicts with existing value: table at {start: {line: 2, column: 8}, end: {line: 3, column: 1}}",
    },
  })
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

///| Test dotted key notation - simple case
test "dotted key notation simple" {
  let result = @toml.parse(
    (
      #|a.b.c = "value"
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    {
      "a": [
        "TomlTable",
        { "b": ["TomlTable", { "c": ["TomlString", "value"] }] },
      ],
    },
  ])
}

///| Test dotted key notation - multiple values
test "dotted key notation multiple" {
  let dotted_multiple_toml =
    #|a.b.c = "value1"
    #|a.b.d = "value2"
    #|a.e = "value3"
    #|f = "value4"
    #|
  @json.inspect(@toml.parse(dotted_multiple_toml), content=[
    "TomlTable",
    {
      "a": [
        "TomlTable",
        {
          "b": [
            "TomlTable",
            { "c": ["TomlString", "value1"], "d": ["TomlString", "value2"] },
          ],
          "e": ["TomlString", "value3"],
        },
      ],
      "f": ["TomlString", "value4"],
    },
  ])
}

///| Test dotted key notation - different data types
test "dotted key notation data types" {
  let dotted_types_toml =
    #|server.host = "localhost"
    #|server.port = 8080
    #|server.enabled = true
    #|server.timeout = 30.5
    #|server.tags = ["web", "api"]
    #|
  @json.inspect(@toml.parse(dotted_types_toml), content=[
    "TomlTable",
    {
      "server": [
        "TomlTable",
        {
          "host": ["TomlString", "localhost"],
          "port": ["TomlInteger", "8080"],
          "enabled": ["TomlBoolean", true],
          "timeout": ["TomlFloat", 30.5],
          "tags": ["TomlArray", [["TomlString", "web"], ["TomlString", "api"]]],
        },
      ],
    },
  ])
}

///| Test dotted key notation - quoted keys
test "dotted key notation quoted keys" {
  let result = @toml.parse(
    (
      #|"first.part"."second.part" = "value"
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    { "first.part": ["TomlTable", { "second.part": ["TomlString", "value"] }] },
  ])
}

///| Test dotted key notation - integer keys
test "dotted key notation integer keys" {
  let result = @toml.parse(
    (
      #|1.2.3 = "numeric path"
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    {
      "1": [
        "TomlTable",
        { "2": ["TomlTable", { "3": ["TomlString", "numeric path"] }] },
      ],
    },
  ])
}

///| Test dotted key notation - conflict with table headers
test "dotted key notation table conflict" {
  let conflict_toml =
    #|a.b = "dotted"
    #|[a]
    #|c = "table"
    #|
  @json.inspect(@toml.parse(conflict_toml), content=[
    "TomlTable",
    {
      "a": [
        "TomlTable",
        { "b": ["TomlString", "dotted"], "c": ["TomlString", "table"] },
      ],
    },
  ])
}

///| Test dotted key notation - deep nesting
test "dotted key notation deep nesting" {
  let result = @toml.parse(
    (
      #|a.b.c.d.e.f = "deep"
    ),
  )
  @json.inspect(result, content=[
    "TomlTable",
    {
      "a": [
        "TomlTable",
        {
          "b": [
            "TomlTable",
            {
              "c": [
                "TomlTable",
                {
                  "d": [
                    "TomlTable",
                    { "e": ["TomlTable", { "f": ["TomlString", "deep"] }] },
                  ],
                },
              ],
            },
          ],
        },
      ],
    },
  ])
}
