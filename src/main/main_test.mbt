///| Tests for main package TOML value types and parsing functionality
test "TomlString creation and to_string" {
  let str_val = @toml.TomlString("Hello, TOML!")
  inspect(str_val.to_string(), content="\"Hello, TOML!\"")
}

///|
test "TomlInteger creation and to_string" {
  let int_val = @toml.TomlInteger(42L)
  inspect(int_val.to_string(), content="42")
}

///|
test "TomlBoolean creation and to_string" {
  let bool_val = @toml.TomlBoolean(true)
  inspect(bool_val.to_string(), content="true")
  let bool_val_false = @toml.TomlBoolean(false)
  inspect(bool_val_false.to_string(), content="false")
}

///|
test "TomlArray creation and to_string" {
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  inspect(array_val.to_string(), content="[1, 2, 3]")
}

///|
test "parse simple TOML with basic types" {
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  let result = @toml.parse(toml_input)

  // Check the result is a table
  match result {
    @toml.TomlTable(table) => {
      // Check name field
      match table.get("name") {
        Some(@toml.TomlString(name)) => inspect(name, content="John Doe")
        _ => fail("Expected name field")
      }

      // Check age field
      match table.get("age") {
        Some(@toml.TomlInteger(age)) => inspect(age, content="30")
        _ => fail("Expected age field")
      }

      // Check enabled field
      match table.get("enabled") {
        Some(@toml.TomlBoolean(enabled)) => inspect(enabled, content="true")
        _ => fail("Expected enabled field")
      }
    }
    _ => fail("Expected table result")
  }
}

///|
test "parse TOML with array" {
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  let result = @toml.parse(toml_array)
  match result {
    @toml.TomlTable(table) =>
      match table.get("numbers") {
        Some(@toml.TomlArray(arr)) => {
          inspect(arr.length(), content="5")
          match arr[0] {
            @toml.TomlInteger(val) => inspect(val, content="1")
            _ => fail("Expected first element to be 1")
          }
          match arr[4] {
            @toml.TomlInteger(val) => inspect(val, content="5")
            _ => fail("Expected last element to be 5")
          }
        }
        _ => fail("Expected numbers array")
      }
    _ => fail("Expected table result")
  }
}

///|
test "parse TOML with inline table" {
  let toml_table = "person = {name = \"Alice\", age = 25}"
  let result = @toml.parse(toml_table)
  match result {
    @toml.TomlTable(table) =>
      match table.get("person") {
        Some(@toml.TomlTable(person_table)) => {
          match person_table.get("name") {
            Some(@toml.TomlString(name)) => inspect(name, content="Alice")
            _ => fail("Expected name in person table")
          }
          match person_table.get("age") {
            Some(@toml.TomlInteger(age)) => inspect(age, content="25")
            _ => fail("Expected age in person table")
          }
        }
        _ => fail("Expected person table")
      }
    _ => fail("Expected table result")
  }
}

///|
test "TomlFloat creation and to_string" {
  let float_val = @toml.TomlFloat(3.14)
  inspect(float_val.to_string(), content="3.14")
}

///|
test "empty TomlTable creation and to_string" {
  let empty_table = @toml.TomlTable(Map::new())
  inspect(empty_table.to_string(), content="{}")
}

///|
test "TomlArray with mixed types" {
  let arr = Array::new()
  arr.push(@toml.TomlString("hello"))
  arr.push(@toml.TomlInteger(42L))
  arr.push(@toml.TomlBoolean(true))
  let array_val = @toml.TomlArray(arr)
  inspect(array_val.to_string(), content="[\"hello\", 42, true]")
}

///|
test "parse error handling with invalid TOML" {
  try {
    let _result = @toml.parse("invalid = ")
    fail("Should have thrown parse error")
  } catch {
    _msg => () // Expected to fail
  }
}

///|
test "demo all TOML value types" {
  // Test creating and using all TOML value types like in main
  let str_val = @toml.TomlString("Hello, TOML!")
  let int_val = @toml.TomlInteger(42L)
  let bool_val = @toml.TomlBoolean(true)
  let float_val = @toml.TomlFloat(3.14)

  // Basic checks
  inspect(str_val.to_string().contains("Hello"), content="true")
  inspect(int_val.to_string(), content="42")
  inspect(bool_val.to_string(), content="true")
  inspect(float_val.to_string(), content="3.14")
}
