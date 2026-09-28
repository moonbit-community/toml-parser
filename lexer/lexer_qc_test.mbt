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
