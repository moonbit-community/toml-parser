///| Comprehensive coverage improvement tests for TOML parser

///| This file targets uncovered code paths to improve test coverage

///| Test EOF handling in parser - covered by creating empty token arrays
test "parser_eof_handling" {
  // Test empty parse input to exercise EOF conditions
  let result = @toml.parse("")
  @json.inspect(result, content=["TomlTable", {}])
}

///| Test integer keys in inline tables
test "inline_table_with_integer_key" {
  let toml_input = "table = {123 = \"value\"}"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    { "table": ["TomlTable", { "123": ["TomlString", "value"] }] },
  ])
}

///| Test string keys in table paths
test "table_path_with_string_key" {
  let toml_input = "[\"section\".\"subsection\"]\nkey = \"value\""
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "section": [
        "TomlTable",
        { "subsection": ["TomlTable", { "key": ["TomlString", "value"] }] },
      ],
    },
  ])
}

///| Test integer keys in table paths
test "table_path_with_integer_key" {
  let toml_input = "[section.123]\nkey = \"value\""
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "section": [
        "TomlTable",
        { "123": ["TomlTable", { "key": ["TomlString", "value"] }] },
      ],
    },
  ])
}

///| Test string keys in array of tables paths
test "array_of_tables_path_with_string_key" {
  let toml_input = "[[\"products\"]]\nname = \"Hammer\""
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "products": [
        "TomlArray",
        [["TomlTable", { "name": ["TomlString", "Hammer"] }]],
      ],
    },
  ])
}

///| Test integer keys in array of tables paths
test "array_of_tables_path_with_integer_key" {
  let toml_input = "[[section.123]]\nvalue = 42"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "section": [
        "TomlTable",
        {
          "123": [
            "TomlArray",
            [["TomlTable", { "value": ["TomlInteger", "42"] }]],
          ],
        },
      ],
    },
  ])
}

///| Test invalid Unicode escape sequences to trigger error paths
test "invalid_unicode_escapes" {
  try {
    ignore(@toml.parse("key = \"\\uZZZZ\""))
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test invalid 8-byte Unicode escape
test "invalid_8byte_unicode_escape" {
  try {
    ignore(@toml.parse("key = \"\\U00200000\"")) // Invalid code point > 0x10FFFF
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test unterminated multiline string
test "unterminated_multiline_string" {
  try {
    ignore(@toml.parse("key = \"\"\"This is unterminated"))
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test homogeneous array with TomlFloat
test "homogeneous_array_with_floats" {
  let arr = [@toml.TomlFloat(1.0), @toml.TomlFloat(2.0)]
  let result = @toml.TomlValue::is_homogeneous_array(arr)
  inspect(result, content="true")
}

///| Test homogeneous array with TomlTable
test "homogeneous_array_with_tables" {
  let table1 = Map::new()
  let table2 = Map::new()
  let arr = [@toml.TomlTable(table1), @toml.TomlTable(table2)]
  let result = @toml.TomlValue::is_homogeneous_array(arr)
  inspect(result, content="true")
}

///| Test homogeneous array type checking with TomlBoolean
test "homogeneous_array_type_check_boolean" {
  let arr = [@toml.TomlBoolean(true), @toml.TomlInteger(42L)]
  let result = @toml.TomlValue::is_homogeneous_array(arr)
  inspect(result, content="false")
}

///| Test homogeneous array type checking with TomlTable vs other
test "homogeneous_array_type_check_table_vs_other" {
  let table = Map::new()
  let arr = [@toml.TomlTable(table), @toml.TomlInteger(42L)]
  let result = @toml.TomlValue::is_homogeneous_array(arr)
  inspect(result, content="false")
}

///| Test nested validation failure in arrays
test "nested_validation_failure_in_array" {
  // Create a heterogeneous nested array (which should be invalid)
  let nested_arr = [@toml.TomlInteger(1L), @toml.TomlString("test")]
  let invalid_nested = @toml.TomlArray(nested_arr)
  let outer_arr = [invalid_nested]
  let outer_array_value = @toml.TomlArray(outer_arr)
  let result = outer_array_value.validate()
  inspect(result, content="false")
}

///| Test table path conflict error  
test "table_path_conflict_error" {
  try {
    ignore(@toml.parse("key = 42\n[key]"))
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test array of tables path conflict error
test "array_of_tables_path_conflict_error" {
  try {
    ignore(@toml.parse("key = 42\n[[key]]"))
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test empty inline table
test "empty_inline_table" {
  let toml_input = "table = {}"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=["TomlTable", { "table": ["TomlTable", {}] }])
}

///| Test empty array
test "empty_array" {
  let toml_input = "arr = []"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=["TomlTable", { "arr": ["TomlArray", []] }])
}

///| Test various TomlValue to_string methods to ensure coverage
test "toml_value_to_string_coverage" {
  // Test float to_string
  let float_val = @toml.TomlFloat(3.14)
  let float_str = float_val.to_string()
  inspect(float_str.contains("3.14"), content="true")

  // Test datetime to_string variants
  let offset_dt = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-05-15T10:30:00Z"),
  )
  let offset_str = offset_dt.to_string()
  inspect(offset_str, content="2023-05-15T10:30:00Z")
  let local_dt = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-05-15T10:30:00"),
  )
  let local_str = local_dt.to_string()
  inspect(local_str, content="2023-05-15T10:30:00")
  let local_date = @toml.TomlDateTime(@tokenize.LocalDate("2023-05-15"))
  let date_str = local_date.to_string()
  inspect(date_str, content="2023-05-15")
  let local_time = @toml.TomlDateTime(@tokenize.LocalTime("10:30:00"))
  let time_str = local_time.to_string()
  inspect(time_str, content="10:30:00")
}

///| Test float token parsing to ensure coverage
test "float_token_parsing" {
  let toml_input = "pi = 3.14159"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=["TomlTable", { "pi": ["TomlFloat", 3.14159] }])
}

///| Test array with trailing comma
test "array_with_trailing_comma" {
  let toml_input = "numbers = [1, 2, 3,]"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
      ],
    },
  ])
}

///| Test to increase coverage of main function components
test "main_function_components_coverage" {
  // This test exercises the same functions as main() to improve coverage
  let str_val = @toml.TomlString("Hello, TOML!")
  let int_val = @toml.TomlInteger(42L)
  let bool_val = @toml.TomlBoolean(true)

  // Call to_string methods to match main function behavior
  inspect(str_val.to_string(), content="\"Hello, TOML!\"")
  inspect(int_val.to_string(), content="42")
  inspect(bool_val.to_string(), content="true")

  // Create and manipulate arrays like in main
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  inspect(array_val.to_string(), content="[1, 2, 3]")

  // Test parsing like in main function
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  let result1 = @toml.parse(toml_input)
  inspect(result1.to_string().contains("John Doe"), content="true")

  // Test array parsing
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  let result2 = @toml.parse(toml_array)
  inspect(result2.to_string().contains("[1, 2, 3, 4, 5]"), content="true")

  // Test inline table parsing
  let toml_table = "person = {name = \"Alice\", age = 25}"
  let result3 = @toml.parse(toml_table)
  inspect(result3.to_string().contains("Alice"), content="true")
}

///| Test binary number parsing via hex format
test "hex_number_parsing_coverage" {
  let toml_input = "hex_num = 0xDEADBEEF"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    { "hex_num": ["TomlInteger", "3735928559"] },
  ])
}

