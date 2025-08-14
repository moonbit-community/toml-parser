///| Comprehensive test demonstrating the TOML parser capabilities
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

///| Test nested arrays and mixed data types
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

///| Test inline tables and nesting
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

///| Test realistic application configuration
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

///| Test string escaping and special characters
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

///| Test numerical edge cases
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
  @json.inspect(@toml.parse("empty_array = []"), content=[
    "TomlTable",
    { "empty_array": ["TomlArray", []] },
  ])
}

///| Test negative numbers (now supported!)
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

///| Test negative numbers in various contexts
test "negative numbers in context" {
  // Single negative integer
  @json.inspect(@toml.parse("count = -5"), content=[
    "TomlTable",
    { "count": ["TomlInteger", "-5"] },
  ])

  // Single negative float  
  @json.inspect(@toml.parse("temperature = -15.5"), content=[
    "TomlTable",
    { "temperature": ["TomlFloat", -15.5] },
  ])

  // Array with mixed positive and negative numbers
  @json.inspect(@toml.parse("values = [1, -2, 3.0, -4.5]"), content=[
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
  ])

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

///| Test complex data structure (simulating a microservice config)
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

///| same as parse except it will 
/// reraise the error without location to make it stable
fn parse_no_loc(s : String) -> @toml.TomlValue raise {
  @toml.parse(s) catch {
    Failure(err) => {
      // Handle MoonBit compiler error format: "FAILED: /path/to/file:line:col message"
      let msg = err
      match msg.strip_prefix("FAILED: ") {
        Some(_rest) => {
          // Extract the actual message after the file location
          let parts = msg.split(" ").collect()
          if parts.length() >= 3 {
            // Skip "FAILED:" and the file location, take the rest as the message
            let message_parts = []
            for i = 2; i < parts.length(); i = i + 1 {
              message_parts.push(parts[i].to_string())
            }
            let actual_msg = message_parts.join(" ")
            raise Failure(actual_msg)
            // Now remove location info after " at " if present
            // let at_parts = actual_msg.split(" at ").collect()
            // if at_parts.length() > 1 {
            //   raise Failure(at_parts[0].to_string())
            // } else {
            //   raise Failure(actual_msg)
            // }
          } else {
            raise Failure(msg)
          }
        }
        None => {
          // Original format, just remove " at " location
          let parts = msg.split(" at ").collect()
          match parts.length() {
            1 => raise Failure(msg) // No " at " found
            _ => raise Failure(parts[0].to_string()) // Take everything before " at "
          }
        }
      }
    }
    err => raise err
  }
}

///| Test error handling with expect tests
test "error handling" {

  // Missing value
  @json.inspect(try? parse_no_loc("key ="), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected value at {start: {line: 1, column: 6}, end: {line: 1, column: 6}}",
    },
  })
  // Missing key
  @json.inspect(try? parse_no_loc("= \"value\""), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected key at {start: {line: 1, column: 1}, end: {line: 1, column: 2}}",
    },
  })

  // Unterminated string
  @json.inspect(try? @toml.parse("key = \"unterminated"), content={
    "Err": {
      "$tag": "Failure",
      "0": "FAILED: /Users/hongbozhang/git/toml-parser/src/lexer/lexer.mbt:135:5-135:30 Unterminated string at line 1, column 20",
    },
  })

  // Invalid syntax - incomplete array
  @json.inspect(try? parse_no_loc("key = [1, 2"), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected ',' or ']' in array at {start: {line: 1, column: 12}, end: {line: 1, column: 12}}",
    },
  })

  // Empty key
  @json.inspect(try? parse_no_loc(" = \"value\""), content={
    "Err": {
      "$tag": "Failure",
      "0": "Expected key at {start: {line: 1, column: 2}, end: {line: 1, column: 3}}",
    },
  })
}

///| Test edge cases with expect tests
test "edge cases" {
  // Empty input should result in empty table
  @json.inspect(@toml.parse(""), content=["TomlTable", {}])

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
  @json.inspect(@toml.parse("spaced   =   \"value\"  "), content=[
    "TomlTable",
    { "spaced": ["TomlString", "value"] },
  ])

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
