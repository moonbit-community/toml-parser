/// Parser implementation for TOML

///| Check if we're at the end of tokens
fn Parser::is_at_end(self : Parser) -> Bool {
  self.position >= self.tokens.length()
}

///| Get current token without advancing
fn Parser::peek(self : Parser) -> Token {
  if self.is_at_end() {
    EOF
  } else {
    self.tokens[self.position]
  }
}

///| Get current token and advance position
fn Parser::advance(self : Parser) -> Token {
  if self.is_at_end() {
    EOF
  } else {
    let token = self.tokens[self.position]
    self.position = self.position + 1
    token
  }
}

///| Expect a specific token and advance
fn Parser::expect(self : Parser, expected : Token) -> ParseResult[Unit] {
  let current = self.advance()
  if current == expected {
    Ok(())
  } else {
    Err("Expected \{expected}, but found \{current}")
  }
}

///| Skip newline tokens
fn Parser::skip_newlines(self : Parser) -> Unit {
  while self.peek() is Newline {
    ignore(self.advance())
  }
}

///| Parse a primary value (string, number, boolean)
fn Parser::parse_value(self : Parser) -> ParseResult[TomlValue] {
  match self.advance() {
    StringToken(s) => Ok(TomlString(s))
    IntegerToken(i) => Ok(TomlInteger(i))
    FloatToken(f) => Ok(TomlFloat(f))
    BooleanToken(b) => Ok(TomlBoolean(b))
    LeftBracket => self.parse_array()
    LeftBrace => self.parse_inline_table()
    _ => Err("Expected value")
  }
}

///| Parse an array [1, 2, 3]
fn Parser::parse_array(self : Parser) -> ParseResult[TomlValue] {
  let values = Array::new()
  self.skip_newlines()
  if self.peek() == RightBracket {
    ignore(self.advance()) // consume ]
    return Ok(TomlArray(values))
  }
  while true {
    match self.parse_value() {
      Ok(value) => values.push(value)
      Err(msg) => return Err(msg)
    }
    self.skip_newlines()
    match self.peek() {
      Comma => {
        ignore(self.advance())
        self.skip_newlines()
      }
      RightBracket => {
        ignore(self.advance())
        break
      }
      _ => return Err("Expected ',' or ']' in array")
    }
  }
  Ok(TomlArray(values))
}

///| Parse an inline table {key = value, key2 = value2}
fn Parser::parse_inline_table(self : Parser) -> ParseResult[TomlValue] {
  let table = Map::new()
  if self.peek() is RightBrace {
    ignore(self.advance()) // consume }
    return Ok(TomlTable(table))
  }
  while true {
    // Parse key
    let key = match self.advance() {
      Identifier(k) => k
      StringToken(k) => k
      _ => return Err("Expected key in inline table")
    }

    // Expect =
    match self.expect(Equals) {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }

    // Parse value
    match self.parse_value() {
      Ok(value) => table[key] = value
      Err(msg) => return Err(msg)
    }
    match self.peek() {
      Comma => ignore(self.advance())
      RightBrace => {
        ignore(self.advance())
        break
      }
      _ => return Err("Expected ',' or '}' in inline table")
    }
  }
  Ok(TomlTable(table))
}

///| Parse a key-value pair: key = value
fn Parser::parse_key_value(self : Parser) -> ParseResult[(String, TomlValue)] {
  // Parse key
  let key = match self.advance() {
    Identifier(k) => k
    StringToken(k) => k
    _ => return Err("Expected key")
  }

  // Expect =
  match self.expect(Equals) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }

  // Parse value
  match self.parse_value() {
    Ok(value) => Ok((key, value))
    Err(msg) => Err(msg)
  }
}

///| Parse a TOML document (simple key-value pairs for now)
pub fn parse(input : String) -> ParseResult[TomlValue] {
  match tokenize(input) {
    Ok(tokens) => {
      let parser = Parser::new(tokens)
      let table = Map::new()
      while parser.peek() != EOF {
        parser.skip_newlines()
        if parser.peek() == EOF {
          break
        }
        match parser.parse_key_value() {
          Ok((key, value)) => table[key] = value
          Err(msg) => return Err(msg)
        }
        parser.skip_newlines()
      }
      Ok(TomlTable(table))
    }
    Err(msg) => Err("Tokenization error: " + msg)
  }
}
