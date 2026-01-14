///| Comprehensive datetime lexer tests to validate refactored read_datetime_with_loc

///|
/// Test LocalTime parsing - 2-digit start pattern
test "lexer datetime LocalTime basic" {
  let tokens = @tokenize.tokenize(
    (
      #|time = 07:32:00
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "07:32:00"], { "loc": "1:8-1:16" }],
    ["EOF", { "loc": "1:16-1:16" }],
  ])
}

///|
/// Test LocalTime with fractional seconds
test "lexer datetime LocalTime with fractional seconds" {
  let tokens = @tokenize.tokenize(
    (
      #|time = 07:32:00.999999
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "07:32:00.999999"], { "loc": "1:8-1:23" }],
    ["EOF", { "loc": "1:23-1:23" }],
  ])
}

///|
/// Test LocalTime edge cases - midnight and end of day
test "lexer datetime LocalTime edge times" {
  let tokens1 = @tokenize.tokenize(
    (
      #|time = 00:00:00
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "00:00:00"], { "loc": "1:8-1:16" }],
    ["EOF", { "loc": "1:16-1:16" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|time = 23:59:59
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "23:59:59"], { "loc": "1:8-1:16" }],
    ["EOF", { "loc": "1:16-1:16" }],
  ])
}

///|
/// Test LocalDate parsing - 4-digit start, no time component
test "lexer datetime LocalDate basic" {
  let tokens = @tokenize.tokenize(
    (
      #|date = 1979-05-27
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "1979-05-27"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
}

///|
/// Test LocalDate edge cases - various years
test "lexer datetime LocalDate various years" {
  // Historical date
  let tokens1 = @tokenize.tokenize(
    (
      #|date = 1900-01-01
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "1900-01-01"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
  // Far future date
  let tokens2 = @tokenize.tokenize(
    (
      #|date = 9999-12-31
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "9999-12-31"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
  // Leap year date
  let tokens3 = @tokenize.tokenize(
    (
      #|date = 2024-02-29
    ),
  )
  json_inspect(tokens3, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "2024-02-29"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
}

///|
/// Test LocalDateTime - date with T and time, no timezone
test "lexer datetime LocalDateTime basic" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "1979-05-27T07:32:00"],
      { "loc": "1:12-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
}

///|
/// Test LocalDateTime with fractional seconds
test "lexer datetime LocalDateTime with fractional seconds" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00.999999
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "1979-05-27T00:32:00.999999"],
      { "loc": "1:12-1:38" },
    ],
    ["EOF", { "loc": "1:38-1:38" }],
  ])
}

///|
/// Test OffsetDateTime with Z (UTC)
test "lexer datetime OffsetDateTime with Z" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00Z
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T07:32:00Z"],
      { "loc": "1:12-1:32" },
    ],
    ["EOF", { "loc": "1:32-1:32" }],
  ])
}

///|
/// Test OffsetDateTime with Z and fractional seconds
test "lexer datetime OffsetDateTime Z with fractional" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00.123456Z
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T07:32:00.123456Z"],
      { "loc": "1:12-1:39" },
    ],
    ["EOF", { "loc": "1:39-1:39" }],
  ])
}

///|
/// Test OffsetDateTime with positive offset
test "lexer datetime OffsetDateTime positive offset" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00+07:00
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T00:32:00+07:00"],
      { "loc": "1:12-1:37" },
    ],
    ["EOF", { "loc": "1:37-1:37" }],
  ])
}

///|
/// Test OffsetDateTime with negative offset
test "lexer datetime OffsetDateTime negative offset" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00-07:00
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T00:32:00-07:00"],
      { "loc": "1:12-1:37" },
    ],
    ["EOF", { "loc": "1:37-1:37" }],
  ])
}

///|
/// Test OffsetDateTime with offset and fractional seconds
test "lexer datetime OffsetDateTime offset with fractional" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00.999999-07:00
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "datetime", { "loc": "1:1-1:9" }],
    ["Equals", { "loc": "1:10-1:11" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T00:32:00.999999-07:00"],
      { "loc": "1:12-1:44" },
    ],
    ["EOF", { "loc": "1:44-1:44" }],
  ])
}

///|
/// Test OffsetDateTime with various timezone offsets
test "lexer datetime OffsetDateTime various offsets" {
  // +00:00 (UTC)
  let tokens1 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00+00:00
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-01-01T12:00:00+00:00"],
      { "loc": "1:6-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
  // -00:00 (UTC)
  let tokens2 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00-00:00
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-01-01T12:00:00-00:00"],
      { "loc": "1:6-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
  // +14:00 (max positive)
  let tokens3 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00+14:00
    ),
  )
  json_inspect(tokens3, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-01-01T12:00:00+14:00"],
      { "loc": "1:6-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
  // -12:00 (max negative)
  let tokens4 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00-12:00
    ),
  )
  json_inspect(tokens4, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-01-01T12:00:00-12:00"],
      { "loc": "1:6-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
  // Half-hour offset (India +05:30)
  let tokens5 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00+05:30
    ),
  )
  json_inspect(tokens5, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-01-01T12:00:00+05:30"],
      { "loc": "1:6-1:31" },
    ],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
}

