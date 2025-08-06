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
  @json.inspect(maybe_tokens, content={
    "Ok": [
      ["Identifier", "hex"],
      "Equals",
      ["IntegerToken", "0"],
      ["Identifier", "GHI"],
      "EOF",
    ],
  }) // FIXME: Should fail with invalid hex digit
}
