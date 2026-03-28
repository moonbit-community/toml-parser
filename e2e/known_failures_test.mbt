// Known failures from toml-test suite. Each test reproduces a specific issue.
// Fixed tests are active (no #skip). Remaining issues are #skip as backlog.

// ============================================================
// FIXED: Tokenizer infinite loop on dashed bare keys in table headers
// ============================================================

///|
test "fixed: [a-a-a] table header parses correctly" {
  let result = try? @toml.parse("[a-a-a]\n_ = false\n")
  inspect(
    result,
    content=(
      #|Ok([a-a-a]
      #|_ = false
      #|)
    ),
  )
}

///|
test "fixed: leading underscore value rejected (not infinite loop)" {
  let result = try? @toml.parse("x = _1.2\n")
  inspect(
    result,
    content=(
      #|Err(Failure("parser.mbt:184:20-184:70@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 7 } }"))
    ),
  )
}

// ============================================================
// FIXED: '+' prefix for positive integers/floats
// ============================================================

///|
test "fixed: positive prefix '+' tokenized for integers" {
  let result = try? @toml.parse("pos = +99\n")
  inspect(
    result,
    content=(
      #|Ok(pos = 99
      #|)
    ),
  )
}

///|
test "fixed: positive prefix '+' tokenized for floats" {
  let result = try? @toml.parse("pos = +1.0\n")
  inspect(
    result,
    content=(
      #|Ok(pos = 1.0
      #|)
    ),
  )
}

// ============================================================
// FIXED: CRLF line endings
// ============================================================

///|
test "fixed: CRLF line ending handled" {
  let result = try? @toml.parse("key = \"val\"\r\n")
  inspect(
    result,
    content=(
      #|Ok(key = "val"
      #|)
    ),
  )
}

// ============================================================
// FIXED: Datetime with space separator
// ============================================================

///|
test "fixed: datetime with space separator" {
  let result = try? @toml.parse("dt = 1987-07-05 17:45:00Z\n")
  inspect(
    result,
    content=(
      #|Ok(dt = 1987-07-05 17:45:00Z
      #|)
    ),
  )
}

// ============================================================
// FIXED: Numeric keys with leading zeros preserved
// ============================================================

///|
test "fixed: numeric key leading zeros preserved" {
  let result = try? @toml.parse("0123 = true\n")
  inspect(
    result,
    content=(
      #|Ok(0123 = true
      #|)
    ),
  )
}

// ============================================================
// FIXED: Multiline basic string line ending backslash
// ============================================================

///|
test "fixed: multiline string line ending backslash" {
  let input =
    #|str = """
    #|The quick brown \
    #|
    #|  fox jumps over the lazy dog."""
    #|
  let result = try? @toml.parse(input)
  inspect(
    result,
    content=(
      #|Ok(str = "The quick brown fox jumps over the lazy dog."
      #|)
    ),
  )
}

// ============================================================
// FIXED: Escape sequences \x and \e
// ============================================================

///|
test "fixed: hex escape \\xHH" {
  let result = try? @toml.parse("esc = \"\\x41\"\n")
  inspect(
    result,
    content=(
      #|Ok(esc = "A"
      #|)
    ),
  )
}

///|
test "fixed: escape \\e (ESC)" {
  let result = try? @toml.parse("esc = \"\\e\"\n")
  inspect(
    result,
    content=(
      #|Ok(esc = "\u001B"
      #|)
    ),
  )
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
// FIXED: Keywords as table/key names
// ============================================================

///|
test "fixed: keyword as table name" {
  let result = try? @toml.parse("[true]\nx = 1\n")
  inspect(
    result,
    content=(
      #|Ok([true]
      #|x = 1
      #|)
    ),
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
  debug_inspect(result, content="")
}

// ============================================================
// FIXED: Multiline strings with consecutive quotes
// ============================================================

///|
test "fixed: multiline string with consecutive quotes" {
  let input =
    #|str = """Here are two quotes: "". Cool."""
    #|
  let result = try? @toml.parse(input)
  inspect(
    result,
    content=(
      #|Ok(str = "Here are two quotes: \"\". Cool."
      #|)
    ),
  )
}

// ============================================================
// FIXED: Dashed bare key starting with dash
// ============================================================

///|
test "fixed: dashed bare key starting with dash" {
  let result = try? @toml.parse("-key = 1\n")
  inspect(
    result,
    content=(
      #|Ok(-key = 1
      #|)
    ),
  )
}
