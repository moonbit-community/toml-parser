///|
/// Property-based tests for `bobzhang/lexer`, driven by
/// `moonbitlang/core/quickcheck`.
///
/// The central contract exercised here: when a caller crosses every line
/// terminator with `skip_single_newline` (or `advance` + `new_line`), the
/// lexer's `get_loc()` must equal a reference `(line, column)` computed from
/// the consumed prefix alone, where a column is one *character* (a surrogate
/// pair counts once, exactly as `advance` counts it) — no matter which
/// consuming primitive (`advance`, `update_view`, `expect_string`,
/// `expect_char`, `skip_whitespace`) moved the cursor.

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

///|
/// Characters biased towards what the lexer treats specially: whitespace,
/// line terminators, BMP non-ASCII (incl. neighbours of the surrogate
/// block) and astral characters that are stored as surrogate pairs.
fn interesting_char_gen() -> @qc.Generator[Char] {
  @qc.frequency([
    (6, @qc.char_range('a', 'z')),
    (3, @qc.elements([' ', '\t', '\r', '\n'])),
    (1, @qc.elements(['=', '"', '#', '0', '9', '\u{0}'])),
    (2, @qc.elements(['é', '中', '\u{D7FF}', '\u{E000}', '\u{FFFF}'])),
    (2, @qc.elements(['😈', '𝄞', '\u{10000}', '\u{10FFFF}'])),
    (1, @qc.spawn()),
  ])
}

///|
fn chars_gen() -> @qc.Generator[Array[Char]] {
  // Chunks are single characters or a CRLF pair, so `\r\n` shows up often
  // enough to matter.
  let chunk = @qc.frequency([
    (10, interesting_char_gen().map(c => [c])),
    (1, @qc.pure(['\r', '\n'])),
  ])
  @qc.sized(size => {
    @qc.int_range(0, size + 1).flat_map(n => {
      chunk
      .array_with_size(n)
      .map(chunks => {
        let out = []
        for c in chunks {
          out.append(c)
        }
        out
      })
    })
  })
}

///|
/// A well-formed (surrogate-pair-correct) input string.
priv struct Input {
  chars : Array[Char]
} derive(Debug)

///|
fn Input::text(self : Input) -> String {
  String::from_array(self.chars)
}

///|
impl @qc.Arbitrary for Input with fn arbitrary(size, rs) {
  { chars: chars_gen().run(size, rs), }
}

///|
impl @qc.Shrink for Input with fn shrink(self) {
  @qc.Shrink::shrink(self.chars).map(chars => { chars, })
}

///|
/// An input plus a script of small non-negative integers that a driver
/// interprets as lexer operations / argument choices.
priv struct Script {
  chars : Array[Char]
  ops : Array[Int]
} derive(Debug)

///|
fn Script::text(self : Script) -> String {
  String::from_array(self.chars)
}

///|
impl @qc.Arbitrary for Script with fn arbitrary(size, rs) {
  let rs2 = rs.split()
  let ops = @qc.sized(size => {
    @qc.int_range(0, size * 2 + 1).flat_map(n => {
      @qc.int_range(0, 64).array_with_size(n)
    })
  }).run(size, rs2)
  { chars: chars_gen().run(size, rs), ops, }
}

///|
impl @qc.Shrink for Script with fn shrink(self) {
  @qc.Shrink::shrink((self.chars, self.ops)).map(p => { chars: p.0, ops: p.1, })
}

///|
/// Raw UTF-16 code units, including lone (unpaired) surrogates. MoonBit
/// `String`s can hold such data, so the lexer must at least stay in bounds.
priv struct Units {
  units : Array[Int]
  ops : Array[Int]
} derive(Debug)

///|
fn unit_gen() -> @qc.Generator[Int] {
  @qc.frequency([
    (4, @qc.int_range('a'.to_int(), 'z'.to_int() + 1)),
    (2, @qc.elements([' ', '\t', '\r', '\n'].map(c => c.to_int()))),
    (2, @qc.int_range(0xD800, 0xDC00)), // leading surrogates
    (2, @qc.int_range(0xDC00, 0xE000)), // trailing surrogates
    (1, @qc.int_range(0, 0x10000)),
  ])
}

