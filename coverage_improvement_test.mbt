///|
/// Tests specifically designed to improve coverage of uncovered lines
test "test complex TOML with all token types" {
  let complex_toml =
    #|string_key = "value with \"quotes\""
    #|integer_key = 42
    #|float_key = 3.14159
    #|bool_key = true
    #|int_array = [1, 2, 3, 4, 5]
    #|inline_table = { name = "John", age = 30 }
    #|[database]
    #|server = "192.168.1.1"
    #|ports = [ 8001, 8001, 8002 ]
    #|connection_max = 5000
    #|enabled = true
    #|[servers.alpha]
    #|ip = "10.0.0.1"
    #|dc = "eqdc10"
    #|[servers.beta]
    #|ip = "10.0.0.2"
    #|dc = "eqdc10"
    #|
  // This now successfully parses with nested tables support
  json_inspect(try? @toml.parse(complex_toml), content={
    "Ok": [
      "TomlTable",
      {
        "string_key": ["TomlString", "value with \"quotes\""],
        "integer_key": ["TomlInteger", "42"],
        "float_key": ["TomlFloat", 3.14159],
        "bool_key": ["TomlBoolean", true],
        "int_array": [
          "TomlArray",
          [
            ["TomlInteger", "1"],
            ["TomlInteger", "2"],
            ["TomlInteger", "3"],
            ["TomlInteger", "4"],
            ["TomlInteger", "5"],
          ],
        ],
        "inline_table": [
          "TomlTable",
          { "name": ["TomlString", "John"], "age": ["TomlInteger", "30"] },
        ],
        "database": [
          "TomlTable",
          {
            "server": ["TomlString", "192.168.1.1"],
            "ports": [
              "TomlArray",
              [
                ["TomlInteger", "8001"],
                ["TomlInteger", "8001"],
                ["TomlInteger", "8002"],
              ],
            ],
            "connection_max": ["TomlInteger", "5000"],
            "enabled": ["TomlBoolean", true],
          },
        ],
        "servers": [
          "TomlTable",
          {
            "alpha": [
              "TomlTable",
              {
                "ip": ["TomlString", "10.0.0.1"],
                "dc": ["TomlString", "eqdc10"],
              },
            ],
            "beta": [
              "TomlTable",
              {
                "ip": ["TomlString", "10.0.0.2"],
                "dc": ["TomlString", "eqdc10"],
              },
            ],
          },
        ],
      },
    ],
  })
}

///|
test "test tokenizer unreachable path coverage" {
  // This is trying to hit the unreachable else branch in tokenize function
  let tokens = @tokenize.tokenize(
    (
      #|simple = true
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "simple", { "loc": "1:1-1:7" }],
    ["Equals", { "loc": "1:8-1:9" }],
    ["BooleanToken", true, { "loc": "1:10-1:14" }],
    ["EOF", { "loc": "1:14-1:14" }],
  ])
}

///|
test "test edge case number formats for error paths" {
  // Try to trigger integer parsing errors

  let tokens = try? @tokenize.tokenize(
    "huge = 999999999999999999999999999999999999999",
  )
  json_inspect(tokens, content={
    "Err": [
      "Failure", "internal/tokenize/tokenize.mbt:656:12-656:41@bobzhang/toml FAILED: Invalid integer: 999999999999999999999999999999999999999",
    ],
  })
}

///|
test "test literal string handling" {
  let tokens = @tokenize.tokenize(
    (
      #|literal = 'this is a literal string'
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "literal", { "loc": "1:1-1:8" }],
    ["Equals", { "loc": "1:9-1:10" }],
    ["StringToken", "this is a literal string", { "loc": "1:11-1:37" }],
    ["EOF", { "loc": "1:37-1:37" }],
  ])
}

///|
test "test various escape sequences coverage" {
  let toml_with_escapes =
    #|newline = "line1\nline2"
    #|tab = "col1\tcol2"
    #|carriage = "line1\rline2"
    #|backslash = "path\\to\\file"
    #|quote = "say \"hello\""
    #|
  json_inspect(try? @toml.parse(toml_with_escapes), content={
    "Ok": [
      "TomlTable",
      {
        "newline": ["TomlString", "line1\nline2"],
        "tab": ["TomlString", "col1\tcol2"],
        "carriage": ["TomlString", "line1\rline2"],
        "backslash": ["TomlString", "path\\to\\file"],
        "quote": ["TomlString", "say \"hello\""],
      },
    ],
  })
}

///|
test "test whitespace and comment skipping" {
  let toml_with_whitespace =
    #|key1 = "value1"
    #|
    #|
    #|key2 = "value2"
    #|
  json_inspect(try? @toml.parse(toml_with_whitespace), content={
    "Ok": [
      "TomlTable",
      { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
    ],
  })
}

///|
test "test mixed case hex digits" {
  let tokens = @tokenize.tokenize(
    (
      #|mixed_hex = 0xaBcDeF
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "mixed_hex", { "loc": "1:1-1:10" }],
    ["Equals", { "loc": "1:11-1:12" }],
    ["IntegerToken", "11259375", { "loc": "1:13-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
  ])
}