///| Test octal number parsing
test "octal_number_parsing_coverage" {
  let toml_input = "octal_num = 0o755"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    { "octal_num": ["TomlInteger", "493"] },
  ])
}

///| Test binary number parsing
test "binary_number_parsing_coverage" {
  let toml_input = "binary_num = 0b1010"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    { "binary_num": ["TomlInteger", "10"] },
  ])
}

///| Test multiple array of tables to exercise array appending logic
test "multiple_array_of_tables" {
  let toml_input = "[[products]]\nname = \"Hammer\"\n\n[[products]]\nname = \"Nail\""
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    {
      "products": [
        "TomlArray",
        [
          ["TomlTable", { "name": ["TomlString", "Hammer"] }],
          ["TomlTable", { "name": ["TomlString", "Nail"] }],
        ],
      ],
    },
  ])
}

///| Test negative number parsing
test "negative_number_parsing" {
  let toml_input = "negative = -42"
  let result = @toml.parse(toml_input)
  @json.inspect(result, content=[
    "TomlTable",
    { "negative": ["TomlInteger", "-42"] },
  ])
}

///| Test error handling with invalid characters
test "invalid_character_error" {
  try {
    ignore(@toml.parse("key = @invalid"))
    inspect(false, content="true") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected error
  }
}

///| Test multiline basic string with line ending backslash
test "multiline_string_line_ending_backslash" {
  let toml_input = "multiline = \"\"\"\nLine 1 \\\n    Line 2\"\"\""
  let result = @toml.parse(toml_input)
  match result {
    @toml.TomlTable(table) =>
      match table.get("multiline") {
        Some(@toml.TomlString(str)) =>
          // Should have whitespace trimmed after backslash
          inspect(
            str.contains("Line 1") && str.contains("Line 2"),
            content="true",
          )
        _ => inspect(false, content="true")
      }
    _ => inspect(false, content="true")
  }
}
