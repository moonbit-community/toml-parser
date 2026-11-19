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
      #|Failure(Invalid hex number: value out of Int64 range) at { start: { line: 1, column: 5 }, end: { line: 1, column: 23 } })
    ),
  )
  inspect(
    parse_expect_to_fail(
      "x = 0b1111111111111111111111111111111111111111111111111111111111111111\n",
    ),
    content=(
      #|Failure(Invalid binary number: value out of Int64 range) at { start: { line: 1, column: 5 }, end: { line: 1, column: 71 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0o2000000000000000000000\n"),
    content=(
      #|Failure(Invalid octal number: value out of Int64 range) at { start: { line: 1, column: 5 }, end: { line: 1, column: 29 } })
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

// ============================================================
// Bare keys that look like numbers, dates or special floats are keys: the
// numeric and date rules apply in value position only.
// ============================================================

///|
test "leading-zero bare keys keep their underscores and suffix" {
  debug_inspect(
    @toml.parse("0_1 = 1\n01 = 2\n01abc = 3\n"),
    content=(
      #|TomlTable(
      #|  {
      #|    "0_1": TomlInteger(1),
      #|    "01": TomlInteger(2),
      #|    "01abc": TomlInteger(3),
      #|  },
      #|)
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0_1\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 8 } })
    ),
  )
}

