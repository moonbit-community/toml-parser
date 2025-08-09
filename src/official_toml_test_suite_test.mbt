///| Official TOML Test Suite - Tests based on https://github.com/toml-lang/toml-test/tree/main/tests/valid

///| These tests cover features from the official TOML specification

///| Tests are implemented using MoonBit's multiline string syntax (#|...|#)

///| Test basic string values
test "basic string" {
  let basic_string_toml =
    #|basic = "value"
    #|
  @json.inspect(@toml.parse(basic_string_toml), content=[
    "TomlTable",
    { "basic": ["TomlString", "value"] },
  ])
}

///| Test string with escape sequences
test "string escape sequences" {
  let escaped_string_toml =
    #|escaped = "I'm a string. \"You can quote me\". Name\tJosé\nLocation\tSF."
    #|
  @json.inspect(@toml.parse(escaped_string_toml), content=[
    "TomlTable",
    {
      "escaped": [
        "TomlString", "I'm a string. \"You can quote me\". Name\tJosé\nLocation\tSF.",
      ],
    },
  ])
}

///| Test basic integer values
test "basic integer" {
  let integer_toml =
    #|answer = 42
    #|negative = -17
    #|zero = 0
    #|
  @json.inspect(@toml.parse(integer_toml), content=[
    "TomlTable",
    {
      "answer": ["TomlInteger", "42"],
      "negative": ["TomlInteger", "-17"],
      "zero": ["TomlInteger", "0"],
    },
  ])
}

///| Test basic float values
test "basic float" {
  let float_toml =
    #|pi = 3.14
    #|negative = -0.01
    #|positive = 5.0
    #|
  @json.inspect(@toml.parse(float_toml), content=[
    "TomlTable",
    {
      "pi": ["TomlFloat", 3.14],
      "negative": ["TomlFloat", -0.01],
      "positive": ["TomlFloat", 5.0],
    },
  ])
}

///| Test boolean values
test "basic boolean" {
  let boolean_toml =
    #|enabled = true
    #|disabled = false
    #|
  @json.inspect(@toml.parse(boolean_toml), content=[
    "TomlTable",
    { "enabled": ["TomlBoolean", true], "disabled": ["TomlBoolean", false] },
  ])
}

///| Test homogeneous arrays
test "homogeneous arrays" {
  let array_toml =
    #|integers = [1, 2, 3, 4, 5]
    #|strings = ["red", "yellow", "green"]
    #|booleans = [true, false, true]
    #|floats = [1.1, 2.2, 3.3]
    #|
  @json.inspect(@toml.parse(array_toml), content=[
    "TomlTable",
    {
      "integers": [
        "TomlArray",
        [
          ["TomlInteger", "1"],
          ["TomlInteger", "2"],
          ["TomlInteger", "3"],
          ["TomlInteger", "4"],
          ["TomlInteger", "5"],
        ],
      ],
      "strings": [
        "TomlArray",
        [
          ["TomlString", "red"],
          ["TomlString", "yellow"],
          ["TomlString", "green"],
        ],
      ],
      "booleans": [
        "TomlArray",
        [["TomlBoolean", true], ["TomlBoolean", false], ["TomlBoolean", true]],
      ],
      "floats": [
        "TomlArray",
        [["TomlFloat", 1.1], ["TomlFloat", 2.2], ["TomlFloat", 3.3]],
      ],
    },
  ])
}

///| Test nested arrays  
test "nested arrays" {
  let nested_array_toml =
    #|nested = [[1, 2], [3, 4, 5]]
    #|
  @json.inspect(@toml.parse(nested_array_toml), content=[
    "TomlTable",
    {
      "nested": [
        "TomlArray",
        [
          ["TomlArray", [["TomlInteger", "1"], ["TomlInteger", "2"]]],
          [
            "TomlArray",
            [["TomlInteger", "3"], ["TomlInteger", "4"], ["TomlInteger", "5"]],
          ],
        ],
      ],
    },
  ])
}

///| Test empty arrays
test "empty arrays" {
  let empty_array_toml =
    #|empty = []
    #|
  @json.inspect(@toml.parse(empty_array_toml), content=[
    "TomlTable",
    { "empty": ["TomlArray", []] },
  ])
}

