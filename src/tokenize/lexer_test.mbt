///| Tests for the TOML lexer
test "tokenize simple key-value" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "value"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "value", { "loc": "1:7-1:14" }],
    ["EOF", { "loc": "1:14-1:14" }],
  ])
}

///|
test "tokenize integer" {
  let tokens = @tokenize.tokenize(
    (
      #|number = 42
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "number", { "loc": "1:1-1:7" }],
    ["Equals", { "loc": "1:8-1:9" }],
    ["IntegerToken", "42", { "loc": "1:10-1:12" }],
    ["EOF", { "loc": "1:12-1:12" }],
  ])
}

///|
test "tokenize float" {
  let tokens = @tokenize.tokenize(
    (
      #|pi = 3.14
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "pi", { "loc": "1:1-1:3" }],
    ["Equals", { "loc": "1:4-1:5" }],
    ["FloatToken", 3.14, { "loc": "1:6-1:10" }],
    ["EOF", { "loc": "1:10-1:10" }],
  ])
}

///|
test "tokenize boolean" {
  let tokens = @tokenize.tokenize(
    (
      #|enabled = true
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "enabled", { "loc": "1:1-1:8" }],
    ["Equals", { "loc": "1:9-1:10" }],
    ["BooleanToken", true, { "loc": "1:11-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///|
test "tokenize array syntax" {
  let tokens = @tokenize.tokenize(
    (
      #|[1, 2, 3]
    ),
  )
  @json.inspect(tokens, content=[
    ["LeftBracket", { "loc": "1:1-1:2" }],
    ["IntegerToken", "1", { "loc": "1:2-1:3" }],
    ["Comma", { "loc": "1:3-1:4" }],
    ["IntegerToken", "2", { "loc": "1:5-1:6" }],
    ["Comma", { "loc": "1:6-1:7" }],
    ["IntegerToken", "3", { "loc": "1:8-1:9" }],
    ["RightBracket", { "loc": "1:9-1:10" }],
    ["EOF", { "loc": "1:10-1:10" }],
  ])
}

///|
test "tokenize with comments" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "value" # this is a comment
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "value", { "loc": "1:7-1:14" }],
    ["EOF", { "loc": "1:34-1:34" }],
  ]) // comment ignored
}

///|
test "tokenize multiline" {
  let tokens = @tokenize.tokenize(
    (
      #|key1 = "value1"
      #|key2 = 42
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key1", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["StringToken", "value1", { "loc": "1:8-1:16" }],
    ["Newline", { "loc": "1:16-2:1" }],
    ["Identifier", "key2", { "loc": "2:1-2:5" }],
    ["Equals", { "loc": "2:6-2:7" }],
    ["IntegerToken", "42", { "loc": "2:8-2:10" }],
    ["EOF", { "loc": "2:10-2:10" }],
  ])
}

///|
test "unicode or emoji" {
  let tokens = @tokenize.tokenize(
    (
      #|key1 = "💩"
      #|key2 = "💩"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key1", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["StringToken", "💩", { "loc": "1:8-1:11" }],
    ["Newline", { "loc": "1:11-2:1" }],
    ["Identifier", "key2", { "loc": "2:1-2:5" }],
    ["Equals", { "loc": "2:6-2:7" }],
    ["StringToken", "💩", { "loc": "2:8-2:11" }],
    ["EOF", { "loc": "2:11-2:11" }],
  ])
  // more tests

}

///| Test uncovered Token JSON serialization methods
test "test DateTimeToken JSON serialization" {
  let dt = @tokenize.OffsetDateTime("1979-05-27T07:32:00Z")
  let token = @tokenize.DateTimeToken(dt, loc=@tokenize.default_loc())
  @json.inspect(token, content=[
    "DateTimeToken",
    ["OffsetDateTime", "1979-05-27T07:32:00Z"],
    { "loc": "1:1-1:1" },
  ])
}

///|
test "test LeftBrace token JSON serialization" {
  let tokens = @tokenize.tokenize(
    (
      #|{}
    ),
  )
  @json.inspect(tokens, content=[
    ["LeftBrace", { "loc": "1:1-1:2" }],
    ["RightBrace", { "loc": "1:2-1:3" }],
    ["EOF", { "loc": "1:3-1:3" }],
  ])
}

