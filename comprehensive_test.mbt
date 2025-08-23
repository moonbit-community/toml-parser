///|
/// Comprehensive test demonstrating the TOML parser capabilities
test "complex TOML document" {
  // For now, let's test a simpler version since we haven't implemented [section] syntax yet
  // let simple_toml = "title = \"TOML Example\"\nversion = 1.0\nenabled = true\nports = [8000, 8001, 8002]"
  let simple_toml =
    #|title = "TOML Example"
    #|version = 1.0
    #|enabled = true
    #|ports = [8000, 8001, 8002]
    #|
  @json.inspect(@toml.parse(simple_toml), content=[
    "TomlTable",
    {
      "title": ["TomlString", "TOML Example"],
      "version": ["TomlFloat", 1],
      "enabled": ["TomlBoolean", true],
      "ports": [
        "TomlArray",
        [
          ["TomlInteger", "8000"],
          ["TomlInteger", "8001"],
          ["TomlInteger", "8002"],
        ],
      ],
    },
  ])
}

///|
/// Test nested arrays and mixed data types
test "nested arrays and mixed types" {
  let complex_toml =
    #|mixed_array = [1, "hello", true, 3.14]
    #|nested_array = [[1, 2], ["a", "b"], [true, false]]
    #|numbers = [1, 2, 3, 4, 5]
    #|strings = ["red", "yellow", "green"]
    #|booleans = [true, false, true]
    #|floats = [1.1, 2.2, 3.3]
    #|
  @json.inspect(@toml.parse(complex_toml), content=[
    "TomlTable",
    {
      "mixed_array": [
        "TomlArray",
        [
          ["TomlInteger", "1"],
          ["TomlString", "hello"],
          ["TomlBoolean", true],
          ["TomlFloat", 3.14],
        ],
      ],
      "nested_array": [
        "TomlArray",
        [
          ["TomlArray", [["TomlInteger", "1"], ["TomlInteger", "2"]]],
          ["TomlArray", [["TomlString", "a"], ["TomlString", "b"]]],
          ["TomlArray", [["TomlBoolean", true], ["TomlBoolean", false]]],
        ],
      ],
      "numbers": [
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

///|
/// Test inline tables and nesting
test "inline tables and nesting" {
  let inline_toml =
    #|server = {host = "localhost", port = 8080, enabled = true}
    #|database = {name = "mydb", user = "admin", settings = {timeout = 30, pool_size = 10}}
    #|endpoints = ["/api/v1", "/api/v2", "/health"]
    #|
  @json.inspect(@toml.parse(inline_toml), content=[
    "TomlTable",
    {
      "server": [
        "TomlTable",
        {
          "host": ["TomlString", "localhost"],
          "port": ["TomlInteger", "8080"],
          "enabled": ["TomlBoolean", true],
        },
      ],
      "database": [
        "TomlTable",
        {
          "name": ["TomlString", "mydb"],
          "user": ["TomlString", "admin"],
          "settings": [
            "TomlTable",
            {
              "timeout": ["TomlInteger", "30"],
              "pool_size": ["TomlInteger", "10"],
            },
          ],
        },
      ],
      "endpoints": [
        "TomlArray",
        [
          ["TomlString", "/api/v1"],
          ["TomlString", "/api/v2"],
          ["TomlString", "/health"],
        ],
      ],
    },
  ])
}

///|
/// Test realistic application configuration
test "application configuration" {
  let app_config =
    #|app_name = "WebServer"
    #|version = "1.2.3"
    #|debug = false
    #|max_connections = 1000
    #|timeout = 30.5
    #|allowed_hosts = ["127.0.0.1", "localhost", "example.com"]
    #|features = {logging = true, metrics = false, caching = {enabled = true, ttl = 300}}
    #|
  @json.inspect(@toml.parse(app_config), content=[
    "TomlTable",
    {
      "app_name": ["TomlString", "WebServer"],
      "version": ["TomlString", "1.2.3"],
      "debug": ["TomlBoolean", false],
      "max_connections": ["TomlInteger", "1000"],
      "timeout": ["TomlFloat", 30.5],
      "allowed_hosts": [
        "TomlArray",
        [
          ["TomlString", "127.0.0.1"],
          ["TomlString", "localhost"],
          ["TomlString", "example.com"],
        ],
      ],
      "features": [
        "TomlTable",
        {
          "logging": ["TomlBoolean", true],
          "metrics": ["TomlBoolean", false],
          "caching": [
            "TomlTable",
            { "enabled": ["TomlBoolean", true], "ttl": ["TomlInteger", "300"] },
          ],
        },
      ],
    },
  ])
}

///|
/// Test string escaping and special characters
test "advanced string handling" {
  let string_tests =
    #|basic = "simple string"
    #|with_quotes = "I said \"Hello World\""
    #|with_escapes = "Line 1\nLine 2\tTabbed"
    #|with_backslash = "C:\\Users\\Name"
    #|unicode_like = "café"
    #|empty = ""
    #|single_quotes = 'Single quoted string'
    #|mixed = ["double", 'single', "escaped\"quote"]
    #|
  @json.inspect(@toml.parse(string_tests), content=[
    "TomlTable",
    {
      "basic": ["TomlString", "simple string"],
      "with_quotes": ["TomlString", "I said \"Hello World\""],
      "with_escapes": ["TomlString", "Line 1\nLine 2\tTabbed"],
      "with_backslash": ["TomlString", "C:\\Users\\Name"],
      "unicode_like": ["TomlString", "café"],
      "empty": ["TomlString", ""],
      "single_quotes": ["TomlString", "Single quoted string"],
      "mixed": [
        "TomlArray",
        [
          ["TomlString", "double"],
          ["TomlString", "single"],
          ["TomlString", "escaped\"quote"],
        ],
      ],
    },
  ])
}

///|
/// Test numerical edge cases
test "numerical edge cases" {
  // Test various number formats and edge cases
  let number_tests =
    #|zero = 0
    #|positive = 42
    #|small_float = 0.1
    #|large_float = 1000000.999999
    #|mixed_numbers = [0, 1, 42, 3.14, 2.5, 0.0]
    #|
  @json.inspect(@toml.parse(number_tests), content=[
    "TomlTable",
    {
      "zero": ["TomlInteger", "0"],
      "positive": ["TomlInteger", "42"],
      "small_float": ["TomlFloat", 0.1],
      "large_float": ["TomlFloat", 1000000.999999],
      "mixed_numbers": [
        "TomlArray",
        [
          ["TomlInteger", "0"],
          ["TomlInteger", "1"],
          ["TomlInteger", "42"],
          ["TomlFloat", 3.14],
          ["TomlFloat", 2.5],
          ["TomlFloat", 0],
        ],
      ],
    },
  ])
}

///|
test "empty array" {
  @json.inspect(
    @toml.parse(
      (
        #|empty_array = []
      ),
    ),
    content=["TomlTable", { "empty_array": ["TomlArray", []] }],
  )
}

///|
/// Test negative numbers (now supported!)
test "negative numbers" {
  let negative_toml =
    #|negative_int = -42
    #|negative_float = -3.14
    #|zero = 0
    #|positive = 123
    #|mixed_array = [-1, 2, -3.5, 4.0]
    #|extreme_negative = -9223372036854775807
    #|small_negative = -0.001
    #|
  @json.inspect(@toml.parse(negative_toml), content=[
    "TomlTable",
    {
      "negative_int": ["TomlInteger", "-42"],
      "negative_float": ["TomlFloat", -3.14],
      "zero": ["TomlInteger", "0"],
      "positive": ["TomlInteger", "123"],
      "mixed_array": [
        "TomlArray",
        [
          ["TomlInteger", "-1"],
          ["TomlInteger", "2"],
          ["TomlFloat", -3.5],
          ["TomlFloat", 4],
        ],
      ],
      "extreme_negative": ["TomlInteger", "-9223372036854775807"],
      "small_negative": ["TomlFloat", -0.001],
    },
  ])
}

///|
/// Test negative numbers in various contexts
test "negative numbers in context" {
  // Single negative integer
  @json.inspect(
    @toml.parse(
      (
        #|count = -5
      ),
    ),
    content=["TomlTable", { "count": ["TomlInteger", "-5"] }],
  )

  // Single negative float  
  @json.inspect(
    @toml.parse(
      (
        #|temperature = -15.5
      ),
    ),
    content=["TomlTable", { "temperature": ["TomlFloat", -15.5] }],
  )

  // Array with mixed positive and negative numbers
  @json.inspect(
    @toml.parse(
      (
        #|values = [1, -2, 3.0, -4.5]
      ),
    ),
    content=[
      "TomlTable",
      {
        "values": [
          "TomlArray",
          [
            ["TomlInteger", "1"],
            ["TomlInteger", "-2"],
            ["TomlFloat", 3],
            ["TomlFloat", -4.5],
          ],
        ],
      },
    ],
  )

  // Inline table with negative values
  let coords_toml =
    #|coords = {x = -10, y = 20, z = -5.5}
    #|
  @json.inspect(@toml.parse(coords_toml), content=[
    "TomlTable",
    {
      "coords": [
        "TomlTable",
        {
          "x": ["TomlInteger", "-10"],
          "y": ["TomlInteger", "20"],
          "z": ["TomlFloat", -5.5],
        },
      ],
    },
  ])

  // Multiple negative values
  let multi_negative =
    #|min_temp = -40
    #|max_debt = -1000.50
    #|adjustment = -0.1
    #|
  @json.inspect(@toml.parse(multi_negative), content=[
    "TomlTable",
    {
      "min_temp": ["TomlInteger", "-40"],
      "max_debt": ["TomlFloat", -1000.5],
      "adjustment": ["TomlFloat", -0.1],
    },
  ])
}

///|
/// Test complex data structure (simulating a microservice config)
test "microservice configuration" {
  let microservice_config =
    #|service_name = "user-service"
    #|version = "2.1.0"
    #|environment = "production"
    #|http = {port = 8080, host = "0.0.0.0", timeout = 30.0}
    #|database = {url = "postgresql://localhost:5432/users", max_connections = 20, retry_attempts = 3}
    #|redis = {enabled = true, host = "redis-cluster", port = 6379, db = 0}
    #|logging = {level = "INFO", format = "json", outputs = ["stdout", "file"]}
    #|metrics = {enabled = true, port = 9090, path = "/metrics"}
    #|health_check = {endpoint = "/health", interval = 10, timeout = 5.0}
    #|rate_limiting = {enabled = true, requests_per_minute = 1000, burst = 50}
    #|
  @json.inspect(@toml.parse(microservice_config), content=[
    "TomlTable",
    {
      "service_name": ["TomlString", "user-service"],
      "version": ["TomlString", "2.1.0"],
      "environment": ["TomlString", "production"],
      "http": [
        "TomlTable",
        {
          "port": ["TomlInteger", "8080"],
          "host": ["TomlString", "0.0.0.0"],
          "timeout": ["TomlFloat", 30],
        },
      ],
      "database": [
        "TomlTable",
        {
          "url": ["TomlString", "postgresql://localhost:5432/users"],
          "max_connections": ["TomlInteger", "20"],
          "retry_attempts": ["TomlInteger", "3"],
        },
      ],
      "redis": [
        "TomlTable",
        {
          "enabled": ["TomlBoolean", true],
          "host": ["TomlString", "redis-cluster"],
          "port": ["TomlInteger", "6379"],
          "db": ["TomlInteger", "0"],
        },
      ],
      "logging": [
        "TomlTable",
        {
          "level": ["TomlString", "INFO"],
          "format": ["TomlString", "json"],
          "outputs": [
            "TomlArray",
            [["TomlString", "stdout"], ["TomlString", "file"]],
          ],
        },
      ],
      "metrics": [
        "TomlTable",
        {
          "enabled": ["TomlBoolean", true],
          "port": ["TomlInteger", "9090"],
          "path": ["TomlString", "/metrics"],
        },
      ],
      "health_check": [
        "TomlTable",
        {
          "endpoint": ["TomlString", "/health"],
          "interval": ["TomlInteger", "10"],
          "timeout": ["TomlFloat", 5],
        },
      ],
      "rate_limiting": [
        "TomlTable",
        {
          "enabled": ["TomlBoolean", true],
          "requests_per_minute": ["TomlInteger", "1000"],
          "burst": ["TomlInteger", "50"],
        },
      ],
    },
  ])
}

///|
/// same as parse except it will 
/// reraise the error without location to make it stable
fn parse_no_loc(s : String) -> @toml.TomlValue raise {
  @toml.parse(s) catch {
    Failure(err) => {
      // Handle MoonBit compiler error format: "FAILED: /path/to/file:line:col message"
      let msg = err.split("FAILED: ")[1:].to_array().join("")
      raise Failure(msg)
      // match msg.strip_prefix("FAILED: ") {
      //   Some(_rest) => {
      //     // Extract the actual message after the file location
      //     let parts = msg.split(" ").collect()
      //     if parts.length() >= 3 {
      //       // Skip "FAILED:" and the file location, take the rest as the message
      //       let message_parts = []
      //       for i = 2; i < parts.length(); i = i + 1 {
      //         message_parts.push(parts[i].to_string())
      //       }
      //       let actual_msg = message_parts.join(" ")
      //       raise Failure(actual_msg)
      //       // Now remove location info after " at " if present
      //       // let at_parts = actual_msg.split(" at ").collect()
      //       // if at_parts.length() > 1 {
      //       //   raise Failure(at_parts[0].to_string())
      //       // } else {
      //       //   raise Failure(actual_msg)
      //       // }
      //     } else {
      //       raise Failure(msg)
      //     }
      //   }
      //   None => {
      //     // Original format, just remove " at " location
      //     let parts = msg.split(" at ").collect()
      //     match parts.length() {
      //       1 => raise Failure(msg) // No " at " found
      //       _ => raise Failure(parts[0].to_string()) // Take everything before " at "
      //     }
      //   }
      // }

    }
    err => raise err
  }
}

///|
/// Test error handling with expect tests
test "error handling" {

  // Missing value
  @json.inspect(try? parse_no_loc("key ="), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 6}, end: {line: 1, column: 6}}",
    ],
  })
  // Missing key
  @json.inspect(try? parse_no_loc("= \"value\""), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 1}, end: {line: 1, column: 2}}",
    ],
  })

  // Unterminated string
  @json.inspect(try? parse_no_loc("key = \"unterminated"), content={
    "Err": ["Failure", "Unterminated string at line 1, column 8"],
  })

  // Invalid syntax - incomplete array
  @json.inspect(try? parse_no_loc("key = [1, 2"), content={
    "Err": [
      "Failure", "Expected ',' or ']' in array at {start: {line: 1, column: 12}, end: {line: 1, column: 12}}",
    ],
  })

  // Empty key
  @json.inspect(try? parse_no_loc(" = \"value\""), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 2}, end: {line: 1, column: 3}}",
    ],
  })
}

