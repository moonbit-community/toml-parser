///|
typealias @lexer.Lexer

///| Check if character is numeric
fn is_numeric(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///| Check if character is alpha (letter)
fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///| Check if character is alphanumeric
// fn is_alphanumeric(ch : Char) -> Bool {
//   is_alpha(ch) || is_numeric(ch)
// }

///| Parse a number (integer or float), with optional negative sign
fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
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

///|
test "read_number" {
  let lexer = Lexer::new("123")
  inspect(lexer.read_number(false), content="IntegerToken(123)")
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
