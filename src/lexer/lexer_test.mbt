///| Tests for the TOML lexer
test "tokenize simple key-value" {
  let tokens = @lexer.tokenize("key = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///|
test "tokenize integer" {
  let tokens = @lexer.tokenize("number = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "number"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///|
test "tokenize float" {
  let tokens = @lexer.tokenize("pi = 3.14")
  @json.inspect(tokens, content=[
    ["Identifier", "pi"],
    "Equals",
    ["FloatToken", 3.14],
    ["EOF"],
  ])
}

///|
test "tokenize boolean" {
  let tokens = @lexer.tokenize("enabled = true")
  @json.inspect(tokens, content=[
    ["Identifier", "enabled"],
    "Equals",
    ["BooleanToken", true],
    ["EOF"],
  ])
}

///|
test "tokenize array syntax" {
  let tokens = @lexer.tokenize("[1, 2, 3]")
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
  let tokens = @lexer.tokenize("key = \"value\" # this is a comment")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ]) // comment ignored
}

///|
test "tokenize multiline" {
  let tokens = @lexer.tokenize("key1 = \"value1\"\nkey2 = 42")
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
  let tokens = @lexer.tokenize(str)
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