///|
/// Test location tracking for various error scenarios
test "error location tracking" {

  // Test 1: Error at beginning of line
  @json.inspect(try? parse_no_loc("=missing_key"), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 1}, end: {line: 1, column: 2}}",
    ],
  })

  // Test 2: Error in the middle of a line
  @json.inspect(try? parse_no_loc("valid_key = "), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 13}, end: {line: 1, column: 13}}",
    ],
  })

  // Test 3: Error with spaces before it
  @json.inspect(try? parse_no_loc("   key = "), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 10}, end: {line: 1, column: 10}}",
    ],
  })

  // Test 4: Missing equals sign
  @json.inspect(try? parse_no_loc("key \"value\""), content={
    "Err": [
      "Failure", "Expected '=' at {start: {line: 1, column: 5}, end: {line: 1, column: 12}}",
    ],
  })

  // Test 5: Invalid value type
  @json.inspect(try? parse_no_loc("key = invalid_unquoted"), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 7}, end: {line: 1, column: 23}}",
    ],
  })
}

///|
/// Test multiline error location tracking
test "multiline error locations" {

  // Test 1: Error on second line
  let multiline_test1 =
    #|key1 = "valid"
    #|key2 = 
    #|
  @json.inspect(try? parse_no_loc(multiline_test1), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 2, column: 8}, end: {line: 3, column: 1}}",
    ],
  })

  // Test 2: Error on third line
  let multiline_test2 =
    #|key1 = "valid"
    #|key2 = "also_valid"
    #|= missing_key
    #|
  @json.inspect(try? parse_no_loc(multiline_test2), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 3, column: 1}, end: {line: 3, column: 2}}",
    ],
  })

  // Test 3: Array error on second line
  let multiline_test3 =
    #|key1 = "valid"
    #|key2 = [1, 2, 
    #|
  @json.inspect(try? parse_no_loc(multiline_test3), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 3, column: 1}, end: {line: 3, column: 1}}",
    ],
  })

  // Test 4: Error after newlines and comments
  let multiline_test4 =
    #|# Comment line
    #|
    #|key1 = "valid"
    #|   
    #|= error_here
    #|
  @json.inspect(try? parse_no_loc(multiline_test4), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 5, column: 1}, end: {line: 5, column: 2}}",
    ],
  })
}

