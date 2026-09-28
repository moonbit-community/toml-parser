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
