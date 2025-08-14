///| Parser implementation for TOML
typealias @tokenize.(Token, TomlDateTime)

///|
fnalias @tokenize.tokenize

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
    rest => parse_error(rest, "Expected value")
  }
}

///| Parse an array [1, 2, 3]
fn Parser::parse_array(self : Parser) -> TomlValue raise {
  let values = []
  self.skip_newlines()
  match self.view() {
    [RightBracket(..), .. rest] => {
      self.update_view(rest)
      return TomlArray(values)
    }
    _ => ()
  }
  while true {
    let value = self.parse_value()
    values.push(value)
    self.skip_newlines()
    match self.view() {
      [Comma(..), .. rest] => {
        self.update_view(rest)
        self.skip_newlines()
        match self.view() {
          [RightBracket(..), .. rest] => {
            self.update_view(rest)
            break
          }
          _ => ()
        }
      }
      [RightBracket(..), .. rest] => {
        self.update_view(rest)
        break
      }
      _ => parse_error(self.view(), "Expected ',' or ']' in array")
    }
  }
  TomlArray(values)
}

///| Parse an inline table {key = value, key2 = value2}
fn Parser::parse_inline_table(self : Parser) -> TomlValue raise {
  let table = {}
  match self.view() {
    [RightBrace(..), .. rest] => {
      self.update_view(rest)
      return TomlTable(table)
    }
    _ => ()
  }
  while true {
    // Parse key
    let key = match self.view() {
      [Identifier(k, ..), .. rest] => {
        self.update_view(rest)
        k
      }
      [StringToken(k, ..), .. rest] => {
        self.update_view(rest)
        k
      }
      [IntegerToken(i, ..), .. rest] => {
        self.update_view(rest)
        i.to_string()
      }
      rest => parse_error(rest, "Expected key in inline table")
    }

    // Expect =
    match self.view() {
      [Equals(..), .. rest] => self.update_view(rest)
      rest => parse_error(rest, "Expected '='")
    }

    // Parse value
    let value = self.parse_value()
    table[key] = value
    match self.view() {
      [Comma(..), .. rest] => self.update_view(rest)
      [RightBrace(..), .. rest] => {
        self.update_view(rest)
        break
      }
      _ => parse_error(self.view(), "Expected ',' or '}' in inline table")
    }
  }
  TomlTable(table)
}

