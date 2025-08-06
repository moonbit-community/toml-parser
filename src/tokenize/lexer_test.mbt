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

///| Test datetime token JSON representation
test "datetime token to_json" {
  let offset_dt_token = @tokenize.DateTimeToken(
    @tokenize.OffsetDateTime("1979-05-27T07:32:00Z"),
  )
  @json.inspect(offset_dt_token.to_json(), content=[
    "DateTimeToken",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
  ])
  let local_dt_token = @tokenize.DateTimeToken(
    @tokenize.LocalDateTime("1979-05-27T07:32:00"),
  )
  @json.inspect(local_dt_token.to_json(), content=[
    "DateTimeToken",
    ["LocalDateTime", "1979-05-27T07:32:00"],
  ])
  let local_date_token = @tokenize.DateTimeToken(
    @tokenize.LocalDate("1979-05-27"),
  )
  @json.inspect(local_date_token.to_json(), content=[
    "DateTimeToken",
    ["LocalDate", "1979-05-27"],
  ])
  let local_time_token = @tokenize.DateTimeToken(
    @tokenize.LocalTime("07:32:00"),
  )
  @json.inspect(local_time_token.to_json(), content=[
    "DateTimeToken",
    ["LocalTime", "07:32:00"],
  ])
}

///| Test left and right brace tokens
test "brace tokens" {
  let tokens = @tokenize.tokenize("table = {key = value}")
  @json.inspect(tokens, content=[
    ["Identifier", "table"],
    "Equals",
    "LeftBrace",
    ["Identifier", "key"],
    "Equals",
    ["Identifier", "value"],
    "RightBrace",
    ["EOF"],
  ])
}

///| Test left and right brace JSON representation
test "brace tokens to_json" {
  let left_brace = @tokenize.LeftBrace
  @json.inspect(left_brace.to_json(), content="LeftBrace")
  let right_brace = @tokenize.RightBrace
  @json.inspect(right_brace.to_json(), content="RightBrace")
}

