///| Tests for Token enum variants and ToJson implementation
///| This tests uncovered token types to improve coverage

test "test DateTimeToken ToJson" {
  // Test the uncovered DateTimeToken case in ToJson implementation
  let dt = @tokenize.TomlDateTime::OffsetDateTime("1979-05-27T07:32:00Z")
  let token = @tokenize.DateTimeToken(dt)
  let json = token.to_json()
  
  // Should return ["DateTimeToken", dt] format
  match json {
    Array([String("DateTimeToken"), _]) => assert_true(true)
    _ => assert_true(false)
  }
}

test "test LeftBrace token ToJson" {
  // Test the uncovered LeftBrace case in ToJson implementation
  let token = @tokenize.LeftBrace
  let json = token.to_json()
  
  assert_eq(json, "LeftBrace")
}

test "test RightBrace token ToJson" {
  // Test the uncovered RightBrace case in ToJson implementation
  let token = @tokenize.RightBrace
  let json = token.to_json()
  
  assert_eq(json, "RightBrace")
}

test "test Dot token ToJson" {
  // Test the uncovered Dot case in ToJson implementation
  let token = @tokenize.Dot
  let json = token.to_json()
  
  assert_eq(json, "Dot")
}

test "test TomlDateTime types" {
  // Test different DateTime types for completeness
  let offset_dt = @tokenize.TomlDateTime::OffsetDateTime("1979-05-27T07:32:00Z")
  let local_dt = @tokenize.TomlDateTime::LocalDateTime("1979-05-27T07:32:00")
  let local_date = @tokenize.TomlDateTime::LocalDate("1979-05-27")
  let local_time = @tokenize.TomlDateTime::LocalTime("07:32:00")
  
  // Test that they can be created and compared
  assert_eq(offset_dt, @tokenize.TomlDateTime::OffsetDateTime("1979-05-27T07:32:00Z"))
  assert_eq(local_dt, @tokenize.TomlDateTime::LocalDateTime("1979-05-27T07:32:00"))
  assert_eq(local_date, @tokenize.TomlDateTime::LocalDate("1979-05-27"))
  assert_eq(local_time, @tokenize.TomlDateTime::LocalTime("07:32:00"))
}