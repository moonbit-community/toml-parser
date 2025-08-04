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

///| Check if character is hexadecimal
fn is_hex(ch : Char) -> Bool {
  is_numeric(ch) || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F')
}

///| Check if character is binary (0 or 1)
fn is_binary(ch : Char) -> Bool {
  ch == '0' || ch == '1'
}

///| Check if character is octal (0-7)
fn is_octal(ch : Char) -> Bool {
  ch >= '0' && ch <= '7'
}

///| Check if character is alphanumeric
fn is_alphanumeric(ch : Char) -> Bool {
  is_alpha(ch) || is_numeric(ch)
}

///| Get current character without advancing
fn Lexer::peek(self : Lexer) -> Char? {
  if self.position >= self.input.length() {
    None // End of input
  } else {
    Some(self.input.get_char(self.position).unwrap())
  }
}

///| Get current character and advance position
/// TODO: handle surrogate pairs and multi-byte characters
fn Lexer::advance(self : Lexer) -> Unit {
  if self.position < self.input.length() {
    let ch = self.input.get_char(self.position).unwrap()
    self.position = self.position + 1
    if ch == '\n' {
      self.line = self.line + 1
      self.column = 1
    } else {
      self.column = self.column + 1
    }
  }
}

///| Skip whitespace characters
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.peek() is Some(ch) && is_whitespace(ch) {
    self.advance()
  }
}

///| Skip comments (start with #)
fn Lexer::skip_comment(self : Lexer) -> Unit {
  if self.peek() is Some('#') {
    while self.peek() is Some(ch) && ch != '\n' {
      self.advance()
    }
  }
}

///| Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {
  let mut result = ""
  while self.peek() is Some(ch) && (is_alphanumeric(ch) || ch == '-') {
    self.advance()
    result = result + Char::to_string(ch)
  }
  result
}

///| Parse a table header name (can be quoted or unquoted, can contain dots)
fn Lexer::read_table_header_name(self : Lexer) -> String raise {
  match self.peek() {
    Some('"') => {
      // Quoted table name
      self.read_string('"')
    }
    Some(ch) if is_alpha(ch) => {
      // Unquoted table name (can contain dots for nesting)
      let mut result = ""
      while self.peek() is Some(ch) && (is_alphanumeric(ch) || ch == '-' || ch == '.' || ch == '_') {
        self.advance()
        result = result + Char::to_string(ch)
      }
      result
    }
    _ => fail("Expected table header name")
  }
}

///| Parse a quoted string
fn Lexer::read_string(self : Lexer, quote_char : Char) -> String raise {
  self.advance() // consume opening quote
  let mut result = ""
  while self.peek() is Some(ch) && ch != quote_char {
    self.advance() // consume character`  
    if ch == '\\' {
      // Handle escape sequences
      match self.peek() {
        Some(escaped) => {
          self.advance() // consume escape character  
          match escaped {
            'n' => result = result + "\n"
            't' => result = result + "\t"
            'r' => result = result + "\r"
            '\\' => result = result + "\\"
            '"' => result = result + "\""
            '\'' => result = result + "'"
            _ => fail("Invalid escape sequence: \\" + Char::to_string(escaped))
          }
        }
        None => fail("Unexpected end of input after escape character")
      }
    } else {
      result = result + Char::to_string(ch)
    }
  }
  if self.peek() is Some(x) && x == quote_char {
    self.advance() // consume closing quote
    result
  } else {
    fail("Unterminated string")
  }
}

///| Parse a literal string (single quotes - no escape sequences)
fn Lexer::read_literal_string(self : Lexer, quote_char : Char) -> String raise {
  self.advance() // consume opening quote
  let mut result = ""
  while self.peek() is Some(ch) && ch != quote_char {
    self.advance() // consume character
    result = result + Char::to_string(ch)
  }
  if self.peek() is Some(x) && x == quote_char {
    self.advance() // consume closing quote
    result
  } else {
    fail("Unterminated literal string")
  }
}

