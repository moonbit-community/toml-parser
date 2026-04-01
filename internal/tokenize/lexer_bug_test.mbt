///|
test "test invalid float parsing" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|invalid = 1.2.3
    ),
  )
  debug_inspect(
    maybe_tokens,
    content=(
      #|Ok(
      #|  [
      #|    Identifier(
      #|      "invalid",
      #|      loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 8 } },
      #|    ),
      #|    Equals(loc={ start: { line: 1, column: 9 }, end: { line: 1, column: 10 } }),
      #|    FloatToken(
      #|      1.2,
      #|      loc={ start: { line: 1, column: 11 }, end: { line: 1, column: 14 } },
      #|      raw="1.2",
      #|    ),
      #|    Dot(loc={ start: { line: 1, column: 14 }, end: { line: 1, column: 15 } }),
      #|    IntegerToken(
      #|      3,
      #|      loc={ start: { line: 1, column: 15 }, end: { line: 1, column: 16 } },
      #|    ),
      #|    EOF(loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 16 } }),
      #|  ],
      #|)
    ),
  ) // FIXME:Should fail with invalid float literal
}

///|
test "test invalid hex digit error" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|hex = 0xGHI
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:521:5-521:50@bobzhang/toml FAILED: Invalid hex number format at line 1, column 7\")"
    ),
  )
}

///|
test "test octal without digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|test = 0o
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:567:5-567:52@bobzhang/toml FAILED: Invalid octal number format at line 1, column 8\")"
    ),
  )
}

///|
test "test binary without digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|test = 0b
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:620:5-620:53@bobzhang/toml FAILED: Invalid binary number format at line 1, column 8\")"
    ),
  )
}

///|
test "test hex with invalid delimiter" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|hex = 0x123XYZ
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:544:9-548:10@bobzhang/toml FAILED: Invalid char 'X', expected whitespace, comma, or end of input after 0x... at line 1, column 12\")"
    ),
  )
}

///|
test "test hex regex is anchored to current view" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|hex = 0xG0x10
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:521:5-521:50@bobzhang/toml FAILED: Invalid hex number format at line 1, column 7\")"
    ),
  )
}

///|
test "test datetime timezone regex is anchored to current view" {
  let tokens = @tokenize.tokenize(
    (
      #|dt = 2023-06-15T12:30:00xZ
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "dt",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 3 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 4 }, end: { line: 1, column: 5 } }),
      #|  DateTimeToken(
      #|    LocalDateTime("2023-06-15T12:30:00"),
      #|    loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 25 } },
      #|  ),
      #|  Identifier(
      #|    "xZ",
      #|    loc={ start: { line: 1, column: 25 }, end: { line: 1, column: 27 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 27 }, end: { line: 1, column: 27 } }),
      #|]
    ),
  )
}

///|
test "test octal regex is anchored to current view" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|oct = 0o80o7
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:567:5-567:52@bobzhang/toml FAILED: Invalid octal number format at line 1, column 7\")"
    ),
  )
}

///|
test "test binary regex is anchored to current view" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|bin = 0b20b10
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:620:5-620:53@bobzhang/toml FAILED: Invalid binary number format at line 1, column 7\")"
    ),
  )
}

///|
test "test hex with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|hex = 0x123A
    ),
  )
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "hex",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  IntegerToken(
      #|    4666,
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 13 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 13 }, end: { line: 1, column: 13 } }),
      #|]
    ),
  )
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0x123A, 0xB]
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "arr",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  LeftBracket(loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 8 } }),
      #|  IntegerToken(
      #|    4666,
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 14 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 14 }, end: { line: 1, column: 15 } }),
      #|  IntegerToken(
      #|    11,
      #|    loc={ start: { line: 1, column: 16 }, end: { line: 1, column: 19 } },
      #|  ),
      #|  RightBracket(loc={ start: { line: 1, column: 19 }, end: { line: 1, column: 20 } }),
      #|  EOF(loc={ start: { line: 1, column: 20 }, end: { line: 1, column: 20 } }),
      #|]
    ),
  )
}

///|
test "test hex case variations" {
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xaBcDeF
    ),
  )
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "hex",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  IntegerToken(
      #|    11259375,
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 15 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 15 }, end: { line: 1, column: 15 } }),
      #|]
    ),
  )
}

///|
test "test octal with invalid digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|oct = 0o789
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:584:9-588:10@bobzhang/toml FAILED: Invalid char '8', expected whitespace, comma, or end of input after 0o... at line 1, column 10\")"
    ),
  )
}

///|
test "test octal with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|oct = 0o755
    ),
  )
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "oct",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  IntegerToken(
      #|    493,
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 12 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 12 }, end: { line: 1, column: 12 } }),
      #|]
    ),
  )
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0o644, 0o755]
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "arr",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  LeftBracket(loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 8 } }),
      #|  IntegerToken(
      #|    420,
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 13 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 13 }, end: { line: 1, column: 14 } }),
      #|  IntegerToken(
      #|    493,
      #|    loc={ start: { line: 1, column: 15 }, end: { line: 1, column: 20 } },
      #|  ),
      #|  RightBracket(loc={ start: { line: 1, column: 20 }, end: { line: 1, column: 21 } }),
      #|  EOF(loc={ start: { line: 1, column: 21 }, end: { line: 1, column: 21 } }),
      #|]
    ),
  )
}

///|
test "test binary with invalid digits" {
  let maybe_tokens = try? @tokenize.tokenize(
    (
      #|bin = 0b1012
    ),
  )
  debug_inspect(
    maybe_tokens.unwrap_err().to_string(),
    content=(
      #|"Failure(\"internal/tokenize/tokenize.mbt:637:9-641:10@bobzhang/toml FAILED: Invalid char '2', expected whitespace, comma, or end of input after 0b... at line 1, column 12\")"
    ),
  )
}

///|
test "test binary with valid delimiters" {
  let tokens1 = @tokenize.tokenize(
    (
      #|bin = 0b1010
    ),
  )
  debug_inspect(
    tokens1,
    content=(
      #|[
      #|  Identifier(
      #|    "bin",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  IntegerToken(
      #|    10,
      #|    loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 13 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 13 }, end: { line: 1, column: 13 } }),
      #|]
    ),
  )
  let tokens2 = @tokenize.tokenize(
    (
      #|arr = [0b101, 0b110]
    ),
  )
  debug_inspect(
    tokens2,
    content=(
      #|[
      #|  Identifier(
      #|    "arr",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 6 } }),
      #|  LeftBracket(loc={ start: { line: 1, column: 7 }, end: { line: 1, column: 8 } }),
      #|  IntegerToken(
      #|    5,
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 13 } },
      #|  ),
      #|  Comma(loc={ start: { line: 1, column: 13 }, end: { line: 1, column: 14 } }),
      #|  IntegerToken(
      #|    6,
      #|    loc={ start: { line: 1, column: 15 }, end: { line: 1, column: 20 } },
      #|  ),
      #|  RightBracket(loc={ start: { line: 1, column: 20 }, end: { line: 1, column: 21 } }),
      #|  EOF(loc={ start: { line: 1, column: 21 }, end: { line: 1, column: 21 } }),
      #|]
    ),
  )
}
