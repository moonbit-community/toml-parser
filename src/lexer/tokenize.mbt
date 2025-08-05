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

///| Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0 }
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
