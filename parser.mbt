///|
using @tokenize {tokenize, type Token, type TomlDateTime}

///|
/// Skip newline tokens
fn Parser::skip_newlines(self : Parser) -> Unit {
  let next_view = loop self.view() {
    [Newline(..), .. rest] => continue rest
    rest => rest
  }
  self.update_view(next_view)
}

///|
/// Try to consume a single bare key from the current position.
/// Handles identifiers, strings, integers, booleans (true/false),
/// and special float keywords (inf/nan) in key position.
fn Parser::try_parse_single_key(self : Parser) -> String? {
  match self.view() {
    [Identifier(name, ..), .. rest] => {
      self.update_view(rest)
      Some(name)
    }
    [StringToken(_, multiline=true, ..), ..] =>
      None // multiline strings not allowed as keys
    [StringToken(name, ..), .. rest] => {
      self.update_view(rest)
      Some(name)
    }
    [IntegerToken(i, ..), .. rest] => {
      self.update_view(rest)
      Some(i.to_string())
    }
    [BooleanToken(b, ..), .. rest] => {
      self.update_view(rest)
      Some(if b { "true" } else { "false" })
    }
    [FloatToken(f, ..), .. rest] => {
      // inf and nan are valid bare keys
      if f.is_inf() {
        self.update_view(rest)
        Some(if f < 0.0 { "-inf" } else { "inf" })
      } else if f.is_nan() {
        self.update_view(rest)
        Some("nan")
      } else {
        None
      }
    }
    [DateTimeToken(dt, ..), .. rest] => {
      // Date-like bare keys (e.g. 2001-02-03)
      self.update_view(rest)
      let s = match dt {
        OffsetDateTime(s) => s
        LocalDateTime(s) => s
        LocalDate(s) => s
        LocalTime(s) => s
      }
      Some(s)
    }
    _ => None
  }
}

///|
/// Parse a primary value (string, number, boolean)
fn Parser::parse_value(
  self : Self,
  skip_newlines? : Bool = false,
) -> TomlValue raise {
  match self.view(skip_newlines~) {
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
    // TOML Array
    [LeftBracket, .. rest] => {
      self.update_view(rest)
      self.parse_array()
    }
    // TOML Inline Table
    [LeftBrace, .. rest] => {
      self.update_view(rest)
      self.parse_inline_table()
    }
    [Identifier("inf", ..), .. rest] => {
      self.update_view(rest)
      TomlFloat(1.0 / 0.0) // positive infinity
    }
    [Identifier("nan", ..), .. rest] => {
      self.update_view(rest)
      TomlFloat(0.0 / 0.0) // NaN
    }
    _ => self.error("Expected value")
  }
}

///|
/// Parse an array [1, 2, 3]
fn Parser::parse_array(self : Self) -> TomlValue raise {
  let values = []
  while true {
    if self.view(skip_newlines=true) is [RightBracket, .. rest] {
      self.update_view(rest)
      return TomlArray(values)
    }
    // self.skip_newlines() // here Newline is allowed
    values.push(self.parse_value(skip_newlines=true))
    match self.view(skip_newlines=true) {
      [Comma, .. rest] => self.update_view(rest)
      [RightBracket, .. rest] => {
        self.update_view(rest)
        break
      }
      _ => self.error("Expected ',' or ']' in array")
    }
  }
  TomlArray(values)
}

///|
/// Parse an inline table {key = value, key2 = value2}
/// No trailing comma allowed unlike Array
fn Parser::parse_inline_table(self : Parser) -> TomlValue raise {
  let table = {}
  self.skip_newlines() // TOML 1.1: allow newlines in inline tables
  if self.view() is [RightBrace, .. rest] {
    self.update_view(rest)
    return TomlTable(table)
  }
  while true {
    self.skip_newlines()
    // Parse dotted key
    let key_path = self.parse_dotted_key()

    // Expect =
    match self.view() {
      [Equals, .. rest] => self.update_view(rest)
      _ => self.error("Expected '='")
    }

    // Parse value
    let value = self.parse_value()
    set_dotted_key_value(table, key_path, value) catch {
      error => self.error(error.to_string())
    }
    self.skip_newlines()
    match self.view() {
      [Comma, .. rest] => {
        self.update_view(rest)
        self.skip_newlines()
        // Trailing comma: check for closing brace after comma
        if self.view() is [RightBrace, .. rest2] {
          self.update_view(rest2)
          break
        }
      }
      [RightBrace, .. rest] => {
        self.update_view(rest)
        break
      }
      _ => self.error("Expected ',' or '}' in inline table")
    }
  }
  TomlTable(table)
}

///|
/// Parse a table path: section.subsection.key
fn Parser::parse_table_path(self : Parser) -> Array[String] raise {
  self.parse_dotted_key()
}

