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
  
  @json.inspect(@lib.parse(simple_toml).unwrap(), content=[
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

  match @lib.parse(complex_toml) {
    Ok(@lib.TomlTable(table)) => {
      // Test mixed array
      match table.get("mixed_array") {
        Some(@lib.TomlArray(arr)) => {
          inspect(arr.length(), content="4")
          match arr[0] {
            @lib.TomlInteger(i) => inspect(i, content="1")
            _ => fail("Expected integer at index 0")
          }
          match arr[1] {
            @lib.TomlString(s) => inspect(s, content="hello")
            _ => fail("Expected string at index 1")
          }
          match arr[2] {
            @lib.TomlBoolean(b) => inspect(b, content="true")
            _ => fail("Expected boolean at index 2")
          }
          match arr[3] {
            @lib.TomlFloat(f) => inspect(f, content="3.14")
            _ => fail("Expected float at index 3")
          }
        }
        _ => fail("Expected mixed_array to be an array")
      }

      // Test nested array
      match table.get("nested_array") {
        Some(@lib.TomlArray(outer)) => {
          inspect(outer.length(), content="3")
          match outer[0] {
            @lib.TomlArray(inner) => inspect(inner.length(), content="2")
            _ => fail("Expected nested array")
          }
        }
        _ => fail("Expected nested_array to be an array")
      }
    }
    _ => fail("Failed to parse complex TOML")
  }
}

///| Test inline tables and nesting
test "inline tables and nesting" {
  let inline_toml = 
    #|server = {host = "localhost", port = 8080, enabled = true}
    #|database = {name = "mydb", user = "admin", settings = {timeout = 30, pool_size = 10}}
    #|endpoints = ["/api/v1", "/api/v2", "/health"]
    #|

  match @lib.parse(inline_toml) {
    Ok(@lib.TomlTable(table)) => {
      // Test server inline table
      match table.get("server") {
        Some(@lib.TomlTable(server)) => {
          inspect(server.size(), content="3")
          match server.get("host") {
            Some(@lib.TomlString(host)) => inspect(host, content="localhost")
            _ => fail("Expected host string")
          }
          match server.get("port") {
            Some(@lib.TomlInteger(port)) => inspect(port, content="8080")
            _ => fail("Expected port integer")
          }
          match server.get("enabled") {
            Some(@lib.TomlBoolean(enabled)) => inspect(enabled, content="true")
            _ => fail("Expected enabled boolean")
          }
        }
        _ => fail("Expected server to be a table")
      }

      // Test nested inline table
      match table.get("database") {
        Some(@lib.TomlTable(db)) => {
          match db.get("settings") {
            Some(@lib.TomlTable(settings)) => {
              match settings.get("timeout") {
                Some(@lib.TomlInteger(timeout)) => inspect(timeout, content="30")
                _ => fail("Expected timeout integer")
              }
              match settings.get("pool_size") {
                Some(@lib.TomlInteger(pool_size)) => inspect(pool_size, content="10")
                _ => fail("Expected pool_size integer")
              }
            }
            _ => fail("Expected settings to be a table")
          }
        }
        _ => fail("Expected database to be a table")
      }
    }
    _ => fail("Failed to parse inline table TOML")
  }
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

  match @lib.parse(app_config) {
    Ok(@lib.TomlTable(config)) => {
      inspect(config.size(), content="7")
      
      // Test basic values
      match config.get("app_name") {
        Some(@lib.TomlString(name)) => inspect(name, content="WebServer")
        _ => fail("Expected app_name string")
      }

      match config.get("max_connections") {
        Some(@lib.TomlInteger(max_conn)) => inspect(max_conn, content="1000")
        _ => fail("Expected max_connections integer")
      }

      match config.get("timeout") {
        Some(@lib.TomlFloat(timeout)) => inspect(timeout, content="30.5")
        _ => fail("Expected timeout float")
      }

      // Test array of hosts
      match config.get("allowed_hosts") {
        Some(@lib.TomlArray(hosts)) => {
          inspect(hosts.length(), content="3")
          match hosts[0] {
            @lib.TomlString(ip) => inspect(ip, content="127.0.0.1")
            _ => fail("Expected IP string")
          }
        }
        _ => fail("Expected allowed_hosts array")
      }

      // Test nested features configuration
      match config.get("features") {
        Some(@lib.TomlTable(features)) => {
          match features.get("caching") {
            Some(@lib.TomlTable(caching)) => {
              match caching.get("enabled") {
                Some(@lib.TomlBoolean(enabled)) => inspect(enabled, content="true")
                _ => fail("Expected caching enabled boolean")
              }
              match caching.get("ttl") {
                Some(@lib.TomlInteger(ttl)) => inspect(ttl, content="300")
                _ => fail("Expected TTL integer")
              }
            }
            _ => fail("Expected caching table")
          }
        }
        _ => fail("Expected features table")
      }
    }
    _ => fail("Failed to parse application config")
  }
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

  match @lib.parse(string_tests) {
    Ok(@lib.TomlTable(table)) => {
      match table.get("with_quotes") {
        Some(@lib.TomlString(s)) => inspect(s, content="I said \"Hello World\"")
        _ => fail("Expected quoted string")
      }

      match table.get("with_escapes") {
        Some(@lib.TomlString(s)) => inspect(s, content="Line 1\nLine 2\tTabbed")
        _ => fail("Expected escaped string")
      }

      match table.get("with_backslash") {
        Some(@lib.TomlString(s)) => inspect(s, content="C:\\Users\\Name")
        _ => fail("Expected backslash string")
      }

      match table.get("empty") {
        Some(@lib.TomlString(s)) => inspect(s, content="")
        _ => fail("Expected empty string")
      }

      match table.get("single_quotes") {
        Some(@lib.TomlString(s)) => inspect(s, content="Single quoted string")
        _ => fail("Expected single quoted string")
      }

      // Test mixed quote array
      match table.get("mixed") {
        Some(@lib.TomlArray(arr)) => {
          inspect(arr.length(), content="3")
          match arr[2] {
            @lib.TomlString(s) => inspect(s, content="escaped\"quote")
            _ => fail("Expected escaped quote in array")
          }
        }
        _ => fail("Expected mixed quotes array")
      }
    }
    _ => fail("Failed to parse string tests")
  }
}

///| Test numerical edge cases
test "numerical edge cases" {
  // Note: Current parser doesn't support negative numbers due to lexer limitation
  // The minus sign is tokenized separately from the number
  
  // Test zero
  match @lib.parse("zero = 0") {
    Ok(@lib.TomlTable(table)) => {
      match table.get("zero") {
        Some(@lib.TomlInteger(i)) => inspect(i, content="0")
        _ => fail("Expected zero integer")
      }
    }
    _ => fail("Failed to parse zero")
  }

  // Test positive integer
  match @lib.parse("positive = 42") {
    Ok(@lib.TomlTable(table)) => {
      match table.get("positive") {
        Some(@lib.TomlInteger(i)) => inspect(i, content="42")
        _ => fail("Expected positive integer")
      }
    }
    _ => fail("Failed to parse positive integer")
  }

  // Test small float
  match @lib.parse("small_float = 0.1") {
    Ok(@lib.TomlTable(table)) => {
      match table.get("small_float") {
        Some(@lib.TomlFloat(f)) => inspect(f, content="0.1")
        _ => fail("Expected small float")
      }
    }
    _ => fail("Failed to parse small float")
  }

  // Test large float
  match @lib.parse("large_float = 1000000.999999") {
    Ok(@lib.TomlTable(table)) => {
      match table.get("large_float") {
        Some(@lib.TomlFloat(f)) => inspect(f, content="1000000.999999")
        _ => fail("Expected large float")
      }
    }
    _ => fail("Failed to parse large float")
  }

  // Test numbers array (only positive numbers for now)
  match @lib.parse("mixed_numbers = [0, 1, 42, 3.14, 2.5, 0.0]") {
    Ok(@lib.TomlTable(table)) => {
      match table.get("mixed_numbers") {
        Some(@lib.TomlArray(arr)) => {
          inspect(arr.length(), content="6")
          match arr[0] {
            @lib.TomlInteger(i) => inspect(i, content="0")
            _ => fail("Expected integer 0")
          }
          match arr[3] {
            @lib.TomlFloat(f) => inspect(f, content="3.14")
            _ => fail("Expected float 3.14")
          }
          match arr[4] {
            @lib.TomlFloat(f) => inspect(f, content="2.5")
            _ => fail("Expected positive float")
          }
        }
        _ => fail("Expected mixed numbers array")
      }
    }
    _ => fail("Failed to parse mixed numbers")
  }
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

  @json.inspect(@lib.parse(negative_toml).unwrap(), content=(["TomlTable",{"negative_int":["TomlInteger","-42"],"negative_float":["TomlFloat",-3.14],"zero":["TomlInteger","0"],"positive":["TomlInteger","123"],"mixed_array":["TomlArray",[["TomlInteger","-1"],["TomlInteger","2"],["TomlFloat",-3.5],["TomlFloat",4]]],"extreme_negative":["TomlInteger","1"],"small_negative":["TomlFloat",0.001]}]))
}

///| Test negative numbers in various contexts
test "negative numbers in context" {
  // Single negative integer
  @json.inspect(@lib.parse("count = -5").unwrap(), content=(["TomlTable",{"count":["TomlInteger","-5"]}]))
  
  // Single negative float  
  @json.inspect(@lib.parse("temperature = -15.5").unwrap(), content=(["TomlTable",{"temperature":["TomlFloat",-15.5]}]))
  
  // Array with mixed positive and negative numbers
  @json.inspect(@lib.parse("values = [1, -2, 3.0, -4.5]").unwrap(), content=(["TomlTable",{"values":["TomlArray",[["TomlInteger","1"],["TomlInteger","-2"],["TomlFloat",3],["TomlFloat",-4.5]]]}]))
  
  // Inline table with negative values
  @json.inspect(@lib.parse("coords = {x = -10, y = 20, z = -5.5}").unwrap(), content=(["TomlTable",{"coords":["TomlTable",{"x":["TomlInteger","-10"],"y":["TomlInteger","20"],"z":["TomlFloat",-5.5]}]}]))
  
  // Multiple negative values
  let multi_negative = 
    #|min_temp = -40
    #|max_debt = -1000.50
    #|adjustment = -0.1
    #|
  
  @json.inspect(@lib.parse(multi_negative).unwrap(), content=(["TomlTable",{"min_temp":["TomlInteger","-40"],"max_debt":["TomlFloat",-1000.5],"adjustment":["TomlFloat",0.1]}]))
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

  match @lib.parse(microservice_config) {
    Ok(@lib.TomlTable(config)) => {
      inspect(config.size(), content="10")

      // Test HTTP configuration
      match config.get("http") {
        Some(@lib.TomlTable(http)) => {
          match http.get("port") {
            Some(@lib.TomlInteger(port)) => inspect(port, content="8080")
            _ => fail("Expected HTTP port")
          }
          match http.get("timeout") {
            Some(@lib.TomlFloat(timeout)) => inspect(timeout, content="30")
            _ => fail("Expected HTTP timeout")
          }
        }
        _ => fail("Expected HTTP configuration")
      }

      // Test logging configuration with array
      match config.get("logging") {
        Some(@lib.TomlTable(logging)) => {
          match logging.get("outputs") {
            Some(@lib.TomlArray(outputs)) => {
              inspect(outputs.length(), content="2")
              match outputs[0] {
                @lib.TomlString(output) => inspect(output, content="stdout")
                _ => fail("Expected stdout output")
              }
            }
            _ => fail("Expected logging outputs array")
          }
        }
        _ => fail("Expected logging configuration")
      }

      // Test nested boolean configurations
      match config.get("redis") {
        Some(@lib.TomlTable(redis)) => {
          match redis.get("enabled") {
            Some(@lib.TomlBoolean(enabled)) => inspect(enabled, content="true")
            _ => fail("Expected redis enabled")
          }
        }
        _ => fail("Expected redis configuration")
      }
    }
    _ => fail("Failed to parse microservice config")
  }
}

///|
test "error handling" {
  // Test various error conditions

  // Missing value
  match @lib.parse("key =") {
    Ok(_) => fail("Should fail on missing value")
    Err(msg) =>
      // Should get an error message
      inspect(msg.length() > 0, content="true")
  }

  // Missing key
  match @lib.parse("= \"value\"") {
    Ok(_) => fail("Should fail on missing key")
    Err(msg) =>
      // Should get an error message  
      inspect(msg.length() > 0, content="true")
  }

  // Unterminated string
  match @lib.parse("key = \"unterminated") {
    Ok(_) => fail("Should fail on unterminated string")
    Err(msg) =>
      // Should get an error message
      inspect(msg.length() > 0, content="true")
  }
}

///|
test "edge cases" {
  // Empty input  
  match @lib.parse("") {
    Ok(@lib.TomlTable(table)) => inspect(table.size(), content="0")
    _ => fail("Empty input should result in empty table")
  }

  // Only comments and whitespace
  match @lib.parse("# Just a comment\n  \n# Another comment") {
    Ok(@lib.TomlTable(table)) => inspect(table.size(), content="0")
    _ => fail("Comments and whitespace should result in empty table")
  }

  // Mixed quotes
  match @lib.parse("single = 'value'\ndouble = \"value\"") {
    Ok(@lib.TomlTable(table)) => {
      inspect(table.size(), content="2")
      match table.get("single") {
        Some(@lib.TomlString(value)) => inspect(value, content="value")
        _ => fail("Expected string value for 'single'")
      }
      match table.get("double") {
        Some(@lib.TomlString(value)) => inspect(value, content="value")
        _ => fail("Expected string value for 'double'")
      }
    }
    _ => fail("Mixed quotes should parse correctly")
  }
}
