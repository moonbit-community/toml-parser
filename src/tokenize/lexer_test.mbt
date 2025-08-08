///| Tests for the TOML lexer
test "tokenize simple key-value" {
  let tokens = @tokenize.tokenize("key = \"value\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    "EOF",
  ])
}

///|
test "tokenize integer" {
  let tokens = @tokenize.tokenize("number = 42")
  @json.inspect(tokens, content=[
    ["Identifier", "number"],
    "Equals",
    ["IntegerToken", "42"],
    "EOF",
  ])
}

///|
test "tokenize float" {
  let tokens = @tokenize.tokenize("pi = 3.14")
  @json.inspect(tokens, content=[
    ["Identifier", "pi"],
    "Equals",
    ["FloatToken", 3.14],
    "EOF",
  ])
}

///|
test "tokenize boolean" {
  let tokens = @tokenize.tokenize("enabled = true")
  @json.inspect(tokens, content=[
    ["Identifier", "enabled"],
    "Equals",
    ["BooleanToken", true],
    "EOF",
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
    "EOF",
  ])
}

///|
test "tokenize with comments" {
  let tokens = @tokenize.tokenize("key = \"value\" # this is a comment")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "value"],
    "EOF",
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
    "EOF",
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
    "EOF",
  ])
  // more tests

}

///| Test uncovered Token JSON serialization methods
test "test DateTimeToken JSON serialization" {
  let dt = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let token = @tokenize.DateTimeToken(dt)
  @json.inspect(token, content=[
    "DateTimeToken",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
  ])
}

///|
test "test LeftBrace token JSON serialization" {
  let tokens = @tokenize.tokenize("{}")
  @json.inspect(tokens, content=["LeftBrace", "RightBrace", "EOF"])
}

///|
test "test RightBrace token JSON serialization" {
  let tokens = @tokenize.tokenize("}")
  @json.inspect(tokens, content=["RightBrace", "EOF"])
}

///|
test "test Dot token JSON serialization" {
  let tokens = @tokenize.tokenize(".")
  @json.inspect(tokens, content=["Dot", "EOF"])
}

///| Test special number formats
test "tokenize hexadecimal numbers" {
  let tokens = @tokenize.tokenize("hex = 0xDEAD")
  @json.inspect(tokens, content=[
    ["Identifier", "hex"],
    "Equals",
    ["IntegerToken", "57005"],
    "EOF",
  ])
  let tokens2 = @tokenize.tokenize("hex2 = 0X1F")
  @json.inspect(tokens2, content=[
    ["Identifier", "hex2"],
    "Equals",
    ["IntegerToken", "31"],
    "EOF",
  ])
}

///|
test "tokenize octal numbers" {
  let tokens = @tokenize.tokenize("oct = 0o755")
  @json.inspect(tokens, content=[
    ["Identifier", "oct"],
    "Equals",
    ["IntegerToken", "493"],
    "EOF",
  ])
  let tokens2 = @tokenize.tokenize("oct2 = 0O123")
  @json.inspect(tokens2, content=[
    ["Identifier", "oct2"],
    "Equals",
    ["IntegerToken", "83"],
    "EOF",
  ])
}

///|
test "tokenize binary numbers" {
  let tokens = @tokenize.tokenize("bin = 0b1101")
  @json.inspect(tokens, content=[
    ["Identifier", "bin"],
    "Equals",
    ["IntegerToken", "13"],
    "EOF",
  ])
  let tokens2 = @tokenize.tokenize("bin2 = 0B101010")
  @json.inspect(tokens2, content=[
    ["Identifier", "bin2"],
    "Equals",
    ["IntegerToken", "42"],
    "EOF",
  ])
}

///|
test "tokenize numbers with underscores" {
  let tokens = @tokenize.tokenize("num = 1_000_000")
  @json.inspect(tokens, content=[
    ["Identifier", "num"],
    "Equals",
    ["IntegerToken", "1000000"],
    "EOF",
  ])
  let tokens2 = @tokenize.tokenize("float_val = 3.14_159")
  @json.inspect(tokens2, content=[
    ["Identifier", "float_val"],
    "Equals",
    ["FloatToken", 3.14159],
    "EOF",
  ])
  let tokens3 = @tokenize.tokenize("hex_under = 0xFF_FF")
  @json.inspect(tokens3, content=[
    ["Identifier", "hex_under"],
    "Equals",
    ["IntegerToken", "65535"],
    "EOF",
  ])
}

///|
test "tokenize special hex digits" {
  let tokens = @tokenize.tokenize("hex_digits = 0x0123456789ABCDEF")
  @json.inspect(tokens, content=[
    ["Identifier", "hex_digits"],
    "Equals",
    ["IntegerToken", "81985529216486895"],
    "EOF",
  ])
}

///| Test uncovered escape sequences and error conditions
test "test escaped single quote in string" {
  let tokens = @tokenize.tokenize("key = \"test\\' quote\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key"],
    "Equals",
    ["StringToken", "test' quote"],
    "EOF",
  ])
}

///|
fn Error::failure_message(x : Error) -> String {
  match x {
    Failure(msg) => msg.split(" ")[2:].map(x => x.to_string()).join(" ")
    // TODO: Array[Show]::join?
    // msg.split(":")[1:].map(x=>x.to_string()).join("")
    _ => "Unexpected error".to_string()
  }
}

///|
test "test invalid escape sequence error" {
  let maybe_tokens = try? @tokenize.tokenize("key = \"test\\z invalid\"")
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid escape sequence: \\z at line 1, column 14",
  ) // Should fail with invalid escape sequence
}

///|
test "test unterminated string error" {
  let maybe_tokens = try? @tokenize.tokenize("key = \"unterminated")
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated string at line 1, column 20",
  ) // Should fail with unterminated string
}

///|
test "test unexpected end after escape" {
  let maybe_tokens = try? @tokenize.tokenize("key = \"test\\")
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected end of input after escape character at line 1, column 13",
  ) // Should fail with unexpected end after escape
}

///|
test "test invalid characters" {
  let maybe_tokens = try? @tokenize.tokenize("key @ value")
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected character: @",
  ) // Should fail with unexpected character
}

///|
test "test binary number with underscores" {
  let tokens = @tokenize.tokenize("bin = 0b1010_1100")
  @json.inspect(tokens, content=[
    ["Identifier", "bin"],
    "Equals",
    ["IntegerToken", "172"],
    "EOF",
  ])
}

///|
test "test negative sign not followed by number" {
  let maybe_tokens = try? @tokenize.tokenize("key = -abc")
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected character: -",
  )
}