///| Parse a multiline string (triple quotes)
fn Lexer::read_multiline_string(self : Lexer, quote_char : Char) -> String raise {
  let mut result = ""
  let mut quote_count = 0
  let mut first_newline_consumed = false
  
  // Skip the first newline if present (TOML spec)
  if self.peek() is Some('\n') {
    self.advance()
    first_newline_consumed = true
  }
  
  while self.peek() is Some(ch) {
    if ch == quote_char {
      quote_count = quote_count + 1
      self.advance()
      if quote_count == 3 {
        // Found closing triple quotes
        break
      }
    } else {
      // Add any accumulated quotes to result
      for i = 0; i < quote_count; i = i + 1 {
        result = result + Char::to_string(quote_char)
      }
      quote_count = 0
      
      self.advance()
      if ch == '\\' && quote_char == '"' {
        // Handle escape sequences only in basic multiline strings (double quotes)
        match self.peek() {
          Some(escaped) => {
            self.advance()
            match escaped {
              'n' => result = result + "\n"
              't' => result = result + "\t"
              'r' => result = result + "\r"
              '\\' => result = result + "\\"
              '"' => result = result + "\""
              '\'' => result = result + "'"
              ' ' | '\t' => {
                // Line ending backslash - skip whitespace and newline
                while self.peek() is Some(ws) && (ws == ' ' || ws == '\t') {
                  self.advance()
                }
                if self.peek() is Some('\n') {
                  self.advance()
                }
              }
              _ => fail("Invalid escape sequence in multiline string: \\" + Char::to_string(escaped))
            }
          }
          None => fail("Unexpected end of input after escape character")
        }
      } else {
        // For literal multiline strings (single quotes), add character as-is
        result = result + Char::to_string(ch)
      }
    }
  }
  
  if quote_count < 3 {
    fail("Unterminated multiline string")
  }
  
  result
}

///| Parse a hexadecimal number (0x prefix)
fn Lexer::read_hex_number(self : Lexer) -> Token raise {
  let mut num_str = "0x"
  self.advance() // consume '0'
  self.advance() // consume 'x'
  
  while self.peek() is Some(ch) && (is_hex(ch) || ch == '_') {
    if ch != '_' { // Skip underscores
      num_str = num_str + Char::to_string(ch)
    }
    self.advance()
  }
  
  // Convert hex to decimal
  let hex_part = num_str.substring(2) // Remove "0x" prefix
  let mut result = 0L
  for i = 0; i < hex_part.length(); i = i + 1 {
    result = result * 16L
    match hex_part.get_char(i) {
      Ok(ch) => {
        let digit = match ch {
          '0' => 0L | '1' => 1L | '2' => 2L | '3' => 3L | '4' => 4L
          '5' => 5L | '6' => 6L | '7' => 7L | '8' => 8L | '9' => 9L
          'a' | 'A' => 10L | 'b' | 'B' => 11L | 'c' | 'C' => 12L
          'd' | 'D' => 13L | 'e' | 'E' => 14L | 'f' | 'F' => 15L
          _ => fail("Invalid hex digit: " + Char::to_string(ch))
        }
        result = result + digit
      }
      Err(_) => fail("Invalid hex number")
    }
  }
  IntegerToken(result)
}

///| Parse an octal number (0o prefix)
fn Lexer::read_octal_number(self : Lexer) -> Token raise {
  let mut num_str = "0o"
  self.advance() // consume '0'
  self.advance() // consume 'o'
  
  while self.peek() is Some(ch) && (is_octal(ch) || ch == '_') {
    if ch != '_' { // Skip underscores
      num_str = num_str + Char::to_string(ch)
    }
    self.advance()
  }
  
  // Convert octal to decimal
  let octal_part = num_str.substring(2) // Remove "0o" prefix
  let mut result = 0L
  for i = 0; i < octal_part.length(); i = i + 1 {
    result = result * 8L
    match octal_part.get_char(i) {
      Ok(ch) => {
        let digit = match ch {
          '0' => 0L | '1' => 1L | '2' => 2L | '3' => 3L
          '4' => 4L | '5' => 5L | '6' => 6L | '7' => 7L
          _ => fail("Invalid octal digit: " + Char::to_string(ch))
        }
        result = result + digit
      }
      Err(_) => fail("Invalid octal number")
    }
  }
  IntegerToken(result)
}

///| Parse a binary number (0b prefix)
fn Lexer::read_binary_number(self : Lexer) -> Token raise {
  let mut num_str = "0b"
  self.advance() // consume '0'
  self.advance() // consume 'b'
  
  while self.peek() is Some(ch) && (is_binary(ch) || ch == '_') {
    if ch != '_' { // Skip underscores
      num_str = num_str + Char::to_string(ch)
    }
    self.advance()
  }
  
  // Convert binary to decimal
  let binary_part = num_str.substring(2) // Remove "0b" prefix
  let mut result = 0L
  for i = 0; i < binary_part.length(); i = i + 1 {
    result = result * 2L
    match binary_part.get_char(i) {
      Ok(ch) => {
        let digit = match ch {
          '0' => 0L
          '1' => 1L
          _ => fail("Invalid binary digit: " + Char::to_string(ch))
        }
        result = result + digit
      }
      Err(_) => fail("Invalid binary number")
    }
  }
  IntegerToken(result)
}

