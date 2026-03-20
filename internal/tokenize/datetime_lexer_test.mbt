///| Comprehensive datetime lexer tests to validate refactored read_datetime_with_loc

///|
/// Test LocalTime parsing - 2-digit start pattern
test "lexer datetime LocalTime basic" {
  let tokens = @tokenize.tokenize(
    (
      #|time = 07:32:00
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("07:32:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 16 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 16 } }),
      #|]
    ),
  )
}

///|
/// Test LocalTime with fractional seconds
test "lexer datetime LocalTime with fractional seconds" {
  let tokens = @tokenize.tokenize(
    (
      #|time = 07:32:00.999999
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("07:32:00.999999"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 23 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 23 }, end: { line: 1, column: 23 } }),
      #|]
    ),
  )
}

///|
/// Test LocalTime edge cases - midnight and end of day
test "lexer datetime LocalTime edge times" {
  let tokens1 = @tokenize.tokenize(
    (
      #|time = 00:00:00
    ),
  )
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("00:00:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 16 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 16 } }),
      #|]
    ),
  )
  let tokens2 = @tokenize.tokenize(
    (
      #|time = 23:59:59
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("23:59:59"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 16 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 16 } }),
      #|]
    ),
  )
}

///|
/// Test LocalDate parsing - 4-digit start, no time component
test "lexer datetime LocalDate basic" {
  let tokens = @tokenize.tokenize(
    (
      #|date = 1979-05-27
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("1979-05-27"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("1900-01-01"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
  // Far future date
  let tokens2 = @tokenize.tokenize(
    (
      #|date = 9999-12-31
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("9999-12-31"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
  // Leap year date
  let tokens3 = @tokenize.tokenize(
    (
      #|date = 2024-02-29
    ),
  )
  debug_inspect(
    tokens3,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2024-02-29"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
}

///|
/// Test LocalDateTime - date with T and time, no timezone
test "lexer datetime LocalDateTime basic" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("1979-05-27T07:32:00"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
}

///|
/// Test LocalDateTime with fractional seconds
test "lexer datetime LocalDateTime with fractional seconds" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00.999999
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("1979-05-27T00:32:00.999999"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 38 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 38 }, end: { line: 1, column: 38 } }),
      #|]
    ),
  )
}

///|
/// Test OffsetDateTime with Z (UTC)
test "lexer datetime OffsetDateTime with Z" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00Z
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T07:32:00Z"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 32 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 32 }, end: { line: 1, column: 32 } }),
      #|]
    ),
  )
}

///|
/// Test OffsetDateTime with Z and fractional seconds
test "lexer datetime OffsetDateTime Z with fractional" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T07:32:00.123456Z
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T07:32:00.123456Z"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 39 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 39 }, end: { line: 1, column: 39 } }),
      #|]
    ),
  )
}

///|
/// Test OffsetDateTime with positive offset
test "lexer datetime OffsetDateTime positive offset" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00+07:00
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T00:32:00+07:00"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 37 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 37 }, end: { line: 1, column: 37 } }),
      #|]
    ),
  )
}

///|
/// Test OffsetDateTime with negative offset
test "lexer datetime OffsetDateTime negative offset" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00-07:00
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T00:32:00-07:00"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 37 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 37 }, end: { line: 1, column: 37 } }),
      #|]
    ),
  )
}

