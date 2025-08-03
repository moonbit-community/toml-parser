///| Tests for the TOML lexer
test "tokenize simple key-value" {
  let tokens = @toml.tokenize("key = \"value\"").unwrap()
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ])
}

///|
test "tokenize integer" {
  let tokens = @toml.tokenize("number = 42").unwrap()
  @json.inspect(tokens, content=[
    ["Identifier", "number"],
    "Equals",
    ["IntegerToken", "42"],
    ["EOF"],
  ])
}

///|
test "tokenize float" {
  let tokens = @toml.tokenize("pi = 3.14").unwrap()
  @json.inspect(tokens, content=[
    ["Identifier", "pi"],
    "Equals",
    ["FloatToken", 3.14],
    ["EOF"],
  ])
}

///|
test "tokenize boolean" {
  let tokens = @toml.tokenize("enabled = true").unwrap()
  @json.inspect(tokens, content=[
    ["Identifier", "enabled"],
    "Equals",
    ["BooleanToken", true],
    ["EOF"],
  ])
}

///|
test "tokenize array syntax" {
  let tokens = @toml.tokenize("[1, 2, 3]").unwrap()
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
  let tokens = @toml.tokenize("key = \"value\" # this is a comment").unwrap()
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    ["EOF"],
  ]) // comment ignored
}

///|
test "tokenize multiline" {
  let tokens = @toml.tokenize("key1 = \"value1\"\nkey2 = 42").unwrap()
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