///|
/// Test array parsing error locations
test "array error locations" {

  // Test 1: Missing closing bracket at specific position
  @json.inspect(try? parse_no_loc("arr = [1, 2, 3"), content={
    "Err": [
      "Failure", "Expected ',' or ']' in array at {start: {line: 1, column: 15}, end: {line: 1, column: 15}}",
    ],
  })

  // Test 2: Missing comma between elements
  @json.inspect(try? parse_no_loc("arr = [1 2]"), content={
    "Err": [
      "Failure", "Expected ',' or ']' in array at {start: {line: 1, column: 10}, end: {line: 1, column: 11}}",
    ],
  })

  // Test 3: Invalid value in array
  @json.inspect(try? parse_no_loc("arr = [1, invalid, 3]"), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 11}, end: {line: 1, column: 18}}",
    ],
  })

  // Test 4: Nested array error
  @json.inspect(try? parse_no_loc("arr = [[1, 2], [3, ]"), content={
    "Err": [
      "Failure", "Expected ',' or ']' in array at {start: {line: 1, column: 21}, end: {line: 1, column: 21}}",
    ],
  })

  // Test 5: Array with newlines
  let array_multiline =
    #|arr = [
    #|  1,
    #|  2,
    #|  invalid_value
    #|]
    #|
  @json.inspect(try? parse_no_loc(array_multiline), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 4, column: 3}, end: {line: 4, column: 16}}",
    ],
  })
}