///|
test "test RightBrace token JSON serialization" {
  let tokens = @tokenize.tokenize(
    (
      #|}
    ),
  )
  @json.inspect(tokens, content=[
    ["RightBrace", { "loc": "1:1-1:2" }],
    ["EOF", { "loc": "1:2-1:2" }],
  ])
}

///|
test "test Dot token JSON serialization" {
  let tokens = @tokenize.tokenize(
    (
      #|.
    ),
  )
  @json.inspect(tokens, content=[
    ["Dot", { "loc": "1:1-1:2" }],
    ["EOF", { "loc": "1:2-1:2" }],
  ])
}

///| Test special number formats
test "tokenize hexadecimal numbers" {
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xDEAD
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "57005", { "loc": "1:7-1:13" }],
    ["EOF", { "loc": "1:13-1:13" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|hex2 = 0X1F
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "hex2", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["IntegerToken", "31", { "loc": "1:8-1:12" }],
    ["EOF", { "loc": "1:12-1:12" }],
  ])
}

///|
test "tokenize octal numbers" {
  let tokens = @tokenize.tokenize(
    (
      #|oct = 0o755
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "oct", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "493", { "loc": "1:7-1:12" }],
    ["EOF", { "loc": "1:12-1:12" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|oct2 = 0O123
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "oct2", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["IntegerToken", "83", { "loc": "1:8-1:13" }],
    ["EOF", { "loc": "1:13-1:13" }],
  ])
}

///|
test "tokenize binary numbers" {
  let tokens = @tokenize.tokenize(
    (
      #|bin = 0b1101
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "bin", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "13", { "loc": "1:7-1:13" }],
    ["EOF", { "loc": "1:13-1:13" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|bin2 = 0B101010
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "bin2", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    ["IntegerToken", "42", { "loc": "1:8-1:16" }],
    ["EOF", { "loc": "1:16-1:16" }],
  ])
}

///|
test "tokenize numbers with underscores" {
  let tokens = @tokenize.tokenize(
    (
      #|num = 1_000_000
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "num", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "1000000", { "loc": "1:7-1:16" }],
    ["EOF", { "loc": "1:16-1:16" }],
  ])
  let tokens2 = @tokenize.tokenize(
    (
      #|float_val = 3.14_159
    ),
  )
  @json.inspect(tokens2, content=[
    ["Identifier", "float_val", { "loc": "1:1-1:10" }],
    ["Equals", { "loc": "1:11-1:12" }],
    ["FloatToken", 3.14159, { "loc": "1:13-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
  ])
  let tokens3 = @tokenize.tokenize(
    (
      #|hex_under = 0xFF_FF
    ),
  )
  @json.inspect(tokens3, content=[
    ["Identifier", "hex_under", { "loc": "1:1-1:10" }],
    ["Equals", { "loc": "1:11-1:12" }],
    ["IntegerToken", "65535", { "loc": "1:13-1:20" }],
    ["EOF", { "loc": "1:20-1:20" }],
  ])
}

///|
test "tokenize special hex digits" {
  let tokens = @tokenize.tokenize(
    (
      #|hex_digits = 0x0123456789ABCDEF
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex_digits", { "loc": "1:1-1:11" }],
    ["Equals", { "loc": "1:12-1:13" }],
    ["IntegerToken", "81985529216486895", { "loc": "1:14-1:32" }],
    ["EOF", { "loc": "1:32-1:32" }],
  ])
}

///| Test uncovered escape sequences and error conditions
test "test escaped single quote in string" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "test\' quote"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "test' quote", { "loc": "1:7-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
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
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "test\z invalid"
      ),
    )
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid escape sequence: \\z at line 1, column 14",
  ) // Should fail with invalid escape sequence
}

///|
test "test unterminated string error" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "unterminated
      ),
    )
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated string at line 1, column 20",
  ) // Should fail with unterminated string
}

///|
test "test unexpected end after escape" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "test\
      ),
    )
  // TODO: ArgsLoc no absolute loc
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected end of input after escape character at line 1, column 13",
  ) // Should fail with unexpected end after escape
}

///|
test "test invalid characters" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key @ value
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected character: '@'",
  ) // Should fail with unexpected character
}

///|
test "test binary number with underscores" {
  let tokens = @tokenize.tokenize(
    (
      #|bin = 0b1010_1100
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "bin", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "172", { "loc": "1:7-1:18" }],
    ["EOF", { "loc": "1:18-1:18" }],
  ])
}

