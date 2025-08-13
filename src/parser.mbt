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
    EOF(loc=@tokenize.default_loc())
  } else {
    self.tokens[self.position]
  }
}

///| Get current token and advance position
fn Parser::advance(self : Parser) -> Token {
  if self.is_at_end() {
    EOF(loc=@tokenize.default_loc())
  } else {
    let token = self.tokens[self.position]
    self.position = self.position + 1
    token
  }
}

///| Skip newline tokens
fn Parser::skip_newlines(self : Parser) -> Unit {
  while true {
    match self.view() {
      [Newline(..), .. rest] => self.update_view(rest)
      _ => break
    }
  }
}

///| Parse a primary value (string, number, boolean)
fn Parser::parse_value(self : Parser) -> TomlValue raise {
  match self.view() {
    [StringToken(s, ..), .. rest] => {
      self.update_view(rest)
      TomlString(s)
    }
    [IntegerToken(i, ..), .. rest] => {
      self.update_view(rest)
      TomlInteger(i)
    }
    [FloatToken(f, ..), .. rest] => {
      self.update_view(rest)
      TomlFloat(f)
    }
    [BooleanToken(b, ..), .. rest] => {
      self.update_view(rest)
      TomlBoolean(b)
    }
    [DateTimeToken(dt, ..), .. rest] => {
      self.update_view(rest)
      TomlDateTime(dt)
    }
    [LeftBracket(..), .. rest] => {
      self.update_view(rest)
      self.parse_array()
    }
    [LeftBrace(..), .. rest] => {
      self.update_view(rest)
      self.parse_inline_table()
    }
    _ => fail("Expected value")
  }
}

///| Parse an array [1, 2, 3]
fn Parser::parse_array(self : Parser) -> TomlValue raise {
  let values = []
  self.skip_newlines()
  if self.peek() is RightBracket(..) {
    ignore(self.advance()) // consume ]
    return TomlArray(values)
  }
  while true {
    let value = self.parse_value()
    values.push(value)
    self.skip_newlines()
    match self.view() {
      [Comma(..), .. rest] => {
        self.update_view(rest)
        self.skip_newlines()
        if self.peek() is RightBracket(..) {
          ignore(self.advance())
          break
        }
      }
      [RightBracket(..), .. rest] => {
        self.update_view(rest)
        break
      }
      _ => fail("Expected ',' or ']' in array")
    }
  }
  TomlArray(values)
}

///| Parse an inline table {key = value, key2 = value2}
fn Parser::parse_inline_table(self : Parser) -> TomlValue raise {
  let table = {}
  if self.peek() is RightBrace(..) {
    ignore(self.advance()) // consume }
    return TomlTable(table)
  }
  while true {
    // Parse key
    let key = match self.advance() {
      Identifier(k, ..) => k
      StringToken(k, ..) => k
      IntegerToken(i, ..) => i.to_string()
      _ => fail("Expected key in inline table")
    }

    // Expect =
    match self.peek() {
      Equals(..) => ignore(self.advance())
      _ => fail("Expected '='")
    }

    // Parse value
    let value = self.parse_value()
    table[key] = value
    match self.peek() {
      Comma(..) => ignore(self.advance())
      RightBrace(..) => {
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
    Identifier(name, ..) => name
    StringToken(name, ..) => name
    IntegerToken(i, ..) => i.to_string()
    _ => fail("Expected table name")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while self.peek() is Dot(..) {
    ignore(self.advance()) // consume dot
    let key = match self.advance() {
      Identifier(name, ..) => name
      StringToken(name, ..) => name
      IntegerToken(i, ..) => i.to_string()
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
    IntegerToken(i) => i.to_string()
    _ => fail("Expected table name in array of tables")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while self.peek() is Dot(..) {
    ignore(self.advance()) // consume dot
    let key = match self.advance() {
      Identifier(name, ..) => name
      StringToken(name, ..) => name
      IntegerToken(i, ..) => i.to_string()
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
    IntegerToken(i) => i.to_string()
    _ => fail("Expected key")
  }

  // Expect =
  match self.peek() {
    Equals(..) => ignore(self.advance())
    _ => fail("Expected '='")
  }

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
  while true {
    parser.skip_newlines()
    match parser.peek() {
      EOF(..) => break
      LeftBracket(..) => {
        // Look ahead to see if this is [[ (array of tables) or [ (regular table)
        ignore(parser.advance()) // consume first [
        if parser.peek() is LeftBracket(..) {
          // This is array of tables [[...]]
          ignore(parser.advance()) // consume second [
          let table_path = parser.parse_array_of_tables_path()
          // expect first ]
          match parser.peek() {
            RightBracket(..) => ignore(parser.advance())
            _ => fail("Expected ']'")
          }
          // expect second ]
          match parser.peek() {
            RightBracket(..) => ignore(parser.advance())
            _ => fail("Expected ']'")
          }

          // Create or append to the array of tables structure
          current_table = create_array_of_tables(main_table, table_path)
        } else {
          // This is a regular table [...]
          let table_path = parser.parse_table_path()
          match parser.peek() {
            RightBracket(..) => ignore(parser.advance())
            _ => fail("Expected ']'")
          }

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