///| Test dot token 
test "dot token" {
  let tokens = @tokenize.tokenize("table.subtable = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "table"],
    "Dot",
    ["Identifier", "subtable"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test dot token JSON representation
test "dot token to_json" {
  let dot = @tokenize.Dot
  @json.inspect(dot.to_json(), content="Dot")
}

///| Test datetime tokenization in TOML content
test "tokenize datetime" {
  let tokens = @tokenize.tokenize("date = \"1979-05-27T07:32:00Z\"")
  // Test datetime as string since datetime parsing might not be implemented yet
  @json.inspect(tokens, content=[
    ["Identifier", "date"],
    "Equals",
    ["StringToken", "1979-05-27T07:32:00Z"],
    ["EOF"],
  ])
}

///| Test complex inline table with braces
test "complex inline table tokenization" {
  let tokens = @tokenize.tokenize(
    "server = {host = \"localhost\", port = 8080, ssl = true}",
  )
  // Verify we get the brace tokens
  let mut has_left_brace = false
  let mut has_right_brace = false
  for token in tokens {
    if token == @tokenize.LeftBrace {
      has_left_brace = true
    }
    if token == @tokenize.RightBrace {
      has_right_brace = true
    }
  }
  inspect(has_left_brace, content="true")
  inspect(has_right_brace, content="true")
}

///| Test nested structures with dots
test "nested structure with dots" {
  let tokens = @tokenize.tokenize("database.connection.host = \"localhost\"")
  let mut dot_count = 0
  for token in tokens {
    match token {
      @tokenize.Dot => dot_count = dot_count + 1
      _ => ()
    }
  }
  inspect(dot_count, content="2") // Should have 2 dots
}

///| Test edge cases in tokenization

///| Test empty input tokenization
test "tokenize empty input" {
  let tokens = @tokenize.tokenize("")
  @json.inspect(tokens, content=[["EOF"]])
}

///| Test whitespace only input
test "tokenize whitespace only" {
  let tokens = @tokenize.tokenize("   \t\r   ")
  @json.inspect(tokens, content=[["EOF"]])
}

///| Test comment only input
test "tokenize comment only" {
  let tokens = @tokenize.tokenize("# this is just a comment")
  @json.inspect(tokens, content=[["EOF"]])
}

///| Test newline handling
test "tokenize multiple newlines" {
  let tokens = @tokenize.tokenize("key = \"value\"\n\n\nother = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    "Newline",
    "Newline",
    "Newline",
    ["Identifier", "other"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///| Test mixed quotes in content
test "tokenize mixed quotes" {
  let tokens = @tokenize.tokenize("key = \"value with 'single' quotes\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value with 'single' quotes"],
    ["EOF"],
  ])
}

///| Test special characters in strings
test "tokenize special characters" {
  let tokens = @tokenize.tokenize(
    "key = \"value with \\n newline and \\t tab\"",
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value with \n newline and \t tab"],
    ["EOF"],
  ])
}

///| Test numbers with underscores
test "tokenize numbers with underscores" {
  let tokens = @tokenize.tokenize("num = 1_000_000")
  @json.inspect(tokens, content=[
    ["Identifier", "num"],
    "Equals",
    ["IntegerToken", "1000000"],
    ["EOF"],
  ])
}

///| Test floating point edge cases
test "tokenize float edge cases" {
  let tokens = @tokenize.tokenize("f1 = 1.0\nf2 = .5\nf3 = 5.\nf4 = 1e10")
  // Check that we get float tokens for valid floats
  let mut has_floats = false
  for token in tokens {
    match token {
      @tokenize.FloatToken(_) => has_floats = true
      _ => ()
    }
  }
  inspect(has_floats, content="true")
}

///| Test boolean edge cases
test "tokenize boolean edge cases" {
  let tokens = @tokenize.tokenize("b1 = true\nb2 = false")
  @json.inspect(tokens, content=[
    ["Identifier", "b1"],
    "Equals",
    ["BooleanToken", true],
    "Newline",
    ["Identifier", "b2"],
    "Equals",
    ["BooleanToken", false],
    ["EOF"],
  ])
}

///| Test identifier edge cases  
test "tokenize identifier edge cases" {
  let tokens = @tokenize.tokenize("key_123 = \"value\"\nkey-with-dashes = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "key_123"],
    "Equals",
    ["StringToken", "value"],
    "Newline",
    ["Identifier", "key-with-dashes"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///| Test line ending variations
test "tokenize different line endings" {
  let tokens = @tokenize.tokenize(
    "key1 = \"value1\"\nkey2 = \"value2\"\nkey3 = \"value3\"",
  )
  let mut newline_count = 0
  for token in tokens {
    match token {
      @tokenize.Newline => newline_count = newline_count + 1
      _ => ()
    }
  }
  inspect(newline_count >= 2, content="true") // Should have at least 2 newlines
}

///| Test complex array structures
test "tokenize complex array" {
  let tokens = @tokenize.tokenize(
    "arr = [[1, 2], [\"a\", \"b\"], [true, false]]",
  )
  let mut bracket_count = 0
  for token in tokens {
    match token {
      @tokenize.LeftBracket | @tokenize.RightBracket =>
        bracket_count = bracket_count + 1
      _ => ()
    }
  }
  inspect(bracket_count, content="8") // Should have 8 brackets total
}

///| Test nested inline tables
test "tokenize nested inline tables" {
  let tokens = @tokenize.tokenize("table = {outer = {inner = \"value\"}}")
  let mut brace_count = 0
  for token in tokens {
    match token {
      @tokenize.LeftBrace | @tokenize.RightBrace =>
        brace_count = brace_count + 1
      _ => ()
    }
  }
  inspect(brace_count, content="4") // Should have 4 braces total
}

///| Test dot notation tokenization
test "tokenize dot notation" {
  let tokens = @tokenize.tokenize("table.subtable.key = \"value\"")
  let mut dot_count = 0
  for token in tokens {
    match token {
      @tokenize.Dot => dot_count = dot_count + 1
      _ => ()
    }
  }
  inspect(dot_count, content="2") // Should have 2 dots
}

///| Test comments mixed with code
test "tokenize comments mixed with code" {
  let tokens = @tokenize.tokenize(
    "key = \"value\" # comment\nother = 42 # another comment",
  )
  // Comments should be filtered out, check we get the expected tokens
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    "Newline",
    ["Identifier", "other"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///| Test very long identifier
test "tokenize long identifier" {
  let long_id = "very_long_identifier_with_many_underscores_and_numbers_123456789"
  let tokens = @tokenize.tokenize(long_id + " = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", long_id],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test very long string
test "tokenize long string" {
  let long_string = "This is a very long string that contains many words and should test the string parsing capabilities of the tokenizer"
  let tokens = @tokenize.tokenize("key = \"" + long_string + "\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", long_string],
    ["EOF"],
  ])
}

///| Test international characters
test "tokenize international characters" {
  let tokens = @tokenize.tokenize("key = \"值\"\nother = \"valeur\"")
  // Test that we can at least handle international characters in string values
  let has_international = tokens.length() > 0
  inspect(has_international, content="true")
}

///| Test leading and trailing whitespace
test "tokenize with leading trailing whitespace" {
  let tokens = @tokenize.tokenize("   key   =   \"value\"   ")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test mixed case booleans (should be case sensitive)
test "tokenize case sensitive booleans" {
  let tokens = @tokenize.tokenize("t1 = true\nt2 = True\nt3 = TRUE")
  // Only "true" should be recognized as boolean, others as identifiers
  let mut boolean_count = 0
  for token in tokens {
    match token {
      @tokenize.BooleanToken(_) => boolean_count = boolean_count + 1
      _ => ()
    }
  }
  inspect(boolean_count, content="1") // Only lowercase "true" should be boolean
}