///|
/// Test inline table error locations
test "inline table error locations" {

  // Test 1: Missing closing brace
  @json.inspect(try? parse_no_loc("table = {key = \"value\""), content={
    "Err": [
      "Failure", "Expected ',' or '}' in inline table at {start: {line: 1, column: 23}, end: {line: 1, column: 23}}",
    ],
  })

  // Test 2: Missing key in inline table
  @json.inspect(try? parse_no_loc("table = {= \"value\"}"), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 10}, end: {line: 1, column: 11}}",
    ],
  })

  // Test 3: Missing value in inline table  
  @json.inspect(try? parse_no_loc("table = {key = }"), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 16}, end: {line: 1, column: 17}}",
    ],
  })

  // Test 4: Missing equals in inline table
  @json.inspect(try? parse_no_loc("table = {key \"value\"}"), content={
    "Err": [
      "Failure", "Expected '=' at {start: {line: 1, column: 14}, end: {line: 1, column: 21}}",
    ],
  })

  // Test 5: Invalid syntax after comma
  @json.inspect(try? parse_no_loc("table = {key1 = \"val1\", }"), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 25}, end: {line: 1, column: 26}}",
    ],
  })
}

///|
/// Test table header error locations  
test "table header error locations" {

  // Test 1: Missing closing bracket in table header
  @json.inspect(try? parse_no_loc("[table_name"), content={
    "Err": [
      "Failure", "Expected ']' at {start: {line: 1, column: 12}, end: {line: 1, column: 12}}",
    ],
  })

  // Test 2: Missing table name
  @json.inspect(try? parse_no_loc("[]"), content={
    "Err": [
      "Failure", "Expected table name at {start: {line: 1, column: 2}, end: {line: 1, column: 3}}",
    ],
  })

  // Test 3: Array of tables missing second bracket
  @json.inspect(try? parse_no_loc("[[table_name]"), content={
    "Err": [
      "Failure", "Expected ']' at {start: {line: 1, column: 14}, end: {line: 1, column: 14}}",
    ],
  })

  // Test 4: Array of tables missing table name
  @json.inspect(try? parse_no_loc("[[]]"), content={
    "Err": [
      "Failure", "Expected table name in array of tables at {start: {line: 1, column: 3}, end: {line: 1, column: 4}}",
    ],
  })

  // Test 5: Invalid character in table name position
  @json.inspect(try? parse_no_loc("[#invalid]"), content={
    "Err": [
      "Failure", "Expected table name at {start: {line: 1, column: 11}, end: {line: 1, column: 11}}",
    ],
  })
}

