///|
/// Lexer implementation for TOML
#valtype
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq, Debug)

///|
#deprecated("compare with `==`; the Eq impl is unaffected")
pub extend Position with Eq::{not_equal, equal}

///|
#deprecated("render via the Debug trait, e.g. `debug_inspect`")
pub extend Position with Debug::{to_repr}

///|
/// Lexer state with position tracking for better error reporting
struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
}

///|
/// Get a view of the input string
/// # Example:
/// ```
/// let lexer = Lexer::Lexer("Hello, world!")
/// lexer.advance()
/// lexer.advance()
/// inspect(lexer.view(), content="llo, world!")
/// ```
pub fn Lexer::view(self : Lexer) -> StringView {
  self.input.view(start_offset=self.position)
}

///|
/// Update the lexer's position and column based on a new view
/// # Example:
/// ```
/// let lexer = Lexer::Lexer("😈x中world!")
/// match lexer.view() {
///  [.."😈x", .. rest] => lexer.update_view(rest)
///  _ => ()
/// }
/// inspect(lexer.peek(), content="Some('中')")
/// ```
pub fn Lexer::update_view(self : Lexer, view : StringView) -> Unit {
  let new_offset = view.start_offset()
  // Columns count characters (as `advance` does), not UTF-16 code units, so
  // a surrogate pair between the old and new offsets counts once. Moving
  // backwards (backtracking to a saved view) subtracts symmetrically.
  if new_offset >= self.position {
    self.column += column_width(self.input, self.position, new_offset)
  } else {
    self.column -= column_width(self.input, new_offset, self.position)
  }
  self.position = new_offset
}

///|
/// Number of columns spanned by the UTF-16 range `[start, end)` of `input`:
/// one per character, where a well-formed surrogate pair is one character
/// and any unpaired surrogate code unit is one character on its own.
fn column_width(input : String, start : Int, end : Int) -> Int {
  let end = if end > input.length() { input.length() } else { end }
  let mut width = 0
  for i = start; i < end; i = i + 1 {
    let paired_trailing = i > start &&
      input.unsafe_get(i).is_trailing_surrogate() &&
      input.unsafe_get(i - 1).is_leading_surrogate()
    if !paired_trailing {
      width += 1
    }
  }
  width
}

///|
/// Create a new lexer
pub fn Lexer::Lexer(input : String) -> Lexer {
  { input, position: 0, line: 1, column: 1, }
}

///|
/// Tests for lexer creation
test "lexer creation" {
  let lexer = Lexer::Lexer("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
  inspect(lexer.line, content="1")
  inspect(lexer.column, content="1")
}

///|
/// Skip whitespace characters not including newlines
/// Note: This method does not skip '\n' characters as those are significant in TOML
/// # Example:
/// ```
/// let lexer = Lexer::Lexer("  \t\rHello, world!")
/// lexer.skip_whitespace()
/// inspect(lexer.peek(), content="Some('H')")
/// ```
pub fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  let next = for view = self.view() {
    match view {
      ['\r', '\n', ..] | ['\n', ..] as rest => break rest
      [' ' | '\t' | '\r', .. rest] => continue rest
      rest => break rest
    }
  }
  self.update_view(next)
}

///|
/// Consume one line terminator if the cursor is sitting on one.
///
/// Both `\n` and `\r\n` are treated as a single newline, and the line
/// counter is advanced. If the next character is not a newline this is a
/// no-op, which makes the call safe to use after constructs that may or
/// may not have left a trailing newline behind (e.g. comments at EOF).
pub fn Lexer::skip_single_newline(self : Lexer) -> Unit {
  match self.view() {
    ['\r', '\n', .. rest] | ['\n', .. rest] => {
      self.update_view(rest)
      self.new_line()
    }
    _ => ()
  }
}

///|
/// Get current character without advancing
/// # Example:
/// ```
/// let lexer = Lexer::Lexer("Hello, world!")
/// inspect(lexer.peek(), content="Some('H')")
/// lexer.advance()
/// inspect(lexer.peek(), content="Some('e')")
/// ```
pub fn Lexer::peek(self : Lexer) -> Char? {
  self.input.get_char(self.position)
}

///|
/// Return the raw UTF-16 code unit at the cursor without advancing.
///
/// Unlike `peek`, which decodes a full `Char` (and so may span a surrogate
/// pair), this returns the underlying 16-bit unit directly. Useful in hot
/// paths where the lexer only needs to test ASCII bytes and wants to skip
/// the UTF-decoding cost. Returns `None` at end of input.
pub fn Lexer::peek_charcode(self : Lexer) -> UInt16? {
  if self.position < self.input.length() {
    Some(self.input.unsafe_get(self.position))
  } else {
    None
  }
}

