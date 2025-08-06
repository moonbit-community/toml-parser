///| Tests for the TOML lexer
test "tokenize simple key-value" {
  let tokens = @tokenize.tokenize("key = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///|
test "tokenize integer" {
  let tokens = @tokenize.tokenize("number = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "number"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///|
test "tokenize float" {
  let tokens = @tokenize.tokenize("pi = 3.14")
  @json.inspect(tokens, content=[
    ["Identifier", "pi"],
    "Equals",
    ["FloatToken", 3.14],
    ["EOF"],
  ])
}

///|
test "tokenize boolean" {
  let tokens = @tokenize.tokenize("enabled = true")
  @json.inspect(tokens, content=[
    ["Identifier", "enabled"],
    "Equals",
    ["BooleanToken", true],
    ["EOF"],
  ])
}

///|
test "tokenize array syntax" {
  let tokens = @tokenize.tokenize("[1, 2, 3]")
  @json.inspect(tokens, content=[
    "LeftBracket",
    ["IntegerToken", "1"],
    "Comma",
    ["IntegerToken", "2"],
    "Comma",
    ["IntegerToken", "3"],
    "RightBracket",
    ["EOF"],
  ])
}

///|
test "tokenize with comments" {
  let tokens = @tokenize.tokenize("key = \"value\" # this is a comment")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ]) // comment ignored
}

///|
test "tokenize multiline" {
  let tokens = @tokenize.tokenize("key1 = \"value1\"\nkey2 = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "key1"],
    "Equals",
    ["StringToken", "value1"],
    "Newline",
    ["Identifier", "key2"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///|
test "unicode or emoji" {
  let str =
    #|key1 = "💩"
    #|key2 = "💩"
  let tokens = @tokenize.tokenize(str)
  @json.inspect(tokens, content=[
    ["Identifier", "key1"],
    "Equals",
    ["StringToken", "💩"],
    "Newline",
    ["Identifier", "key2"],
    "Equals",
    ["StringToken", "💩"],
    ["EOF"],
  ])
  // more tests

}

///| Test ToJson for DateTimeToken - cover uncovered DateTimeToken branch
test "token to_json datetime token" {
  let offset_dt_token = @tokenize.DateTimeToken(
    @tokenize.OffsetDateTime("2023-01-01T00:00:00Z"),
  )
  @json.inspect(offset_dt_token.to_json(), content=[
    "DateTimeToken",
    ["OffsetDateTime", "2023-01-01T00:00:00Z"],
  ])
  let local_dt_token = @tokenize.DateTimeToken(
    @tokenize.LocalDateTime("2023-01-01T00:00:00"),
  )
  @json.inspect(local_dt_token.to_json(), content=[
    "DateTimeToken",
    ["LocalDateTime", "2023-01-01T00:00:00"],
  ])
  let local_date_token = @tokenize.DateTimeToken(
    @tokenize.LocalDate("2023-01-01"),
  )
  @json.inspect(local_date_token.to_json(), content=[
    "DateTimeToken",
    ["LocalDate", "2023-01-01"],
  ])
  let local_time_token = @tokenize.DateTimeToken(
    @tokenize.LocalTime("12:30:45"),
  )
  @json.inspect(local_time_token.to_json(), content=[
    "DateTimeToken",
    ["LocalTime", "12:30:45"],
  ])
}

///| Test ToJson for brace tokens - cover uncovered LeftBrace and RightBrace branches
test "token to_json brace tokens" {
  let left_brace = @tokenize.LeftBrace
  @json.inspect(left_brace.to_json(), content="LeftBrace")
  let right_brace = @tokenize.RightBrace
  @json.inspect(right_brace.to_json(), content="RightBrace")
}

///| Test ToJson for dot token - cover uncovered Dot branch
test "token to_json dot token" {
  let dot_token = @tokenize.Dot
  @json.inspect(dot_token.to_json(), content="Dot")
}

///| Test tokenization that produces brace and dot tokens for coverage
test "tokenize inline table with braces" {
  let tokens = @tokenize.tokenize("person = {name = \"John\"}")
  @json.inspect(tokens, content=[
    ["Identifier", "person"],
    "Equals",
    "LeftBrace",
    ["Identifier", "name"],
    "Equals",
    ["StringToken", "John"],
    "RightBrace",
    ["EOF"],
  ])
}

///| Test tokenization with dot notation (for future dotted keys support)
test "tokenize with dots" {
  let tokens = @tokenize.tokenize("a.b = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "a"],
    "Dot",
    ["Identifier", "b"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test edge cases for tokenizer to improve coverage

///| Test tokenizing hexadecimal numbers
test "tokenize hexadecimal numbers" {
  let tokens1 = @tokenize.tokenize("hex = 0x1F")
  @json.inspect(tokens1, content=[
    ["Identifier", "hex"],
    "Equals",
    ["IntegerToken", "31"], // 0x1F = 31
    ["EOF"],
  ])
  let tokens2 = @tokenize.tokenize("hex2 = 0X1f")
  @json.inspect(tokens2, content=[
    ["Identifier", "hex2"],
    "Equals",
    ["IntegerToken", "31"], // 0X1f = 31
    ["EOF"],
  ])
}

///| Test tokenizing octal numbers
test "tokenize octal numbers" {
  let tokens1 = @tokenize.tokenize("oct = 0o17")
  @json.inspect(tokens1, content=[
    ["Identifier", "oct"],
    "Equals",
    ["IntegerToken", "15"], // 0o17 = 15
    ["EOF"],
  ])
  let tokens2 = @tokenize.tokenize("oct2 = 0O17")
  @json.inspect(tokens2, content=[
    ["Identifier", "oct2"],
    "Equals",
    ["IntegerToken", "15"], // 0O17 = 15
    ["EOF"],
  ])
}

///| Test tokenizing binary numbers
test "tokenize binary numbers" {
  let tokens1 = @tokenize.tokenize("bin = 0b1010")
  @json.inspect(tokens1, content=[
    ["Identifier", "bin"],
    "Equals",
    ["IntegerToken", "10"], // 0b1010 = 10
    ["EOF"],
  ])
  let tokens2 = @tokenize.tokenize("bin2 = 0B1010")
  @json.inspect(tokens2, content=[
    ["Identifier", "bin2"],
    "Equals",
    ["IntegerToken", "10"], // 0B1010 = 10
    ["EOF"],
  ])
}

///| Test negative numbers (covers negative number parsing)
test "tokenize negative numbers" {
  let tokens1 = @tokenize.tokenize("neg = -42")
  @json.inspect(tokens1, content=[
    ["Identifier", "neg"],
    "Equals",
    ["IntegerToken", "-42"],
    ["EOF"],
  ])
  let tokens2 = @tokenize.tokenize("neg_float = -3.14")
  @json.inspect(tokens2, content=[
    ["Identifier", "neg_float"],
    "Equals",
    ["FloatToken", -3.14],
    ["EOF"],
  ])

  // Note: Negative hex might not be directly supported in all implementations
  // It would tokenize as separate tokens: "-", "0", "x10"
}

///| Test numbers with underscores (TOML allows underscores in numbers)
test "tokenize numbers with underscores" {
  let tokens1 = @tokenize.tokenize("big_num = 1_000_000")
  @json.inspect(tokens1, content=[
    ["Identifier", "big_num"],
    "Equals",
    ["IntegerToken", "1000000"],
    ["EOF"],
  ])
  let tokens2 = @tokenize.tokenize("float_num = 3.141_592_653")
  @json.inspect(tokens2, content=[
    ["Identifier", "float_num"],
    "Equals",
    ["FloatToken", 3.141592653],
    ["EOF"],
  ])
}

///| Test literal strings (single quotes)
test "tokenize literal strings" {
  let tokens = @tokenize.tokenize("path = 'C:\\\\Windows\\\\System32'")
  @json.inspect(tokens, content=[
    ["Identifier", "path"],
    "Equals",
    ["StringToken", "C:\\\\Windows\\\\System32"],
    ["EOF"],
  ])
}

///| Test error cases for invalid characters
test "tokenize invalid characters" {
  try {
    let _ = @tokenize.tokenize("key = @invalid")
    fail("Should have failed on invalid character @")
  } catch {
    _ => () // Expected failure
  }
}

///| Test error cases for invalid negative signs
test "tokenize invalid negative signs" {
  try {
    let _ = @tokenize.tokenize("key = -abc")
    fail("Should have failed on invalid negative identifier")
  } catch {
    _ => () // Expected failure
  }
}

///| Test basic string with escapes
test "tokenize basic string with escapes" {
  let tokens = @tokenize.tokenize("str = \"Hello\\nWorld\"")
  @json.inspect(tokens, content=[
    ["Identifier", "str"],
    "Equals",
    ["StringToken", "Hello\nWorld"], // Escape sequences are processed
    ["EOF"],
  ])
}

///| Test complex whitespace and formatting
test "tokenize with complex whitespace" {
  let tokens = @tokenize.tokenize(
    "  key1  =   \"value1\"   ,   key2   =   42   ",
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key1"],
    "Equals",
    ["StringToken", "value1"],
    "Comma",
    ["Identifier", "key2"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///| Test multiple comment lines
test "tokenize multiple comments" {
  let tokens = @tokenize.tokenize(
    "# First comment\nkey = \"value\" # Inline comment\n# Final comment",
  )
  @json.inspect(tokens, content=[
    "Newline",
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    "Newline",
    ["EOF"],
  ])
}

///| Test zero handling in special number formats
test "tokenize zero in special formats" {
  // Test zero not being interpreted as special format
  let tokens1 = @tokenize.tokenize("zero = 0")
  @json.inspect(tokens1, content=[
    ["Identifier", "zero"],
    "Equals",
    ["IntegerToken", "0"],
    ["EOF"],
  ])

  // Test 0 followed by non-special character
  let tokens2 = @tokenize.tokenize("num = 01")
  @json.inspect(tokens2, content=[
    ["Identifier", "num"],
    "Equals",
    ["IntegerToken", "1"], // Leading zero is dropped in normal integer
    ["EOF"],
  ])
}

///| Test float parsing edge cases
test "tokenize float edge cases" {
  // Test float starting with zero
  let tokens1 = @tokenize.tokenize("float = 0.5")
  @json.inspect(tokens1, content=[
    ["Identifier", "float"],
    "Equals",
    ["FloatToken", 0.5],
    ["EOF"],
  ])

  // Test very small float
  let tokens2 = @tokenize.tokenize("small = 0.001")
  @json.inspect(tokens2, content=[
    ["Identifier", "small"],
    "Equals",
    ["FloatToken", 0.001],
    ["EOF"],
  ])
}
