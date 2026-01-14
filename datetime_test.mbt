///| Comprehensive datetime validation tests for TOML specification compliance

///|
/// Test TOML 1.0 spec examples for Offset Date-Time
test "toml spec offset datetime examples" {
  // RFC 3339 examples from TOML spec
  let odt1 = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("1979-05-27T07:32:00Z"),
  )
  inspect(odt1.to_string(), content="1979-05-27T07:32:00Z")
  let odt2 = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("1979-05-27T00:32:00-07:00"),
  )
  inspect(odt2.to_string(), content="1979-05-27T00:32:00-07:00")
  let odt3 = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("1979-05-27T00:32:00.999999-07:00"),
  )
  inspect(odt3.to_string(), content="1979-05-27T00:32:00.999999-07:00")
}

///|
/// Test TOML 1.0 spec examples for Local Date-Time  
test "toml spec local datetime examples" {
  let ldt1 = @toml.TomlDateTime(@tokenize.LocalDateTime("1979-05-27T07:32:00"))
  inspect(ldt1.to_string(), content="1979-05-27T07:32:00")
  let ldt2 = @toml.TomlDateTime(
    @tokenize.LocalDateTime("1979-05-27T00:32:00.999999"),
  )
  inspect(ldt2.to_string(), content="1979-05-27T00:32:00.999999")
}

///|
/// Test TOML 1.0 spec examples for Local Date
test "toml spec local date examples" {
  let ld1 = @toml.TomlDateTime(@tokenize.LocalDate("1979-05-27"))
  inspect(ld1.to_string(), content="1979-05-27")
  let ld2 = @toml.TomlDateTime(@tokenize.LocalDate("2023-12-31"))
  inspect(ld2.to_string(), content="2023-12-31")
  let ld3 = @toml.TomlDateTime(@tokenize.LocalDate("1900-01-01"))
  inspect(ld3.to_string(), content="1900-01-01")
}

///|
/// Test TOML 1.0 spec examples for Local Time
test "toml spec local time examples" {
  let lt1 = @toml.TomlDateTime(@tokenize.LocalTime("07:32:00"))
  inspect(lt1.to_string(), content="07:32:00")
  let lt2 = @toml.TomlDateTime(@tokenize.LocalTime("00:32:00.999999"))
  inspect(lt2.to_string(), content="00:32:00.999999")
}

///|
/// Test datetime arrays (homogeneous and mixed)
test "datetime arrays validation" {
  // Array of same datetime type (should be valid in TOML)
  let offset_array = Array::new()
  offset_array.push(
    @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-01T00:00:00Z")),
  )
  offset_array.push(
    @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-02T00:00:00Z")),
  )
  offset_array.push(
    @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-03T00:00:00Z")),
  )
  let offset_arr_value = @toml.TomlArray(offset_array)
  let offset_str = offset_arr_value.to_string()
  inspect(offset_str.contains("2023-01-01T00:00:00Z"), content="true")
  inspect(offset_str.contains("2023-01-02T00:00:00Z"), content="true")
  inspect(offset_str.contains("2023-01-03T00:00:00Z"), content="true")

  // Array of local dates
  let date_array = Array::new()
  date_array.push(@toml.TomlDateTime(@tokenize.LocalDate("2023-01-01")))
  date_array.push(@toml.TomlDateTime(@tokenize.LocalDate("2023-01-02")))
  date_array.push(@toml.TomlDateTime(@tokenize.LocalDate("2023-01-03")))
  let date_arr_value = @toml.TomlArray(date_array)
  let date_str = date_arr_value.to_string()
  inspect(date_str.contains("2023-01-01"), content="true")
  inspect(date_str.contains("2023-01-02"), content="true")
  inspect(date_str.contains("2023-01-03"), content="true")
}

///|
/// Test datetime in complex nested structures
test "datetime in nested structures" {
  let event_table : Map[String, @toml.TomlValue] = Map::new()
  event_table["name"] = @toml.TomlString("Conference 2023")
  event_table["start_date"] = @toml.TomlDateTime(
    @tokenize.LocalDate("2023-06-15"),
  )
  event_table["start_time"] = @toml.TomlDateTime(
    @tokenize.LocalTime("09:00:00"),
  )
  event_table["end_datetime"] = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-06-17T17:00:00"),
  )
  let sessions = Array::new()
  let session1 : Map[String, @toml.TomlValue] = Map::new()
  session1["title"] = @toml.TomlString("Opening Keynote")
  session1["scheduled_at"] = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-06-15T09:00:00+00:00"),
  )
  sessions.push(@toml.TomlTable(session1))
  let session2 : Map[String, @toml.TomlValue] = Map::new()
  session2["title"] = @toml.TomlString("Technical Workshop")
  session2["scheduled_at"] = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-06-15T14:00:00+00:00"),
  )
  sessions.push(@toml.TomlTable(session2))
  event_table["sessions"] = @toml.TomlArray(sessions)
  let event_value = @toml.TomlTable(event_table)
  let event_str = event_value.to_string()

  // Verify all datetime values are present
  inspect(event_str.contains("2023-06-15"), content="true")
  inspect(event_str.contains("09:00:00"), content="true")
  inspect(event_str.contains("2023-06-17T17:00:00"), content="true")
  inspect(event_str.contains("2023-06-15T09:00:00+00:00"), content="true")
  inspect(event_str.contains("2023-06-15T14:00:00+00:00"), content="true")
}