///|
fn Units::text(self : Units) -> String {
  string_of_units(self.units)
}

///|
impl @qc.Arbitrary for Units with fn arbitrary(size, rs) {
  let rs2 = rs.split()
  let units = @qc.int_range(0, size + 1)
    .flat_map(n => unit_gen().array_with_size(n))
    .run(size, rs)
  let ops = @qc.int_range(0, size * 2 + 1)
    .flat_map(n => @qc.int_range(0, 64).array_with_size(n))
    .run(size, rs2)
  { units, ops, }
}

///|
impl @qc.Shrink for Units with fn shrink(self) {
  @qc.Shrink::shrink((self.units, self.ops)).map(p => { units: p.0, ops: p.1, })
}

// ---------------------------------------------------------------------------
// Reference model and helpers
// ---------------------------------------------------------------------------

///|
/// Reference location after consuming `consumed`, assuming every `\n` was
/// crossed with a newline-aware primitive. Columns count characters.
fn reference_loc(consumed : StringView) -> @lexer.Position {
  let mut line = 1
  let mut column = 1
  for c in consumed {
    if c == '\n' {
      line += 1
      column = 1
    } else {
      column += 1
    }
  }
  { line, column, }
}

///|
fn consumed(input : String, lexer : @lexer.Lexer) -> StringView {
  input.view(end_offset=lexer.get_position())
}

///|
fn state(lexer : @lexer.Lexer) -> (Int, @lexer.Position) {
  (lexer.get_position(), lexer.get_loc())
}

///|
fn at_line_terminator(view : StringView) -> Bool {
  view is (['\n', ..] | ['\r', '\n', ..])
}

///|
/// Up to `k` leading characters of `view` that do not reach a line
/// terminator (`\n` or the `\r` of a `\r\n`).
fn same_line_prefix(view : StringView, k : Int) -> String {
  let sb = StringBuilder()
  let mut taken = 0
  let mut rest = view
  while taken < k && !at_line_terminator(rest) {
    match rest {
      [c, .. tail] => {
        sb.write_char(c)
        rest = tail
        taken += 1
      }
      _ => break
    }
  }
  sb.to_string()
}

///|
/// Advance `n` characters without crossing a line terminator. Returns how
/// many characters were actually consumed.
fn advance_same_line(lexer : @lexer.Lexer, n : Int) -> Int {
  let mut i = 0
  while i < n && lexer.peek() is Some(_) && !at_line_terminator(lexer.view()) {
    lexer.advance()
    i += 1
  }
  i
}

///|
fn fresh_at(input : String, ops : Array[Int]) -> @lexer.Lexer {
  // Position a lexer somewhere inside `input` using only newline-aware
  // moves: `ops[0]` (0..63) picks a point spread over the whole input, and
  // `ops[3]` sometimes pushes the cursor on to the next line terminator.
  let lexer = @lexer.Lexer::Lexer(input)
  let steps = if ops.is_empty() {
    0
  } else {
    ops[0] * (input.length() + 1) / 64
  }
  for _ in 0..<steps {
    if at_line_terminator(lexer.view()) {
      lexer.skip_single_newline()
    } else if lexer.peek() is Some(_) {
      lexer.advance()
    }
  }
  if ops.length() > 3 && ops[3] % 3 == 0 {
    while lexer.peek() is Some(_) && !at_line_terminator(lexer.view()) {
      lexer.advance()
    }
  }
  lexer
}

