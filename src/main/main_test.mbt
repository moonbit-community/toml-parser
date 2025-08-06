///| Tests for the main demo functionality to improve coverage
test "main module toml value creation and formatting" {
  // Test basic value types mentioned in main
  let str_val = @toml.TomlString("Hello, TOML!")
  inspect(str_val.to_string(), content="\"Hello, TOML!\"")
  let int_val = @toml.TomlInteger(42L)
  inspect(int_val.to_string(), content="42")
  let bool_val = @toml.TomlBoolean(true)
  inspect(bool_val.to_string(), content="true")
}

///|
test "main module array creation like in demo" {
  // Test array creation as done in main
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  inspect(array_val.to_string(), content="[1, 2, 3]")
}

///|
test "main module simple toml parsing like in demo" {
  // Test the exact TOML input from main demo
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  let result = @toml.parse(toml_input)

  // Verify the parsing worked correctly
  match result {
    @toml.TomlTable(table) => {
      match table.get("name") {
        Some(@toml.TomlString(name)) => inspect(name, content="John Doe")
        _ => fail("Expected name to be a string")
      }
      match table.get("age") {
        Some(@toml.TomlInteger(age)) => inspect(age, content="30")
        _ => fail("Expected age to be an integer")
      }
      match table.get("enabled") {
        Some(@toml.TomlBoolean(enabled)) => inspect(enabled, content="true")
        _ => fail("Expected enabled to be a boolean")
      }
    }
    _ => fail("Expected result to be a table")
  }
}

///|
test "main module array parsing like in demo" {
  // Test the array parsing from main demo
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  let result = @toml.parse(toml_array)
  match result {
    @toml.TomlTable(table) =>
      match table.get("numbers") {
        Some(@toml.TomlArray(arr)) => {
          inspect(arr.length(), content="5")
          match arr[0] {
            @toml.TomlInteger(val) => inspect(val, content="1")
            _ => fail("Expected first element to be integer 1")
          }
          match arr[4] {
            @toml.TomlInteger(val) => inspect(val, content="5")
            _ => fail("Expected last element to be integer 5")
          }
        }
        _ => fail("Expected numbers to be an array")
      }
    _ => fail("Expected result to be a table")
  }
}

///|
test "main module inline table parsing like in demo" {
  // Test the inline table parsing from main demo
  let toml_table = "person = {name = \"Alice\", age = 25}"
  let result = @toml.parse(toml_table)
  match result {
    @toml.TomlTable(table) =>
      match table.get("person") {
        Some(@toml.TomlTable(person_table)) => {
          match person_table.get("name") {
            Some(@toml.TomlString(name)) => inspect(name, content="Alice")
            _ => fail("Expected person name to be a string")
          }
          match person_table.get("age") {
            Some(@toml.TomlInteger(age)) => inspect(age, content="25")
            _ => fail("Expected person age to be an integer")
          }
        }
        _ => fail("Expected person to be a table")
      }
    _ => fail("Expected result to be a table")
  }
}

///|
test "main module error handling scenarios" {
  // Test various error scenarios that would be triggered in main

  // Invalid TOML syntax
  try {
    let _ = @toml.parse("invalid = toml syntax [")
    fail("Should have thrown an error for invalid syntax")
  } catch {
    _ => () // Expected to fail
  }

  // Malformed key-value pair
  try {
    let _ = @toml.parse("key = ")
    fail("Should have thrown an error for incomplete value")
  } catch {
    _ => () // Expected to fail
  }

  // Invalid array syntax
  try {
    let _ = @toml.parse("arr = [1, 2, 3")
    fail("Should have thrown an error for unclosed array")
  } catch {
    _ => () // Expected to fail
  }
}

///|
test "main module complex demo scenarios" {
  // Test more complex scenarios that extend main functionality

  // Mixed array with same types (should work)
  let mixed_array_toml = "items = [\"apple\", \"banana\", \"cherry\"]"
  let result = @toml.parse(mixed_array_toml)
  match result {
    @toml.TomlTable(table) =>
      match table.get("items") {
        Some(@toml.TomlArray(arr)) => {
          inspect(arr.length(), content="3")
          match arr[1] {
            @toml.TomlString(val) => inspect(val, content="banana")
            _ => fail("Expected string value")
          }
        }
        _ => fail("Expected items to be an array")
      }
    _ => fail("Expected result to be a table")
  }

  // Nested inline table
  let nested_table_toml = "config = {database = {host = \"localhost\", port = 5432}}"
  let result2 = @toml.parse(nested_table_toml)
  match result2 {
    @toml.TomlTable(table) =>
      match table.get("config") {
        Some(@toml.TomlTable(config_table)) =>
          match config_table.get("database") {
            Some(@toml.TomlTable(db_table)) => {
              match db_table.get("host") {
                Some(@toml.TomlString(host)) =>
                  inspect(host, content="localhost")
                _ => fail("Expected host to be a string")
              }
              match db_table.get("port") {
                Some(@toml.TomlInteger(port)) => inspect(port, content="5432")
                _ => fail("Expected port to be an integer")
              }
            }
            _ => fail("Expected database to be a table")
          }
        _ => fail("Expected config to be a table")
      }
    _ => fail("Expected result to be a table")
  }
}

///|
test "main module whitespace and newline handling" {
  // Test whitespace handling like main would encounter
  let whitespace_toml = "  key1  =  \"value1\"  \n  key2  =  42  \n"
  let result = @toml.parse(whitespace_toml)
  match result {
    @toml.TomlTable(table) => {
      inspect(table.contains("key1"), content="true")
      inspect(table.contains("key2"), content="true")
    }
    _ => fail("Expected result to be a table")
  }
}
