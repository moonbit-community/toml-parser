/// Lexer implementation for TOML

///| Check if character is whitespace
fn is_whitespace(ch : Char) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\r'
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
fn Lexer::peek(self : Lexer) -> Char? {
  if self.position >= self.input.length() {
    None // End of input
  } else {
    Some(self.input.get_char(self.position).unwrap())
  }
}

///| Get current character and advance position
/// TODO: handle surrogate pairs and multi-byte characters
fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    let ch = self.input.get_char(self.position).unwrap()
    self.position = self.position + 1
    if ch == '\n' {
      self.line = self.line + 1
      self.column = 1
    } else {
      self.column = self.column + 1
    }
  }
}

///| Skip whitespace characters
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.peek() is Some(ch) && is_whitespace(ch) {
    self.advance()
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

///| Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {
  let mut result = ""
  while self.peek() is Some(ch) && (is_alphanumeric(ch) || ch == '-') {
    self.advance()
    result = result + Char::to_string(ch)
  }
  result
}

///| Parse a basic string (double quotes) with escape sequences
fn Lexer::read_basic_string(self : Lexer) -> String raise {
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
  if self.peek() is Some('"') {
    self.advance() // consume closing quote
    result
  } else {
    fail("Unterminated string")
  }
}

///| Parse a literal string (single quotes) without escape sequences
fn Lexer::read_literal_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let mut result = ""
  while self.peek() is Some(ch) && ch != '\'' {
    self.advance() // consume character
    result = result + Char::to_string(ch)
  }
  if self.peek() is Some('\'') {
    self.advance() // consume closing quote
    result
  } else {
    fail("Unterminated string")
  }
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
    if ch != '_' {
      self.advance()
      let digit = match ch {
        '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' => ch.to_int() - '0'.to_int()
        'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
        'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
        _ => fail("Invalid hex digit: " + Char::to_string(ch))
      }
      result = result * 16L + digit.to_int64()
    } else {
      self.advance() // skip underscore
    }
  }
  result
}

///| Parse octal number
fn Lexer::read_octal_number(self : Lexer) -> Int64 {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_octal_digit(ch) || ch == '_') {
    if ch != '_' {
      self.advance()
      let digit = ch.to_int() - '0'.to_int()
      result = result * 8L + digit.to_int64()
    } else {
      self.advance() // skip underscore
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
fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
  let mut num_str = if is_negative { "-" } else { "" }
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
      _ => {
        // Not a special format, restore position and continue as normal
        self.position = saved_pos
      }
    }
  }

  // Read digits
  while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
    if ch != '_' {
      self.advance()
      num_str = num_str + Char::to_string(ch)
    } else {
      self.advance() // skip underscore
    }
  }

  // Check for decimal point
  if self.peek() is Some('.') {
    is_float = true
    self.advance()
    num_str = num_str + Char::to_string('.')
    while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
      if ch != '_' {
        self.advance()
        num_str = num_str + Char::to_string(ch)
      } else {
        self.advance() // skip underscore
      }
    }
  }
  
  if is_float {
    FloatToken(@strconv.parse_double(num_str)) catch {
      _ => fail("Invalid float: " + num_str)
    }
  } else {
    IntegerToken(@strconv.parse_int64(num_str)) catch {
      _ => fail("Invalid integer: " + num_str)
    }
  }
}

///| Get the next token
fn Lexer::next_token(self : Lexer) -> Token raise {
  self.skip_whitespace()
  self.skip_comment()
  match self.peek() {
    None => return EOF
    Some('\n') => {
      self.advance()
      return Newline
    }
    Some('[') => {
      self.advance()
      return LeftBracket
    }
    Some(']') => {
      self.advance()
      return RightBracket
    }
    Some('{') => {
      self.advance()
      return LeftBrace
    }
    Some('}') => {
      self.advance()
      return RightBrace
    }
    Some('=') => {
      self.advance()
      return Equals
    }
    Some(',') => {
      self.advance()
      return Comma
    }
    Some('.') => {
      self.advance()
      return Dot
    }
    Some('"') => StringToken(self.read_basic_string())
    Some('\'') => StringToken(self.read_literal_string())
    Some(ch) =>
      if is_numeric(ch) {
        self.read_number(false)
      } else if ch == '-' {
        // Check if this is a negative number or negative special float
        let saved_pos = self.position
        self.advance() // consume the '-'
        match self.peek() {
          Some(next_ch) if is_numeric(next_ch) =>
            // This is a negative number, read it
            self.read_number(true)

          _ => {
            // Not a negative number or special float, restore position and error
            self.position = saved_pos
            fail("Unexpected character: " + Char::to_string(ch))
          }
        }

      } else if is_alpha(ch) {
        let identifier = self.read_identifier()
        // Check for boolean keywords
        match identifier {
          "true" => BooleanToken(true)
          "false" => BooleanToken(false)
          _ => Identifier(identifier)
        }
      } else {
        fail("Unexpected character: " + Char::to_string(ch))
      }
  }
}

///| Tokenize entire input
pub fn tokenize(input : String) -> Array[Token] raise {
  let lexer = Lexer::new(input)
  let tokens = Array::new()
  while true {
    let token = lexer.next_token()
    tokens.push(token)
    if token == EOF {
      break tokens
    }
  } else {
    // This should never be reached, but needed for type checking
    tokens
  }
}
