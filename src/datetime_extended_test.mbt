///| Extended datetime tests for improved coverage
test "test TomlDateTime types and equality" {
  let offset_dt1 = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let offset_dt2 = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let offset_dt3 = @tokenize.OffsetDateTime("1980-05-27T07:32:00Z")
  inspect(offset_dt1 == offset_dt2, content="true")
  inspect(offset_dt1 == offset_dt3, content="false")
  let local_dt = @tokenize.LocalDateTime("1979-05-27T07:32:00")
  let local_date = @tokenize.LocalDate("1979-05-27")
  let local_time = @tokenize.LocalTime("07:32:00")
  inspect(offset_dt1 == local_dt, content="false")
  inspect(local_dt == local_date, content="false")
  inspect(local_date == local_time, content="false")
}

///|
test "test datetime token JSON serialization" {
  let offset_dt = @tokenize.OffsetDateTime("1979-05-27T07:32:00+01:00")
  let token = @tokenize.DateTimeToken(offset_dt)

  // Test that datetime token can be serialized to JSON
  let json_result = token.to_json()
  @json.inspect(json_result, content=[
    "DateTimeToken",
    ["OffsetDateTime", "1979-05-27T07:32:00+01:00"],
  ])
}

///|
test "test different datetime formats" {
  let local_dt = @tokenize.LocalDateTime("1979-05-27T07:32:00")
  let local_date = @tokenize.LocalDate("1979-05-27")
  let local_time = @tokenize.LocalTime("07:32:00")
  let offset_dt_z = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let offset_dt_plus = @tokenize.OffsetDateTime("1979-05-27T07:32:00+01:00")

  // Test Show implementation
  inspect(local_dt.to_string().contains("LocalDateTime"), content="true")
  inspect(local_date.to_string().contains("LocalDate"), content="true")
  inspect(local_time.to_string().contains("LocalTime"), content="true")
  inspect(offset_dt_z.to_string().contains("OffsetDateTime"), content="true")
  inspect(offset_dt_plus.to_string().contains("OffsetDateTime"), content="true")
}

///|
test "test datetime token creation and usage" {
  let dt = @tokenize.OffsetDateTime("2023-12-25T00:00:00Z")
  let token = @tokenize.DateTimeToken(dt)

  // Test token equality
  let same_token = @tokenize.DateTimeToken(
    @tokenize.OffsetDateTime("2023-12-25T00:00:00Z"),
  )
  let diff_token = @tokenize.DateTimeToken(
    @tokenize.OffsetDateTime("2023-12-26T00:00:00Z"),
  )
  inspect(token == same_token, content="true")
  inspect(token == diff_token, content="false")
}