///|
/// Test precise column tracking with various spacing
test "precise column tracking" {

  // Test 1: Error at specific column with tabs (assuming tab = 1 column)
  @json.inspect(try? parse_no_loc("\tkey ="), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 7}, end: {line: 1, column: 7}}",
    ],
  })

  // Test 2: Error with mixed spaces and content (should fail due to missing newline)
  @json.inspect(try? parse_no_loc("  key1 = \"val\"  key2 = "), content={
    "Err": [
      "Failure", "Expected newline or end of file after key-value pair at {start: {line: 1, column: 17}, end: {line: 1, column: 21}}",
    ],
  })

  // Test 3: Long key name error position
  @json.inspect(try? parse_no_loc("very_long_key_name_here = "), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 27}, end: {line: 1, column: 27}}",
    ],
  })

  // Test 4: Error position after unicode characters
  @json.inspect(try? parse_no_loc("café = "), content={
    "Err": ["Failure", "Unexpected character: 'é'"],
  })

  // Test 5: Multiple equals signs - error on second one
  @json.inspect(try? parse_no_loc("key = = \"value\""), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 7}, end: {line: 1, column: 8}}",
    ],
  })
}

///|
/// Test complex error scenarios with precise location tracking
test "complex error location scenarios" {

  // Test 1: Deep nesting error location
  let deep_nested =
    #|outer = {
    #|  middle = {
    #|    inner = {
    #|      key = 
    #|    }
    #|  }
    #|}
    #|
  @json.inspect(try? parse_no_loc(deep_nested), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 10}, end: {line: 2, column: 1}}",
    ],
  })

  // Test 2: Error at end of file
  @json.inspect(try? parse_no_loc("key = [1, 2, 3"), content={
    "Err": [
      "Failure", "Expected ',' or ']' in array at {start: {line: 1, column: 15}, end: {line: 1, column: 15}}",
    ],
  })

  // Test 3: Error with different quote types
  @json.inspect(try? parse_no_loc("key = 'unterminated"), content={
    "Err": ["Failure", "Unterminated string at line 1, column 8"],
  })

  // Test 4: Error in array of tables with location  
  let aot_error =
    #|[[servers]]
    #|name = "server1"
    #|
    #|[[servers]]
    #|name = 
    #|
  @json.inspect(try? parse_no_loc(aot_error), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 5, column: 8}, end: {line: 6, column: 1}}",
    ],
  })

  // Test 5: Error with trailing whitespace and newlines
  let trailing_ws =
    #|key1 = "value"   
    #|key2 =    
    #|   
    #|
  @json.inspect(try? parse_no_loc(trailing_ws), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 2, column: 11}, end: {line: 3, column: 1}}",
    ],
  })
}