///|
/// Run one scripted operation. Line terminators are always crossed with
/// `skip_single_newline`; everything else is chosen by `op`.
fn step(lexer : @lexer.Lexer, op : Int) -> Unit raise {
  let view = lexer.view()
  if at_line_terminator(view) {
    lexer.skip_single_newline()
    return
  }
  let k = op / 8 % 4 + 1
  match op % 8 {
    0 | 1 => lexer.advance()
    2 => lexer.skip_whitespace()
    3 => {
      let prefix = same_line_prefix(view, k)
      lexer.update_view(view.view(start_offset=prefix.length()))
    }
    4 => lexer.expect_string(same_line_prefix(view, k))
    5 => if lexer.peek() is Some(c) { lexer.expect_char(c) }
    6 => {
      // A mismatching expectation must fail and leave the state alone
      // (the caller re-checks the location against the model).
      let prefix = same_line_prefix(view, k)
      let next = view.view(start_offset=prefix.length())
      let s = prefix + (if next is ['\u{1}', ..] { "\u{2}" } else { "\u{1}" })
      try lexer.expect_string(s) catch {
        _ => ()
      } noraise {
        _ => fail("expect_string(\{repr(s)}) unexpectedly succeeded")
      }
    }
    _ => ignore(lexer.peek())
  }
}

