///| Additional TOML Test Cases - More comprehensive tests based on official examples

///| These provide additional coverage of edge cases and complex scenarios

///|
/// Test key names with various characters
test "key name variations" {
  let key_variations_toml =
    #|bare_key = "value"
    #|bare-key = "value"
    #|bare_key2 = "value"
    #|"127.0.0.1" = "value"
    #|"character encoding" = "value"
    #|"ʎǝʞ" = "value"
    #|
  @json.inspect(@toml.parse(key_variations_toml), content=[
    "TomlTable",
    {
      "bare_key": ["TomlString", "value"],
      "bare-key": ["TomlString", "value"],
      "bare_key2": ["TomlString", "value"],
      "127.0.0.1": ["TomlString", "value"],
      "character encoding": ["TomlString", "value"],
      "ʎǝʞ": ["TomlString", "value"],
    },
  ])
}

///|
test "numeric keys" {
  let numeric_keys_toml =
    #|1234 = "value"
    #|0 = "zero"
    #|
  @json.inspect(@toml.parse(numeric_keys_toml), content=[
    "TomlTable",
    { "1234": ["TomlString", "value"], "0": ["TomlString", "zero"] },
  ])
  // according to the spec, bare keys may only contain ASCII letters, ASCII digits, underscores, 
  // and dashes (A-Za-z0-9_-).
  // Note that bare keys are allowed to be composed of only ASCII digits, e.g. 1234, but are
  // always interpreted as strings.
}

///|
/// Test complex escape sequences  
test "complex escape sequences" {
  let escape_sequences_toml =
    #|basic = "I'm a string. \"You can quote me\". Name\tJosé\nLocation\tSF."
    #|newline = "First line\nSecond line"
    #|tab = "Column1\tColumn2"
    #|carriage_return = "Line1\rLine2"
    #|backslash = "This is a backslash: \\"
    #|quote = "This has a quote: \""
    #|
  @json.inspect(@toml.parse(escape_sequences_toml), content=[
    "TomlTable",
    {
      "basic": [
        "TomlString", "I'm a string. \"You can quote me\". Name\tJosé\nLocation\tSF.",
      ],
      "newline": ["TomlString", "First line\nSecond line"],
      "tab": ["TomlString", "Column1\tColumn2"],
      "carriage_return": ["TomlString", "Line1\rLine2"],
      "backslash": ["TomlString", "This is a backslash: \\"],
      "quote": ["TomlString", "This has a quote: \""],
    },
  ])
}

///|
/// Test various number formats
test "number formats" {
  let numbers_toml =
    #|positive_int = 42
    #|negative_int = -17
    #|zero = 0
    #|positive_float = 1.0
    #|negative_float = -2.5
    #|pi = 3.14159
    #|large_float = 50000000000000000000000.0
    #|small_float = 0.00001
    #|large_number = 9223372036854775807
    #|
  @json.inspect(@toml.parse(numbers_toml), content=[
    "TomlTable",
    {
      "positive_int": ["TomlInteger", "42"],
      "negative_int": ["TomlInteger", "-17"],
      "zero": ["TomlInteger", "0"],
      "positive_float": ["TomlFloat", 1.0],
      "negative_float": ["TomlFloat", -2.5],
      "pi": ["TomlFloat", 3.14159],
      "large_float": ["TomlFloat", 50000000000000000000000.0],
      "small_float": ["TomlFloat", 0.00001],
      "large_number": ["TomlInteger", "9223372036854775807"],
    },
  ])
}

