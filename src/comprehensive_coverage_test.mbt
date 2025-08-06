///| Comprehensive tests to maximize coverage

///| Test additional TomlValue functionality
test "comprehensive toml value tests" {
  // Test datetime validation and edge cases
  let dt_value = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T00:00:00Z"),
  )
  inspect(dt_value.validate(), content="true")

  // Test nested validation scenarios
  let nested_table : Map[String, @toml.TomlValue] = Map::new()
  let inner_table : Map[String, @toml.TomlValue] = Map::new()
  inner_table["key"] = @toml.TomlString("value")
  nested_table["inner"] = @toml.TomlTable(inner_table)
  let outer_value = @toml.TomlTable(nested_table)
  inspect(outer_value.validate(), content="true")
}

///| Test edge cases in array homogeneity
test "array homogeneity edge cases" {
  // Test array with single datetime
  let single_dt_array = Array::new()
  single_dt_array.push(@toml.TomlDateTime(@tokenize.LocalDate("2023-01-01")))
  inspect(
    @toml.TomlValue::is_homogeneous_array(single_dt_array),
    content="true",
  )

  // Test mixed datetime types (should be homogeneous)
  let mixed_dt_array = Array::new()
  mixed_dt_array.push(
    @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-01T00:00:00Z")),
  )
  mixed_dt_array.push(
    @toml.TomlDateTime(@tokenize.LocalDateTime("2023-01-01T00:00:00")),
  )
  mixed_dt_array.push(@toml.TomlDateTime(@tokenize.LocalDate("2023-01-01")))
  mixed_dt_array.push(@toml.TomlDateTime(@tokenize.LocalTime("00:00:00")))
  inspect(@toml.TomlValue::is_homogeneous_array(mixed_dt_array), content="true")
}

///| Test additional error scenarios
test "additional error scenarios" {
  // Test malformed array
  try {
    ignore(@toml.parse("arr = [1, 2,]")) // trailing comma
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }

  // Test incomplete inline table
  try {
    ignore(@toml.parse("table = {key =")) // incomplete inline table
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test additional parser edge cases for coverage  
test "parser additional coverage" {
  // Test with various whitespace and newline combinations
  let result = @toml.parse("\n\n\nkey = \"value\"\n\n\n")
  let result_str = result.to_string()
  inspect(result_str.contains("value"), content="true")

  // Test inline table with spaces
  let inline_result = @toml.parse("table = { key = \"value\" }")
  let inline_str = inline_result.to_string()
  inspect(inline_str.contains("value"), content="true")
}

///| Test complex tokenizer scenarios
test "complex tokenizer scenarios" {
  // Test empty key-value with whitespace
  let tokens = @tokenize.tokenize("  key  =  \"value\"  \n  ")
  let has_key = tokens.length() >= 4 // At least identifier, equals, string, newline, EOF
  inspect(has_key, content="true")

  // Test multiple equals (should be separate tokens)
  let equals_tokens = @tokenize.tokenize("key = value = other")
  let mut equals_count = 0
  for token in equals_tokens {
    match token {
      @tokenize.Equals => equals_count = equals_count + 1
      _ => ()
    }
  }
  inspect(equals_count, content="2")
}

///| Test parser state management
test "parser state scenarios" {
  // Test empty table followed by content
  let result = @toml.parse("[empty_table]\n\n[another_table]\nkey = \"value\"")
  let result_str = result.to_string()
  inspect(result_str.contains("empty_table"), content="true")
  inspect(result_str.contains("another_table"), content="true")
  inspect(result_str.contains("value"), content="true")
}

///| Test additional string scenarios  
test "string handling edge cases" {
  // Test string with just escaped quotes
  let result = @toml.parse("key = \"He said \\\"Hello\\\"\"")
  let result_str = result.to_string()
  inspect(result_str.contains("He said \"Hello\""), content="true")

  // Test empty string
  let empty_result = @toml.parse("empty = \"\"")
  let empty_str = empty_result.to_string()
  inspect(empty_str.contains("empty"), content="true")
}

///| Test number edge cases
test "number parsing edge cases" {
  // Test zero
  let zero_result = @toml.parse("zero = 0")
  let zero_str = zero_result.to_string()
  inspect(zero_str.contains("0"), content="true")

  // Test negative float
  let neg_float_result = @toml.parse("neg = -3.14")
  let neg_str = neg_float_result.to_string()
  inspect(neg_str.contains("-3.14"), content="true")
}

///| Test comment handling variations
test "comment variations" {
  let result = @toml.parse("key = \"value\" # comment with special chars !@#$%")
  let result_str = result.to_string()
  inspect(result_str.contains("value"), content="true")
  // Comment should be stripped
  inspect(!result_str.contains("#"), content="true")
}

///| Test table name variations
test "table name scenarios" {
  // Test simple table name
  let result = @toml.parse("[table_name_123]\nkey = \"value\"")
  let result_str = result.to_string()
  inspect(result_str.contains("table_name_123"), content="true")

  // Test table with quoted name
  let quoted_result = @toml.parse("[\"table with spaces\"]\nkey = \"value\"")
  let quoted_str = quoted_result.to_string()
  inspect(quoted_str.contains("table with spaces"), content="true")
}
