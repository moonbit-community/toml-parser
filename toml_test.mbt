///|
/// Basic tests for TOML value types
test "toml string value" {
  let value = @toml.TomlString("hello world")
  inspect(value.to_string(), content="\"hello world\"")
}

///|
test "toml integer value" {
  let value = @toml.TomlInteger(42L)
  inspect(value.to_string(), content="42")
}

///|
test "toml float value" {
  let value = @toml.TomlFloat(3.14)
  inspect(value.to_string(), content="3.14")
}

///|
test "toml boolean value" {
  let true_value = @toml.TomlBoolean(true)
  let false_value = @toml.TomlBoolean(false)
  inspect(true_value.to_string(), content="true")
  inspect(false_value.to_string(), content="false")
}

///|
test "toml array value" {
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let value = @toml.TomlArray(arr)
  inspect(value.to_string(), content="[1, 2, 3]")
}

///|
test "toml table value" {
  let table : Map[String, @toml.TomlValue] = Map::new()
  table["key1"] = @toml.TomlString("value1")
  table["key2"] = @toml.TomlInteger(42L)
  let value = @toml.TomlTable(table)
  // Note: Map iteration order might vary, we'll test the contains functionality
  let str_repr = value.to_string()
  // Basic structure check
  inspect(str_repr.has_prefix("{") && str_repr.has_suffix("}"), content="false")
}

///|
/// Tests for datetime values - Offset DateTime
test "toml offset datetime value" {
  let offset_dt = @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z"))
  inspect(offset_dt.to_string(), content="1979-05-27T07:32:00Z")
  let offset_dt_with_tz = @toml.TomlDateTime(
    OffsetDateTime("1979-05-27T07:32:00+01:00"),
  )
  inspect(offset_dt_with_tz.to_string(), content="1979-05-27T07:32:00+01:00")
  let offset_dt_negative = @toml.TomlDateTime(
    OffsetDateTime("1979-05-27T07:32:00-05:00"),
  )
  inspect(offset_dt_negative.to_string(), content="1979-05-27T07:32:00-05:00")
}

///|
/// Tests for datetime values - Local DateTime
test "toml local datetime value" {
  let local_dt = @toml.TomlDateTime(LocalDateTime("1979-05-27T07:32:00"))
  inspect(local_dt.to_string(), content="1979-05-27T07:32:00")
  let local_dt_with_seconds = @toml.TomlDateTime(
    LocalDateTime("2023-12-25T15:30:45"),
  )
  inspect(local_dt_with_seconds.to_string(), content="2023-12-25T15:30:45")
  let local_dt_with_fractional = @toml.TomlDateTime(
    LocalDateTime("2023-12-25T15:30:45.123"),
  )
  inspect(
    local_dt_with_fractional.to_string(),
    content="2023-12-25T15:30:45.123",
  )
}

///|
/// Tests for datetime values - Local Date
test "toml local date value" {
  let local_date = @toml.TomlDateTime(LocalDate("1979-05-27"))
  inspect(local_date.to_string(), content="1979-05-27")
  let local_date_future = @toml.TomlDateTime(LocalDate("2025-12-31"))
  inspect(local_date_future.to_string(), content="2025-12-31")
  let local_date_past = @toml.TomlDateTime(LocalDate("1900-01-01"))
  inspect(local_date_past.to_string(), content="1900-01-01")
}

///|
/// Tests for datetime values - Local Time
test "toml local time value" {
  let local_time = @toml.TomlDateTime(LocalTime("07:32:00"))
  inspect(local_time.to_string(), content="07:32:00")
  let local_time_with_fractional = @toml.TomlDateTime(LocalTime("15:30:45.999"))
  inspect(local_time_with_fractional.to_string(), content="15:30:45.999")
  let local_time_midnight = @toml.TomlDateTime(LocalTime("00:00:00"))
  inspect(local_time_midnight.to_string(), content="00:00:00")
  let local_time_noon = @toml.TomlDateTime(LocalTime("12:00:00"))
  inspect(local_time_noon.to_string(), content="12:00:00")
}

///|
/// Tests for datetime JSON representation
test "toml datetime to_json" {
  let offset_dt = @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z"))
  @json.inspect(offset_dt.to_json(), content=[
    "TomlDateTime",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
  ])
  let local_dt = @toml.TomlDateTime(LocalDateTime("1979-05-27T07:32:00"))
  @json.inspect(local_dt.to_json(), content=[
    "TomlDateTime",
    ["LocalDateTime", "1979-05-27T07:32:00"],
  ])
  let local_date = @toml.TomlDateTime(LocalDate("1979-05-27"))
  @json.inspect(local_date.to_json(), content=[
    "TomlDateTime",
    ["LocalDate", "1979-05-27"],
  ])
  let local_time = @toml.TomlDateTime(LocalTime("07:32:00"))
  @json.inspect(local_time.to_json(), content=[
    "TomlDateTime",
    ["LocalTime", "07:32:00"],
  ])
}