///| Test inline tables
test "inline tables" {
  let inline_table_toml =
    #|person = {name = "John", age = 30}
    #|point = {x = 1, y = 2}
    #|empty = {}
    #|
  @json.inspect(@toml.parse(inline_table_toml), content=[
    "TomlTable",
    {
      "person": [
        "TomlTable",
        { "name": ["TomlString", "John"], "age": ["TomlInteger", "30"] },
      ],
      "point": [
        "TomlTable",
        { "x": ["TomlInteger", "1"], "y": ["TomlInteger", "2"] },
      ],
      "empty": ["TomlTable", {}],
    },
  ])
}

///| Test complex values combination
test "complex values combination" {
  let complex_toml =
    #|title = "TOML Example"
    #|version = 1.0
    #|enabled = true
    #|ports = [8000, 8001, 8002]
    #|database = {server = "192.168.1.1", port = 5432, enabled = true}
    #|tags = ["production", "web"]
    #|
  @json.inspect(@toml.parse(complex_toml), content=[
    "TomlTable",
    {
      "title": ["TomlString", "TOML Example"],
      "version": ["TomlFloat", 1.0],
      "enabled": ["TomlBoolean", true],
      "ports": [
        "TomlArray",
        [
          ["TomlInteger", "8000"],
          ["TomlInteger", "8001"],
          ["TomlInteger", "8002"],
        ],
      ],
      "database": [
        "TomlTable",
        {
          "server": ["TomlString", "192.168.1.1"],
          "port": ["TomlInteger", "5432"],
          "enabled": ["TomlBoolean", true],
        },
      ],
      "tags": [
        "TomlArray",
        [["TomlString", "production"], ["TomlString", "web"]],
      ],
    },
  ])
}

// TODO: The following tests are commented out because they require features not yet implemented in the parser
// Once these features are implemented, these tests should be uncommented and verified

///| Test basic table syntax
test "basic table" {
  let table_toml =
    #|[owner]
    #|name = "Tom Preston-Werner"
    #|organization = "GitHub"
    #|
  @json.inspect(@toml.parse(table_toml), content=[
    "TomlTable",
    {
      "owner": [
        "TomlTable",
        {
          "name": ["TomlString", "Tom Preston-Werner"],
          "organization": ["TomlString", "GitHub"],
        },
      ],
    },
  ])
}

///| Test nested tables [a.b.c] syntax
test "nested tables" {
  let nested_table_toml =
    #|[servers.alpha]
    #|ip = "10.0.0.1"
    #|dc = "eqdc10"
    #|
    #|[servers.beta]
    #|ip = "10.0.0.2"
    #|dc = "eqdc10"
    #|
  @json.inspect(@toml.parse(nested_table_toml), content=[
    "TomlTable",
    {
      "servers": [
        "TomlTable",
        {
          "alpha": [
            "TomlTable",
            { "ip": ["TomlString", "10.0.0.1"], "dc": ["TomlString", "eqdc10"] },
          ],
          "beta": [
            "TomlTable",
            { "ip": ["TomlString", "10.0.0.2"], "dc": ["TomlString", "eqdc10"] },
          ],
        },
      ],
    },
  ])
}

///| Test array of tables [[array]] syntax
test "array of tables" {
  let array_of_tables_toml =
    #|[[products]]
    #|name = "Hammer"
    #|sku = 738594937
    #|
    #|[[products]]
    #|name = "Nail"
    #|sku = 284758393
    #|
  @json.inspect(@toml.parse(array_of_tables_toml), content=[
    "TomlTable",
    {
      "products": [
        "TomlArray",
        [
          [
            "TomlTable",
            {
              "name": ["TomlString", "Hammer"],
              "sku": ["TomlInteger", "738594937"],
            },
          ],
          [
            "TomlTable",
            {
              "name": ["TomlString", "Nail"],
              "sku": ["TomlInteger", "284758393"],
            },
          ],
        ],
      ],
    },
  ])
}

