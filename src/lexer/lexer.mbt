/// Lexer implementation for TOML

///| Lexer state with position tracking for better error reporting
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
}

///| Get a view of the input string
/// # Example:
/// ```
/// let lexer = Lexer::new("Hello, world!")
/// lexer.advance()
/// lexer.advance()
/// inspect(lexer.view(), content="llo, world!")
/// ```
pub fn Lexer::view(self : Lexer) -> @string.View {
  self.input.view(start_offset=self.position)
}
///| Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0, line: 1, column: 1 }
}

///| Tests for lexer creation
test "lexer creation" {
  let lexer = Lexer::new("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
  inspect(lexer.line, content="1")
  inspect(lexer.column, content="1")
}

///| Skip whitespace characters not including newlines
/// Note: This method does not skip '\n' characters as those are significant in TOML
/// # Example:
/// ```
/// let lexer = Lexer::new("  \t\rHello, world!")
/// lexer.skip_whitespace()
/// inspect(lexer.peek(), content="Some('H')")
/// ```
pub fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  for pos = self.position {
    if pos >= self.input.length() {
      break
    }
    let ch = self.input.unsafe_charcode_at(pos)
    if ch is (' ' | '\t' | '\r') {
      self.position += 1
      self.column += 1
      continue pos + 1
    } else {
      break
    }
  }
}

///|
/// 
/// peeck and check it matches a bmp character
/// TODO @param ch change its type to UInt16 when overloading
/// support is there
pub fn Lexer::check_is_charcode(self : Lexer, ch : Int) -> Bool {
  self.position < self.input.length() &&
  self.input.unsafe_charcode_at(self.position) == ch
}

///|
pub fn Lexer::check_not_charcode(self : Lexer, ch : Int) -> Bool {
  self.position < self.input.length() &&
  self.input.unsafe_charcode_at(self.position) != ch
}

///|
pub fn Lexer::try_consume_charcode(self : Lexer, ch : Int) -> Bool {
  if self.check_is_charcode(ch) {
    self.advance()
    true
  } else {
    false
  }
}

///|
pub fn Lexer::advance_until_charcode(self : Lexer, ch : Int) -> Unit {
  while self.check_not_charcode(ch) {
    self.advance()
  }
}

///|
/// advance as long as the predicate is true
/// # Example:
/// ```
/// let lexer = Lexer::new("Hello, world!")
/// lexer.repeat_if(ch=> ch is ('a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-'))
/// inspect(lexer.peek(), content="Some(',')")
/// ```
pub fn Lexer::repeat_if(self : Lexer, f : (Char) -> Bool) -> Unit {
  while self.peek() is Some(ch) && f(ch) {
    self.advance()
  }
}

///| Skip comments (start with #)
pub fn Lexer::skip_comment(self : Lexer) -> Unit {
  if self.check_is_charcode('#') {
    self.advance_until_charcode('\n')
  }
}

///| Get current character without advancing
/// # Example:
/// ```
/// let lexer = Lexer::new("Hello, world!")
/// inspect(lexer.peek(), content="Some('H')")
/// lexer.advance()
/// inspect(lexer.peek(), content="Some('e')")
/// ```
pub fn Lexer::peek(self : Lexer) -> Char? {
  self.input.get_char(self.position)
}

///|
pub fn Lexer::peek_charcode(self : Lexer) -> Int? {
  if self.position < self.input.length() {
    Some(self.input.unsafe_charcode_at(self.position))
  } else {
    None
  }
}

///| Get current line number for error reporting
pub fn Lexer::get_line(self : Lexer) -> Int {
  self.line
}

///| Get current column number for error reporting
pub fn Lexer::get_column(self : Lexer) -> Int {
  self.column
}

///| Get current position for error reporting
pub fn Lexer::get_position(self : Lexer) -> Int {
  self.position
}

///| Explicitly advance to a new line (call when encountering '\n')
/// This updates line and column tracking appropriately
pub fn Lexer::new_line(self : Lexer) -> Unit {
  self.line += 1
  self.column = 1
}

///| Expect a specific character and advance, or fail with detailed error
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

  // store the original postion for precise error reporting
  let saved_pos = self.position
  let saved_line = self.line
  let saved_column = self.column
  for i = 0; i < str.length(); i = i + 1 {
    if self.peek_charcode() is Some(ch) && ch == str.unsafe_charcode_at(i) {
      self.advance()
    } else {
      self.position = saved_pos
      self.line = saved_line
      self.column = saved_column
      fail(self.error(msg.unwrap_or("Expected string: " + str)))
    }
  }
}

///| Create a detailed error message with position information
pub fn Lexer::error(self : Lexer, msg : String) -> String {
  msg +
  " at line " +
  self.line.to_string() +
  ", column " +
  self.column.to_string()
}

///| Get current character and advance position
/// handle surrogate pairs and multi-byte characters
/// Note: Does not automatically track newlines - call new_line() explicitly when needed
pub fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    self.column += 1
    let ch = self.input.unsafe_charcode_at(self.position)
    if !ch.is_surrogate() {
      self.position += 1
    } else {
      self.position += 2
    }
  }
}

///| Test position tracking with explicit new_line() API
test "position tracking" {
  let lexer = Lexer::new("hello\nworld")
  inspect(lexer.get_line(), content="1")
  inspect(lexer.get_column(), content="1")
  lexer.advance() // h
  inspect(lexer.get_column(), content="2")
  for i = 0; i < 4; i = i + 1 {
    lexer.advance() // e,l,l,o
  }
  inspect(lexer.get_column(), content="6")
  lexer.advance() // \n
  inspect(lexer.get_column(), content="7") // Column advances normally
  inspect(lexer.get_line(), content="1") // Line doesn't change automatically

  // Explicitly call new_line() when encountering newline
  lexer.new_line()
  inspect(lexer.get_line(), content="2")
  inspect(lexer.get_column(), content="1")
}

///| Test skip whitespace with position tracking
test "skip whitespace with position tracking" {
  let lexer = Lexer::new("  \t\rH")
  lexer.skip_whitespace()
  inspect(lexer.get_column(), content="5") // moved past 4 whitespace chars
  inspect(lexer.peek(), content="Some('H')")
}

///| Test explicit new_line API
test "explicit new_line API" {
  let lexer = Lexer::new("test")
  inspect(lexer.get_line(), content="1")
  inspect(lexer.get_column(), content="1")
  lexer.new_line()
  inspect(lexer.get_line(), content="2")
  inspect(lexer.get_column(), content="1")
  lexer.advance() // t
  inspect(lexer.get_column(), content="2")
  lexer.new_line()
  inspect(lexer.get_line(), content="3")
  inspect(lexer.get_column(), content="1")
}