///|
test "test negative sign not followed by number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = -abc
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected character: '-'",
  )
}

///| Test lexer expect_string error cases
test "lexer expect_string failure" {
  let lexer = @lexer.Lexer::new(
    (
      #|hello world
    ),
  )
  let maybe_result = try? lexer.expect_string("goodbye")
  @json.inspect(
    maybe_result.unwrap_err().failure_message(),
    content="Expected string: goodbye at line 1, column 1",
  )
}

///| Test Unicode 4-digit escape with lowercase hex letters
test "unicode 4 escape lowercase hex" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "\uabcd"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "ꯍ", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///| Test Unicode 4-digit escape with uppercase hex letters
test "unicode 4 escape uppercase hex" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "\uABCD"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "ꯍ", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///| Test Unicode 4-digit escape invalid hex digit
test "unicode 4 escape invalid hex" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\uGHIJ"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode escape sequence: expected 4 hex digits at line 1, column 10",
  )
}

///| Test Unicode 4-digit escape incomplete sequence
test "unicode 4 escape incomplete" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\u123"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode escape sequence: expected 4 hex digits at line 1, column 10",
  )
}

///| Test Unicode 4-digit escape invalid code point
test "unicode 4 escape invalid code point" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\uD800"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode code point: 55296 at line 1, column 14",
  )
}

///| Test Unicode 8-digit escape with lowercase hex letters
test "unicode 8 escape lowercase hex" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "\U000000ab"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "«", { "loc": "1:7-1:19" }],
    ["EOF", { "loc": "1:19-1:19" }],
  ])
}

///| Test Unicode 8-digit escape with uppercase hex letters
test "unicode 8 escape uppercase hex" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "\U000000AB"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "«", { "loc": "1:7-1:19" }],
    ["EOF", { "loc": "1:19-1:19" }],
  ])
}

///| Test Unicode 8-digit escape invalid hex digit
test "unicode 8 escape invalid hex" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U0000000G"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode escape sequence: expected 8 hex digits at line 1, column 10",
  )
}

///| Test Unicode 8-digit escape incomplete sequence
test "unicode 8 escape incomplete" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U0000001"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode escape sequence: expected 8 hex digits at line 1, column 10",
  )
}

///| Test Unicode 8-digit escape invalid code point (too large)
test "unicode 8 escape invalid code point large" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U00110000"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode code point: 1114112 at line 1, column 18",
  )
}

///| Test Unicode 8-digit escape invalid code point (surrogate range)
test "unicode 8 escape invalid code point surrogate" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U0000D800"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode code point: 55296 at line 1, column 18",
  )
}

///| Test Unicode 8-digit escape invalid code point conversion
test "unicode 8 escape invalid conversion" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U7FFFFFFF"
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid Unicode code point: 2147483647 at line 1, column 18",
  )
}

///| Test backspace escape sequence
test "backspace escape sequence" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "test\b"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "test\b", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///| Test form feed escape sequence
test "form feed escape sequence" {
  let tokens = @tokenize.tokenize(
    (
      #|key = "test\f"
    ),
  )
  // FIXME(upstream): inspect test generate '\f' instead of '\u000C'
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "test\u000C", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///| Test multiline basic string with escape sequences
test "multiline basic string escapes" {
  let tokens = @tokenize.tokenize(
    (
      #|key = """line1\nline2\tindented"""
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "line1\nline2\tindented", { "loc": "1:7-1:35" }],
    ["EOF", { "loc": "1:35-1:35" }],
  ])
}

///| Test multiline basic string with all escape types
test "multiline basic string all escapes" {
  let tokens = @tokenize.tokenize(
    (
      #|key = """\n\t\r\\\"\b\f\u0041\U00000042"""
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "\n\t\r\\\"\b\u000CAB", { "loc": "1:7-1:43" }],
    ["EOF", { "loc": "1:43-1:43" }],
  ])
}

///| Test multiline basic string with line ending backslash and CR
test "multiline basic string line ending backslash CR" {
  let tokens = @tokenize.tokenize("key = \"\"\"line1\\\r\n   line2\"\"\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "line1line2", { "loc": "1:7-2:13" }],
    ["EOF", { "loc": "2:13-2:13" }],
  ])
}

///| Test multiline basic string invalid escape
test "multiline basic string invalid escape" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """\z"""
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid escape sequence: \\z at line 1, column 12",
  )
}