///|
/// Test location tracking with comments and special characters
test "location tracking with special cases" {

  // Test 1: Error after comment on same line (should fail since comments aren't implemented)
  @json.inspect(try? parse_no_loc("key = # comment"), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 16}, end: {line: 1, column: 16}}",
    ],
  })

  // Test 2: Error with windows-style line endings (if supported)
  @json.inspect(try? parse_no_loc("key1 = \"value\"\r\nkey2 = "), content={
    "Err": ["Failure", "Unexpected character: '\r'"],
  })

  // Test 3: Error with just spaces as a key
  @json.inspect(try? parse_no_loc("   = \"value\""), content={
    "Err": [
      "Failure", "Expected key at {start: {line: 1, column: 4}, end: {line: 1, column: 5}}",
    ],
  })

  // Test 4: Complex array with error at specific nested position
  let complex_array =
    #|data = [
    #|  [1, 2, 3],
    #|  ["a", "b", ],
    #|  [true, false, invalid_token]
    #|]
    #|
  @json.inspect(try? parse_no_loc(complex_array), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 4, column: 17}, end: {line: 4, column: 30}}",
    ],
  })

  // Test 5: Very long line with error at the end
  let long_line = "very_long_key_name_that_goes_on_and_on_and_on_and_on_and_on = "
  @json.inspect(try? parse_no_loc(long_line), content={
    "Err": [
      "Failure", "Expected value at {start: {line: 1, column: 63}, end: {line: 1, column: 63}}",
    ],
  })
}

