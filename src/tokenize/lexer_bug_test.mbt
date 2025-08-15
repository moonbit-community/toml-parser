///|
test "test invalid float parsing" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|invalid = 1.2.3
    ),
  )
  @json.inspect(maybe_tokens, content={
    "Ok": [
      ["Identifier", "invalid", { "loc": "1:1-1:8" }],
      ["Equals", { "loc": "1:9-1:10" }],
      ["FloatToken", 1.2, { "loc": "1:11-1:14" }],
      ["Dot", { "loc": "1:14-1:15" }],
      ["IntegerToken", "3", { "loc": "1:15-1:16" }],
      ["EOF", { "loc": "1:16-1:16" }],
    ],
  }) // FIXME:Should fail with invalid float literal
}

///|
test "test invalid hex digit error" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|hex = 0xGHI
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, expected 0..=9, a..=f, A..=F after 0x at line 1, column 7",
  )
}

///|
test "test octal without digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|test = 0o
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid octal number, expected 0..=7 after 0o at line 1, column 8",
  )
}

///|
test "test binary without digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|test = 0b
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid binary number, expected 0 or 1 after 0b at line 1, column 8",
  )
}

///|
test "test hex with invalid delimiter" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|hex = 0x123XYZ
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, expected whitespace, comma, or end of input after 0x at line 1, column 12",
  )
}

///|
test "test hex with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|hex = 0x123A
    ),
  )
  @json.inspect(tokens1, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "4666", { "loc": "1:7-1:13" }],
    ["EOF", { "loc": "1:13-1:13" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0x123A, 0xB]
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "arr", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["LeftBracket", { "loc": "1:7-1:8" }],
    ["IntegerToken", "4666", { "loc": "1:8-1:14" }],
    ["Comma", { "loc": "1:14-1:15" }],
    ["IntegerToken", "11", { "loc": "1:16-1:19" }],
    ["RightBracket", { "loc": "1:19-1:20" }],
    ["EOF", { "loc": "1:20-1:20" }],
  ])
}

///|
test "test hex case variations" {
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xaBcDeF
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "11259375", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///|
test "test octal with invalid digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|oct = 0o789
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid octal number, expected whitespace, comma, or end of input after 0o at line 1, column 10",
  )
}

///|
test "test octal with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|oct = 0o755
    ),
  )
  @json.inspect(tokens1, content=[
    ["Identifier", "oct", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "493", { "loc": "1:7-1:12" }],
    ["EOF", { "loc": "1:12-1:12" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0o644, 0o755]
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "arr", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["LeftBracket", { "loc": "1:7-1:8" }],
    ["IntegerToken", "420", { "loc": "1:8-1:13" }],
    ["Comma", { "loc": "1:13-1:14" }],
    ["IntegerToken", "493", { "loc": "1:15-1:20" }],
    ["RightBracket", { "loc": "1:20-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
  ])
}

///|
test "test binary with invalid digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|bin = 0b1012
    ),
  )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid binary number, expected whitespace, comma, or end of input after 0b at line 1, column 12",
  )
}

///|
test "test binary with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|bin = 0b1010
    ),
  )
  @json.inspect(tokens1, content=[
    ["Identifier", "bin", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "10", { "loc": "1:7-1:13" }],
    ["EOF", { "loc": "1:13-1:13" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0b101, 0b110]
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "arr", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["LeftBracket", { "loc": "1:7-1:8" }],
    ["IntegerToken", "5", { "loc": "1:8-1:13" }],
    ["Comma", { "loc": "1:13-1:14" }],
    ["IntegerToken", "6", { "loc": "1:15-1:20" }],
    ["RightBracket", { "loc": "1:20-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
  ])
}
