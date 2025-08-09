///|
typealias @lexer.Lexer

///| Check if character is numeric
fn is_numeric(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///| Check if character is alpha (letter)
fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///| Check if character is hexadecimal digit
fn is_hex_digit(ch : Char) -> Bool {
  ch is ('0'..='9' | 'a'..='f' | 'A'..='F')
}

///| Check if character is binary digit
fn is_binary_digit(ch : Char) -> Bool {
  ch == '0' || ch == '1'
}

///| Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {
  let sb = StringBuilder::new()
  while true {
    match self.view() {
      ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-' as x, .. rest] => {
        self.update_view(rest)
        sb.write_char(x)
      }
      _ => break
    }
  }
  sb.to_string()
}

///| Parse Unicode escape sequence \uXXXX
fn Lexer::read_unicode_4_escape(self : Lexer) -> Char raise {
  let mut code = 0
  for i = 0; i < 4; i = i + 1 {
    match self.peek() {
      Some(ch) if is_hex_digit(ch) => {
        self.advance()
        let digit = match ch {
          '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
            ch.to_int() - '0'.to_int()
          'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
          'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
        }
        code = code * 16 + digit
      }
      _ =>
        fail(
          self.error("Invalid Unicode escape sequence: expected 4 hex digits"),
        )
    }
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
}

///| Parse Unicode escape sequence \UXXXXXXXX
fn Lexer::read_unicode_8_escape(self : Lexer) -> Char raise {
  let mut code = 0
  for i = 0; i < 8; i = i + 1 {
    match self.peek() {
      Some(ch) if is_hex_digit(ch) => {
        self.advance()
        let digit = match ch {
          '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
            ch.to_int() - '0'.to_int()
          'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
          'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
        }
        code = code * 16 + digit
      }
      _ =>
        fail(
          self.error("Invalid Unicode escape sequence: expected 8 hex digits"),
        )
    }
  }
  if code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF) {
    fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: " + code.to_string()))
  }
}

///| Parse a basic string (double quotes) with escape sequences
fn Lexer::read_basic_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let sb = StringBuilder::new()
  while self.peek() is Some(ch) && ch != '"' {
    self.advance() // consume character`  
    if ch == '\\' {
      // Handle escape sequences
      match self.peek_charcode() {
        Some(escaped) => {
          self.advance() // consume escape character  
          match escaped {
            'n' => sb.write_char('\n')
            't' => sb.write_char('\t')
            'r' => sb.write_char('\r')
            '\\' => sb.write_char('\\')
            '"' => sb.write_char('"')
            '\'' => sb.write_char('\'')
            'b' => sb.write_char('\u0008')
            'f' => sb.write_char('\u000C')
            'u' => sb.write_char(self.read_unicode_4_escape())
            'U' => sb.write_char(self.read_unicode_8_escape())
            _ =>
              fail(
                self.error(
                  "Invalid escape sequence: \\\{escaped.to_char().unwrap_or('?')}",
                ),
              )
            // TODO:refine the error message 
          }
        }
        None =>
          fail(self.error("Unexpected end of input after escape character"))
      }
    } else {
      sb.write_char(ch)
    }
  }
  self.expect_char('"', msg="Unterminated string")
  sb.to_string()
}

///| Parse a literal string (single quotes) without escape sequences
fn Lexer::read_literal_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let sb = StringBuilder::new()
  self.repeat_if(ch => if ch != '\'' {
    sb.write_char(ch)
    true
  } else {
    false
  })
  self.expect_char('\'', msg="Unterminated string")
  sb.to_string()
}