///|
/// Test OffsetDateTime with offset and fractional seconds
test "lexer datetime OffsetDateTime offset with fractional" {
  let tokens = @tokenize.tokenize(
    (
      #|datetime = 1979-05-27T00:32:00.999999-07:00
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "datetime",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 11 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T00:32:00.999999-07:00"),
      #|    loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 44 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 44 }, end: { line: 1, column: 44 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-01-01T12:00:00+00:00"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
  // -00:00 (UTC)
  let tokens2 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00-00:00
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-01-01T12:00:00-00:00"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
  // +14:00 (max positive)
  let tokens3 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00+14:00
    ),
  )
  debug_inspect(
    tokens3,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-01-01T12:00:00+14:00"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
  // -12:00 (max negative)
  let tokens4 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00-12:00
    ),
  )
  debug_inspect(
    tokens4,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-01-01T12:00:00-12:00"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
  // Half-hour offset (India +05:30)
  let tokens5 = @tokenize.tokenize(
    (
      #|dt = 2023-01-01T12:00:00+05:30
    ),
  )
  debug_inspect(
    tokens5,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-01-01T12:00:00+05:30"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 31 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 31 }, end: { line: 1, column: 31 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("12:30:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 16 } },
      #|  ),
      #|  Newline(loc={ start: { line: 1, column: 16 }, end: { line: 2, column: 1 } }),
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 2, column: 1 }, end: { line: 2, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 2, column: 6 }, end: { line: 2, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-06-15"),
      #|    loc={ start: { line: 2, column: 8 }, end: { line: 2, column: 18 } },
      #|  ),
      #|  Newline(loc={ start: { line: 2, column: 18 }, end: { line: 3, column: 1 } }),
      #|  Identifier(
      #|    "local_dt",
      #|    loc={ start: { line: 3, column: 1 }, end: { line: 3, column: 9 } },
      #|  ),
      #|  Equals(loc={ start: { line: 3, column: 10 }, end: { line: 3, column: 11 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("2023-06-15T12:30:00"),
      #|    loc={ start: { line: 3, column: 12 }, end: { line: 3, column: 31 } },
      #|  ),
      #|  Newline(loc={ start: { line: 3, column: 31 }, end: { line: 4, column: 1 } }),
      #|  Identifier(
      #|    "offset_dt",
      #|    loc={ start: { line: 4, column: 1 }, end: { line: 4, column: 10 } },
      #|  ),
      #|  Equals(loc={ start: { line: 4, column: 11 }, end: { line: 4, column: 12 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2023-06-15T12:30:00Z"),
      #|    loc={ start: { line: 4, column: 13 }, end: { line: 4, column: 33 } },
      #|  ),
      #|  EOF(loc={ start: { line: 4, column: 33 }, end: { line: 4, column: 33 } }),
      #|]
    ),
  )
}

///|
/// Test datetime in array context
test "lexer datetime in array" {
  let tokens = @tokenize.tokenize(
    (
      #|dates = [2023-01-01, 2023-06-15, 2023-12-31]
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "dates",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 6 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 8 } }),
      #|  LeftBracket(loc={ start: { line: 1, column: 9 }, end: { line: 1, column: 10 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-01-01"),
      #|    loc={ start: { line: 1, column: 10 }, end: { line: 1, column: 20 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 20 }, end: { line: 1, column: 21 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-06-15"),
      #|    loc={ start: { line: 1, column: 22 }, end: { line: 1, column: 32 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 32 }, end: { line: 1, column: 33 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-12-31"),
      #|    loc={ start: { line: 1, column: 34 }, end: { line: 1, column: 44 } },
      #|  ),
      #|  RightBracket(loc={ start: { line: 1, column: 44 }, end: { line: 1, column: 45 } }),
      #|  EOF(loc={ start: { line: 1, column: 45 }, end: { line: 1, column: 45 } }),
      #|]
    ),
  )
}

///|
/// Test datetime followed by comment
test "lexer datetime with comment" {
  let tokens = @tokenize.tokenize(
    (
      #|date = 2023-06-15 # deployment date
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-06-15"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 36 }, end: { line: 1, column: 36 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("12:30:45.1"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
  // 3 digits (milliseconds)
  let tokens2 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("12:30:45.123"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 20 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 20 }, end: { line: 1, column: 20 } }),
      #|]
    ),
  )
  // 6 digits (microseconds)
  let tokens3 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123456
    ),
  )
  debug_inspect(
    tokens3,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("12:30:45.123456"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 23 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 23 }, end: { line: 1, column: 23 } }),
      #|]
    ),
  )
  // 9 digits (nanoseconds)
  let tokens4 = @tokenize.tokenize(
    (
      #|time = 12:30:45.123456789
    ),
  )
  debug_inspect(
    tokens4,
    content=(
      #|[
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalTime("12:30:45.123456789"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 26 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 26 }, end: { line: 1, column: 26 } }),
      #|]
    ),
  )
}