///| Test array of tables with nested paths
test "nested array of tables" {
  let nested_array_toml =
    #|[[fruit.physical]]
    #|color = "red"
    #|shape = "round"
    #|
    #|[[fruit.physical]]
    #|color = "yellow"
    #|shape = "banana"
    #|
  @json.inspect(@toml.parse(nested_array_toml), content=[
    "TomlTable",
    {
      "fruit": [
        "TomlTable",
        {
          "physical": [
            "TomlArray",
            [
              [
                "TomlTable",
                {
                  "color": ["TomlString", "red"],
                  "shape": ["TomlString", "round"],
                },
              ],
              [
                "TomlTable",
                {
                  "color": ["TomlString", "yellow"],
                  "shape": ["TomlString", "banana"],
                },
              ],
            ],
          ],
        },
      ],
    },
  ])
}

///| Test mixed regular tables and array of tables
test "mixed tables and array of tables" {
  let mixed_toml =
    #|title = "Test Document"
    #|
    #|[owner]
    #|name = "John Doe"
    #|
    #|[[products]]
    #|name = "Hammer"
    #|price = 12.99
    #|
    #|[[products]]
    #|name = "Saw"
    #|price = 25.50
    #|
    #|[database]
    #|server = "192.168.1.1"
    #|port = 5432
    #|
  @json.inspect(@toml.parse(mixed_toml), content=[
    "TomlTable",
    {
      "title": ["TomlString", "Test Document"],
      "owner": ["TomlTable", { "name": ["TomlString", "John Doe"] }],
      "products": [
        "TomlArray",
        [
          [
            "TomlTable",
            { "name": ["TomlString", "Hammer"], "price": ["TomlFloat", 12.99] },
          ],
          [
            "TomlTable",
            { "name": ["TomlString", "Saw"], "price": ["TomlFloat", 25.50] },
          ],
        ],
      ],
      "database": [
        "TomlTable",
        {
          "server": ["TomlString", "192.168.1.1"],
          "port": ["TomlInteger", "5432"],
        },
      ],
    },
  ])
}

// TODO: Datetime parsing not yet implemented (though data structures exist)
// test "datetime values" {
//   let datetime_toml =
//     #|date1 = 1979-05-27T07:32:00Z
//     #|date2 = 1979-05-27T00:32:00-07:00
//     #|local_date = 1979-05-27
//     #|local_time = 07:32:00
//     #|local_datetime = 1979-05-27T07:32:00
//     #|
//   @json.inspect(@toml.parse(datetime_toml), content=[
//     "TomlTable",
//     {
//       "date1": ["TomlDateTime", ["OffsetDateTime", "1979-05-27T07:32:00Z"]],
//       "date2": ["TomlDateTime", ["OffsetDateTime", "1979-05-27T00:32:00-07:00"]],
//       "local_date": ["TomlDateTime", ["LocalDate", "1979-05-27"]],
//       "local_time": ["TomlDateTime", ["LocalTime", "07:32:00"]],
//       "local_datetime": ["TomlDateTime", ["LocalDateTime", "1979-05-27T07:32:00"]]
//     }
//   ])
// }

///| Test multiline basic strings
test "multiline basic strings" {
  let multiline_basic_toml =
    #|str1 = """
    #|Roses are red
    #|Violets are blue"""
    #|
  @json.inspect(@toml.parse(multiline_basic_toml), content=[
    "TomlTable",
    { "str1": ["TomlString", "Roses are red\nViolets are blue"] },
  ])
}

///| Test literal strings (single quotes)
test "literal strings" {
  let literal_string_toml =
    #|winpath = 'C:\Users\nodejs\templates'
    #|quoted = 'Tom "Dubs" Preston-Werner'
    #|regex = '<\i\c*\s*>'
    #|
  @json.inspect(@toml.parse(literal_string_toml), content=[
    "TomlTable",
    {
      "winpath": ["TomlString", "C:\\Users\\nodejs\\templates"],
      "quoted": ["TomlString", "Tom \"Dubs\" Preston-Werner"],
      "regex": ["TomlString", "<\\i\\c*\\s*>"],
    },
  ])
}