///|
/// Test edge cases for datetime formats
test "datetime format edge cases" {
  // Leap year dates
  let leap_year = @toml.TomlDateTime(@tokenize.LocalDate("2024-02-29"))
  inspect(leap_year.to_string(), content="2024-02-29")

  // End of year
  let new_years_eve = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-12-31T23:59:59"),
  )
  inspect(new_years_eve.to_string(), content="2023-12-31T23:59:59")

  // Start of year  
  let new_years_day = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2024-01-01T00:00:00Z"),
  )
  inspect(new_years_day.to_string(), content="2024-01-01T00:00:00Z")

  // Maximum precision fractional seconds
  let max_precision = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-01-01T12:00:00.123456789"),
  )
  inspect(max_precision.to_string(), content="2023-01-01T12:00:00.123456789")

  // Various timezone offsets
  let tz_positive = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00+14:00"),
  )
  inspect(tz_positive.to_string(), content="2023-01-01T12:00:00+14:00")
  let tz_negative = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00-12:00"),
  )
  inspect(tz_negative.to_string(), content="2023-01-01T12:00:00-12:00")
  let tz_half_hour = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00+05:30"),
  )
  inspect(tz_half_hour.to_string(), content="2023-01-01T12:00:00+05:30")
}

///|
/// Test datetime serialization and deserialization consistency
test "datetime serialization consistency" {
  let original_offset = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let toml_value = @toml.TomlDateTime(original_offset)
  let serialized = toml_value.to_string()

  // The serialized form should match the original
  inspect(serialized, content="1979-05-27T07:32:00Z")

  // Test with JSON conversion
  let json_repr = toml_value.to_json()
  json_inspect(json_repr, content=[
    "TomlDateTime",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
  ])
}

///|
/// Test datetime comparison and equality  
test "datetime comparison" {
  // Same datetime different representations should be equal
  let dt1 = @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-01T12:00:00Z"))
  let dt2 = @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-01T12:00:00Z"))
  inspect(dt1 == dt2, content="true")

  // Different datetimes should not be equal
  let dt3 = @toml.TomlDateTime(@tokenize.OffsetDateTime("2023-01-01T12:00:01Z"))
  inspect(dt1 == dt3, content="false")

  // Different datetime types should not be equal even with same time
  let local_dt = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-01-01T12:00:00"),
  )
  let offset_dt = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00Z"),
  )
  inspect(local_dt == offset_dt, content="false")
}

///|
/// Test historical and future dates
test "datetime historical and future dates" {
  // Historical dates
  let unix_epoch = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("1970-01-01T00:00:00Z"),
  )
  inspect(unix_epoch.to_string(), content="1970-01-01T00:00:00Z")
  let pre_unix = @toml.TomlDateTime(@tokenize.LocalDate("1969-12-31"))
  inspect(pre_unix.to_string(), content="1969-12-31")

  // Far future dates
  let far_future = @toml.TomlDateTime(@tokenize.LocalDate("3000-01-01"))
  inspect(far_future.to_string(), content="3000-01-01")

  // Y2K
  let y2k = @toml.TomlDateTime(@tokenize.LocalDateTime("2000-01-01T00:00:00"))
  inspect(y2k.to_string(), content="2000-01-01T00:00:00")
}

///|
/// Test timezone boundary cases
test "timezone boundary cases" {
  // UTC variants
  let utc_z = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00Z"),
  )
  let utc_plus = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00+00:00"),
  )
  let utc_minus = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00-00:00"),
  )
  inspect(utc_z.to_string(), content="2023-01-01T12:00:00Z")
  inspect(utc_plus.to_string(), content="2023-01-01T12:00:00+00:00")
  inspect(utc_minus.to_string(), content="2023-01-01T12:00:00-00:00")

  // Extreme timezone offsets (valid in spec)
  let max_positive = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00+14:00"),
  )
  let max_negative = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-01-01T12:00:00-12:00"),
  )
  inspect(max_positive.to_string(), content="2023-01-01T12:00:00+14:00")
  inspect(max_negative.to_string(), content="2023-01-01T12:00:00-12:00")
}

///|
/// Test realistic application scenarios
test "realistic datetime scenarios" {
  // Application configuration with various datetime needs
  let config : Map[String, @toml.TomlValue] = Map::new()

  // Deployment timestamp (offset datetime)
  config["deployed_at"] = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("2023-06-15T14:30:00+00:00"),
  )

  // Scheduled maintenance (local datetime - timezone agnostic)
  config["maintenance_window"] = @toml.TomlDateTime(
    @tokenize.LocalDateTime("2023-06-20T02:00:00"),
  )

  // License expiry (date only)
  config["license_expires"] = @toml.TomlDateTime(
    @tokenize.LocalDate("2024-12-31"),
  )

  // Daily backup time (time only)
  config["backup_time"] = @toml.TomlDateTime(@tokenize.LocalTime("03:00:00"))

  // Array of maintenance windows
  let maintenance_windows = Array::new()
  maintenance_windows.push(
    @toml.TomlDateTime(@tokenize.LocalDateTime("2023-06-20T02:00:00")),
  )
  maintenance_windows.push(
    @toml.TomlDateTime(@tokenize.LocalDateTime("2023-07-20T02:00:00")),
  )
  maintenance_windows.push(
    @toml.TomlDateTime(@tokenize.LocalDateTime("2023-08-20T02:00:00")),
  )
  config["maintenance_schedule"] = @toml.TomlArray(maintenance_windows)
  let config_value = @toml.TomlTable(config)
  let config_str = config_value.to_string()

  // Verify all datetime formats are preserved
  inspect(config_str.contains("2023-06-15T14:30:00+00:00"), content="true")
  inspect(config_str.contains("2023-06-20T02:00:00"), content="true")
  inspect(config_str.contains("2024-12-31"), content="true")
  inspect(config_str.contains("03:00:00"), content="true")
  inspect(config_str.contains("2023-07-20T02:00:00"), content="true")
  inspect(config_str.contains("2023-08-20T02:00:00"), content="true")
}
