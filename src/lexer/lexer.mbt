/// Lexer implementation for TOML

///| Lexer state with position tracking for better error reporting
pub(all) struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
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

///| Parse an identifier or keyword
pub fn Lexer::read_identifier(self : Lexer) -> String {
  // let mut result = ""
  let sb = StringBuilder::new()
  while self.peek_charcode() is Some(ch) &&
        ch is ('a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-') {
    self.advance()
    sb.write_char(ch.unsafe_to_char())
  }
  sb.to_string()
}

///| Parse a basic string (double quotes) with escape sequences
/// # Example:
/// ```
/// let lexer = Lexer::new("\"Hello, \\\"world\\\"!\"")
/// inspect(lexer.read_basic_string(), content="Hello, \"world\"!")
/// ```
pub fn Lexer::read_basic_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let sb = StringBuilder::new()
  while self.peek() is Some(ch) && ch != '"' {
    self.advance() // consume character`  
    if ch == '\\' {
      // Handle escape sequences
      match self.peek_charcode() {
        Some(escaped) => {
          self.advance() // consume escape character  
          match escaped {
            'n' => sb.write_char('\n')
            't' => sb.write_char('\t')
            'r' => sb.write_char('\r')
            '\\' => sb.write_char('\\')
            '"' => sb.write_char('"')
            '\'' => sb.write_char('\'')
            'b' => sb.write_char('\u0008')
            'f' => sb.write_char('\u000C')
            'u' => sb.write_char(self.read_unicode_4_escape())
            'U' => sb.write_char(self.read_unicode_8_escape())
            _ =>
              fail(
                self.error(
                  "Invalid escape sequence: \\\{escaped.to_char().unwrap_or('?')}",
                ),
              )
            // TODO:refine the error message 
          }
        }
        None =>
          fail(self.error("Unexpected end of input after escape character"))
      }
    } else {
      sb.write_char(ch)
    }
  }
  self.expect_char('"', msg="Unterminated string")
  sb.to_string()
}

///| Parse a literal string (single quotes) without escape sequences
pub fn Lexer::read_literal_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let sb = StringBuilder::new()
  self.repeat_if(ch => if ch != '\'' {
    sb.write_char(ch)
    true
  } else {
    false
  })
  self.expect_char('\'', msg="Unterminated string")
  sb.to_string()
}

///| Parse a multi-line basic string (triple double quotes) with escape sequences
/// # Example:
/// ```
/// let lexer = Lexer::new("\"\"\"Hello,\nworld!\"\"\"")
/// inspect(lexer.read_multiline_basic_string(), content="Hello,\nworld!")
/// ```
pub fn Lexer::read_multiline_basic_string(self : Lexer) -> String raise {
  // consume opening triple quotes
  // self.advance() // first "
  // self.advance() // second "
  // self.advance() // third "
  self.expect_char('"')
  self.expect_char('"')
  self.expect_char('"')
  // Skip line ending immediately following the opening delimiter
  if self.try_consume_charcode('\r') {
    if self.try_consume_charcode('\n') {
      self.new_line()
    }
  } else if self.try_consume_charcode('\n') {
    self.new_line()
  }
  let sb = StringBuilder::new()
  while self.position < self.input.length() {
    // Check for closing triple quotes
    if self.peek() is Some('"') {
      let saved_pos = self.position
      let saved_line = self.line
      let saved_column = self.column
      self.advance()
      if self.try_consume_charcode('"') {
        if self.try_consume_charcode('"') {
          return sb.to_string()
        }
      }
      // Not triple quotes, restore position and continue
      self.position = saved_pos
      self.line = saved_line
      self.column = saved_column
    }
    match self.peek() {
      Some(ch) => {
        self.advance()
        if ch == '\\' {
          // Handle escape sequences
          match self.peek() {
            Some(escaped) => {
              self.advance()
              match escaped {
                'n' => sb.write_char('\n')
                't' => sb.write_char('\t')
                'r' => sb.write_char('\r')
                '\\' => sb.write_char('\\')
                '"' => sb.write_char('"')
                '\'' => sb.write_char('\'')
                'b' => sb.write_char('\u0008')
                'f' => sb.write_char('\u000C')
                'u' => sb.write_char(self.read_unicode_4_escape())
                'U' => sb.write_char(self.read_unicode_8_escape())
                // Line ending backslash (trim whitespace at line start)
                '\r' | '\n' => {
                  self.new_line()
                  if escaped == '\r' && self.peek() is Some('\n') {
                    self.advance() // consume the \n after \r
                  }
                  // Skip whitespace at the beginning of the next line
                  while self.peek() is Some(ws) && ws is (' ' | '\t') {
                    self.advance()
                  }
                }
                _ =>
                  fail(
                    self.error(
                      "Invalid escape sequence: \\" + Char::to_string(escaped),
                    ),
                  )
              }
            }
            None =>
              fail(self.error("Unexpected end of input after escape character"))
          }
        } else {
          sb.write_char(ch)
          if ch == '\n' {
            self.new_line()
          }
        }
      }
      None => fail(self.error("Unterminated multiline string"))
    }
  }
  fail(self.error("Unterminated multiline string"))
}