///|
test "radix-looking bare keys" {
  debug_inspect(
    @toml.parse(
      "0xg = 1\n0x8000000000000000 = 2\n0x1=3\n0o8 = 4\n0b2 = 5\n0x = 6\n",
    ),
    content=(
      #|TomlTable(
      #|  {
      #|    "0xg": TomlInteger(1),
      #|    "0x8000000000000000": TomlInteger(2),
      #|    "0x1": TomlInteger(3),
      #|    "0o8": TomlInteger(4),
      #|    "0b2": TomlInteger(5),
      #|    "0x": TomlInteger(6),
      #|  },
      #|)
    ),
  )
  debug_inspect(
    @toml.parse("[0xG0x10]\n0o7=1\n0b1=2\n"),
    content=(
      #|TomlTable({ "0xG0x10": TomlTable({ "0o7": TomlInteger(1), "0b1": TomlInteger(2) }) })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0xg\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 8 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0x\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 7 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0o789\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 10 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0b10_\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 10 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 0x8000000000000000\n"),
    content=(
      #|Failure(Invalid hex number: value out of Int64 range) at { start: { line: 1, column: 5 }, end: { line: 1, column: 23 } })
    ),
  )
  debug_inspect(
    @toml.parse("x=0x1\n"),
    content=(
      #|TomlTable({ "x": TomlInteger(1) })
    ),
  )
}

///|
test "date-looking bare keys" {
  debug_inspect(
    @toml.parse("2023-02-30 = 1\n2023-01-01abc = 2\n[2023-13-01]\n"),
    content=(
      #|TomlTable(
      #|  {
      #|    "2023-02-30": TomlInteger(1),
      #|    "2023-01-01abc": TomlInteger(2),
      #|    "2023-13-01": TomlTable({}),
      #|  },
      #|)
    ),
  )
  inspect(
    parse_expect_to_fail("x = 2023-02-30\n"),
    content=(
      #|Failure(Invalid date: day 30 exceeds max 28 for month 2) at { start: { line: 1, column: 5 }, end: { line: 1, column: 15 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = [2023-13-01]\n"),
    content=(
      #|Failure(Invalid date: month 13 out of range) at { start: { line: 1, column: 6 }, end: { line: 1, column: 16 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = {y = 2023-00-01}\n"),
    content=(
      #|Failure(Invalid date: month 0 out of range) at { start: { line: 1, column: 10 }, end: { line: 1, column: 20 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 2023-01-01abc\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 18 } })
    ),
  )
}

///|
test "signed special float bare keys" {
  debug_inspect(
    @toml.parse("-infinite = 1\n-inf.x = 2\n-nan-1 = 3\n"),
    content=(
      #|TomlTable(
      #|  {
      #|    "-infinite": TomlInteger(1),
      #|    "-inf": TomlTable({ "x": TomlInteger(2) }),
      #|    "-nan-1": TomlInteger(3),
      #|  },
      #|)
    ),
  )
  inspect(
    parse_expect_to_fail("x = -infinite\n"),
    content=(
      #|Expected value at { start: { line: 1, column: 5 }, end: { line: 1, column: 14 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = -inf.x\n"),
    content=(
      #|Expected newline or end of file after key-value pair at { start: { line: 1, column: 9 }, end: { line: 1, column: 10 } })
    ),
  )
}

///|
test "dotted keys after numbers" {
  debug_inspect(
    @toml.parse("1.abc = 1\n1.2x = 2\n3.5e3-y = 3\n"),
    content=(
      #|TomlTable(
      #|  {
      #|    "1": TomlTable({ "abc": TomlInteger(1), "2x": TomlInteger(2) }),
      #|    "3": TomlTable({ "5e3-y": TomlInteger(3) }),
      #|  },
      #|)
    ),
  )
  inspect(
    parse_expect_to_fail("1. = 1\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 3 } })
    ),
  )
  inspect(
    parse_expect_to_fail("a.1. = 1\n"),
    content=(
      #|Expected key after dot at { start: { line: 1, column: 3 }, end: { line: 1, column: 5 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 1.2x\n"),
    content=(
      #|Expected newline or end of file after key-value pair at { start: { line: 1, column: 6 }, end: { line: 1, column: 7 } })
    ),
  )
}

///|
test "a plus sign in an exponent is not a bare key character" {
  inspect(
    parse_expect_to_fail("1e+2x = 1\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 5 } })
    ),
  )
  inspect(
    parse_expect_to_fail("1e+2 = 1\n"),
    content=(
      #|Expected key at { start: { line: 1, column: 1 }, end: { line: 1, column: 5 } })
    ),
  )
  inspect(
    parse_expect_to_fail("a.1.2e+3 = 1\n"),
    content=(
      #|Expected key after dot at { start: { line: 1, column: 3 }, end: { line: 1, column: 9 } })
    ),
  )
  debug_inspect(
    @toml.parse("1e-2x = 1\n1.2e-3 = 2\n"),
    content=(
      #|TomlTable(
      #|  {
      #|    "1e-2x": TomlInteger(1),
      #|    "1": TomlTable({ "2e-3": TomlInteger(2) }),
      #|  },
      #|)
    ),
  )
}

///|
test "local time followed by a comment" {
  debug_inspect(
    @toml.parse("x = 07:32:00#comment\n"),
    content=(
      #|TomlTable({ "x": TomlDateTime(LocalTime("07:32:00")) })
    ),
  )
}

///|
test "time fraction needs seconds" {
  inspect(
    parse_expect_to_fail("x = 07:32.1\n"),
    content=(
      #|Unexpected character: ':')
    ),
  )
  inspect(
    parse_expect_to_fail("x = 1979-05-27T07:32.1Z\n"),
    content=(
      #|Expected newline or end of file after key-value pair at { start: { line: 1, column: 21 }, end: { line: 1, column: 22 } })
    ),
  )
  inspect(
    parse_expect_to_fail("x = 1979-05-27 07:32.5\n"),
    content=(
      #|Expected newline or end of file after key-value pair at { start: { line: 1, column: 21 }, end: { line: 1, column: 22 } })
    ),
  )
}

///|
test "escaped single quote is not an escape" {
  inspect(
    parse_expect_to_fail("x = \"\\'\"\n"),
    content=(
      #|Invalid escape sequence: \' at line 1, column 6)
    ),
  )
  inspect(
    parse_expect_to_fail("x = \"\"\"\\'\"\"\"\n"),
    content=(
      #|Invalid escape sequence: \' at line 1, column 10)
    ),
  )
}

///|
test "line ending backslash needs LF or CRLF" {
  inspect(
    parse_expect_to_fail("x = \"\"\"a\\\rb\"\"\"\n"),
    content=(
      #|Invalid escape: backslash followed by a bare CR at line 1, column 11)
    ),
  )
  debug_inspect(
    @toml.parse("x = \"\"\"a\\\r\n  b\"\"\"\n"),
    content=(
      #|TomlTable({ "x": TomlString("ab") })
    ),
  )
}

///|
test "control character code is hex" {
  let del = (0x7f).unsafe_to_char().to_string()
  inspect(
    parse_expect_to_fail("x = \"" + del + "\"\n"),
    content=(
      #|Invalid control character in basic string: U+007F at line 1, column 7)
    ),
  )
}
