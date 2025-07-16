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
fn Lexer::peek(self : Lexer) -> Char {
  if self.position >= self.input.length() {
    '\u0000' // End of input
  } else {
    self.input.char_at(self.position)
  }
}

///| Get current character and advance position
fn Lexer::advance(self : Lexer) -> Char {
  if self.position >= self.input.length() {
    '\u0000'
  } else {
    let ch = self.input.char_at(self.position)
    self.position = self.position + 1
    if ch == '\n' {
      self.line = self.line + 1
      self.column = 1
    } else {
      self.column = self.column + 1
    }
    ch
  }
}

///| Skip whitespace characters
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while is_whitespace(self.peek()) {
    ignore(self.advance())
  }
}

///| Skip comments (start with #)
fn Lexer::skip_comment(self : Lexer) -> Unit {
  if self.peek() == '#' {
    while self.peek() != '\n' && self.peek() != '\u0000' {
      ignore(self.advance())
    }
  }
}

///| Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {
  let mut result = ""
  while is_alphanumeric(self.peek()) || self.peek() == '-' {
    result = result + Char::to_string(self.advance())
  }
  result
}

///| Parse a quoted string
fn Lexer::read_string(self : Lexer) -> ParseResult[String] {
  let quote_char = self.advance() // consume opening quote
  let mut result = ""
  while self.peek() != quote_char && self.peek() != '\u0000' {
    let ch = self.advance()
    if ch == '\\' {
      // Handle escape sequences
      let escaped = self.advance()
      match escaped {
        'n' => result = result + "\n"
        't' => result = result + "\t"
        'r' => result = result + "\r"
        '\\' => result = result + "\\"
        '"' => result = result + "\""
        '\'' => result = result + "'"
        _ =>
          return Err("Invalid escape sequence: \\" + Char::to_string(escaped))
      }
    } else {
      result = result + Char::to_string(ch)
    }
  }
  if self.peek() == quote_char {
    ignore(self.advance()) // consume closing quote
    Ok(result)
  } else {
    Err("Unterminated string")
  }
}

///| Simple integer parsing function
fn parse_int(s : String) -> Int? {
  let len = s.length()
  if len == 0 {
    return None
  }
  let mut result = 0
  let mut i = 0
  let mut negative = false
  if s.charcode_at(0) == '-' {
    negative = true
    i = 1
  }
  for j = i; j < len; j = j + 1 {
    let ch = s.charcode_at(j)
    if ch >= '0' && ch <= '9' {
      let digit = ch - '0'
      result = result * 10 + digit
    } else {
      return None
    }
  }
  Some(if negative { -result } else { result })
}

///| Simple double parsing function (very basic)
fn parse_double(s : String) -> Double? {
  // This is a simplified implementation
  // In a real implementation, you'd want more robust parsing
  let parts_arr = Array::new()
  s.split(".").each(fn(part) { parts_arr.push(part.to_string()) })
  if parts_arr.length() != 2 {
    return None
  }
  match (parse_int(parts_arr[0]), parse_int(parts_arr[1])) {
    (Some(int_part), Some(frac_part)) => {
      let frac_len = parts_arr[1].length()
      let mut divisor = 1.0
      for i = 0; i < frac_len; i = i + 1 {
        divisor = divisor * 10.0
      }
      Some(int_part.to_double() + frac_part.to_double() / divisor)
    }
    _ => None
  }
}

///| Parse a number (integer or float)
fn Lexer::read_number(self : Lexer) -> ParseResult[Token] {
  let mut num_str = ""
  let mut is_float = false

  // Read digits
  while is_numeric(self.peek()) {
    num_str = num_str + Char::to_string(self.advance())
  }

  // Check for decimal point
  if self.peek() == '.' {
    is_float = true
    num_str = num_str + Char::to_string(self.advance())
    while is_numeric(self.peek()) {
      num_str = num_str + Char::to_string(self.advance())
    }
  }
  if is_float {
    match parse_double(num_str) {
      Some(val) => Ok(FloatToken(val))
      None => Err("Invalid float: " + num_str)
    }
  } else {
    match parse_int(num_str) {
      Some(val) => Ok(IntegerToken(val.to_int64()))
      None => Err("Invalid integer: " + num_str)
    }
  }
}

///| Get the next token
fn Lexer::next_token(self : Lexer) -> ParseResult[Token] {
  self.skip_whitespace()
  self.skip_comment()
  let ch = self.peek()
  if ch == '\u0000' {
    return Ok(EOF)
  }
  if ch == '\n' {
    ignore(self.advance())
    return Ok(Newline)
  }
  match ch {
    '[' => {
      ignore(self.advance())
      Ok(LeftBracket)
    }
    ']' => {
      ignore(self.advance())
      Ok(RightBracket)
    }
    '{' => {
      ignore(self.advance())
      Ok(LeftBrace)
    }
    '}' => {
      ignore(self.advance())
      Ok(RightBrace)
    }
    '=' => {
      ignore(self.advance())
      Ok(Equals)
    }
    ',' => {
      ignore(self.advance())
      Ok(Comma)
    }
    '.' => {
      ignore(self.advance())
      Ok(Dot)
    }
    '"' | '\'' =>
      match self.read_string() {
        Ok(str_val) => Ok(StringToken(str_val))
        Err(msg) => Err(msg)
      }
    _ =>
      if is_numeric(ch) {
        self.read_number()
      } else if is_alpha(ch) {
        let identifier = self.read_identifier()
        // Check for boolean keywords
        match identifier {
          "true" => Ok(BooleanToken(true))
          "false" => Ok(BooleanToken(false))
          _ => Ok(Identifier(identifier))
        }
      } else {
        Err("Unexpected character: " + Char::to_string(ch))
      }
  }
}

///| Tokenize entire input
pub fn tokenize(input : String) -> ParseResult[Array[Token]] {
  let lexer = Lexer::new(input)
  let tokens = Array::new()
  while true {
    match lexer.next_token() {
      Ok(token) => {
        tokens.push(token)
        if token == EOF {
          return Ok(tokens)
        }
      }
      Err(msg) => return Err(msg)
    }
  } else {
    // This should never be reached, but needed for type checking
    Ok(tokens)
  }
}
