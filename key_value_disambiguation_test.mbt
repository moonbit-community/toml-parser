///|
/// Regression tests for number-like tokens that must work both as values and
/// as bare keys. The tokenizer keeps the raw source text on numeric tokens
/// and the parser decides from the grammatical context; previously the
/// tokenizer guessed the context with a lookahead that misclassified
/// numbers in several positions.

///|
test "underscored or exponent numbers as last array element" {
  // These used to fail with "Expected value": a number followed by `]` and
  // newline/EOF was mistaken for a table-header key.
  debug_inspect(
    @toml.parse("arr = [1_0]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlInteger(10)]) })
    ),
  )
  debug_inspect(
    @toml.parse("arr = [1_000.5]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlFloat(1000.5)]) })
    ),
  )
  debug_inspect(
    @toml.parse("arr = [1e3]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlFloat(1000)]) })
    ),
  )
  debug_inspect(
    @toml.parse("arr = [\n  1_000.5,\n  2.5_5,\n]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlFloat(1000.5), TomlFloat(2.55)]) })
    ),
  )
}

///|
test "'+' signed numbers as last array element" {
  // The old key-position lookahead rejected any `+number]` at end of line.
  debug_inspect(
    @toml.parse("arr = [+5]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlInteger(5)]) })
    ),
  )
  debug_inspect(
    @toml.parse("arr = [+5.5]\n"),
    content=(
      #|TomlTable({ "arr": TomlArray([TomlFloat(5.5)]) })
    ),
  )
}

///|
test "number-like bare keys keep their raw text" {
  debug_inspect(
    @toml.parse("[1_0]\nx = 1\n"),
    content=(
      #|TomlTable({ "1_0": TomlTable({ "x": TomlInteger(1) }) })
    ),
  )
  debug_inspect(
    @toml.parse("[-1_0]\nx = 1\n"),
    content=(
      #|TomlTable({ "-1_0": TomlTable({ "x": TomlInteger(1) }) })
    ),
  )
  debug_inspect(
    @toml.parse("[0xAB]\nx = 1\n"),
    content=(
      #|TomlTable({ "0xAB": TomlTable({ "x": TomlInteger(1) }) })
    ),
  )
  debug_inspect(
    @toml.parse("0xAB.cd = 1\n"),
    content=(
      #|TomlTable({ "0xAB": TomlTable({ "cd": TomlInteger(1) }) })
    ),
  )
  debug_inspect(
    @toml.parse("1_000.5 = 3\n"),
    content=(
      #|TomlTable({ "1_000": TomlTable({ "5": TomlInteger(3) }) })
    ),
  )
  debug_inspect(
    @toml.parse("-5y = 3\n"),
    content=(
      #|TomlTable({ "-5y": TomlInteger(3) })
    ),
  )
}

///|
test "uppercase hex octal binary prefixes are not numbers" {
  // TOML only allows lowercase 0x/0o/0b prefixes, so 0X/0O/0B in value
  // position is an error...
  for input in ["x = 0XDEAD\n", "x = 0O755\n", "x = 0B1010\n"] {
    assert_true(parse_expect_to_fail(input).has_prefix("Expected value"))
  }
  // ...but they are still valid bare keys.
  debug_inspect(
    @toml.parse("[0XAB]\nx = 1\n"),
    content=(
      #|TomlTable({ "0XAB": TomlTable({ "x": TomlInteger(1) }) })
    ),
  )
}

///|
test "'+' signed numbers are never bare keys" {
  // '+' is not a bare-key character, so all of these must be rejected
  // (several used to parse with the '+' silently dropped).
  inspect(
    parse_expect_to_fail("+5 = 3\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 3 } })
    ),
  )
  inspect(
    parse_expect_to_fail("+5.5 = 3\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 5 } })
    ),
  )
  inspect(
    parse_expect_to_fail("+5e3 = 3\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 5 } })
    ),
  )
  inspect(
    parse_expect_to_fail("+5y = 3\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 3 } })
    ),
  )
  inspect(
    parse_expect_to_fail("[+5]\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 2 }, end: { line: 1, column: 4 } })
    ),
  )
  inspect(
    parse_expect_to_fail("+inf = 1\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 5 } })
    ),
  )
}

///|
test "signed number values still work" {
  debug_inspect(
    @toml.parse("x = +5\ny = -5\n"),
    content=(
      #|TomlTable({ "x": TomlInteger(5), "y": TomlInteger(-5) })
    ),
  )
  debug_inspect(
    @toml.parse("x = +5.5\ny = -5.5\n"),
    content=(
      #|TomlTable({ "x": TomlFloat(5.5), "y": TomlFloat(-5.5) })
    ),
  )
}

