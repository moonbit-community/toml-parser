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

///| Test DateTimeToken to_json
test "DateTimeToken to_json" {
  let dt = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let token = @tokenize.DateTimeToken(dt)
  @json.inspect(token, content=[
    "DateTimeToken",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
  ])
}

///| Test LeftBrace token to_json  
test "LeftBrace token to_json" {
  let token = @tokenize.LeftBrace
  @json.inspect(token, content="LeftBrace")
}

///| Test RightBrace token to_json
test "RightBrace token to_json" {
  let token = @tokenize.RightBrace
  @json.inspect(token, content="RightBrace")
}

///| Test Dot token to_json
test "Dot token to_json" {
  let token = @tokenize.Dot
  @json.inspect(token, content="Dot")
}

///| Test tokenize inline table with braces
test "tokenize inline table with braces" {
  let tokens = @tokenize.tokenize("{name = \"test\"}")
  @json.inspect(tokens, content=[
    "LeftBrace",
    ["Identifier", "name"],
    "Equals",
    ["StringToken", "test"],
    "RightBrace",
    ["EOF"],
  ])
}

///| Test tokenize dotted key
test "tokenize dotted key" {
  let tokens = @tokenize.tokenize("table.key = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "table"],
    "Dot",
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test TomlDateTime variants to_json
test "TomlDateTime variants to_json" {
  let offset_dt = @tokenize.OffsetDateTime("1979-05-27T07:32:00+01:00")
  @json.inspect(offset_dt, content=[
    "OffsetDateTime", "1979-05-27T07:32:00+01:00",
  ])
  let local_dt = @tokenize.LocalDateTime("1979-05-27T07:32:00")
  @json.inspect(local_dt, content=["LocalDateTime", "1979-05-27T07:32:00"])
  let local_date = @tokenize.LocalDate("1979-05-27")
  @json.inspect(local_date, content=["LocalDate", "1979-05-27"])
  let local_time = @tokenize.LocalTime("07:32:00")
  @json.inspect(local_time, content=["LocalTime", "07:32:00"])
}

///| Test tokenize with escaped characters in strings
test "tokenize escaped characters" {
  let tokens = @tokenize.tokenize("key = \"hello\\nworld\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "hello\nworld"],
    ["EOF"],
  ])
}

///| Test tokenize with empty string
test "tokenize empty string" {
  let tokens = @tokenize.tokenize("key = \"\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", ""],
    ["EOF"],
  ])
}

///| Test tokenize with negative numbers
test "tokenize negative integer" {
  let tokens = @tokenize.tokenize("negative = -42")
  @json.inspect(tokens, content=[
    ["Identifier", "negative"],
    "Equals",
    ["IntegerToken", "-42"],
    ["EOF"],
  ])
}

///| Test tokenize with negative float
test "tokenize negative float" {
  let tokens = @tokenize.tokenize("negative_float = -3.14")
  @json.inspect(tokens, content=[
    ["Identifier", "negative_float"],
    "Equals",
    ["FloatToken", -3.14],
    ["EOF"],
  ])
}

///| Test tokenize boolean false
test "tokenize boolean false" {
  let tokens = @tokenize.tokenize("disabled = false")
  @json.inspect(tokens, content=[
    ["Identifier", "disabled"],
    "Equals",
    ["BooleanToken", false],
    ["EOF"],
  ])
}

///| Test tokenize complex inline table
test "tokenize complex inline table" {
  let tokens = @tokenize.tokenize("{a = 1, b = \"hello\", c = true}")
  @json.inspect(tokens, content=[
    "LeftBrace",
    ["Identifier", "a"],
    "Equals",
    ["IntegerToken", "1"],
    "Comma",
    ["Identifier", "b"],
    "Equals",
    ["StringToken", "hello"],
    "Comma",
    ["Identifier", "c"],
    "Equals",
    ["BooleanToken", true],
    "RightBrace",
    ["EOF"],
  ])
}

///| Test tokenize whitespace handling
test "tokenize with extra whitespace" {
  let tokens = @tokenize.tokenize("  key  =  \"value\"  ")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///| Test tokenize empty input
test "tokenize empty input" {
  let tokens = @tokenize.tokenize("")
  @json.inspect(tokens, content=[["EOF"]])
}

///| Test tokenize with just newlines
test "tokenize just newlines" {
  let tokens = @tokenize.tokenize("\n\n")
  @json.inspect(tokens, content=["Newline", "Newline", ["EOF"]])
}