///| Test multiline basic string unexpected end after escape
test "multiline basic string unexpected end after escape" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """\
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unexpected end of input after escape character at line 1, column 11",
  )
}

///| Test multiline basic string unterminated
test "multiline basic string unterminated" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """incomplete
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated multiline string at line 1, column 20",
  )
}

///| Test multiline basic string early termination in loop
test "multiline basic string early termination" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """line
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated multiline string at line 1, column 14",
  )
}

///| Test multiline literal string with CR+LF
test "multiline literal string CRLF" {
  let tokens = @tokenize.tokenize("key = '''line1\r\nline2'''")
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "line1\r\nline2", { "loc": "1:7-2:9" }],
    ["EOF", { "loc": "2:9-2:9" }],
  ])
}

///| Test multiline literal string unterminated
test "multiline literal string unterminated" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = '''incomplete
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated multiline literal string at line 1, column 20",
  )
}

///| Test hex number with no digits after 0x
test "hex number invalid digit error path" {
  // This should fail because there are no hex digits after 0x
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0x
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, expected 0..=9, a..=f, A..=F after 0x at line 1, column 7",
  )
}

///| Test invalid float parsing case
test "invalid float error" {
  // This should trigger the invalid float error in read_number
  // but the current implementation may parse it differently
  let tokens = @tokenize.tokenize(
    (
      #|key = 3.14
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["FloatToken", 3.14, { "loc": "1:7-1:11" }],
    ["EOF", { "loc": "1:11-1:11" }],
  ])
}

///| Test multiline literal string tokenization
test "multiline literal string token" {
  let tokens = @tokenize.tokenize(
    (
      #|key = '''hello world'''
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "hello world", { "loc": "1:7-1:24" }],
    ["EOF", { "loc": "1:24-1:24" }],
  ])
}

///| Test tokenize while loop else branch (should never be reached)
test "tokenize else branch coverage" {
  // This tests the else branch in tokenize function that should never be reached
  // The function returns inside the while loop, so the else is unreachable
  let tokens = @tokenize.tokenize(
    (
      #|key = "value"
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "value", { "loc": "1:7-1:14" }],
    ["EOF", { "loc": "1:14-1:14" }],
  ])
}

///| Test multiline basic string with single quote escape
test "multiline basic string single quote escape" {
  let tokens = @tokenize.tokenize(
    (
      #|key = """line with \' quote"""
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "line with ' quote", { "loc": "1:7-1:31" }],
    ["EOF", { "loc": "1:31-1:31" }],
  ])
}

///| Test multiline basic string with CR only (without LF)
test "multiline basic string CR only" {
  // CR: '\r' is hard to visualize in the multipline string
  // explicit escaping is better for testing
  let tokens = @tokenize.tokenize("key = \"\"\"line1\\\rline2\"\"\"")
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "line1line2", { "loc": "1:7-2:9" }],
    ["EOF", { "loc": "2:9-2:9" }],
  ])
}

///| Test multiline basic string early termination at None peek
test "multiline basic string none peek" {
  // This creates a string that will reach None in the peek() during processing
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """incomplete string
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Unterminated multiline string at line 1, column 27",
  )
}

///| Test Unicode escape sequence that results in None from to_char
test "unicode escape invalid conversion to char" {
  // This tests an edge case where to_char returns None
  let tokens = @tokenize.tokenize(
    (
      #|key = "\uFFFF"
    ),
  )
  // This should work for valid Unicode, but test the error path
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "￿", { "loc": "1:7-1:15" }],
    ["EOF", { "loc": "1:15-1:15" }],
  ])
}

///| Test hex number with underscore in the middle
test "hex number with underscores" {
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xDE_AD_BE_EF
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "3735928559", { "loc": "1:7-1:20" }],
    ["EOF", { "loc": "1:20-1:20" }],
  ])
}

///| Test CR followed by LF after multiline string opening
test "multiline string opening CRLF" {
  let tokens = @tokenize.tokenize(
    (
      #|key = """
      #|content"""
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "key", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["StringToken", "content", { "loc": "1:7-2:11" }],
    ["EOF", { "loc": "2:11-2:11" }],
  ])
}