///|
/// Test multiple datetime values in same TOML
test "lexer datetime multiple datetimes" {
  let tokens = @tokenize.tokenize(
    (
      #|time = 12:30:00
      #|date = 2023-06-15
      #|local_dt = 2023-06-15T12:30:00
      #|offset_dt = 2023-06-15T12:30:00Z
    ),
  )
  // Just verify token types are correct for each
  json_inspect(tokens, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "12:30:00"], { "loc": "1:8-1:16" }],
    ["Newline", { "loc": "1:16-2:1" }],
    ["Identifier", "date", { "loc": "2:1-2:5" }],
    ["Equals", { "loc": "2:6-2:7" }],
    ["DateTimeToken", ["LocalDate", "2023-06-15"], { "loc": "2:8-2:18" }],
    ["Newline", { "loc": "2:18-3:1" }],
    ["Identifier", "local_dt", { "loc": "3:1-3:9" }],
    ["Equals", { "loc": "3:10-3:11" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "2023-06-15T12:30:00"],
      { "loc": "3:12-3:31" },
    ],
    ["Newline", { "loc": "3:31-4:1" }],
    ["Identifier", "offset_dt", { "loc": "4:1-4:10" }],
    ["Equals", { "loc": "4:11-4:12" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2023-06-15T12:30:00Z"],
      { "loc": "4:13-4:33" },
    ],
    ["EOF", { "loc": "4:33-4:33" }],
  ])
}

///|
/// Test datetime in array context
test "lexer datetime in array" {
  let tokens = @tokenize.tokenize(
    (
      #|dates = [2023-01-01, 2023-06-15, 2023-12-31]
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "dates", { "loc": "1:1-1:6" }],
    ["Equals", { "loc": "1:7-1:8" }],
    ["LeftBracket", { "loc": "1:9-1:10" }],
    ["DateTimeToken", ["LocalDate", "2023-01-01"], { "loc": "1:10-1:20" }],
    ["Comma", { "loc": "1:20-1:21" }],
    ["DateTimeToken", ["LocalDate", "2023-06-15"], { "loc": "1:22-1:32" }],
    ["Comma", { "loc": "1:32-1:33" }],
    ["DateTimeToken", ["LocalDate", "2023-12-31"], { "loc": "1:34-1:44" }],
    ["RightBracket", { "loc": "1:44-1:45" }],
    ["EOF", { "loc": "1:45-1:45" }],
  ])
}

///|
/// Test datetime followed by comment
test "lexer datetime with comment" {
  let tokens = @tokenize.tokenize(
    (
      #|date = 2023-06-15 # deployment date
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "2023-06-15"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:36-1:36" }],
  ])
}

///|
/// Test LocalTime with various fractional second precisions
test "lexer datetime LocalTime fractional precision" {
  // 1 digit
  let tokens1 = @tokenize.tokenize(
    (
      #|time = 12:30:45.1
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "12:30:45.1"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
  // 3 digits (milliseconds)
  let tokens2 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "12:30:45.123"], { "loc": "1:8-1:20" }],
    ["EOF", { "loc": "1:20-1:20" }],
  ])
  // 6 digits (microseconds)
  let tokens3 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123456
    ),
  )
  json_inspect(tokens3, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalTime", "12:30:45.123456"], { "loc": "1:8-1:23" }],
    ["EOF", { "loc": "1:23-1:23" }],
  ])
  // 9 digits (nanoseconds)
  let tokens4 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123456789
    ),
  )
  json_inspect(tokens4, content=[
    ["Identifier", "time", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["LocalTime", "12:30:45.123456789"],
      { "loc": "1:8-1:26" },
    ],
    ["EOF", { "loc": "1:26-1:26" }],
  ])
}

///|
/// Test inline table with datetime
test "lexer datetime in inline table" {
  let tokens = @tokenize.tokenize(
    (
      #|event = { date = 2023-06-15, time = 09:00:00 }
    ),
  )
  json_inspect(tokens, content=[
    ["Identifier", "event", { "loc": "1:1-1:6" }],
    ["Equals", { "loc": "1:7-1:8" }],
    ["LeftBrace", { "loc": "1:9-1:10" }],
    ["Identifier", "date", { "loc": "1:11-1:15" }],
    ["Equals", { "loc": "1:16-1:17" }],
    ["DateTimeToken", ["LocalDate", "2023-06-15"], { "loc": "1:18-1:28" }],
    ["Comma", { "loc": "1:28-1:29" }],
    ["Identifier", "time", { "loc": "1:30-1:34" }],
    ["Equals", { "loc": "1:35-1:36" }],
    ["DateTimeToken", ["LocalTime", "09:00:00"], { "loc": "1:37-1:45" }],
    ["RightBrace", { "loc": "1:46-1:47" }],
    ["EOF", { "loc": "1:47-1:47" }],
  ])
}