///|
/// Test inline table with datetime
test "lexer datetime in inline table" {
  let tokens = @tokenize.tokenize(
    (
      #|event = { date = 2023-06-15, time = 09:00:00 }
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "event",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 6 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 8 } }),
      #|  LeftBrace(loc={ start: { line: 1, column: 9 }, end: { line: 1, column: 10 } }),
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 11 }, end: { line: 1, column: 15 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 17 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-06-15"),
      #|    loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 28 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 28 }, end: { line: 1, column: 29 } }),
      #|  Identifier(
      #|    "time",
      #|    loc={ start: { line: 1, column: 30 }, end: { line: 1, column: 34 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 35 }, end: { line: 1, column: 36 } }),
      #|  DateTimeToken(
      #|    LocalTime("09:00:00"),
      #|    loc={ start: { line: 1, column: 37 }, end: { line: 1, column: 45 } },
      #|  ),
      #|  RightBrace(loc={ start: { line: 1, column: 46 }, end: { line: 1, column: 47 } }),
      #|  EOF(loc={ start: { line: 1, column: 47 }, end: { line: 1, column: 47 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-06-15"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  Newline(loc={ start: { line: 1, column: 18 }, end: { line: 2, column: 1 } }),
      #|  Identifier(
      #|    "other",
      #|    loc={ start: { line: 2, column: 1 }, end: { line: 2, column: 6 } },
      #|  ),
      #|  Equals(loc={ start: { line: 2, column: 7 }, end: { line: 2, column: 8 } }),
      #|  IntegerToken(
      #|    123,
      #|    loc={ start: { line: 2, column: 9 }, end: { line: 2, column: 12 } },
      #|  ),
      #|  EOF(loc={ start: { line: 2, column: 12 }, end: { line: 2, column: 12 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "odt1",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T07:32:00Z"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 28 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 28 }, end: { line: 1, column: 28 } }),
      #|]
    ),
  )
  let tokens2 = @tokenize.tokenize(
    (
      #|odt2 = 1979-05-27T00:32:00-07:00
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "odt2",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T00:32:00-07:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 33 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 33 }, end: { line: 1, column: 33 } }),
      #|]
    ),
  )
  let tokens3 = @tokenize.tokenize(
    (
      #|odt3 = 1979-05-27T00:32:00.999999-07:00
    ),
  )
  debug_inspect(
    tokens3,
    content=(
      #|[
      #|  Identifier(
      #|    "odt3",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T00:32:00.999999-07:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 40 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 40 }, end: { line: 1, column: 40 } }),
      #|]
    ),
  )
  let tokens4 = @tokenize.tokenize(
    (
      #|ldt1 = 1979-05-27T07:32:00
    ),
  )
  debug_inspect(
    tokens4,
    content=(
      #|[
      #|  Identifier(
      #|    "ldt1",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("1979-05-27T07:32:00"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 27 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 27 }, end: { line: 1, column: 27 } }),
      #|]
    ),
  )
  let tokens5 = @tokenize.tokenize(
    (
      #|ldt2 = 1979-05-27T00:32:00.999999
    ),
  )
  debug_inspect(
    tokens5,
    content=(
      #|[
      #|  Identifier(
      #|    "ldt2",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("1979-05-27T00:32:00.999999"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 34 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 34 }, end: { line: 1, column: 34 } }),
      #|]
    ),
  )
  let tokens6 = @tokenize.tokenize(
    (
      #|ld1 = 1979-05-27
    ),
  )
  debug_inspect(
    tokens6,
    content=(
      #|[
      #|  Identifier(
      #|    "ld1",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  DateTimeToken(
      #|    LocalDate("1979-05-27"),
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 17 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 17 }, end: { line: 1, column: 17 } }),
      #|]
    ),
  )
  let tokens7 = @tokenize.tokenize(
    (
      #|lt1 = 07:32:00
    ),
  )
  debug_inspect(
    tokens7,
    content=(
      #|[
      #|  Identifier(
      #|    "lt1",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  DateTimeToken(
      #|    LocalTime("07:32:00"),
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 15 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 15 }, end: { line: 1, column: 15 } }),
      #|]
    ),
  )
  let tokens8 = @tokenize.tokenize(
    (
      #|lt2 = 00:32:00.999999
    ),
  )
  debug_inspect(
    tokens8,
    content=(
      #|[
      #|  Identifier(
      #|    "lt2",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  DateTimeToken(
      #|    LocalTime("00:32:00.999999"),
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 22 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 22 }, end: { line: 1, column: 22 } }),
      #|]
    ),
  )
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
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-01-01"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
  // End of year
  let tokens2 = @tokenize.tokenize(
    (
      #|date = 2023-12-31
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    LocalDate("2023-12-31"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 18 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 18 }, end: { line: 1, column: 18 } }),
      #|]
    ),
  )
  // New Year's Eve 23:59:59
  let tokens3 = @tokenize.tokenize(
    (
      #|dt = 2023-12-31T23:59:59
    ),
  )
  debug_inspect(
    tokens3,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("2023-12-31T23:59:59"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 25 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 25 }, end: { line: 1, column: 25 } }),
      #|]
    ),
  )
  // New Year's Day 00:00:00
  let tokens4 = @tokenize.tokenize(
    (
      #|dt = 2024-01-01T00:00:00Z
    ),
  )
  debug_inspect(
    tokens4,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("2024-01-01T00:00:00Z"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 26 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 26 }, end: { line: 1, column: 26 } }),
      #|]
    ),
  )
}