///| Parse a multi-line basic string (triple double quotes) with escape sequences
fn Lexer::read_multiline_basic_string(self : Lexer) -> String raise {
  // consume opening triple quotes
  self.expect_string("\"\"\"")
  // Skip line ending immediately following the opening delimiter
  if self.try_consume_charcode('\r') {
    if self.try_consume_charcode('\n') {
      self.new_line()
    }
  } else if self.try_consume_charcode('\n') {
    self.new_line()
  }
  let sb = StringBuilder::new()
  while self.get_position() < self.input.length() {
    // Check for closing triple quotes
    if self.peek() is Some('"') {
      self.advance()
      if self.try_consume_charcode('"') {
        if self.try_consume_charcode('"') {
          return sb.to_string()
        }
      }
      // Not triple quotes, continue parsing (we've already consumed the quote)
      // Note: This is a simplification - a proper implementation would backtrack
      sb.write_char('"')
    }
    match self.peek() {
      Some(ch) => {
        self.advance()
        if ch == '\\' {
          // Handle escape sequences
          match self.peek() {
            Some(escaped) => {
              self.advance()
              match escaped {
                'n' => sb.write_char('\n')
                't' => sb.write_char('\t')
                'r' => sb.write_char('\r')
                '\\' => sb.write_char('\\')
                '"' => sb.write_char('"')
                '\'' => sb.write_char('\'')
                'b' => sb.write_char('\u0008')
                'f' => sb.write_char('\u000C')
                'u' => sb.write_char(self.read_unicode_4_escape())
                'U' => sb.write_char(self.read_unicode_8_escape())
                // Line ending backslash (trim whitespace at line start)
                '\r' | '\n' => {
                  self.new_line()
                  if escaped == '\r' && self.peek() is Some('\n') {
                    self.advance() // consume the \n after \r
                  }
                  // Skip whitespace at the beginning of the next line
                  while self.peek() is Some(ws) && ws is (' ' | '\t') {
                    self.advance()
                  }
                }
                _ =>
                  fail(
                    self.error(
                      "Invalid escape sequence: \\" + Char::to_string(escaped),
                    ),
                  )
              }
            }
            None =>
              fail(self.error("Unexpected end of input after escape character"))
          }
        } else {
          sb.write_char(ch)
          if ch == '\n' {
            self.new_line()
          }
        }
      }
      None => fail(self.error("Unterminated multiline string"))
    }
  }
  fail(self.error("Unterminated multiline string"))
}

///| Parse a multi-line literal string (triple single quotes) without escape sequences
fn Lexer::read_multiline_literal_string(self : Lexer) -> String raise {
  // consume opening triple quotes
  self.expect_string("'''")
  let sb = StringBuilder::new()
  while true {
    match self.view() {
      [.. "'''", .. rest] => {
        // finish reading the string
        self.update_view(rest)
        break
      }
      [.. "\r\n", .. rest] => {
        sb.write_string("\r\n")
        self.update_view(rest)
        self.new_line()
      }
      // TODO: support .. ("\n"|"\r\n")
      // CR: zhangyu

      [ch, .. rest] => {
        if ch is '\n' {
          self.new_line()
        }
        self.update_view(rest)
        sb.write_char(ch)
      }
      [] => fail(self.error("Unterminated multiline literal string"))
    }
  } // FIXME: special typing rules for `while true`
  sb.to_string()
}

///| Parse hexadecimal number
fn Lexer::read_hex_number(self : Lexer) -> Int64 raise {
  let mut result = 0L
  while self.peek() is Some(ch) && (is_hex_digit(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      let digit = match ch {
        '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
          ch.to_int() - '0'.to_int()
        'a' | 'b' | 'c' | 'd' | 'e' | 'f' => ch.to_int() - 'a'.to_int() + 10
        'A' | 'B' | 'C' | 'D' | 'E' | 'F' => ch.to_int() - 'A'.to_int() + 10
        _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
      }
      result = result * 16L + digit.to_int64()
    }
  }
  result
}

///| Parse octal number
fn Lexer::read_octal_number(self : Lexer) -> Int64 {
  let mut result = 0L
  while true {
    match self.view() {
      ['0'..='7' | '_' as x, .. rest] => {
        self.update_view(rest)
        if x != '_' {
          let digit = x.to_int() - '0'
          result = result * 8 + digit.to_int64()
        }
      }
      _ => break
    }
  }
  result
}