///|
/// Test edge cases with expect tests
test "edge cases" {
  // Empty input should result in empty table
  @json.inspect(
    @toml.parse(
      (
        #|
      ),
    ),
    content=["TomlTable", {}],
  )

  // Only comments and whitespace should result in empty table
  let comments_only_toml =
    #|# Just a comment
    #|  
    #|# Another comment
    #|
  @json.inspect(@toml.parse(comments_only_toml), content=["TomlTable", {}])

  // Mixed single and double quotes should parse correctly
  let mixed_quotes_toml =
    #|single = 'value'
    #|double = "value"
    #|
  @json.inspect(@toml.parse(mixed_quotes_toml), content=[
    "TomlTable",
    { "single": ["TomlString", "value"], "double": ["TomlString", "value"] },
  ])

  // Whitespace around equals sign
  @json.inspect(
    @toml.parse(
      (
        #|spaced   =   "value"  
      ),
    ),
    content=["TomlTable", { "spaced": ["TomlString", "value"] }],
  )

  // Multiple newlines and comments
  let complex_whitespace =
    #|# Top comment
    #|
    #|key1 = "value1"
    #|
    #|# Middle comment
    #|
    #|key2 = "value2"
    #|# End comment
    #|
  @json.inspect(@toml.parse(complex_whitespace), content=[
    "TomlTable",
    { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
  ])
}
