// Known failures from toml-test suite. Each test reproduces a specific issue.
// These are annotated with #skip so they don't block CI, but serve as a backlog.

// ============================================================
// BUG: Tokenizer infinite loop on dashed bare keys in table headers
// The lexer read_identifier regex fails to advance on patterns like [a-a-a]
// ============================================================

///|
#skip
test "bug: tokenizer infinite loop on [a-a-a] table header" {
  let _ = try? @toml.parse("[a-a-a]\n_ = false\n")
  // Should parse as table "a-a-a" with key _ = false
}

///|
#skip
test "bug: tokenizer infinite loop on leading underscore value" {
  let _ = try? @toml.parse("x = _1.2\n")
  // Should fail with parse error, not infinite loop
}

// ============================================================
// BUG: '+' prefix not supported for positive integers/floats
// TOML spec allows +99, +1.0, +0, etc.
// ============================================================

///|
#skip
test "bug: positive prefix '+' not tokenized for integers" {
  let result = try? @toml.parse("pos = +99\n")
  inspect(result, content="Ok(TomlTable({\"pos\": TomlInteger(99)}))")
}

///|
#skip
test "bug: positive prefix '+' not tokenized for floats" {
  let result = try? @toml.parse("pos = +1.0\n")
  inspect(result, content="Ok(TomlTable({\"pos\": TomlFloat(1)}))")
}

// ============================================================
// BUG: CRLF line endings not handled
// The tokenizer doesn't handle \r\n or standalone \r
// ============================================================

///|
#skip
test "bug: CRLF line ending not handled" {
  let result = try? @toml.parse("key = \"val\"\r\n")
  inspect(result, content="Ok(TomlTable({\"key\": TomlString(\"val\")}))")
}

// ============================================================
// BUG: Datetime with space separator not parsed
// TOML allows space instead of 'T' between date and time
// e.g. "1987-07-05 17:45:00Z"
// ============================================================

///|
#skip
test "bug: datetime with space separator" {
  let result = try? @toml.parse("dt = 1987-07-05 17:45:00Z\n")
  inspect(
    result,
    content="Ok(TomlTable({\"dt\": TomlDateTime(OffsetDateTime(\"1987-07-05 17:45:00Z\"))}))",
  )
}

// ============================================================
// BUG: Numeric keys with leading zeros get stripped
// TOML bare keys like 0123 should preserve the full string "0123"
// ============================================================

///|
#skip
test "bug: numeric key leading zeros stripped" {
  let result = try? @toml.parse("0123 = true\n")
  // Key should be "0123", not "123"
  json_inspect(result, content=[
    "Ok",
    ["TomlTable", { "0123": ["TomlBoolean", true] }],
  ])
}

// ============================================================
// BUG: Multiline basic string line ending backslash
// A backslash at end of line should trim the newline and leading whitespace
// ============================================================

///|
#skip
test "bug: multiline string line ending backslash" {
  let input =
    #|str = """
    #|The quick brown \
    #|
    #|  fox jumps over the lazy dog."""
    #|
  let result = try? @toml.parse(input)
  inspect(
    result,
    content="Ok(TomlTable({\"str\": TomlString(\"The quick brown fox jumps over the lazy dog.\")}))",
  )
}

// ============================================================
// BUG: Escape sequences \x and \e not supported
// TOML 1.1 adds \xHH hex escapes and \e (ESC) escape
// ============================================================

///|
#skip
test "bug: hex escape \\xHH not supported" {
  let result = try? @toml.parse("esc = \"\\x41\"\n")
  inspect(result, content="Ok(TomlTable({\"esc\": TomlString(\"A\")}))")
}

///|
#skip
test "bug: escape \\e (ESC) not supported" {
  let result = try? @toml.parse("esc = \"\\e\"\n")
  inspect(result, content="Ok(TomlTable({\"esc\": TomlString(\"\\x1b\")}))")
}

// ============================================================
// BUG: Array of tables reopen not handled correctly
// [[array]] should be able to add entries to existing arrays
// ============================================================

///|
#skip
test "bug: array of tables cannot reopen" {
  let input =
    #|[[fruits]]
    #|name = "apple"
    #|
    #|[[fruits.varieties]]
    #|name = "red delicious"
    #|
    #|[[fruits]]
    #|name = "banana"
    #|
  let _ = try? @toml.parse(input)
  // Should parse without error
}

// ============================================================
// BUG: 'true'/'false'/'inf'/'nan' should be allowed as table/key names
// These are keywords only in value position, not key position
// ============================================================

///|
#skip
test "bug: keyword as table name" {
  let result = try? @toml.parse("[true]\nx = 1\n")
  inspect(
    result,
    content="Ok(TomlTable({\"true\": TomlTable({\"x\": TomlInteger(1)})}))",
  )
}

// ============================================================
// BUG: Inline table newlines (TOML 1.1 feature)
// TOML 1.1 allows newlines inside inline tables
// ============================================================

///|
#skip
test "bug: inline table newlines (TOML 1.1)" {
  let input =
    #|x = {
    #|  a = 1,
    #|  b = 2
    #|}
    #|
  let _ = try? @toml.parse(input)
}

// ============================================================
// BUG: Datetime millisecond normalization
// Trailing zeros in milliseconds should be preserved (e.g. .600 not .6)
// ============================================================

///|
#skip
test "bug: datetime millisecond trailing zeros" {
  let result = try? @toml.parse("dt = 1987-07-05T17:45:56.600Z\n")
  // Should preserve .600, not truncate to .6
  json_inspect(result, content=[
    "Ok",
    [
      "TomlTable",
      { "dt": ["TomlDateTime", ["OffsetDateTime", "1987-07-05T17:45:56.600Z"]] },
    ],
  ])
}

// ============================================================
// BUG: Multiline strings with consecutive quotes
// Up to 2 quotes inside a multiline basic string should be valid
// ============================================================

///|
#skip
test "bug: multiline string with consecutive quotes" {
  let input =
    #|str = """Here are two quotes: "". Cool."""
    #|
  let _ = try? @toml.parse(input)
}

// ============================================================
// BUG: Dashed bare key as first char
// Keys starting with - (e.g. -key = 1) should be valid bare keys
// ============================================================

///|
#skip
test "bug: dashed bare key starting with dash" {
  let result = try? @toml.parse("-key = 1\n")
  inspect(result, content="Ok(TomlTable({\"-key\": TomlInteger(1)}))")
}