///|
/// Test complex nested array structures
test "complex nested arrays" {
  let nested_arrays_toml =
    #|nested_arrays_of_ints = [[1, 2], [3, 4, 5]]
    #|nested_mixed_array = [["str1", "str2"], ["str3", "str4"]]
    #|deep_nested = [[[1, 2]], [[3, 4], [5, 6]]]
    #|array_with_spaces = [ [ 1 , 2 ] , [ 3 , 4 ] ]
    #|
  @json.inspect(@toml.parse(nested_arrays_toml), content=[
    "TomlTable",
    {
      "nested_arrays_of_ints": [
        "TomlArray",
        [
          ["TomlArray", [["TomlInteger", "1"], ["TomlInteger", "2"]]],
          [
            "TomlArray",
            [["TomlInteger", "3"], ["TomlInteger", "4"], ["TomlInteger", "5"]],
          ],
        ],
      ],
      "nested_mixed_array": [
        "TomlArray",
        [
          ["TomlArray", [["TomlString", "str1"], ["TomlString", "str2"]]],
          ["TomlArray", [["TomlString", "str3"], ["TomlString", "str4"]]],
        ],
      ],
      "deep_nested": [
        "TomlArray",
        [
          [
            "TomlArray",
            [["TomlArray", [["TomlInteger", "1"], ["TomlInteger", "2"]]]],
          ],
          [
            "TomlArray",
            [
              ["TomlArray", [["TomlInteger", "3"], ["TomlInteger", "4"]]],
              ["TomlArray", [["TomlInteger", "5"], ["TomlInteger", "6"]]],
            ],
          ],
        ],
      ],
      "array_with_spaces": [
        "TomlArray",
        [
          ["TomlArray", [["TomlInteger", "1"], ["TomlInteger", "2"]]],
          ["TomlArray", [["TomlInteger", "3"], ["TomlInteger", "4"]]],
        ],
      ],
    },
  ])
}

