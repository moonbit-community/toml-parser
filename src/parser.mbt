///| Parser implementation for TOML
typealias @tokenize.(Token, TomlDateTime)

///|
fnalias @tokenize.tokenize

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

///| Parse a table path: section.subsection.key
fn Parser::parse_table_path(self : Parser) -> Array[String] raise {
  let path = Array::new()

  // Parse first key
  let first_key = match self.advance() {
    Identifier(name) => name
    StringToken(name) => name
    _ => fail("Expected table name")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while self.peek() == Dot {
    ignore(self.advance()) // consume dot
    let key = match self.advance() {
      Identifier(name) => name
      StringToken(name) => name
      _ => fail("Expected table name after dot")
    }
    path.push(key)
  }
  path
}

///| Parse an array of tables path: section.subsection.key
fn Parser::parse_array_of_tables_path(self : Parser) -> Array[String] raise {
  let path = Array::new()

  // Parse first key
  let first_key = match self.advance() {
    Identifier(name) => name
    StringToken(name) => name
    _ => fail("Expected table name in array of tables")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while self.peek() == Dot {
    ignore(self.advance()) // consume dot
    let key = match self.advance() {
      Identifier(name) => name
      StringToken(name) => name
      _ => fail("Expected table name after dot in array of tables")
    }
    path.push(key)
  }
  path
}

///| Create or get a nested table structure from a path
fn create_nested_table(
  root_table : Map[String, TomlValue],
  path : Array[String],
) -> Map[String, TomlValue] raise {
  let mut current_table = root_table
  for i = 0; i < path.length(); i = i + 1 {
    let key = path[i]
    if current_table.contains(key) {
      match current_table.get(key) {
        Some(TomlTable(existing_table)) => current_table = existing_table
        Some(_) => fail("Table path conflicts with existing value: " + key)
        None => fail("Unexpected error: table should exist")
      }
    } else {
      let new_table = Map::new()
      current_table[key] = TomlTable(new_table)
      current_table = new_table
    }
  }
  current_table
}

///| Create or append to an array of tables structure from a path
fn create_array_of_tables(
  root_table : Map[String, TomlValue],
  path : Array[String],
) -> Map[String, TomlValue] raise {
  let mut current_table = root_table

  // Navigate to the parent of the final key
  for i = 0; i < path.length() - 1; i = i + 1 {
    let key = path[i]
    if current_table.contains(key) {
      match current_table.get(key) {
        Some(TomlTable(existing_table)) => current_table = existing_table
        Some(_) =>
          fail("Array of tables path conflicts with existing value: " + key)
        None => fail("Unexpected error: table should exist")
      }
    } else {
      let new_table = Map::new()
      current_table[key] = TomlTable(new_table)
      current_table = new_table
    }
  }

  // Handle the final key as an array of tables
  let final_key = path[path.length() - 1]
  let new_table = Map::new()
  if current_table.contains(final_key) {
    match current_table.get(final_key) {
      Some(TomlArray(existing_array)) => {
        // Append a new table to the existing array
        existing_array.push(TomlTable(new_table))
        new_table
      }
      Some(_) =>
        fail(
          "Array of tables conflicts with existing non-array value: " +
          final_key,
        )
      None => fail("Unexpected error: array should exist")
    }
  } else {
    // Create new array with the first table
    let array = Array::new()
    array.push(TomlTable(new_table))
    current_table[final_key] = TomlArray(array)
    new_table
  }
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
        // Look ahead to see if this is [[ (array of tables) or [ (regular table)
        ignore(parser.advance()) // consume first [
        if parser.peek() == LeftBracket {
          // This is array of tables [[...]]
          ignore(parser.advance()) // consume second [
          let table_path = parser.parse_array_of_tables_path()
          parser.expect(RightBracket) // expect first ]
          parser.expect(RightBracket) // expect second ]

          // Create or append to the array of tables structure
          current_table = create_array_of_tables(main_table, table_path)
        } else {
          // This is a regular table [...]
          let table_path = parser.parse_table_path()
          parser.expect(RightBracket)

          // Create or get the nested table structure
          current_table = create_nested_table(main_table, table_path)
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