///|
test "hex octal binary overflow is rejected" {
  // These used to silently wrap around (0xFFFFFFFFFFFFFFFF parsed as -1)
  // while decimal overflow was already an error.
  inspect(
    parse_expect_to_fail("x = 0xFFFFFFFFFFFFFFFF\n"),
    content=(
      #|Invalid hex number: value out of Int64 range at line 1, column 5)
    ),
  )
  inspect(
    parse_expect_to_fail(
      "x = 0b1111111111111111111111111111111111111111111111111111111111111111\n",
    ),
    content=(
      #|Invalid binary number: value out of Int64 range at line 1, column 5)
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0o2000000000000000000000\n"),
    content=(
      #|Invalid octal number: value out of Int64 range at line 1, column 5)
    ),
  )
  // The boundaries of the Int64 range still parse.
  debug_inspect(
    @toml.parse("x = 0x7FFFFFFFFFFFFFFF\n"),
    content=(
      #|TomlTable({ "x": TomlInteger(9223372036854775807) })
    ),
  )
  debug_inspect(
    @toml.parse("x = -9223372036854775808\n"),
    content=(
      #|TomlTable({ "x": TomlInteger(-9223372036854775808) })
    ),
  )
}

///|
test "dotted-key tables cannot be reopened by headers" {
  // TOML 1.0: dotted keys define the tables for each key part, and such
  // tables cannot be redefined with a [table] header.
  inspect(
    parse_expect_to_fail("fruit.apple = 1\n\n[fruit]\n"),
    content=(
      #|Duplicate table definition: [fruit] at { start: { line: 3, column: 8 }, end: { line: 4, column: 1 } })
    ),
  )
  inspect(
    parse_expect_to_fail("a.b.c = 1\n[a]\n"),
    content=(
      #|Duplicate table definition: [a] at { start: { line: 2, column: 4 }, end: { line: 3, column: 1 } })
    ),
  )
  inspect(
    parse_expect_to_fail("a.b.c = 1\n[a.b]\n"),
    content=(
      #|Duplicate table definition: [a.b] at { start: { line: 2, column: 6 }, end: { line: 3, column: 1 } })
    ),
  )
  inspect(
    parse_expect_to_fail("[[a]]\nb.c = 1\n[a.b]\n"),
    content=(
      #|Duplicate table definition: [a.b] at { start: { line: 3, column: 6 }, end: { line: 4, column: 1 } })
    ),
  )
}

///|
test "implicit super-tables from headers can still be defined" {
  // Tables created implicitly by [a.b] headers (not by dotted keys) may be
  // defined by a later [a] header.
  debug_inspect(
    @toml.parse("[a.b]\nx = 1\n[a]\ny = 2\n"),
    content=(
      #|TomlTable({ "a": TomlTable({ "b": TomlTable({ "x": TomlInteger(1) }), "y": TomlInteger(2) }) })
    ),
  )
  // Defining a new sub-table under a dotted-key table is also fine.
  debug_inspect(
    @toml.parse("a.b = 1\n[a.c]\nx = 2\n"),
    content=(
      #|TomlTable({ "a": TomlTable({ "b": TomlInteger(1), "c": TomlTable({ "x": TomlInteger(2) }) }) })
    ),
  )
}

///|
test "static arrays cannot be appended by array-of-tables headers" {
  // `[[a]]` may only append to arrays it created, never to a static array,
  // even a static array of inline tables.
  for
    input in [
      "a = []\n[[a]]\n", "a = [{}]\n[[a]]\n", "a = [ {x = 1} ]\n[[a]]\ny = 2\n",
    ] {
    assert_true(parse_expect_to_fail(input).has_prefix("ExpectedArray"))
  }
}

///|
test "bare keys are not subject to numeric underscore or range rules" {
  // Bare keys only require A-Za-z0-9_- characters; underscore placement and
  // Int64 range are numeric-literal rules and do not apply in key position.
  // (Regression: these used to fail numeric validation before the parser
  // could use the raw text as a key.)
  debug_inspect(
    @toml.parse("1__0 = 1\n"),
    content=(
      #|TomlTable({ "1__0": TomlInteger(1) })
    ),
  )
  debug_inspect(
    @toml.parse("[1_]\nx = 2\n"),
    content=(
      #|TomlTable({ "1_": TomlTable({ "x": TomlInteger(2) }) })
    ),
  )
  debug_inspect(
    @toml.parse("1_.5 = 3\n"),
    content=(
      #|TomlTable({ "1_": TomlTable({ "5": TomlInteger(3) }) })
    ),
  )
  debug_inspect(
    @toml.parse("99999999999999999999 = 1\n"),
    content=(
      #|TomlTable({ "99999999999999999999": TomlInteger(1) })
    ),
  )
  debug_inspect(
    @toml.parse("-99999999999999999999 = 1\n"),
    content=(
      #|TomlTable({ "-99999999999999999999": TomlInteger(1) })
    ),
  )
}

///|
test "numeric validation still applies in value position" {
  // The same texts are invalid as values — and the error keeps the specific
  // reason rather than degrading to a generic "Expected value".
  debug_inspect(
    [
      parse_expect_to_fail("x = 1__0\n"),
      parse_expect_to_fail("arr = [1__0]\n"),
      parse_expect_to_fail("x = 1_\n"),
      parse_expect_to_fail("x = 1.5_\n"),
      parse_expect_to_fail("x = 99999999999999999999\n"),
    ],
    content=(
      #|[
      #|  "Failure(Invalid number: underscore not between digits) at { start: { line: 1, column: 5 }, end: { line: 1, column: 9 } })",
      #|  "Failure(Invalid number: underscore not between digits) at { start: { line: 1, column: 8 }, end: { line: 1, column: 12 } })",
      #|  "Failure(Invalid number: trailing underscore) at { start: { line: 1, column: 5 }, end: { line: 1, column: 7 } })",
      #|  "Failure(Invalid number: trailing underscore) at { start: { line: 1, column: 5 }, end: { line: 1, column: 9 } })",
      #|  "Failure(Invalid integer: 99999999999999999999) at { start: { line: 1, column: 5 }, end: { line: 1, column: 25 } })",
      #|]
    ),
  )
}