///|
fn[A] Parser::error(self : Parser, msg : String) -> A raise {
  match self.view() {
    [token, ..] => fail("\{msg} at \{@debug.to_string(token.loc())}")
    [] => fail("\{msg} at the end of input")
  }
}

///|
/// Parse a dotted key path: key.subkey.subsubkey
fn Parser::parse_dotted_key(self : Parser) -> Array[String] raise {
  let path = Array::new()

  // Parse first key - handle the case where the tokenizer saw a float like "1.2"
  match self.view() {
    [FloatToken(f), .. rest] if !f.is_inf() && !f.is_nan() => {
      // Handle float tokens that represent dotted numeric keys like "1.2"
      self.update_view(rest)
      let float_str = f.to_string()

      // Split the float string on the dot to create dotted keys
      let dot_index = match float_str.find(".") {
        Some(i) => i
        None => {
          // No dot found, treat as single key
          path.push(float_str)
          return path
        }
      }
      let first_part = float_str[:dot_index].to_string()
      let second_part = float_str[dot_index + 1:].to_string()
      path.push(first_part)
      path.push(second_part)
    }
    _ =>
      match self.try_parse_single_key() {
        Some(k) => path.push(k)
        None => self.error("Expected key")
      }
  }

  // Parse additional keys separated by dots
  let next_view = loop self.view() {
    [Dot(..), .. rest] => {
      self.update_view(rest)
      // Check for float token (e.g. 1.2 → keys "1" and "2")
      match self.view() {
        [FloatToken(f, ..), .. rest2] if !f.is_inf() && !f.is_nan() => {
          self.update_view(rest2)
          let float_str = f.to_string()
          match float_str.find(".") {
            Some(i) => {
              path.push(float_str[:i].to_string())
              path.push(float_str[i + 1:].to_string())
            }
            None => path.push(float_str)
          }
        }
        _ =>
          match self.try_parse_single_key() {
            Some(k) => path.push(k)
            None => self.error("Expected key after dot")
          }
      }
      continue self.view()
    }
    rest => rest
  }
  self.update_view(next_view)
  path
}

///|
/// Parse a key-value pair with dotted key support: key.subkey = value
fn Parser::parse_key_value(self : Parser) -> (Array[String], TomlValue) raise {
  // Parse dotted key
  let key_path = self.parse_dotted_key()

  // Expect =
  match self.view() {
    [Equals, .. rest] => self.update_view(rest)
    _ => self.error("Expected '='")
  }

  // Parse value
  let value = self.parse_value()
  (key_path, value)
}

///|
/// Parse a TOML document with support for tables
pub fn parse(input : String) -> TomlValue raise {
  let tokens = tokenize(input)
  let parser = Parser::new(tokens)
  let main_table = {}
  for current_table = main_table {
    parser.skip_newlines()
    match parser.view() {
      [EOF, ..] => break
      [LeftBracket, LeftBracket, .. rest] => {
        parser.update_view(rest)
        let table_path = parser.parse_table_path()
        match parser.view() {
          [RightBracket, RightBracket, .. rest] => parser.update_view(rest)
          _ => parser.error("Expected ']]'")
        }
        // Validate newline/EOF/comment after ]]
        match parser.view() {
          [EOF, ..] | [Newline, ..] => ()
          _ => parser.error("Expected newline or end of file after ']]'")
        }
        // Create or append to the array of tables structure
        let current_table = create_array_of_tables(main_table, table_path) catch {
          error => parser.error(error.to_string())
        }
        continue current_table
      }
      [LeftBracket, .. rest] => {
        parser.update_view(rest)
        let table_path = parser.parse_table_path()
        match parser.view() {
          [RightBracket, .. rest3] => parser.update_view(rest3)
          _ => parser.error("Expected ']'")
        }
        // Validate newline/EOF/comment after ]
        match parser.view() {
          [EOF, ..] | [Newline, ..] => ()
          _ =>
            parser.error("Expected newline or end of file after ']'")
        }

        // Create or get the nested table structure
        let current_table = create_nested_table(main_table, table_path) catch {
          error => parser.error(error.to_string())
        }
        continue current_table
      }
      _ => {
        // Parse key-value pair
        let (key_path, value) = parser.parse_key_value()
        set_dotted_key_value(current_table, key_path, value) catch {
          error => parser.error(error.to_string())
        }
        // Validate that key-value pair is properly terminated
        match parser.view() {
          [EOF, ..] => () // EOF is valid
          [Newline, ..] => () // Newline is valid (comments are already skipped by tokenizer)
          _ =>
            parser.error("Expected newline or end of file after key-value pair")
        }
      }
    }
  }
  TomlTable(main_table)
}
