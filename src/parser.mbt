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

///| Parse a primary value (string, number, boolean, datetime)
fn Parser::parse_value(self : Parser) -> TomlValue raise {
  match self.advance() {
    StringToken(s) => TomlString(s)
    IntegerToken(i) => TomlInteger(i)
    FloatToken(f) => TomlFloat(f)
    BooleanToken(b) => TomlBoolean(b)
    DateTimeToken(dt) => TomlDateTime(dt)
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

///| Parse a table path (like "a.b.c" into ["a", "b", "c"])
fn Parser::parse_table_path(self : Parser, path : String) -> Array[String] {
  if path.contains(".") {
    // Split on dots for nested tables
    let parts = path.split(".")
    let result = Array::new()
    for part in parts {
      let trimmed = part.trim()
      if trimmed.length() > 0 {
        result.push(trimmed)
      }
    }
    result
  } else {
    [path]
  }
}

///| Ensure a table path exists in the root table and return the target table
fn Parser::ensure_table_path_exists(self : Parser, root : Map[String, TomlValue], path : Array[String]) -> Map[String, TomlValue] raise {
  let mut current = root
  for segment in path {
    match current.get(segment) {
      Some(TomlTable(existing_table)) => {
        // Table already exists, navigate to it
        current = existing_table
      }
      Some(_) => {
        fail("Key '\{segment}' already exists and is not a table")
      }
      None => {
        // Create new table
        let new_table = Map::new()
        current[segment] = TomlTable(new_table)
        current = new_table
      }
    }
  }
  current
}

///| Ensure an array table exists and return a new table to add to the array
fn Parser::ensure_array_table_exists(self : Parser, root : Map[String, TomlValue], path : Array[String]) -> Map[String, TomlValue] raise {
  if path.length() == 0 {
    fail("Array table path cannot be empty")
  }
  
  // Navigate to the parent table (all but last segment)
  let mut current = root
  for i = 0; i < path.length() - 1; i = i + 1 {
    let segment = path[i]
    match current.get(segment) {
      Some(TomlTable(existing_table)) => {
        current = existing_table
      }
      Some(_) => {
        fail("Key '\{segment}' already exists and is not a table")
      }
      None => {
        let new_table = Map::new()
        current[segment] = TomlTable(new_table)
        current = new_table
      }
    }
  }
  
  // Handle the final segment as an array of tables
  let final_segment = path[path.length() - 1]
  match current.get(final_segment) {
    Some(TomlArray(existing_array)) => {
      // Add a new table to the existing array
      let new_table = Map::new()
      existing_array.push(TomlTable(new_table))
      new_table
    }
    Some(_) => {
      fail("Key '\{final_segment}' already exists and is not an array")
    }
    None => {
      // Create new array with the first table
      let new_table = Map::new()
      let array = [TomlTable(new_table)]
      current[final_segment] = TomlArray(array)
      new_table
    }
  }
}

///| Parse a TOML document (with table support)
pub fn parse(input : String) -> TomlValue raise {
  let tokens = tokenize(input)
  let parser = Parser::new(tokens)
  let root_table = Map::new()
  let mut current_table = root_table
  let mut current_path : Array[String] = []
  
  while parser.peek() != EOF {
    parser.skip_newlines()
    if parser.peek() == EOF {
      break
    }
    
    match parser.peek() {
      TableHeader(section_name) => {
        ignore(parser.advance()) // consume the header token
        current_path = parser.parse_table_path(section_name)
        current_table = parser.ensure_table_path_exists(root_table, current_path)
      }
      ArrayTableHeader(section_name) => {
        ignore(parser.advance()) // consume the header token
        current_path = parser.parse_table_path(section_name)
        current_table = parser.ensure_array_table_exists(root_table, current_path)
      }
      _ => {
        let (key, value) = parser.parse_key_value()
        current_table[key] = value
      }
    }
    parser.skip_newlines()
  }
  TomlTable(root_table)
}