///| Check if a character at position exists and matches
fn char_at_matches(input : String, pos : Int, expected : Char) -> Bool {
  if pos >= input.length() { return false }
  match input.get_char(pos) {
    Ok(ch) => ch == expected
    Err(_) => false
  }
}

///| Check if a string matches date-time patterns
fn is_datetime_pattern(input : String) -> Bool {
  // Simple pattern matching for common TOML datetime formats
  // YYYY-MM-DD
  // YYYY-MM-DDTHH:MM:SS[.fraction][+/-HH:MM|Z]
  // HH:MM:SS[.fraction]
  let len = input.length()
  if len < 8 { return false }
  
  // Check for date pattern: YYYY-MM-DD
  if len >= 10 && char_at_matches(input, 4, '-') && char_at_matches(input, 7, '-') {
    return true
  }
  
  // Check for time pattern: HH:MM:SS
  if len >= 8 && char_at_matches(input, 2, ':') && char_at_matches(input, 5, ':') {
    return true
  }
  
  // Check for date-time pattern: contains both date and T
  if string_contains_char(input, 'T') && string_contains_char(input, '-') && string_contains_char(input, ':') {
    return true
  }
  
  false
}

///| Check if string contains character
fn string_contains_char(input : String, target : Char) -> Bool {
  for i = 0; i < input.length(); i = i + 1 {
    match input.get_char(i) {
      Ok(ch) if ch == target => return true
      _ => continue
    }
  }
  false
}

///| Check if string contains character after a certain position
fn string_contains_char_after(input : String, target : Char, start_pos : Int) -> Bool {
  for i = start_pos; i < input.length(); i = i + 1 {
    match input.get_char(i) {
      Ok(ch) if ch == target => return true
      _ => continue
    }
  }
  false
}

///| Parse a datetime string and determine its type
fn parse_datetime_type(input : String) -> TomlDateTime {
  if string_contains_char(input, 'T') {
    if string_contains_char(input, 'Z') || string_contains_char(input, '+') || string_contains_char_after(input, '-', 10) {
      // Offset datetime like "1979-05-27T07:32:00Z" or "1979-05-27T00:32:00-07:00"
      OffsetDateTime(input)
    } else {
      // Local datetime like "1979-05-27T07:32:00"
      LocalDateTime(input)
    }
  } else if string_contains_char(input, ':') {
    // Local time like "07:32:00"
    LocalTime(input)
  } else {
    // Local date like "1979-05-27"
    LocalDate(input)
  }
}