///| Parse a multi-line literal string (triple single quotes) without escape sequences
/// # Example:
/// ```
/// let lexer = Lexer::new("'''Hello,\nworld!'''")
/// inspect(lexer.read_multiline_literal_string(), content="Hello,\nworld!")
/// ```
pub fn Lexer::read_multiline_literal_string(self : Lexer) -> String raise {
  // consume opening triple quotes
  self.advance() // first '
  self.advance() // second '
  self.advance() // third '

  // Skip line ending immediately following the opening delimiter
  if self.peek() is Some('\r') {
    self.advance()
    if self.peek() is Some('\n') {
      self.advance()
      self.new_line()
    }
  } else if self.peek() is Some('\n') {
    self.advance()
    self.new_line()
  }
  let sb = StringBuilder::new()
  while self.position < self.input.length() {
    // Check for closing triple quotes
    if self.peek() is Some('\'') {
      let saved_pos = self.position
      let saved_line = self.line
      let saved_column = self.column
      self.advance()
      if self.try_consume_charcode('\'') {
        if self.try_consume_charcode('\'') {
          return sb.to_string()
        }
      }
      // Not triple quotes, restore position and continue
      self.position = saved_pos
      self.line = saved_line
      self.column = saved_column
    }
    match self.peek() {
      Some(ch) => {
        self.advance()
        sb.write_char(ch)
        if ch == '\n' {
          self.new_line()
        }
      }
      None => fail(self.error("Unterminated multiline literal string"))
    }
  }
  fail(self.error("Unterminated multiline literal string"))
}

///| Check if character is hexadecimal digit
fn is_hex_digit(ch : Char) -> Bool {
  ch is ('0'..='9' | 'a'..='f' | 'A'..='F')
}

///| Parse Unicode escape sequence \uXXXX
fn Lexer::read_unicode_4_escape(self : Lexer) -> Char raise {
  let mut code = 0
  for i = 0; i < 4; i = i + 1 {
    match self.peek() {
      Some(ch) if is_hex_digit(ch) => {
        self.advance()
        let digit = match ch {
          '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
            ch.to_int() - '0'.to_int()
          'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
          'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
        }
        code = code * 16 + digit
      }
      _ =>
        fail(
          self.error("Invalid Unicode escape sequence: expected 4 hex digits"),
        )
    }
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
}

///| Parse Unicode escape sequence \UXXXXXXXX
fn Lexer::read_unicode_8_escape(self : Lexer) -> Char raise {
  let mut code = 0
  for i = 0; i < 8; i = i + 1 {
    match self.peek() {
      Some(ch) if is_hex_digit(ch) => {
        self.advance()
        let digit = match ch {
          '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
            ch.to_int() - '0'.to_int()
          'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
          'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
        }
        code = code * 16 + digit
      }
      _ =>
        fail(
          self.error("Invalid Unicode escape sequence: expected 8 hex digits"),
        )
    }
  }
  if code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF) {
    fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
}

///| Check if character is binary digit
fn is_binary_digit(ch : Char) -> Bool {
  ch == '0' || ch == '1'
}

///| Check if character is octal digit
fn is_octal_digit(ch : Char) -> Bool {
  ch >= '0' && ch <= '7'
}

///| Parse hexadecimal number
pub fn Lexer::read_hex_number(self : Lexer) -> Int64 raise {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_hex_digit(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      let digit = match ch {
        '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
          ch.to_int() - '0'.to_int()
        'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
        'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
        _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
      }
      result = result * 16L + digit.to_int64()
    }
  }
  result
}

///| Parse octal number
pub fn Lexer::read_octal_number(self : Lexer) -> Int64 {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_octal_digit(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      let digit = ch.to_int() - '0'.to_int()
      result = result * 8L + digit.to_int64()
    }
  }
  result
}

///| Parse binary number
/// # Example:
/// ```
/// let lexer = Lexer::new("0b1010")
/// inspect(lexer.read_binary_number(), content="0")
/// ```
pub fn Lexer::read_binary_number(self : Lexer) -> Int64 {
  let mut result = 0L
  self.repeat_if(ch => if is_binary_digit(ch) || ch == '_' {
    if ch != '_' {
      let digit = ch.to_int() - '0'.to_int()
      result = result * 2L + digit.to_int64()
    }
    true
  } else {
    false
  })
  result
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

///| Test Unicode escape sequences
test "unicode escape sequences" {
  let lexer1 = Lexer::new("\"\\u0041\"") // 'A'
  let result1 = lexer1.read_basic_string()
  inspect(result1, content="A")
  let lexer2 = Lexer::new("\"\\U00000041\"") // 'A'
  let result2 = lexer2.read_basic_string()
  inspect(result2, content="A")
}

///| Test multiline basic string
test "multiline basic string" {
  let lexer = Lexer::new("\"\"\"line1\nline2\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1\nline2")
}

///| Test multiline literal string
test "multiline literal string" {
  let lexer = Lexer::new("'''line1\nline2'''")
  let result = lexer.read_multiline_literal_string()
  inspect(result, content="line1\nline2")
}

///| Test line ending backslash in multiline string
test "line ending backslash" {
  let lexer = Lexer::new("\"\"\"line1\\\n   line2\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1line2") // whitespace should be trimmed
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