///|
/// Test datetime disambiguation - similar patterns
test "lexer datetime disambiguation" {
  // Date followed by something that's NOT a time (no T)
  // This should parse as LocalDate only
  let tokens1 = @tokenize.tokenize(
    (
      #|date = 2023-06-15
      #|other = 123
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "2023-06-15"], { "loc": "1:8-1:18" }],
    ["Newline", { "loc": "1:18-2:1" }],
    ["Identifier", "other", { "loc": "2:1-2:6" }],
    ["Equals", { "loc": "2:7-2:8" }],
    ["IntegerToken", "123", { "loc": "2:9-2:12" }],
    ["EOF", { "loc": "2:12-2:12" }],
  ])
}

///|
/// Test TOML spec RFC 3339 examples
test "lexer datetime RFC 3339 spec examples" {
  // Examples from TOML 1.0 spec
  let tokens1 = @tokenize.tokenize(
    (
      #|odt1 = 1979-05-27T07:32:00Z
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "odt1", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T07:32:00Z"],
      { "loc": "1:8-1:28" },
    ],
    ["EOF", { "loc": "1:28-1:28" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|odt2 = 1979-05-27T00:32:00-07:00
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "odt2", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T00:32:00-07:00"],
      { "loc": "1:8-1:33" },
    ],
    ["EOF", { "loc": "1:33-1:33" }],
  ])
  let tokens3 = @tokenize.tokenize(
    (
      #|odt3 = 1979-05-27T00:32:00.999999-07:00
    ),
  )
  json_inspect(tokens3, content=[
    ["Identifier", "odt3", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T00:32:00.999999-07:00"],
      { "loc": "1:8-1:40" },
    ],
    ["EOF", { "loc": "1:40-1:40" }],
  ])
  let tokens4 = @tokenize.tokenize(
    (
      #|ldt1 = 1979-05-27T07:32:00
    ),
  )
  json_inspect(tokens4, content=[
    ["Identifier", "ldt1", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "1979-05-27T07:32:00"],
      { "loc": "1:8-1:27" },
    ],
    ["EOF", { "loc": "1:27-1:27" }],
  ])
  let tokens5 = @tokenize.tokenize(
    (
      #|ldt2 = 1979-05-27T00:32:00.999999
    ),
  )
  json_inspect(tokens5, content=[
    ["Identifier", "ldt2", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "1979-05-27T00:32:00.999999"],
      { "loc": "1:8-1:34" },
    ],
    ["EOF", { "loc": "1:34-1:34" }],
  ])
  let tokens6 = @tokenize.tokenize(
    (
      #|ld1 = 1979-05-27
    ),
  )
  json_inspect(tokens6, content=[
    ["Identifier", "ld1", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["DateTimeToken", ["LocalDate", "1979-05-27"], { "loc": "1:7-1:17" }],
    ["EOF", { "loc": "1:17-1:17" }],
  ])
  let tokens7 = @tokenize.tokenize(
    (
      #|lt1 = 07:32:00
    ),
  )
  json_inspect(tokens7, content=[
    ["Identifier", "lt1", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["DateTimeToken", ["LocalTime", "07:32:00"], { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
  let tokens8 = @tokenize.tokenize(
    (
      #|lt2 = 00:32:00.999999
    ),
  )
  json_inspect(tokens8, content=[
    ["Identifier", "lt2", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["DateTimeToken", ["LocalTime", "00:32:00.999999"], { "loc": "1:7-1:22" }],
    ["EOF", { "loc": "1:22-1:22" }],
  ])
}

///|
/// Test year boundary dates
test "lexer datetime year boundaries" {
  // Start of year
  let tokens1 = @tokenize.tokenize(
    (
      #|date = 2023-01-01
    ),
  )
  json_inspect(tokens1, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "2023-01-01"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
  // End of year
  let tokens2 = @tokenize.tokenize(
    (
      #|date = 2023-12-31
    ),
  )
  json_inspect(tokens2, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["DateTimeToken", ["LocalDate", "2023-12-31"], { "loc": "1:8-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
  // New Year's Eve 23:59:59
  let tokens3 = @tokenize.tokenize(
    (
      #|dt = 2023-12-31T23:59:59
    ),
  )
  json_inspect(tokens3, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["LocalDateTime", "2023-12-31T23:59:59"],
      { "loc": "1:6-1:25" },
    ],
    ["EOF", { "loc": "1:25-1:25" }],
  ])
  // New Year's Day 00:00:00
  let tokens4 = @tokenize.tokenize(
    (
      #|dt = 2024-01-01T00:00:00Z
    ),
  )
  json_inspect(tokens4, content=[
    ["Identifier", "dt", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "2024-01-01T00:00:00Z"],
      { "loc": "1:6-1:26" },
    ],
    ["EOF", { "loc": "1:26-1:26" }],
  ])
}