///|
/// Return the current 1-based `(line, column)` position.
///
/// Use this to capture the start of a lexeme before consuming it; pair the
/// captured position with the post-consumption value to build the half-open
/// span attached to the resulting token.
pub fn Lexer::get_loc(self : Lexer) -> Position {
  { line: self.line, column: self.column, }
}

///|
/// Get current position for error reporting
pub fn Lexer::get_position(self : Lexer) -> Int {
  self.position
}

///|
/// Explicitly advance to a new line (call when encountering '\n')
/// This updates line and column tracking appropriately
pub fn Lexer::new_line(self : Lexer) -> Unit {
  self.line += 1
  self.column = 1
}

///|
/// Expect a specific character and advance, or fail with detailed error
pub fn Lexer::expect_char(self : Self, ch : Char, msg? : String) -> Unit raise {
  if self.peek() is Some(c) && c == ch {
    self.advance()
  } else {
    let base_msg = msg.unwrap_or("Expected character: " + Char::to_string(ch))
    let location = " at line " +
      self.line.to_string() +
      ", column " +
      self.column.to_string()
    fail(base_msg + location)
  }
}

///|
/// Expect a string and advance, or fail with detailed error
/// Note the parameter `str` is not expected to have a newline
/// otherwise the line position is not correct
/// # Example
pub fn Lexer::expect_string(
  self : Self,
  str : String,
  msg? : String,
) -> Unit raise {
  // Compare the whole literal before moving, so a mismatch leaves the
  // lexer untouched and the error points at the start of the literal.
  // (Comparing code unit by code unit while calling `advance` broke on
  // surrogate pairs, since `advance` steps over both units at once.)
  let view = self.view()
  if view.has_prefix(str) {
    self.update_view(view.view(start_offset=str.length()))
  } else {
    fail(self.error(msg.unwrap_or("Expected string: " + str)))
  }
}

///|
/// Create a detailed error message with position information
pub fn Lexer::error(self : Lexer, msg : String) -> String {
  msg +
  " at line " +
  self.line.to_string() +
  ", column " +
  self.column.to_string()
}

///|
/// Get current character and advance position
/// handle surrogate pairs and multi-byte characters
/// Note: Does not automatically track newlines - call new_line() explicitly when needed
pub fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    self.column += 1
    // Step over a whole surrogate pair, but only if it really is a pair:
    // an unpaired surrogate is a single code unit, and jumping two units
    // would skip the next character or run past the end of the input.
    let ch = self.input.unsafe_get(self.position)
    if ch.is_leading_surrogate() &&
      self.position + 1 < self.input.length() &&
      self.input.unsafe_get(self.position + 1).is_trailing_surrogate() {
      self.position += 2
    } else {
      self.position += 1
    }
  }
}

///|
/// Test position tracking with explicit new_line() API
test "position tracking" {
  let lexer = Lexer::Lexer("hello\nworld")
  inspect(lexer.get_loc().line, content="1")
  inspect(lexer.get_loc().column, content="1")
  lexer.advance() // h
  inspect(lexer.get_loc().column, content="2")
  for i = 0; i < 4; i = i + 1 {
    lexer.advance() // e,l,l,o
  }
  inspect(lexer.get_loc().column, content="6")
  lexer.advance() // \n
  inspect(lexer.get_loc().column, content="7") // Column advances normally
  inspect(lexer.get_loc().line, content="1") // Line doesn't change automatically

  // Explicitly call new_line() when encountering newline
  lexer.new_line()
  inspect(lexer.get_loc().line, content="2")
  inspect(lexer.get_loc().column, content="1")
}

///|
/// Test skip whitespace with position tracking
test "skip whitespace with position tracking" {
  let lexer = Lexer::Lexer("  \t\rH")
  lexer.skip_whitespace()
  inspect(lexer.get_loc().column, content="5") // moved past 4 whitespace chars
  debug_inspect(lexer.peek(), content="Some('H')")
}

///|
/// Test explicit new_line API
test "explicit new_line API" {
  let lexer = Lexer::Lexer("test")
  inspect(lexer.get_loc().line, content="1")
  inspect(lexer.get_loc().column, content="1")
  lexer.new_line()
  inspect(lexer.get_loc().line, content="2")
  inspect(lexer.get_loc().column, content="1")
  lexer.advance() // t
  inspect(lexer.get_loc().column, content="2")
  lexer.new_line()
  inspect(lexer.get_loc().line, content="3")
  inspect(lexer.get_loc().column, content="1")
}