///|
test {
  let lexer = @lexer.Lexer::new("0o755")
  lexer.advance() // consume '0'
  lexer.advance() // consume 'o'
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///| Parse binary number
fn Lexer::read_binary_number(self : Lexer) -> Int64 {
  let mut result = 0L
  self.repeat_if(ch => if is_binary_digit(ch) || ch == '_' {
    if ch != '_' {
      let digit = ch.to_int() - '0'.to_int()
      result = result * 2L + digit.to_int64()
    }
    true
  } else {
    false
  })
  result
}

///| Parse a number (integer or float), with optional negative sign
fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
  let sb = StringBuilder::new()
  if is_negative {
    sb.write_char('-')
  }
  let mut is_float = false

  // Check if this might be a special format number (0x, 0o, 0b)
  if !is_negative {
    match self.view() {
      ['0', 'x' | 'X', .. rest] => {
        self.update_view(rest)
        let value = self.read_hex_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      ['0', 'o' | 'O', .. rest] => {
        self.update_view(rest)
        let value = self.read_octal_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      ['0', 'b' | 'B', .. rest] => {
        self.update_view(rest)
        let value = self.read_binary_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      _ => () // continue with non binary mode
    }
  }
  // Read digits
  while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
    self.advance()
    if ch != '_' {
      sb.write_char(ch)
    }
  }

  // Check for decimal point
  if self.peek() is Some('.') {
    is_float = true
    self.advance()
    sb.write_char('.')
    while self.peek() is Some(ch) && (is_numeric(ch) || ch == '_') {
      self.advance()
      if ch != '_' {
        sb.write_char(ch)
      }
    }
  }
  let s = sb.to_string()
  if is_float {
    FloatToken(@strconv.parse_double(s)) catch {
      _ => fail("Invalid float: " + s)
    }
  } else {
    IntegerToken(@strconv.parse_int64(s)) catch {
      _ => fail("Invalid integer: " + s)
    }
  }
}

///|
test "read_number" {
  let lexer = Lexer::new("123")
  inspect(lexer.read_number(false), content="IntegerToken(123)")
}

///| Get the next token
fn Lexer::next_token(self : Lexer) -> Token raise {
  self.skip_whitespace()
  self.skip_comment()
  match self.peek() {
    None => return EOF
    Some('\n') => {
      self.advance()
      self.new_line()
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
        self.advance() // consume the '-'
        match self.peek() {
          Some(next_ch) if is_numeric(next_ch) =>
            // This is a negative number, read it
            self.read_number(true)
          _ =>
            // Not a negative number, this is an error in TOML
            fail("Unexpected character: " + Char::to_string(ch))
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

///| Test read_number
test "read_number" {
  let lexer = Lexer::new("123")
  inspect(lexer.read_number(false), content="IntegerToken(123)")
}

///| Test Unicode escape sequences
test "unicode escape sequences" {
  let lexer1 = Lexer::new("\"\\u0041\"") // 'A'
  let result1 = lexer1.read_basic_string()
  inspect(result1, content="A")
  let lexer2 = Lexer::new("\"\\U00000041\"") // 'A'
  let result2 = lexer2.read_basic_string()
  inspect(result2, content="A")
}

///| Test multiline basic string
test "multiline basic string" {
  let lexer = Lexer::new("\"\"\"line1\nline2\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1\nline2")
}

///| Test multiline literal string
test "multiline literal string" {
  let lexer = Lexer::new("'''line1\nline2'''")
  let result = lexer.read_multiline_literal_string()
  inspect(result, content="line1\nline2")
}

///| Test line ending backslash in multiline string
test "line ending backslash" {
  let lexer = Lexer::new("\"\"\"line1\\\n   line2\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1line2") // whitespace should be trimmed
}

///| Test basic string parsing
test "basic string parsing" {
  let lexer = Lexer::new("\"Hello, \\\"world\\\"!\"")
  let result = lexer.read_basic_string()
  inspect(result, content="Hello, \"world\"!")
}

///| Test literal string parsing  
test "literal string parsing" {
  let lexer = Lexer::new("'Hello, world!'")
  let result = lexer.read_literal_string()
  inspect(result, content="Hello, world!")
}

///| Test identifier parsing
test "identifier parsing" {
  let lexer = Lexer::new("hello-world_123")
  let result = lexer.read_identifier()
  inspect(result, content="hello-world_123")
}

///| Test hex number parsing
test "hex number parsing" {
  let lexer = Lexer::new("0xDEADBEEF")
  lexer.advance() // consume '0'
  lexer.advance() // consume 'x'
  let result = lexer.read_hex_number()
  inspect(result, content="3735928559")
}

///| Test octal number parsing  
test "octal number parsing" {
  let lexer = Lexer::new("0o755")
  lexer.advance() // consume '0'
  lexer.advance() // consume 'o'
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///| Test binary number parsing
test "binary number parsing" {
  let lexer = Lexer::new("0b1010")
  lexer.advance() // consume '0'
  lexer.advance() // consume 'b'
  let result = lexer.read_binary_number()
  inspect(result, content="10")
}
