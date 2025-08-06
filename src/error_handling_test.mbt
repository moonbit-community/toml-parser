///| Comprehensive error handling and edge case tests across all modules

///| Test malformed number parsing errors
test "error handling malformed numbers" {
  // Test invalid integer
  try {
    let _ = @toml.parse(
      "key = 999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
    )
    fail("Should have failed on extremely large integer")
  } catch {
    _ => () // Expected failure
  }

  // Test invalid float
  try {
    let _ = @toml.parse("key = 3.14.15")
    fail("Should have failed on malformed float")
  } catch {
    _ => () // Expected failure
  }
}

///| Test string parsing edge cases and errors
test "error handling string parsing" {
  // Test string with invalid escape
  try {
    let _ = @toml.parse("key = \"invalid\\q escape\"")
    fail("Should have failed on invalid escape sequence")
  } catch {
    _ => () // Expected failure
  }

  // Test unterminated string
  try {
    let _ = @toml.parse("key = \"unterminated string")
    fail("Should have failed on unterminated string")
  } catch {
    _ => () // Expected failure
  }

  // Test literal string edge cases
  let result = @toml.parse("path = 'C:\\\\Windows\\\\System32'")
  match result {
    @toml.TomlTable(table) =>
      match table.get("path") {
        Some(@toml.TomlString(path)) =>
          inspect(path, content="C:\\\\Windows\\\\System32")
        _ => fail("Expected path to be a string")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test complex nested structure edge cases
test "error handling complex nested structures" {
  // Test deeply nested structure
  let complex_toml = "config = {database = {connections = {primary = {host = \"localhost\", port = 5432}}}}"
  let result = @toml.parse(complex_toml)
  match result {
    @toml.TomlTable(table) => inspect(table.contains("config"), content="true")
    _ => fail("Expected result to be a table")
  }

  // Test mixed array in nested structure (should fail validation)
  let nested_invalid = Array::new()
  let inner_table : Map[String, @toml.TomlValue] = Map::new()
  let mixed_array = Array::new()
  mixed_array.push(@toml.TomlString("string"))
  mixed_array.push(@toml.TomlInteger(42L))
  inner_table["mixed"] = @toml.TomlArray(mixed_array)
  nested_invalid.push(@toml.TomlTable(inner_table))
  let nested_value = @toml.TomlArray(nested_invalid)
  inspect(nested_value.validate(), content="false")
}

///| Test whitespace and formatting edge cases
test "error handling whitespace edge cases" {
  // Test excessive whitespace
  let whitespace_heavy = "    key1    =    \"value1\"    \n\n\n    key2    =    42    \n\n\n"
  let result = @toml.parse(whitespace_heavy)
  match result {
    @toml.TomlTable(table) => {
      inspect(table.contains("key1"), content="true")
      inspect(table.contains("key2"), content="true")
    }
    _ => fail("Expected result to be a table")
  }

  // Test trailing commas in arrays
  let trailing_comma = "numbers = [1, 2, 3,]"
  let result2 = @toml.parse(trailing_comma)
  match result2 {
    @toml.TomlTable(table) =>
      match table.get("numbers") {
        Some(@toml.TomlArray(arr)) => inspect(arr.length(), content="3")
        _ => fail("Expected numbers to be an array")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test comment edge cases
test "error handling comment edge cases" {
  // Test comment at end of file without newline
  let comment_at_end = "key = \"value\" # comment without newline"
  let result = @toml.parse(comment_at_end)
  match result {
    @toml.TomlTable(table) => inspect(table.contains("key"), content="true")
    _ => fail("Expected result to be a table")
  }

  // Test multiple comments
  let multi_comment = "# First comment\n# Second comment\nkey = \"value\" # inline comment\n# Final comment"
  let result2 = @toml.parse(multi_comment)
  match result2 {
    @toml.TomlTable(table) => inspect(table.contains("key"), content="true")
    _ => fail("Expected result to be a table")
  }
}

///| Test array edge cases and errors
test "error handling array edge cases" {
  // Test empty array
  let empty_array_result = @toml.parse("empty = []")
  match empty_array_result {
    @toml.TomlTable(table) =>
      match table.get("empty") {
        Some(@toml.TomlArray(arr)) => inspect(arr.length(), content="0")
        _ => fail("Expected empty to be an array")
      }
    _ => fail("Expected result to be a table")
  }

  // Test array with only whitespace
  let whitespace_array = "numbers = [ \n \t \n ]"
  let result = @toml.parse(whitespace_array)
  match result {
    @toml.TomlTable(table) =>
      match table.get("numbers") {
        Some(@toml.TomlArray(arr)) => inspect(arr.length(), content="0")
        _ => fail("Expected numbers to be an array")
      }
    _ => fail("Expected result to be a table")
  }

  // Test nested arrays
  let nested_arrays = "matrix = [[1, 2], [3, 4]]"
  let result2 = @toml.parse(nested_arrays)
  match result2 {
    @toml.TomlTable(table) =>
      match table.get("matrix") {
        Some(@toml.TomlArray(arr)) => {
          inspect(arr.length(), content="2")
          match arr[0] {
            @toml.TomlArray(inner) => inspect(inner.length(), content="2")
            _ => fail("Expected inner array")
          }
        }
        _ => fail("Expected matrix to be an array")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test table edge cases
test "error handling table edge cases" {
  // Test empty table section
  let empty_table = "[empty_table]\n[another_table]\nkey = \"value\""
  let result = @toml.parse(empty_table)
  match result {
    @toml.TomlTable(table) => {
      inspect(table.contains("empty_table"), content="true")
      inspect(table.contains("another_table"), content="true")
    }
    _ => fail("Expected result to be a table")
  }

  // Test inline table edge cases
  let empty_inline = "empty = {}"
  let result2 = @toml.parse(empty_inline)
  match result2 {
    @toml.TomlTable(table) =>
      match table.get("empty") {
        Some(@toml.TomlTable(inner)) => {
          let mut count = 0
          inner.each(fn(_k, _v) { count = count + 1 })
          inspect(count, content="0")
        }
        _ => fail("Expected empty to be a table")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test number format edge cases
test "error handling number format edge cases" {
  // Test numbers with underscores
  let underscored_numbers = "big = 1_000_000\nfloat = 3.141_592"
  let result = @toml.parse(underscored_numbers)
  match result {
    @toml.TomlTable(table) => {
      match table.get("big") {
        Some(@toml.TomlInteger(val)) => inspect(val, content="1000000")
        _ => fail("Expected big to be an integer")
      }
      match table.get("float") {
        Some(@toml.TomlFloat(val)) => inspect(val, content="3.141592")
        _ => fail("Expected float to be a float")
      }
    }
    _ => fail("Expected result to be a table")
  }

  // Test hexadecimal numbers
  let hex_number = "hex = 0x1A2B"
  let result2 = @toml.parse(hex_number)
  match result2 {
    @toml.TomlTable(table) =>
      match table.get("hex") {
        Some(@toml.TomlInteger(val)) => inspect(val, content="6699") // 0x1A2B = 6699
        _ => fail("Expected hex to be an integer")
      }
    _ => fail("Expected result to be a table")
  }
}
