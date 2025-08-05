/// Lexer implementation for TOML

///| Lexer state (will implement methods later)
struct Lexer {
  input : String
  mut position : Int
  // mut line : Int
  // mut column : Int
}

///| Tests for lexer creation
test "lexer creation" {
  let lexer = Lexer::new("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
  // inspect(lexer.line, content="1")
  // inspect(lexer.column, content="1")
}

///| Skip whitespace characters not including newlines
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
      // self.column += 1
      continue pos + 1
    } else {
      break
    }
  }
}

///| Skip comments (start with #)
fn Lexer::skip_comment(self : Lexer) -> Unit {
  if self.peek() is Some('#') {
    while self.peek() is Some(ch) && ch != '\n' {
      self.advance()
    }
  }
}

///| Check if character is alpha (letter)
fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///| Check if character is numeric
fn is_numeric(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///| Check if character is alphanumeric
fn is_alphanumeric(ch : Char) -> Bool {
  is_alpha(ch) || is_numeric(ch)
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
pub fn Lexer::expect_char(self : Self, ch : Char, msg? : String) -> Unit raise {
  if self.peek() is Some(c) && c == ch {
    self.advance()
  } else {
    fail(msg.unwrap_or("Expected character: " + Char::to_string(ch)))
  }
}

///| Get current character and advance position
/// handle surrogate pairs and multi-byte characters
pub fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    let ch = self.input.unsafe_charcode_at(self.position)
    if !ch.is_surrogate() {
      self.position += 1
      if ch is '\n' {
        // self.line += 1
        // self.column = 1
      } else {
        // self.column += 1
      }
    } else {
      self.position += 2
      // self.column += 1
    }
  }
}

///| Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {
  // let mut result = ""
  let sb = StringBuilder::new()
  while self.peek() is Some(ch) && (is_alphanumeric(ch) || ch == '-') {
    self.advance()
    sb.write_char(ch)
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
  let mut result = ""
  while self.peek() is Some(ch) && ch != '"' {
    self.advance() // consume character`  
    if ch == '\\' {
      // Handle escape sequences
      match self.peek() {
        Some(escaped) => {
          self.advance() // consume escape character  
          match escaped {
            'n' => result = result + "\n"
            't' => result = result + "\t"
            'r' => result = result + "\r"
            '\\' => result = result + "\\"
            '"' => result = result + "\""
            '\'' => result = result + "'"
            _ => fail("Invalid escape sequence: \\" + Char::to_string(escaped))
          }
        }
        None => fail("Unexpected end of input after escape character")
      }
    } else {
      result = result + Char::to_string(ch)
    }
  }
  self.expect_char('"', msg="Unterminated string")
  result
}

///| Parse a literal string (single quotes) without escape sequences
fn Lexer::read_literal_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let mut result = ""
  while self.peek() is Some(ch) && ch != '\'' {
    self.advance() // consume character
    result = result + Char::to_string(ch)
  }
  self.expect_char('\'', msg="Unterminated string")
  result
}

///| Check if character is hexadecimal digit
fn is_hex_digit(ch : Char) -> Bool {
  is_numeric(ch) || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F')
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
fn Lexer::read_hex_number(self : Lexer) -> Int64 raise {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_hex_digit(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      let digit = match ch {
        '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
          ch.to_int() - '0'.to_int()
        'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
        'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
        _ => fail("Invalid hex digit: " + Char::to_string(ch))
      }
      result = result * 16L + digit.to_int64()
    }
  }
  result
}

///| Parse octal number
fn Lexer::read_octal_number(self : Lexer) -> Int64 {
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
fn Lexer::read_binary_number(self : Lexer) -> Int64 {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_binary_digit(ch) || ch == '_') {
    if ch != '_' {
      self.advance()
      let digit = ch.to_int() - '0'.to_int()
      result = result * 2L + digit.to_int64()
    } else {
      self.advance() // skip underscore
    }
  }
  result
}

///| Parse a number (integer or float), with optional negative sign
/// # Example:
/// ```
/// let lexer = Lexer::new("123")
/// inspect(lexer.read_number(false), content="IntegerToken(123)")
/// ```
pub fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
  let sb = StringBuilder::new()
  if is_negative {
    sb.write_char('-')
  }
  let mut is_float = false

  // Check if this might be a special format number (0x, 0o, 0b)
  if self.peek() is Some('0') && !is_negative {
    let saved_pos = self.position
    self.advance() // consume '0'
    match self.peek() {
      Some('x') | Some('X') => {
        self.advance() // consume 'x' or 'X'
        let value = self.read_hex_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      Some('o') | Some('O') => {
        self.advance() // consume 'o' or 'O'
        let value = self.read_octal_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      Some('b') | Some('B') => {
        self.advance() // consume 'b' or 'B'
        let value = self.read_binary_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      _ =>
        // Not a special format, restore position and continue as normal
        self.position = saved_pos
    }
  }

  // Read digits
  while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      sb.write_char(ch)
    }
  }

  // Check for decimal point
  if self.peek() is Some('.') {
    is_float = true
    self.advance()
    sb.write_char('.')
    while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
      self.advance()
      if ch != '_' {
        sb.write_char(ch)
      }
    }
  }
  let s = sb.to_string()
  if is_float {
    FloatToken(@strconv.parse_double(s)) catch {
      _ => fail("Invalid float: " + s)
    }
  } else {
    IntegerToken(@strconv.parse_int64(s)) catch {
      _ => fail("Invalid integer: " + s)
    }
  }
}