///|
fn fixed_seed() -> UInt64 {
  0x1e7e5_2026
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

///|
test "qc: peek/advance walks every character of the input exactly once" {
  @qc.check(
    (inp : Input) => {
      let input = inp.text()
      let lexer = @lexer.Lexer::Lexer(input)
      let out = []
      while lexer.peek() is Some(c) {
        out.push(c)
        lexer.advance()
      }
      out == inp.chars &&
      lexer.get_position() == input.length() &&
      lexer.peek_charcode() is None &&
      lexer.view().length() == 0
    },
    observe=inp => {
      let s = inp.text()
      [
        @qc.classify(s.length() > inp.chars.length(), "has surrogate pairs"),
        @qc.classify(inp.chars.contains('\n'), "has \\n"),
        @qc.classify(s.contains("\r\n"), "has \\r\\n"),
        @qc.classify(inp.chars.is_empty(), "empty"),
      ]
    },
    count=500,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: consumed prefix ++ view() is always the whole input" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let lexer = @lexer.Lexer::Lexer(input)
      for op in s.ops {
        step(lexer, op)
        let pos = lexer.get_position()
        guard pos >= 0 && pos <= input.length() else { return false }
        guard consumed(input, lexer).to_owned() + lexer.view().to_owned() ==
          input else {
          return false
        }
      }
      true
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: get_loc matches a line/column reference model under every primitive" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let lexer = @lexer.Lexer::Lexer(input)
      let mut last = 0
      for op in s.ops {
        step(lexer, op)
        guard lexer.get_position() >= last else { return false }
        last = lexer.get_position()
        guard lexer.get_loc() == reference_loc(consumed(input, lexer)) else {
          return false
        }
      }
      // Drain the rest and check the final location too.
      while lexer.peek() is Some(_) {
        step(lexer, 0)
      }
      lexer.get_position() == input.length() &&
      lexer.get_loc() == reference_loc(input)
    },
    observe=s => {
      let kinds = s.ops.map(op => op % 8)
      [
        @qc.classify(s.text().length() > s.chars.length(), "astral chars"),
        @qc.classify(s.text().contains("\r\n"), "CRLF"),
        @qc.classify(kinds.contains(3), "update_view"),
        @qc.classify(kinds.contains(4), "expect_string"),
        @qc.classify(s.ops.length() > 20, "long script"),
      ]
    },
    counterexample_context=s => repr(s.text()),
    count=500,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: peek, peek_charcode, get_loc and view never consume" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let lexer = fresh_at(input, s.ops)
      let before = state(lexer)
      let v1 = lexer.view().to_owned()
      let p1 = lexer.peek()
      let c1 = lexer.peek_charcode()
      let p2 = lexer.peek()
      let c2 = lexer.peek_charcode()
      ignore(lexer.get_loc())
      ignore(lexer.error("x"))
      p1 == p2 && c1 == c2 && state(lexer) == before && lexer.view() == v1
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: peek and peek_charcode agree with the head of view()" {
  @qc.check(
    (s : Script) => {
      let lexer = fresh_at(s.text(), s.ops)
      let view = lexer.view()
      let head_char : Char? = match view {
        [c, ..] => Some(c)
        [] => None
      }
      let head_unit = if view.length() > 0 {
        Some(view.unsafe_get(0))
      } else {
        None
      }
      lexer.peek() == head_char && lexer.peek_charcode() == head_unit
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: update_view(view()) is the identity" {
  @qc.check(
    (s : Script) => {
      let lexer = fresh_at(s.text(), s.ops)
      let before = state(lexer)
      lexer.update_view(lexer.view())
      state(lexer) == before
    },
    count=200,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: dropping k chars with update_view == k advances" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let a = fresh_at(input, s.ops)
      let b = fresh_at(input, s.ops)
      let k = if s.ops.length() > 1 { s.ops[1] % 6 } else { 1 }
      let n = advance_same_line(a, k)
      let view = b.view()
      let prefix = same_line_prefix(view, k)
      b.update_view(view.view(start_offset=prefix.length()))
      prefix.char_length() == n && state(a) == state(b)
    },
    counterexample_context=s => repr(s.text()),
    count=500,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: update_view to a saved view backtracks exactly (same line)" {
  @qc.check(
    (s : Script) => {
      let lexer = fresh_at(s.text(), s.ops)
      let saved_view = lexer.view()
      let saved = state(lexer)
      let k = if s.ops.length() > 1 { s.ops[1] % 6 } else { 1 }
      ignore(advance_same_line(lexer, k))
      lexer.skip_whitespace()
      lexer.update_view(saved_view)
      state(lexer) == saved && lexer.view() == saved_view
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: expect_string of the upcoming text == advancing over it" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let a = fresh_at(input, s.ops)
      let b = fresh_at(input, s.ops)
      let k = if s.ops.length() > 1 { s.ops[1] % 6 } else { 1 }
      let expected = same_line_prefix(a.view(), k)
      a.expect_string(expected)
      ignore(advance_same_line(b, expected.char_length()))
      state(a) == state(b)
    },
    counterexample_context=s => repr(s.text()),
    count=500,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|

///|
/// Mix arbitrary literals with (extensions of) the upcoming text.
fn pick_literal(lexer : @lexer.Lexer, s : Script, lit : String) -> String {
  let k = if s.ops.length() > 1 { s.ops[1] % 6 } else { 1 }
  let prefix = same_line_prefix(lexer.view(), k)
  match (if s.ops.length() > 2 { s.ops[2] % 3 } else { 0 }) {
    0 => lit
    1 => prefix
    _ => prefix + lit
  }
}

///|
test "qc: expect_string succeeds iff view starts with it; failure changes nothing" {
  @qc.check(
    (p : (Script, String)) => {
      let (s, lit) = p
      let lexer = fresh_at(s.text(), s.ops)
      let before = state(lexer)
      let lit = pick_literal(lexer, s, lit)
      let matches = lexer.view().has_prefix(lit)
      let expected_msg = lexer.error("Expected string: " + lit)
      try lexer.expect_string(lit) catch {
        Failure(msg) =>
          !matches && state(lexer) == before && msg.has_suffix(expected_msg)
        _ => false
      } noraise {
        _ => matches && lexer.get_position() == before.0 + lit.length()
      }
    },
    observe=p => {
      let (s, lit) = p
      let lexer = fresh_at(s.text(), s.ops)
      let lit = pick_literal(lexer, s, lit)
      [
        @qc.classify(lexer.view().has_prefix(lit), "literal matches"),
        @qc.classify(lit.length() > lit.char_length(), "literal has astral"),
      ]
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: expect_char succeeds iff peek matches, otherwise state is unchanged" {
  @qc.check(
    (p : (Script, Char)) => {
      let (s, c) = p
      let lexer = fresh_at(s.text(), s.ops)
      let before = state(lexer)
      let ch = if s.ops.length() > 2 && s.ops[2] % 2 == 0 {
        lexer.peek().unwrap_or(c)
      } else {
        c
      }
      let hit = lexer.peek() == Some(ch)
      let loc_msg = " at line \{before.1.line}, column \{before.1.column}"
      try lexer.expect_char(ch) catch {
        Failure(msg) =>
          !hit && state(lexer) == before && msg.has_suffix(loc_msg)
        _ => false
      } noraise {
        _ =>
          hit &&
          lexer.get_position() == before.0 + ch.utf16_len() &&
          lexer.get_loc() == { ..before.1, column: before.1.column + 1, }
      }
    },
    observe=p => {
      let (s, _) = p
      [@qc.classify(s.ops.length() > 2 && s.ops[2] % 2 == 0, "expected = peek")]
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: skip_whitespace consumes exactly the maximal run of ' ', '\\t', lone '\\r'" {
  @qc.check(
    (s : Script) => {
      let input = s.text()
      let lexer = fresh_at(input, s.ops)
      let (pos0, loc0) = state(lexer)
      lexer.skip_whitespace()
      let (pos1, loc1) = state(lexer)
      let skipped = input.view(start_offset=pos0, end_offset=pos1)
      let only_ws = skipped.iter().all(c => c is (' ' | '\t' | '\r')) &&
        !skipped.contains("\r\n") &&
        !(skipped.has_suffix("\r") && lexer.view() is ['\n', ..])
      let maximal = match lexer.view() {
        [' ' | '\t', ..] => false
        ['\r', '\n', ..] => true
        ['\r', ..] => false
        _ => true
      }
      // Idempotent.
      lexer.skip_whitespace()
      only_ws &&
      maximal &&
      loc1 == { line: loc0.line, column: loc0.column + (pos1 - pos0), } &&
      state(lexer) == (pos1, loc1)
    },
    observe=s => {
      [
        @qc.classify(s.text().contains(" "), "has space"),
        @qc.classify(s.text().contains("\r"), "has \\r"),
      ]
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: skip_single_newline consumes one \\n or \\r\\n, else is a no-op" {
  @qc.check(
    (s : Script) => {
      let lexer = fresh_at(s.text(), s.ops)
      let (pos0, loc0) = state(lexer)
      let expect_len = match lexer.view() {
        ['\n', ..] => 1
        ['\r', '\n', ..] => 2
        _ => 0
      }
      lexer.skip_single_newline()
      if expect_len == 0 {
        state(lexer) == (pos0, loc0)
      } else {
        state(lexer) == (pos0 + expect_len, { line: loc0.line + 1, column: 1, })
      }
    },
    observe=s => {
      let lexer = fresh_at(s.text(), s.ops)
      [
        @qc.label(
          match lexer.view() {
            ['\n', ..] => "at \\n"
            ['\r', '\n', ..] => "at \\r\\n"
            _ => "not at newline"
          },
        ),
      ]
    },
    count=300,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: error() appends the current line and column" {
  @qc.check(
    (p : (Script, String)) => {
      let (s, msg) = p
      let lexer = fresh_at(s.text(), s.ops)
      let loc = lexer.get_loc()
      lexer.error(msg) == "\{msg} at line \{loc.line}, column \{loc.column}"
    },
    count=200,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

///|
test "qc: arbitrary UTF-16 (lone surrogates): cursor stays in bounds and drains" {
  @qc.check(
    (u : Units) => {
      let input = u.text()
      guard input.length() == u.units.length() else { return false }
      let lexer = @lexer.Lexer::Lexer(input)
      let mut last = 0
      for op in u.ops {
        match op % 4 {
          0 | 1 => lexer.advance()
          2 => lexer.skip_whitespace()
          _ => lexer.skip_single_newline()
        }
        let pos = lexer.get_position()
        guard pos >= last && pos <= input.length() else { return false }
        guard lexer.view().length() == input.length() - pos else {
          return false
        }
        guard lexer.peek() == input.get_char(pos) else { return false }
        last = pos
      }
      // `advance` must reach the end in at most one step per code unit and
      // must make progress while input remains.
      let mut steps = 0
      while lexer.get_position() < input.length() && steps <= input.length() {
        let before = lexer.get_position()
        lexer.advance()
        guard lexer.get_position() > before else { return false }
        steps += 1
      }
      lexer.get_position() == input.length()
    },
    observe=u => {
      [
        @qc.classify(
          u.units.iter().any(x => x >= 0xD800 && x < 0xE000),
          "has surrogate units",
        ),
        @qc.classify(
          u.units.length() > 0 &&
          u.units[u.units.length() - 1] >= 0xD800 &&
          u.units[u.units.length() - 1] < 0xDC00,
          "ends with leading surrogate",
        ),
      ]
    },
    counterexample_context=u => {
      u.units.map(x => "0x" + x.to_string(radix=16)).join(" ")
    },
    count=500,
    max_shrinks=2000,
    seed=fixed_seed(),
  )
}

// ---------------------------------------------------------------------------
// Regression tests (shrunk counterexamples found by the quickcheck properties)
// ---------------------------------------------------------------------------

///|
/// Build a string from raw UTF-16 code units (lone surrogates allowed).
fn string_of_units(units : Array[Int]) -> String {
  let sb = StringBuilder()
  for u in units {
    sb.write_char((u & 0xFFFF).unsafe_to_char())
  }
  sb.to_string()
}

///|
test "regression: advance over a lone surrogate stays in bounds" {
  // Found by "qc: arbitrary UTF-16 (lone surrogates) ...": counterexample
  // units=[0xd800]. `advance` used to step two code units for any surrogate,
  // leaving position=2 in a 1-unit string (view() then aborts).
  let lexer = @lexer.Lexer::Lexer(string_of_units([0xD800]))
  lexer.advance()
  debug_inspect(
    (lexer.get_position(), lexer.get_loc()),
    content="(1, { line: 1, column: 2 })",
  )
  inspect(lexer.view(), content="")
  // An unpaired surrogate must not swallow the following character.
  let lexer = @lexer.Lexer::Lexer(string_of_units([0xD800, 'a'.to_int()]))
  lexer.advance()
  debug_inspect(lexer.peek(), content="Some('a')")
  let lexer = @lexer.Lexer::Lexer(string_of_units([0xDC00, 'b'.to_int()]))
  lexer.advance()
  debug_inspect(lexer.peek(), content="Some('b')")
  // A real surrogate pair is still one step.
  let lexer = @lexer.Lexer::Lexer("😈x")
  lexer.advance()
  debug_inspect((lexer.get_position(), lexer.peek()), content="(2, Some('x'))")
}

///|
test "regression: update_view counts a surrogate pair as one column" {
  // Found by "qc: dropping k chars with update_view == k advances" and
  // "qc: get_loc matches a line/column reference model ...": counterexample
  // chars=['😈']. `update_view` added UTF-16 units to the column, while
  // `advance` adds one per character.
  let lexer = @lexer.Lexer::Lexer("😈x中")
  match lexer.view() {
    [.. "😈x", .. rest] => lexer.update_view(rest)
    _ => ()
  }
  debug_inspect(lexer.get_loc(), content="{ line: 1, column: 3 }")
  let by_advance = @lexer.Lexer::Lexer("😈x中")
  by_advance.advance()
  by_advance.advance()
  debug_inspect(by_advance.get_loc(), content="{ line: 1, column: 3 }")
  // Backtracking to a saved view restores the column exactly
  // ("qc: update_view to a saved view backtracks exactly", chars=['\u{f80bc}']).
  let lexer = @lexer.Lexer::Lexer("😈")
  let saved = lexer.view()
  lexer.advance()
  lexer.update_view(saved)
  debug_inspect(lexer.get_loc(), content="{ line: 1, column: 1 }")
}

///|
test "regression: expect_string accepts literals containing astral characters" {
  // Found by "qc: expect_string of the upcoming text == advancing over it":
  // counterexample chars=['😈']. The code-unit loop called `advance`, which
  // steps over the whole pair, so the literal's trailing surrogate was then
  // compared against the next character and the match always failed.
  let lexer = @lexer.Lexer::Lexer("😈x=")
  lexer.expect_string("😈x")
  debug_inspect(
    (lexer.get_position(), lexer.get_loc(), lexer.peek()),
    content="(3, { line: 1, column: 3 }, Some('='))",
  )
  // A mismatch still reports the start position and leaves the lexer alone.
  let lexer = @lexer.Lexer::Lexer("😈y")
  let msg = try lexer.expect_string("😈x") catch {
    Failure(msg) => msg
    _ => "unexpected error"
  } noraise {
    _ => "unexpected success"
  }
  assert_true(msg.has_suffix("Expected string: 😈x at line 1, column 1"))
  inspect(lexer.get_position(), content="0")
}