///| Parse a table path: section.subsection.key
fn Parser::parse_table_path(self : Parser) -> Array[String] raise {
  let path = Array::new()

  // Parse first key
  let first_key = match self.view() {
    [Identifier(name, ..), .. rest] => {
      self.update_view(rest)
      name
    }
    [StringToken(name, ..), .. rest] => {
      self.update_view(rest)
      name
    }
    [IntegerToken(i, ..), .. rest] => {
      self.update_view(rest)
      i.to_string()
    }
    rest => parse_error(rest, "Expected table name")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while true {
    match self.view() {
      [Dot(..), .. rest] => {
        self.update_view(rest)
        let key = match self.view() {
          [Identifier(name, ..), .. rest2] => {
            self.update_view(rest2)
            name
          }
          [StringToken(name, ..), .. rest2] => {
            self.update_view(rest2)
            name
          }
          [IntegerToken(i, ..), .. rest2] => {
            self.update_view(rest2)
            i.to_string()
          }
          rest2 => parse_error(rest2, "Expected table name after dot")
        }
        path.push(key)
      }
      _ => break
    }
  }
  path
}

///| Parse an array of tables path: section.subsection.key
fn Parser::parse_array_of_tables_path(self : Parser) -> Array[String] raise {
  let path = Array::new()

  // Parse first key
  let first_key = match self.view() {
    [Identifier(name), .. rest] => {
      self.update_view(rest)
      name
    }
    [StringToken(name), .. rest] => {
      self.update_view(rest)
      name
    }
    [IntegerToken(i), .. rest] => {
      self.update_view(rest)
      i.to_string()
    }
    rest => parse_error(rest, "Expected table name in array of tables")
  }
  path.push(first_key)

  // Parse additional keys separated by dots
  while true {
    match self.view() {
      [Dot(..), .. rest] => {
        self.update_view(rest)
        let key = match self.view() {
          [Identifier(name, ..), .. rest2] => {
            self.update_view(rest2)
            name
          }
          [StringToken(name, ..), .. rest2] => {
            self.update_view(rest2)
            name
          }
          [IntegerToken(i, ..), .. rest2] => {
            self.update_view(rest2)
            i.to_string()
          }
          rest2 =>
            parse_error(
              rest2, "Expected table name after dot in array of tables",
            )
        }
        path.push(key)
      }
      _ => break
    }
  }
  path
}

///| Create or get a nested table structure from a path
fn create_nested_table(
  root_table : Map[String, TomlValue],
  path : Array[String],
  error_tokens : ArrayView[@tokenize.Token],
) -> Map[String, TomlValue] raise {
  let mut current_table = root_table
  for key in path {
    match current_table.get(key) {
      Some(TomlTable(existing_table)) => current_table = existing_table
      Some(_) =>
        parse_error(
          error_tokens,
          "Table path conflicts with existing value: " + key,
        )
      None => {
        let new_table = Map::new()
        current_table[key] = TomlTable(new_table)
        current_table = new_table
      }
    }
  }
  current_table
}

///| Create or append to an array of tables structure from a path
fn create_array_of_tables(
  root_table : Map[String, TomlValue],
  path : Array[String],
  error_tokens : ArrayView[@tokenize.Token],
) -> Map[String, TomlValue] raise {
  let mut current_table = root_table

  // Navigate to the parent of the final key
  for key in path[:-1] {
    match current_table.get(key) {
      Some(TomlTable(existing_table)) => current_table = existing_table
      Some(_) =>
        parse_error(
          error_tokens,
          "Array of tables path conflicts with existing value: " + key,
        )
      None => {
        let new_table = Map::new()
        current_table[key] = TomlTable(new_table)
        current_table = new_table
      }
    }
  }

  // Handle the final key as an array of tables
  let final_key = path[path.length() - 1]
  let new_table = {}
  match current_table.get(final_key) {
    Some(TomlArray(existing_array)) => {
      // Append a new table to the existing array
      existing_array.push(TomlTable(new_table))
      new_table
    }
    Some(_) =>
      parse_error(
        error_tokens,
        "Array of tables conflicts with existing non-array value: " + final_key,
      )
    None => {
      // Create new array with the first table
      let array = Array::new()
      array.push(TomlTable(new_table))
      current_table[final_key] = TomlArray(array)
      new_table
    }
  }
}

///|
fn[T] parse_error(tokens : ArrayView[@tokenize.Token], msg : String) -> T raise {
  match tokens {
    [token, ..] => fail(msg + " at " + token.loc().to_string())
    [] => fail(msg + " at the end of input")
  }
}

///| Parse a key-value pair: key = value
fn Parser::parse_key_value(self : Parser) -> (String, TomlValue) raise {
  // Parse key
  let key = match self.view() {
    [Identifier(k), .. rest] => {
      self.update_view(rest)
      k
    }
    [StringToken(k), .. rest] => {
      self.update_view(rest)
      k
    }
    [IntegerToken(i), .. rest] => {
      self.update_view(rest)
      i.to_string()
    }
    rest => parse_error(rest, "Expected key")
  }

  // Expect =
  match self.view() {
    [Equals(..), .. rest] => self.update_view(rest)
    rest => parse_error(rest, "Expected '='")
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
    match parser.view() {
      [EOF(..), ..] => break
      [LeftBracket(..), .. rest] => {
        parser.update_view(rest)
        // Look ahead to see if this is [[ (array of tables) or [ (regular table)
        match parser.view() {
          [LeftBracket(..), .. rest2] => {
            // This is array of tables [[...]]
            parser.update_view(rest2)
            let table_path = parser.parse_array_of_tables_path()
            // expect first ]
            match parser.view() {
              [RightBracket(..), .. rest3] => parser.update_view(rest3)
              rest3 => parse_error(rest3, "Expected ']'")
            }
            // expect second ]
            match parser.view() {
              [RightBracket(..), .. rest4] => parser.update_view(rest4)
              rest4 => parse_error(rest4, "Expected ']'")
            }

            // Create or append to the array of tables structure
            current_table = create_array_of_tables(
              main_table,
              table_path,
              parser.view(),
            )
          }
          _ => {
            // This is a regular table [...]
            let table_path = parser.parse_table_path()
            match parser.view() {
              [RightBracket(..), .. rest3] => parser.update_view(rest3)
              rest3 => parse_error(rest3, "Expected ']'")
            }

            // Create or get the nested table structure
            current_table = create_nested_table(
              main_table,
              table_path,
              parser.view(),
            )
          }
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