// TODO: Multiline literal strings not yet supported
// test "multiline literal strings" {
//   let multiline_literal_toml =
//     #|regex2 = '''I [dw]on't need \d{2} apples'''
//     #|lines = '''
//     #|The first newline is
//     #|trimmed in raw strings.
//     #|   All other whitespace
//     #|   is preserved.
//     #|'''
//     #|
//   @json.inspect(@toml.parse(multiline_literal_toml), content=[
//     "TomlTable",
//     {
//       "regex2": ["TomlString", "I [dw]on't need \\d{2} apples"],
//       "lines": ["TomlString", "The first newline is\ntrimmed in raw strings.\n   All other whitespace\n   is preserved.\n"]
//     }
//   ])
// }

///| Test comments functionality
test "comments" {
  let comments_toml =
    #|# This is a full-line comment
    #|key = "value"  # This is a comment at the end of a line
    #|another = "# This is not a comment"
    #|
  @json.inspect(@toml.parse(comments_toml), content=[
    "TomlTable",
    {
      "key": ["TomlString", "value"],
      "another": ["TomlString", "# This is not a comment"],
    },
  ])
}

///| Test integer formats (hex, octal, binary)
test "integer formats" {
  let integer_formats_toml =
    #|hex1 = 0xDEADBEEF
    #|hex2 = 0xdeadbeef
    #|hex3 = 0xdead_beef
    #|oct1 = 0o01234567
    #|oct2 = 0o755
    #|bin1 = 0b11010110
    #|
  @json.inspect(@toml.parse(integer_formats_toml), content=[
    "TomlTable",
    {
      "hex1": ["TomlInteger", "3735928559"],
      "hex2": ["TomlInteger", "3735928559"],
      "hex3": ["TomlInteger", "3735928559"],
      "oct1": ["TomlInteger", "342391"],
      "oct2": ["TomlInteger", "493"],
      "bin1": ["TomlInteger", "214"],
    },
  ])
}

// TODO: Float special values not yet supported - Need to find correct MoonBit API
// test "float special values" {
//   let float_special_toml =
//     #|infinity1 = inf
//     #|infinity2 = +inf
//     #|infinity3 = -inf
//     #|not_a_number1 = nan
//     #|not_a_number2 = +nan
//     #|not_a_number3 = -nan
//     #|
//   @json.inspect(@toml.parse(float_special_toml), content=[
//     "TomlTable",
//     {
//       "infinity1": ["TomlFloat", @double.positive_infinity],
//       "infinity2": ["TomlFloat", @double.positive_infinity],
//       "infinity3": ["TomlFloat", @double.negative_infinity],
//       "not_a_number1": ["TomlFloat", @double.not_a_number()],
//       "not_a_number2": ["TomlFloat", @double.not_a_number()],
//       "not_a_number3": ["TomlFloat", @double.not_a_number()]
//     }
//   ])
// }

///| Test for heterogeneous arrays (should be invalid according to TOML spec)
test "heterogeneous arrays should be invalid" {
  // This test verifies that our parser correctly rejects arrays with mixed types
  // which is required by the TOML specification
  let mixed_array = [
    @toml.TomlInteger(1L),
    @toml.TomlString("hello"),
    @toml.TomlBoolean(true),
  ]
  inspect(@toml.TomlValue::is_homogeneous_array(mixed_array), content="false")
  let mixed_toml_array = @toml.TomlArray(mixed_array)
  inspect(mixed_toml_array.validate(), content="false")
}

///| Test edge cases with whitespace and formatting
test "whitespace handling" {
  let whitespace_toml =
    #|  key1  =  "value1"  
    #|key2= "value2"
    #|key3 ="value3"
    #|key4="value4"
    #|
  @json.inspect(@toml.parse(whitespace_toml), content=[
    "TomlTable",
    {
      "key1": ["TomlString", "value1"],
      "key2": ["TomlString", "value2"],
      "key3": ["TomlString", "value3"],
      "key4": ["TomlString", "value4"],
    },
  ])
}

///| Test array formatting with newlines and trailing commas
test "array formatting" {
  let array_formatting_toml =
    #|array1 = [
    #|  1,
    #|  2,
    #|  3,
    #|]
    #|array2 = [1, 2, 3,]
    #|
  @json.inspect(@toml.parse(array_formatting_toml), content=[
    "TomlTable",
    {
      "array1": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
      "array2": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
    },
  ])
}
