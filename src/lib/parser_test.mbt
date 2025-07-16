///| Tests for the TOML parser
test "parse simple key-value string" {
  match @lib.parse("name = \"John\"") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("name") {
            Some(@lib.TomlString(value)) => inspect(value, content="John")
            _ => fail("Expected string value for 'name'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse simple key-value integer" {
  match @lib.parse("age = 25") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("age") {
            Some(@lib.TomlInteger(value)) => inspect(value, content="25")
            _ => fail("Expected integer value for 'age'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse simple key-value boolean" {
  match @lib.parse("enabled = true") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("enabled") {
            Some(@lib.TomlBoolean(value)) => inspect(value, content="true")
            _ => fail("Expected boolean value for 'enabled'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse simple key-value float" {
  match @lib.parse("pi = 3.14") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("pi") {
            Some(@lib.TomlFloat(value)) => inspect(value, content="3.14")
            _ => fail("Expected float value for 'pi'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse multiple key-value pairs" {
  match @lib.parse("name = \"Alice\"\nage = 30\nenabled = false") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="3")
          match table.get("name") {
            Some(@lib.TomlString(value)) => inspect(value, content="Alice")
            _ => fail("Expected string value for 'name'")
          }
          match table.get("age") {
            Some(@lib.TomlInteger(value)) => inspect(value, content="30")
            _ => fail("Expected integer value for 'age'")
          }
          match table.get("enabled") {
            Some(@lib.TomlBoolean(value)) => inspect(value, content="false")
            _ => fail("Expected boolean value for 'enabled'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse array" {
  match @lib.parse("numbers = [1, 2, 3]") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("numbers") {
            Some(@lib.TomlArray(arr)) => {
              inspect(arr.length(), content="3")
              match arr[0] {
                @lib.TomlInteger(val) => inspect(val, content="1")
                _ => fail("Expected integer at index 0")
              }
              match arr[1] {
                @lib.TomlInteger(val) => inspect(val, content="2")
                _ => fail("Expected integer at index 1")
              }
              match arr[2] {
                @lib.TomlInteger(val) => inspect(val, content="3")
                _ => fail("Expected integer at index 2")
              }
            }
            _ => fail("Expected array value for 'numbers'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "parse inline table" {
  match @lib.parse("person = {name = \"Bob\", age = 25}") {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="1")
          match table.get("person") {
            Some(@lib.TomlTable(inner_table)) => {
              inspect(inner_table.size(), content="2")
              match inner_table.get("name") {
                Some(@lib.TomlString(value)) => inspect(value, content="Bob")
                _ => fail("Expected string value for inner 'name'")
              }
              match inner_table.get("age") {
                Some(@lib.TomlInteger(value)) => inspect(value, content="25")
                _ => fail("Expected integer value for inner 'age'")
              }
            }
            _ => fail("Expected table value for 'person'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}