///|
/// Tests for datetime equality
test "toml datetime equality" {
  let dt1 = @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z"))
  let dt2 = @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z"))
  let dt3 = @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:01Z"))
  inspect(dt1 == dt2, content="true")
  inspect(dt1 == dt3, content="false")
  let local_dt1 = @toml.TomlDateTime(LocalDateTime("2023-01-01T00:00:00"))
  let local_dt2 = @toml.TomlDateTime(LocalDateTime("2023-01-01T00:00:00"))
  inspect(local_dt1 == local_dt2, content="true")
}

///|
/// Tests for mixed datetime array
test "toml mixed datetime array" {
  let arr = Array::new()
  arr.push(@toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z")))
  arr.push(@toml.TomlDateTime(LocalDateTime("1979-05-27T07:32:00")))
  arr.push(@toml.TomlDateTime(LocalDate("1979-05-27")))
  arr.push(@toml.TomlDateTime(LocalTime("07:32:00")))
  let value = @toml.TomlArray(arr)
  let str_repr = value.to_string()

  // Check that it contains all the datetime values
  inspect(str_repr.contains("1979-05-27T07:32:00Z"), content="true")
  inspect(str_repr.contains("1979-05-27T07:32:00"), content="true")
  inspect(str_repr.contains("1979-05-27"), content="true")
  inspect(str_repr.contains("07:32:00"), content="true")
}

///|
/// Tests for datetime in table
test "toml datetime in table" {
  let table : Map[String, @toml.TomlValue] = Map::new()
  table["created_at"] = @toml.TomlDateTime(
    OffsetDateTime("2023-01-01T00:00:00Z"),
  )
  table["updated_at"] = @toml.TomlDateTime(LocalDateTime("2023-01-02T12:30:45"))
  table["birth_date"] = @toml.TomlDateTime(LocalDate("1990-05-15"))
  table["meeting_time"] = @toml.TomlDateTime(LocalTime("14:30:00"))
  let value = @toml.TomlTable(table)
  let str_repr = value.to_string()

  // Basic structure check and content verification
  inspect(str_repr.has_prefix("{") && str_repr.has_suffix("}"), content="false")
  inspect(str_repr.contains("2023-01-01T00:00:00Z"), content="true")
  inspect(str_repr.contains("2023-01-02T12:30:45"), content="true")
  inspect(str_repr.contains("1990-05-15"), content="true")
  inspect(str_repr.contains("14:30:00"), content="true")
}

///|
/// Tests for edge case datetime formats
test "toml datetime edge cases" {
  // Test with fractional seconds
  let dt_with_millis = @toml.TomlDateTime(
    OffsetDateTime("2023-01-01T00:00:00.123Z"),
  )
  inspect(dt_with_millis.to_string(), content="2023-01-01T00:00:00.123Z")
  let dt_with_micros = @toml.TomlDateTime(
    LocalDateTime("2023-01-01T00:00:00.123456"),
  )
  inspect(dt_with_micros.to_string(), content="2023-01-01T00:00:00.123456")

  // Test with different timezone formats
  let dt_with_tz_colon = @toml.TomlDateTime(
    OffsetDateTime("2023-01-01T00:00:00+05:30"),
  )
  inspect(dt_with_tz_colon.to_string(), content="2023-01-01T00:00:00+05:30")
  let dt_with_tz_no_colon = @toml.TomlDateTime(
    OffsetDateTime("2023-01-01T00:00:00+0530"),
  )
  inspect(dt_with_tz_no_colon.to_string(), content="2023-01-01T00:00:00+0530")
}

///|
/// Tests for parser creation  
test "parser creation" {
  let tokens = Array::new()
  let loc = @tokenize.default_loc()
  tokens.push(@tokenize.Identifier("key", loc~))
  tokens.push(@tokenize.Equals(loc~))
  tokens.push(@tokenize.StringToken("value", loc~))
  let parser = @toml.Parser::new(tokens)
  inspect(parser.position, content="0")
  inspect(parser.tokens.length(), content="3")
}

///|
/// Tests for datetime token creation
test "datetime token creation" {
  let loc = @tokenize.default_loc()
  let offset_dt_token = @tokenize.DateTimeToken(
    @tokenize.OffsetDateTime("1979-05-27T07:32:00Z"),
    loc~,
  )
  let local_dt_token = @tokenize.DateTimeToken(
    @tokenize.LocalDateTime("1979-05-27T07:32:00"),
    loc~,
  )
  let local_date_token = @tokenize.DateTimeToken(
    @tokenize.LocalDate("1979-05-27"),
    loc~,
  )
  let local_time_token = @tokenize.DateTimeToken(
    @tokenize.LocalTime("07:32:00"),
    loc~,
  )

  // Test that tokens can be created (basic instantiation test)
  guard offset_dt_token
    is @tokenize.DateTimeToken(@tokenize.OffsetDateTime("1979-05-27T07:32:00Z"))
  guard local_dt_token
    is @tokenize.DateTimeToken(@tokenize.LocalDateTime("1979-05-27T07:32:00"))
  guard local_date_token is @tokenize.DateTimeToken(@tokenize.LocalDate("1979-05-27"))
  guard local_time_token is @tokenize.DateTimeToken(@tokenize.LocalTime("07:32:00"))
}

///|
/// Tests for array homogeneity validation
test "array homogeneity validation" {
  // Homogeneous arrays (should be valid)
  let int_array = Array::new()
  int_array.push(@toml.TomlInteger(1L))
  int_array.push(@toml.TomlInteger(2L))
  int_array.push(@toml.TomlInteger(3L))
  inspect(@toml.TomlValue::is_homogeneous_array(int_array), content="true")
  let string_array = Array::new()
  string_array.push(@toml.TomlString("a"))
  string_array.push(@toml.TomlString("b"))
  string_array.push(@toml.TomlString("c"))
  inspect(@toml.TomlValue::is_homogeneous_array(string_array), content="true")
  let datetime_array = Array::new()
  datetime_array.push(
    @toml.TomlDateTime(OffsetDateTime("2023-01-01T00:00:00Z")),
  )
  datetime_array.push(@toml.TomlDateTime(LocalDateTime("2023-01-02T00:00:00")))
  datetime_array.push(@toml.TomlDateTime(LocalDate("2023-01-03")))
  inspect(@toml.TomlValue::is_homogeneous_array(datetime_array), content="true")

  // Empty array (should be valid)
  let empty_array = Array::new()
  inspect(@toml.TomlValue::is_homogeneous_array(empty_array), content="true")

  // Single element array (should be valid)
  let single_array = Array::new()
  single_array.push(@toml.TomlBoolean(true))
  inspect(@toml.TomlValue::is_homogeneous_array(single_array), content="true")
}

///|
/// Tests for heterogeneous arrays (should be invalid)
test "array heterogeneity detection" {
  // Mixed types (should be invalid)
  let mixed_array = Array::new()
  mixed_array.push(@toml.TomlInteger(1L))
  mixed_array.push(@toml.TomlString("hello"))
  mixed_array.push(@toml.TomlBoolean(true))
  inspect(@toml.TomlValue::is_homogeneous_array(mixed_array), content="false")

  // Numbers with different types (should be invalid in TOML)
  let mixed_numbers = Array::new()
  mixed_numbers.push(@toml.TomlInteger(1L))
  mixed_numbers.push(@toml.TomlFloat(2.5))
  inspect(@toml.TomlValue::is_homogeneous_array(mixed_numbers), content="false")

  // Mixed datetime and string (should be invalid)
  let mixed_dt_string = Array::new()
  mixed_dt_string.push(@toml.TomlDateTime(LocalDate("2023-01-01")))
  mixed_dt_string.push(@toml.TomlString("not a date"))
  inspect(
    @toml.TomlValue::is_homogeneous_array(mixed_dt_string),
    content="false",
  )
}

///|
/// Tests for TomlValue validation
test "toml value validation" {
  // Valid homogeneous array
  let valid_array = Array::new()
  valid_array.push(@toml.TomlInteger(1L))
  valid_array.push(@toml.TomlInteger(2L))
  let valid_toml_array = @toml.TomlArray(valid_array)
  inspect(valid_toml_array.validate(), content="true")

  // Invalid heterogeneous array
  let invalid_array = Array::new()
  invalid_array.push(@toml.TomlInteger(1L))
  invalid_array.push(@toml.TomlString("mixed"))
  let invalid_toml_array = @toml.TomlArray(invalid_array)
  inspect(invalid_toml_array.validate(), content="false")

  // Valid nested structure
  let valid_table : Map[String, @toml.TomlValue] = Map::new()
  let nested_array = Array::new()
  nested_array.push(@toml.TomlString("item1"))
  nested_array.push(@toml.TomlString("item2"))
  valid_table["items"] = @toml.TomlArray(nested_array)
  valid_table["count"] = @toml.TomlInteger(2L)
  let valid_nested = @toml.TomlTable(valid_table)
  inspect(valid_nested.validate(), content="true")

  // Invalid nested structure (contains invalid array)
  let invalid_table : Map[String, @toml.TomlValue] = Map::new()
  let bad_nested_array = Array::new()
  bad_nested_array.push(@toml.TomlString("item1"))
  bad_nested_array.push(@toml.TomlInteger(42L)) // Mixed types
  invalid_table["items"] = @toml.TomlArray(bad_nested_array)
  invalid_table["count"] = @toml.TomlInteger(2L)
  let invalid_nested = @toml.TomlTable(invalid_table)
  inspect(invalid_nested.validate(), content="false")

  // Simple values should always be valid
  inspect(@toml.TomlString("hello").validate(), content="true")
  inspect(@toml.TomlInteger(42L).validate(), content="true")
  inspect(@toml.TomlFloat(3.14).validate(), content="true")
  inspect(@toml.TomlBoolean(true).validate(), content="true")
  inspect(
    @toml.TomlDateTime(OffsetDateTime("2023-01-01T00:00:00Z")).validate(),
    content="true",
  )
}