///| Parse a number (integer or float), with optional negative sign
///| Now also handles datetime recognition
fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
  let mut num_str = if is_negative { "-" } else { "" }
  let mut is_float = false
  let start_pos = self.position - 1 // Account for already consumed character

  // Read digits
  while self.peek() is Some(ch) && is_numeric(ch) {
    self.advance()
    num_str = num_str + Char::to_string(ch)
  }

  // Check for decimal point
  if self.peek() is Some('.') {
    is_float = true
    self.advance()
    num_str = num_str + Char::to_string('.')
    while self.peek() is Some(ch) && is_numeric(ch) {
      self.advance()
      num_str = num_str + Char::to_string(ch)
    }
  }
  
  // Check for datetime patterns (only if not negative and starts with 4 digits)
  if not(is_negative) && num_str.length() >= 4 {
    // Look ahead to see if this might be a datetime
    let mut lookahead = num_str
    let saved_pos = self.position
    
    // Try to read more characters that could be part of a datetime
    while self.peek() is Some(ch) && (ch == '-' || ch == ':' || ch == 'T' || ch == 'Z' || ch == '+' || ch == '.' || is_numeric(ch)) {
      self.advance()
      lookahead = lookahead + Char::to_string(ch)
    }
    
    if is_datetime_pattern(lookahead) {
      return DateTimeToken(parse_datetime_type(lookahead))
    } else {
      // Not a datetime, restore position
      self.position = saved_pos
    }
  }
  
  if is_float {
    FloatToken(@strconv.parse_double(num_str)) catch {
      _ => fail("Invalid float: " + num_str)
    }
  } else {
    IntegerToken(@strconv.parse_int64(num_str)) catch {
      _ => fail("Invalid integer: " + num_str)
    }
  }
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
      // Check for array table header [[section]]
      if self.peek() is Some('[') {
        self.advance() // consume second [
        self.skip_whitespace()
        let header_name = self.read_table_header_name()
        self.skip_whitespace()
        // Expect ]]
        if self.peek() is Some(']') {
          self.advance()
          if self.peek() is Some(']') {
            self.advance()
            return ArrayTableHeader(header_name)
          } else {
            fail("Expected ']]' to close array table header")
          }
        } else {
          fail("Expected ']]' to close array table header")
        }
      } else {
        // Check if this is a table header [section]
        self.skip_whitespace()
        if self.peek() is Some(ch) && (is_alpha(ch) || ch == '"') {
          let header_name = self.read_table_header_name()
          self.skip_whitespace()
          if self.peek() is Some(']') {
            self.advance()
            return TableHeader(header_name)
          } else {
            fail("Expected ']' to close table header")
          }
        } else {
          return LeftBracket
        }
      }
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
    Some('"') => {
      // Check for multiline string (triple quotes)
      let saved_pos = self.position
      self.advance() // consume first quote
      if self.peek() is Some('"') {
        self.advance() // consume second quote
        if self.peek() is Some('"') {
          self.advance() // consume third quote
          return StringToken(self.read_multiline_string('"'))
        } else {
          // Not a multiline string, restore and read normal string
          self.position = saved_pos
          return StringToken(self.read_string('"'))
        }
      } else {
        // Not a multiline string, restore and read normal string  
        self.position = saved_pos
        return StringToken(self.read_string('"'))
      }
    }
    Some('\'') => {
      // Check for multiline literal string (triple single quotes)
      let saved_pos = self.position
      self.advance() // consume first quote
      if self.peek() is Some('\'') {
        self.advance() // consume second quote
        if self.peek() is Some('\'') {
          self.advance() // consume third quote
          return StringToken(self.read_multiline_string('\''))
                 } else {
           // Not a multiline string, restore and read literal string
           self.position = saved_pos
           return StringToken(self.read_literal_string('\''))
         }
       } else {
         // Not a multiline string, restore and read literal string
         self.position = saved_pos
         return StringToken(self.read_literal_string('\''))
       }
    }
    Some(ch) =>
      if ch == '0' {
        // Check for special number formats (hex, octal, binary)
        let saved_pos = self.position
        self.advance() // consume '0'
        match self.peek() {
          Some('x') | Some('X') => self.read_hex_number()
          Some('o') | Some('O') => self.read_octal_number()
          Some('b') | Some('B') => self.read_binary_number()
          _ => {
            // Regular number starting with 0, restore position
            self.position = saved_pos
            self.read_number(false)
          }
        }
      } else if is_numeric(ch) {
        self.read_number(false)
      } else if ch == '-' {
        // Check if this is a negative number
        let saved_pos = self.position
        self.advance() // consume the '-'
        match self.peek() {
          Some(next_ch) if is_numeric(next_ch) =>
            // This is a negative number, read it
            self.read_number(true)
          Some(next_ch) if is_alpha(next_ch) => {
            // Check for negative special float values
            let identifier = self.read_identifier()
            match identifier {
              "inf" => FloatToken(Double::neg_inf)
              "nan" => FloatToken(Double::nan)
              _ => {
                // Not a special float value, error
                self.position = saved_pos
                fail("Unexpected character: " + Char::to_string(ch))
              }
            }
          }
          _ => {
            // Not a negative number or special value, restore position and error
            self.position = saved_pos
            fail("Unexpected character: " + Char::to_string(ch))
          }
        }
      } else if ch == '+' {
        // Check for positive special float values
        let saved_pos = self.position
        self.advance() // consume '+'
                 if self.peek() is Some(next_ch) && is_alpha(next_ch) {
          let identifier = self.read_identifier()
          match identifier {
            "inf" => FloatToken(Double::pos_inf)
            "nan" => FloatToken(Double::nan)
            _ => {
              // Not a special float value, error
              self.position = saved_pos
              fail("Unexpected character: " + Char::to_string(ch))
            }
          }
        } else {
          // Not a special float value, error
          self.position = saved_pos
          fail("Unexpected character: " + Char::to_string(ch))
        }
      } else if is_alpha(ch) {
        let identifier = self.read_identifier()
        // Check for boolean keywords and special float values
        match identifier {
          "true" => BooleanToken(true)
          "false" => BooleanToken(false)
          "inf" => FloatToken(Double::pos_inf)
          "+inf" => FloatToken(Double::pos_inf)
          "-inf" => FloatToken(Double::neg_inf)
          "nan" => FloatToken(Double::nan)
          "+nan" => FloatToken(Double::nan)
          "-nan" => FloatToken(Double::nan)
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
