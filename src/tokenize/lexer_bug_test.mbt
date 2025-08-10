///|
test "test invalid float parsing" {
  let maybe_tokens = try? @tokenize.tokenize("invalid = 1.2.3")
  @json.inspect(maybe_tokens, content={
    "Ok": [
      ["Identifier", "invalid"],
      "Equals",
      ["FloatToken", 1.2],
      "Dot",
      ["IntegerToken", "3"],
      "EOF",
    ],
  }) // FIXME:Should fail with invalid float literal
}

///|
test "test invalid hex digit error" {
  let maybe_tokens = try? @tokenize.tokenize("hex = 0xGHI")
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, expected 0..=9, a..=f, A..=F after 0x at line 1, column 7",
  )
}
  @json.inspect(maybe_tokens, content={
    "Ok": [
      ["Identifier", "hex"],
      "Equals",
      ["IntegerToken", "0"],
      ["Identifier", "GHI"],
      "EOF",
    ],
  }) // FIXME: Should fail with invalid hex digit
///|
test "test hex with invalid delimiter" {
  let maybe_tokens = try? @tokenize.tokenize("hex = 0x123XYZ")
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, expected whitespace, comma, or end of input after 0x at line 1, column 12",
  )
}

///|
test "test hex with valid delimiters" {
  let tokens1 = @tokenize.tokenize("hex = 0x123A")
  @json.inspect(tokens1, content=[
    ["Identifier", "hex"],
    "Equals",
    ["IntegerToken", "4666"],
    "EOF",
  ])
  
  let tokens2 = @tokenize.tokenize("arr = [0x123A, 0xB]")
  @json.inspect(tokens2, content=[
    ["Identifier", "arr"],
    "Equals",
    "LeftBracket",
    ["IntegerToken", "4666"],
    "Comma",
    ["IntegerToken", "11"],
    "RightBracket",
    "EOF",
  ])
}

///|
test "test hex case variations" {
  let tokens = @tokenize.tokenize("hex = 0xaBcDeF")
  @json.inspect(tokens, content=[
    ["Identifier", "hex"],
    "Equals",
    ["IntegerToken", "11259375"],
    "EOF",
  ])
}
