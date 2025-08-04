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
fn Parser::expect(self : Parser, expected : Token) -> Unit raise {
  let current = self.advance()
  if current == expected {
    ()
  } else {
    fail("Expected \{expected}, but found \{current}")
  }
}

///| Skip newline tokens
fn Parser::skip_newlines(self : Parser) -> Unit {
  while self.peek() is Newline {
    ignore(self.advance())
  }
}

///| Parse a primary value (string, number, boolean)
fn Parser::parse_value(self : Parser) -> TomlValue raise {
  match self.advance() {
    StringToken(s) => TomlString(s)
    IntegerToken(i) => TomlInteger(i)
    FloatToken(f) => TomlFloat(f)
    BooleanToken(b) => TomlBoolean(b)
    LeftBracket => self.parse_array()
    LeftBrace => self.parse_inline_table()
    _ => fail("Expected value")
  }
}

///| Parse an array [1, 2, 3]
fn Parser::parse_array(self : Parser) -> TomlValue raise {
  let values = Array::new()
  self.skip_newlines()
  if self.peek() == RightBracket {
    ignore(self.advance()) // consume ]
    return TomlArray(values)
  }
  while true {
    let value = self.parse_value()
    values.push(value)
    self.skip_newlines()
    match self.peek() {
      Comma => {
        ignore(self.advance())
        self.skip_newlines()
        // Check for trailing comma (comma followed by closing bracket)
        if self.peek() == RightBracket {
          ignore(self.advance())
          break
        }
      }
      RightBracket => {
        ignore(self.advance())
        break
      }
      _ => fail("Expected ',' or ']' in array")
    }
  }
  TomlArray(values)
}

///| Parse an inline table {key = value, key2 = value2}
fn Parser::parse_inline_table(self : Parser) -> TomlValue raise {
  let table = Map::new()
  if self.peek() is RightBrace {
    ignore(self.advance()) // consume }
    return TomlTable(table)
  }
  while true {
    // Parse key
    let key = match self.advance() {
      Identifier(k) => k
      StringToken(k) => k
      _ => fail("Expected key in inline table")
    }

    // Expect =
    self.expect(Equals)

    // Parse value
    let value = self.parse_value()
    table[key] = value
    match self.peek() {
      Comma => ignore(self.advance())
      RightBrace => {
        ignore(self.advance())
        break
      }
      _ => fail("Expected ',' or '}' in inline table")
    }
  }
  TomlTable(table)
}

///| Parse a table header: [section]
fn Parser::parse_table_header(self : Parser) -> String raise {
  // Expect [
  self.expect(LeftBracket)
  
  // Parse table name
  let table_name = match self.advance() {
    Identifier(name) => name
    StringToken(name) => name
    _ => fail("Expected table name")
  }
  
  // Expect ]
  self.expect(RightBracket)
  
  table_name
}

///| Parse a key-value pair: key = value
fn Parser::parse_key_value(self : Parser) -> (String, TomlValue) raise {
  // Parse key
  let key = match self.advance() {
    Identifier(k) => k
    StringToken(k) => k
    _ => fail("Expected key")
  }

  // Expect =
  self.expect(Equals)

  // Parse value
  let value = self.parse_value()
  (key, value)
}

///| Parse a TOML document with support for tables
pub fn parse(input : String) -> TomlValue raise {
  let tokens = tokenize(input)
  let parser = Parser::new(tokens)
  let main_table = Map::new()
  let mut current_table = main_table
  
  while parser.peek() != EOF {
    parser.skip_newlines()
    if parser.peek() == EOF {
      break
    }
    
    match parser.peek() {
      LeftBracket => {
        // Parse table header
        let table_name = parser.parse_table_header()
        
        // Create new table if it doesn't exist
        if main_table.contains(table_name) {
          match main_table.get(table_name) {
            Some(TomlTable(existing_table)) => current_table = existing_table
            Some(_) => fail("Table name conflicts with existing value")
            None => fail("Unexpected error: table should exist")
          }
        } else {
          let new_table = Map::new()
          main_table[table_name] = TomlTable(new_table)
          current_table = new_table
        }
      }
      _ => {
        // Parse key-value pair
        let (key, value) = parser.parse_key_value()
        current_table[key] = value
      }
    }
    parser.skip_newlines()
  }
  TomlTable(main_table)
}