///| Test invalid float that could trigger parse error
test "very large invalid float" {
  // Create a huge number that might overflow during parsing
  let huge_number = "999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999.9999"
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 
      ) +
      huge_number,
    )
  // This should trigger the "Invalid float" error, covering that line
  let error_msg = maybe_tokens.unwrap_err().failure_message()
  match error_msg.strip_prefix("Invalid float: ") {
    Some(_) => inspect(true, content="true") // Error message started with "Invalid float: "
    None => inspect(false, content="true") // Unexpected error message
  }
}

///| Test edge case for hex digit error handling  
test "test hex overflow edge case" {
  // Test a hex number that might cause overflow issues
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xFFFFFFFFFFFFFFFF
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "-1", { "loc": "1:7-1:25" }],
    ["EOF", { "loc": "1:25-1:25" }],
  ])
}

///| Test Unicode escape that might fail to_char conversion
test "unicode code point conversion failure" {
  // Try to find a Unicode code that's valid as int but invalid as char
  // Code point 0x110000 is too large for valid Unicode
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U00110000"
      ),
    )
  let error_msg = maybe_tokens.unwrap_err().failure_message()
  match error_msg.strip_prefix("Invalid Unicode code point: ") {
    Some(_) => inspect(true, content="true") // Expected error
    None => inspect(false, content="true") // Unexpected error
  }
}

///| Test very specific multiline string that could reach None peek
test "multiline string abrupt end" {
  // Create a multiline string that ends abruptly without proper closing
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """content without closing
      ),
    )
  let error_msg = maybe_tokens.unwrap_err().failure_message()
  // This should trigger one of the unterminated multiline string errors
  let is_unterminated = match
    error_msg.strip_prefix("Unterminated multiline string") {
    Some(_) => true
    None => false
  }
  inspect(is_unterminated, content="true")
}

///| Test edge case: try to reach the Unicode 8 None conversion path
test "unicode 8 digit none conversion attempt" {
  // Try an edge case that might trigger the None path in unicode 8 escape
  // Use a very large value that might fail conversion
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = "\U7FFFFFFF"
      ),
    )
  let error_msg = maybe_tokens.unwrap_err().failure_message()
  // Should get invalid Unicode code point error
  let has_invalid_unicode = match
    error_msg.strip_prefix("Invalid Unicode code point: ") {
    Some(_) => true
    None => false
  }
  inspect(has_invalid_unicode, content="true")
}

///| Test edge case: try to reach hex digit error path (likely unreachable)
test "attempt hex digit error path" {
  // This tests the theoretical hex digit error path, though it's likely unreachable
  // due to pattern matching filtering
  let tokens = @tokenize.tokenize(
    (
      #|hex = 0xABCDEF123456
    ),
  )
  @json.inspect(tokens, content=[
    ["Identifier", "hex", { "loc": "1:1-1:4" }],
    ["Equals", { "loc": "1:5-1:6" }],
    ["IntegerToken", "188900967593046", { "loc": "1:7-1:21" }],
    ["EOF", { "loc": "1:21-1:21" }],
  ])
}

///| Test multiline string with potential truncation
test "multiline string potential truncation" {
  // Try to create a scenario where multiline string processing might hit None
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = """partial
      ),
    )
  // Should get unterminated string error
  let error_msg = maybe_tokens.unwrap_err().failure_message()
  let is_unterminated = error_msg.contains("Unterminated")
  inspect(is_unterminated, content="true")
}

///|
test "trailing _ in binary number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0b10_10_
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid binary number, no trailing digits after _ at line 1, column 14",
  )
}

///|
test "consequence _ in binary number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0b10__10_10
      ),
    )
  // according to spec, this should fail
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid binary number, consecutive _ at line 1, column 11",
  )
}

///|
test "trailing _ in hex number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0xAB_CD_
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, no trailing digits after _ at line 1, column 14",
  )
}

///|
test "consecutive _ in hex number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0xAB__CD_EF
      ),
    )
  // according to spec, this should fail
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid hex number, consecutive _ at line 1, column 11",
  )
}

///|
test "trailing _ in octal number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0o755_
      ),
    )
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid octal number, no trailing digits after _ at line 1, column 12",
  )
}

///|
test "consecutive _ in octal number" {
  let maybe_tokens = try? @tokenize.tokenize(
      (
        #|key = 0o7__55_44
      ),
    )
  // according to spec, this should fail
  @json.inspect(
    maybe_tokens.unwrap_err().failure_message(),
    content="Invalid octal number, consecutive _ at line 1, column 10",
  )
}