///|
/// Test various inline table formats
test "inline table variations" {
  let inline_tables_toml =
    #|simple = {name = "value"}
    #|empty_table = {}
    #|nested_inline = {a = {b = "c"}}
    #|mixed_types = {string = "value", integer = 42, boolean = true, float = 3.14}
    #|with_arrays = {numbers = [1, 2, 3], strings = ["a", "b"]}
    #|spaces = { key1 = "value1" , key2 = "value2" }
    #|
  @json.inspect(@toml.parse(inline_tables_toml), content=[
    "TomlTable",
    {
      "simple": ["TomlTable", { "name": ["TomlString", "value"] }],
      "empty_table": ["TomlTable", {}],
      "nested_inline": [
        "TomlTable",
        { "a": ["TomlTable", { "b": ["TomlString", "c"] }] },
      ],
      "mixed_types": [
        "TomlTable",
        {
          "string": ["TomlString", "value"],
          "integer": ["TomlInteger", "42"],
          "boolean": ["TomlBoolean", true],
          "float": ["TomlFloat", 3.14],
        },
      ],
      "with_arrays": [
        "TomlTable",
        {
          "numbers": [
            "TomlArray",
            [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
          ],
          "strings": ["TomlArray", [["TomlString", "a"], ["TomlString", "b"]]],
        },
      ],
      "spaces": [
        "TomlTable",
        { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
      ],
    },
  ])
}

///|
/// Test real-world configuration example
test "config file example" {
  let config_toml =
    #|title = "TOML Example Configuration"
    #|
    #|# Database connection
    #|host = "localhost"
    #|port = 5432
    #|username = "admin"
    #|password = "secret123"
    #|ssl_enabled = true
    #|timeout = 30.5
    #|
    #|# Application settings
    #|debug = false
    #|log_level = "info"
    #|max_connections = 100
    #|allowed_origins = ["https://example.com", "https://api.example.com"]
    #|
    #|# Cache configuration
    #|cache = {enabled = true, ttl = 3600, max_size = 1000}
    #|
    #|# Feature flags
    #|features = {new_ui = true, beta_api = false, experimental = true}
    #|
  @json.inspect(@toml.parse(config_toml), content=[
    "TomlTable",
    {
      "title": ["TomlString", "TOML Example Configuration"],
      "host": ["TomlString", "localhost"],
      "port": ["TomlInteger", "5432"],
      "username": ["TomlString", "admin"],
      "password": ["TomlString", "secret123"],
      "ssl_enabled": ["TomlBoolean", true],
      "timeout": ["TomlFloat", 30.5],
      "debug": ["TomlBoolean", false],
      "log_level": ["TomlString", "info"],
      "max_connections": ["TomlInteger", "100"],
      "allowed_origins": [
        "TomlArray",
        [
          ["TomlString", "https://example.com"],
          ["TomlString", "https://api.example.com"],
        ],
      ],
      "cache": [
        "TomlTable",
        {
          "enabled": ["TomlBoolean", true],
          "ttl": ["TomlInteger", "3600"],
          "max_size": ["TomlInteger", "1000"],
        },
      ],
      "features": [
        "TomlTable",
        {
          "new_ui": ["TomlBoolean", true],
          "beta_api": ["TomlBoolean", false],
          "experimental": ["TomlBoolean", true],
        },
      ],
    },
  ])
}

///|
/// Test edge cases with whitespace
test "whitespace edge cases" {
  let whitespace_edge_toml =
    #|   # Comment with leading spaces
    #|key1=42
    #|key2 =43
    #|key3= 44
    #|key4 = 45
    #|
    #|# Arrays with various whitespace
    #|array1=[1,2,3]
    #|array2 = [1, 2, 3]
    #|array3= [ 1 , 2 , 3 ]
    #|array4 =[ 1,2,3 ]
    #|
    #|# Inline tables with whitespace
    #|table1={a=1,b=2}
    #|table2 = {a = 1, b = 2}
    #|table3= { a=1 , b=2 }
    #|
  @json.inspect(@toml.parse(whitespace_edge_toml), content=[
    "TomlTable",
    {
      "key1": ["TomlInteger", "42"],
      "key2": ["TomlInteger", "43"],
      "key3": ["TomlInteger", "44"],
      "key4": ["TomlInteger", "45"],
      "array1": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
      "array2": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
      "array3": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
      "array4": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
      "table1": [
        "TomlTable",
        { "a": ["TomlInteger", "1"], "b": ["TomlInteger", "2"] },
      ],
      "table2": [
        "TomlTable",
        { "a": ["TomlInteger", "1"], "b": ["TomlInteger", "2"] },
      ],
      "table3": [
        "TomlTable",
        { "a": ["TomlInteger", "1"], "b": ["TomlInteger", "2"] },
      ],
    },
  ])
}

///|
/// Test boundary values
test "boundary values" {
  let boundary_toml =
    #|empty_string = ""
    #|single_char = "a"
    #|zero_int = 0
    #|one_int = 1
    #|minus_one = -1
    #|zero_float = 0.0
    #|tiny_float = 0.000001
    #|empty_array = []
    #|single_element_array = [42]
    #|empty_table = {}
    #|single_key_table = {key = "value"}
    #|
  @json.inspect(@toml.parse(boundary_toml), content=[
    "TomlTable",
    {
      "empty_string": ["TomlString", ""],
      "single_char": ["TomlString", "a"],
      "zero_int": ["TomlInteger", "0"],
      "one_int": ["TomlInteger", "1"],
      "minus_one": ["TomlInteger", "-1"],
      "zero_float": ["TomlFloat", 0.0],
      "tiny_float": ["TomlFloat", 0.000001],
      "empty_array": ["TomlArray", []],
      "single_element_array": ["TomlArray", [["TomlInteger", "42"]]],
      "empty_table": ["TomlTable", {}],
      "single_key_table": ["TomlTable", { "key": ["TomlString", "value"] }],
    },
  ])
}

///|
/// Test validation that heterogeneous arrays are properly detected
test "validation comprehensive" {
  // Test that our validation correctly identifies invalid structures

  // Valid nested structure
  let valid_nested_array = [
    @toml.TomlArray([@toml.TomlInteger(1L), @toml.TomlInteger(2L)]),
    @toml.TomlArray([@toml.TomlInteger(3L), @toml.TomlInteger(4L)]),
  ]
  inspect(
    @toml.TomlValue::is_homogeneous_array(valid_nested_array),
    content="true",
  )

  // Invalid nested structure - outer array contains arrays but inner arrays have different types
  let invalid_nested_array = [
    @toml.TomlArray([@toml.TomlInteger(1L), @toml.TomlInteger(2L)]),
    @toml.TomlArray([@toml.TomlString("hello"), @toml.TomlString("world")]),
  ]
  inspect(
    @toml.TomlValue::is_homogeneous_array(invalid_nested_array),
    content="true",
  ) // Outer level is homogeneous (all arrays)

  // But the validation should still pass since each inner array is homogeneous
  let valid_mixed_nested = @toml.TomlArray(invalid_nested_array)
  inspect(valid_mixed_nested.validate(), content="true")
}
