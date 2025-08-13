///|
typealias @lexer.Lexer

///| Check if character is hexadecimal digit
fn is_hex_digit(ch : Char) -> Bool {
  ch is ('0'..='9' | 'a'..='f' | 'A'..='F')
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
          '0'..='9' => ch.to_int() - '0'
          'a'..='f' => ch.to_int() - 'a' + 10
          'A'..='F' => ch.to_int() - 'A' + 10
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
  let next = loop self.view() {
    ['\'', .. rest] => rest
    [ch, .. rest] => {
      sb.write_char(ch)
      continue rest
    }
    [] => fail(self.error("Unterminated string"))
  }
  self.update_view(next)
  sb.to_string()
}

///| Parse a multi-line basic string (triple double quotes) with escape sequences
/// The openining triple quotes are already consumed by the caller
fn Lexer::read_multiline_basic_string(self : Lexer) -> String raise {
  self.skip_single_newline()
  let sb = StringBuilder::new()
  while true {
    match self.view() {
      [.. "\"\"\"", .. rest] => {
        // Check for closing triple quotes  
        self.update_view(rest)
        return sb.to_string()
      }
      ['\\', escaped, .. rest] => {
        self.update_view(rest) // consume escaped character
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
            if escaped == '\r' {
              match self.view() {
                ['\n', .. rest] => self.update_view(rest)
                _ => ()
              }
            }
            // Skip whitespace at the beginning of the next line
            while true {
              match self.view() {
                [' ' | '\t', .. rest] => self.update_view(rest)
                _ => break
              }
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
      ['\\'] => {
        self.advance()
        fail(self.error("Unexpected end of input after escape character"))
      }
      [ch, .. rest] => {
        self.update_view(rest)
        sb.write_char(ch)
        if ch == '\n' {
          self.new_line()
        }
      }
      [] => fail(self.error("Unterminated multiline string"))
    }
  }
  fail(self.error("Unterminated multiline string"))
}

///| Parse a multi-line literal string (triple single quotes) without escape sequences
fn Lexer::read_multiline_literal_string(self : Lexer) -> String raise {
  // consume opening triple quotes
  // strip the newline following the opening delimiter immediately
  match self.view() {
    [.. "\r\n", .. rest] => {
      self.update_view(rest)
      self.new_line()
    }
    [.. "\n", .. rest] => {
      self.update_view(rest)
      self.new_line()
    }
    _ => ()
  }
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
  let mut result = match self.view() {
    ['0', 'x' | 'X', '0'..='9' | 'a'..='f' | 'A'..='F' as ch, .. rest] => {
      self.update_view(rest)
      let digit = match ch {
        '0'..='9' => ch.to_int() - '0'
        'a'..='f' => ch.to_int() - 'a' + 10
        'A'..='F' => ch.to_int() - 'A' + 10
        _ => abort("Internal error: pattern matching inconsistency")
      }
      digit.to_int64()
    }
    _ =>
      fail(
        self.error("Invalid hex number, expected 0..=9, a..=f, A..=F after 0x"),
      )
  }
  while true {
    match self.view() {
      ['0'..='9' | 'a'..='f' | 'A'..='F' as ch, .. rest] => {
        self.update_view(rest)
        let digit = match ch {
          '0'..='9' => ch.to_int() - '0'
          'a'..='f' => ch.to_int() - 'a' + 10
          'A'..='F' => ch.to_int() - 'A' + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch)))
        }
        result = result * 16L + digit.to_int64()
      }
      ['_', '0'..='9' | 'a'..='f' | 'A'..='F' as ch2, .. rest] => {
        self.update_view(rest)
        let digit = match ch2 {
          '0'..='9' => ch2.to_int() - '0'
          'a'..='f' => ch2.to_int() - 'a' + 10
          'A'..='F' => ch2.to_int() - 'A' + 10
          _ => fail(self.error("Invalid hex digit: " + Char::to_string(ch2)))
        }
        result = result * 16L + digit.to_int64()
      }
      ['_', '_', ..] => fail(self.error("Invalid hex number, consecutive _"))
      ['_', ..] =>
        fail(self.error("Invalid hex number, no trailing digits after _"))
      _ => break
    }
  }
  // 0-width assertion
  match self.view() {
    [] => result
    [delimited, ..] =>
      if delimited is (' ' | '\t' | '\r' | '\n' | ',' | ']' | '}' | '#') {
        result
      } else {
        fail(
          self.error(
            "Invalid hex number, expected whitespace, comma, or end of input after 0x",
          ),
        )
      }
  }
}

///| Parse octal number
fn Lexer::read_octal_number(self : Lexer) -> Int64 raise {
  let mut result = match self.view() {
    ['0', 'o' | 'O', '0'..='7' as ch, .. rest] => {
      self.update_view(rest)
      let digit = ch.to_int() - '0'
      digit.to_int64()
    }
    _ => fail(self.error("Invalid octal number, expected 0..=7 after 0o"))
  }
  while true {
    match self.view() {
      ['0'..='7' as ch, .. rest] => {
        self.update_view(rest)
        let digit = ch.to_int() - '0'
        result = result * 8L + digit.to_int64()
      }
      ['_', '0'..='7' as ch2, .. rest] => {
        self.update_view(rest)
        let digit = ch2.to_int() - '0'
        result = result * 8L + digit.to_int64()
      }
      ['_', '_', ..] => fail(self.error("Invalid octal number, consecutive _"))
      ['_', ..] =>
        fail(self.error("Invalid octal number, no trailing digits after _"))
      _ => break
    }
  }
  // 0-width assertion
  match self.view() {
    [] => result
    [delimited, ..] =>
      if delimited is (' ' | '\t' | '\r' | '\n' | ',' | ']' | '}' | '#') {
        result
      } else {
        fail(
          self.error(
            "Invalid octal number, expected whitespace, comma, or end of input after 0o",
          ),
        )
      }
  }
}

///|
test {
  let lexer = @lexer.Lexer::new("0o755")
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///| Parse binary number
fn Lexer::read_binary_number(self : Lexer) -> Int64 raise {
  let mut result = match self.view() {
    ['0', 'b' | 'B', '0' | '1' as ch, .. rest] => {
      self.update_view(rest)
      let digit = ch.to_int() - '0'
      digit.to_int64()
    }
    _ => fail(self.error("Invalid binary number, expected 0 or 1 after 0b"))
  }
  while true {
    match self.view() {
      ['0' | '1' as ch, .. rest] => {
        self.update_view(rest)
        let digit = ch.to_int() - '0'.to_int()
        result = result * 2L + digit.to_int64()
      }
      ['_', '0' | '1' as ch2, .. rest] => {
        self.update_view(rest)
        let digit = ch2.to_int() - '0'
        result = result * 2L + digit.to_int64()
      }
      ['_', '_', ..] => fail(self.error("Invalid binary number, consecutive _"))
      ['_', ..] =>
        fail(self.error("Invalid binary number, no trailing digits after _"))
      _ => break
    }
  }
  // 0-width assertion
  match self.view() {
    [] => result
    [delimited, ..] =>
      if delimited is (' ' | '\t' | '\r' | '\n' | ',' | ']' | '}' | '#') {
        result
      } else {
        fail(
          self.error(
            "Invalid binary number, expected whitespace, comma, or end of input after 0b",
          ),
        )
      }
  }
}

///| Check if the current input matches a datetime pattern without consuming characters
fn Lexer::is_datetime_pattern(self : Lexer) -> Bool {
  // Use pattern matching on the view to look ahead

  // Check for LocalTime pattern: HH:MM:SS[.fff]
  match self.view() {
    [
      '0'..='9',
      '0'..='9',
      ':',
      '0'..='9',
      '0'..='9',
      ':',
      '0'..='9',
      '0'..='9',
      ..,
    ] =>
      // This looks like time, need to verify it's not part of something else
      match self.view() {
        [
          '0'..='9',
          '0'..='9',
          ':',
          '0'..='9',
          '0'..='9',
          ':',
          '0'..='9',
          '0'..='9',
          '.',
          '0'..='9',
          .. rest,
        ] =>
          // Time with fractional seconds - check what follows
          check_datetime_terminator(rest)
        [
          '0'..='9',
          '0'..='9',
          ':',
          '0'..='9',
          '0'..='9',
          ':',
          '0'..='9',
          '0'..='9',
          .. rest,
        ] =>
          // Time without fractional seconds - check what follows
          check_datetime_terminator(rest)
        _ => false
      }
    _ =>
      // Check for date patterns: YYYY-MM-DD[T...]
      match self.view() {
        [
          '0'..='9',
          '0'..='9',
          '0'..='9',
          '0'..='9',
          '-',
          '0'..='9',
          '0'..='9',
          '-',
          '0'..='9',
          '0'..='9',
          ..,
        ] =>
          // This is a date pattern
          true
        _ => false
      }
  }
}

///| Check if characters after a potential datetime are valid terminators
fn check_datetime_terminator(view : @string.View) -> Bool {
  match view {
    [] | [' ' | '\t' | '\n' | '\r' | '=' | ',' | ']' | '}', ..] => true
    _ => false
  }
}

///| Read a complete datetime token
fn Lexer::read_datetime(self : Lexer) -> Token {
  let sb = StringBuilder::new()

  // Check if this starts with time pattern (LocalTime)
  match self.view() {
    [
      '0'..='9',
      '0'..='9',
      ':',
      '0'..='9',
      '0'..='9',
      ':',
      '0'..='9',
      '0'..='9',
      ..,
    ] => {
      // Read time: HH:MM:SS
      for _i = 0; _i < 8; _i = _i + 1 {
        match self.view() {
          ['0'..='9' | ':' as ch, .. rest] => {
            self.update_view(rest)
            sb.write_char(ch)
          }
          _ => break
        }
      }

      // Check for fractional seconds
      match self.view() {
        ['.', .. rest] => {
          self.update_view(rest)
          sb.write_char('.')

          // Read fractional digits
          while true {
            match self.view() {
              ['0'..='9' as ch, .. rest] => {
                self.update_view(rest)
                sb.write_char(ch)
              }
              _ => break
            }
          }
        }
        _ => () // No fractional seconds
      }
      return DateTimeToken(LocalTime(sb.to_string()))
    }
    _ => () // Continue with date-based patterns
  }

  // Read date part: YYYY-MM-DD  
  for _i = 0; _i < 10; _i = _i + 1 {
    match self.view() {
      ['0'..='9' | '-' as ch, .. rest] => {
        self.update_view(rest)
        sb.write_char(ch)
      }
      _ => break
    }
  }

  // Check what comes after the date
  match self.view() {
    ['T', .. rest] => {
      // This is a datetime with time component
      self.update_view(rest)
      sb.write_char('T')

      // Read time part: HH:MM:SS
      for _i = 0; _i < 8; _i = _i + 1 {
        match self.view() {
          ['0'..='9' | ':' as ch, .. rest] => {
            self.update_view(rest)
            sb.write_char(ch)
          }
          _ => break
        }
      }

      // Check for fractional seconds
      match self.view() {
        ['.', .. rest] => {
          self.update_view(rest)
          sb.write_char('.')

          // Read fractional digits
          while true {
            match self.view() {
              ['0'..='9' as ch, .. rest] => {
                self.update_view(rest)
                sb.write_char(ch)
              }
              _ => break
            }
          }
        }
        _ => () // No fractional seconds
      }

      // Check for timezone
      match self.view() {
        ['Z', .. rest] => {
          self.update_view(rest)
          sb.write_char('Z')
          return DateTimeToken(OffsetDateTime(sb.to_string()))
        }
        ['+' | '-' as sign, .. rest] => {
          self.update_view(rest)
          sb.write_char(sign)

          // Read timezone offset: HH:MM
          for _i = 0; _i < 5; _i = _i + 1 {
            match self.view() {
              ['0'..='9' | ':' as ch, .. rest] => {
                self.update_view(rest)
                sb.write_char(ch)
              }
              _ => break
            }
          }
          return DateTimeToken(OffsetDateTime(sb.to_string()))
        }
        _ =>
          // No timezone, this is a LocalDateTime
          return DateTimeToken(LocalDateTime(sb.to_string()))
      }
    }
    _ =>
      // This is just a date (LocalDate)
      return DateTimeToken(LocalDate(sb.to_string()))
  }
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
      ['0', 'x' | 'X', ..] => {
        let value = self.read_hex_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      ['0', 'o' | 'O', ..] => {
        let value = self.read_octal_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      ['0', 'b' | 'B', ..] => {
        let value = self.read_binary_number()
        return IntegerToken(if is_negative { -value } else { value })
      }
      _ => () // continue with non binary mode
    }
  }
  // Read digits
  while true {
    match self.view() {
      ['0'..='9' | '_' as ch, .. rest] => {
        self.update_view(rest)
        if ch != '_' {
          sb.write_char(ch)
        }
      }
      _ => break
    }
  }

  // Check for decimal point
  match self.view() {
    ['.', .. rest] => {
      is_float = true
      self.update_view(rest)
      sb.write_char('.')
      while true {
        match self.view() {
          ['0'..='9' | '_' as ch, .. rest] => {
            self.update_view(rest)
            if ch != '_' {
              sb.write_char(ch)
            }
          }
          _ => break
        }
      }
    }
    _ => ()
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
  match self.view() {
    // End of input
    [] => EOF

    // Newline
    ['\n', .. rest] => {
      self.update_view(rest)
      self.new_line()
      Newline
    }

    // Single character tokens
    ['[', .. rest] => {
      self.update_view(rest)
      LeftBracket
    }
    [']', .. rest] => {
      self.update_view(rest)
      RightBracket
    }
    ['{', .. rest] => {
      self.update_view(rest)
      LeftBrace
    }
    ['}', .. rest] => {
      self.update_view(rest)
      RightBrace
    }
    ['=', .. rest] => {
      self.update_view(rest)
      Equals
    }
    [',', .. rest] => {
      self.update_view(rest)
      Comma
    }
    ['.', .. rest] => {
      self.update_view(rest)
      Dot
    }

    // String literals
    [.. "\"\"\"", .. rest] => {
      self.update_view(rest)
      StringToken(self.read_multiline_basic_string())
    }
    ['"', ..] => StringToken(self.read_basic_string())
    [.. "'''", .. rest] => {
      self.update_view(rest)
      StringToken(self.read_multiline_literal_string())
    }
    ['\'', ..] => StringToken(self.read_literal_string())

    // DateTime patterns (check before numbers)
    ['0'..='9', ..] =>
      if self.is_datetime_pattern() {
        self.read_datetime()
      } else {
        self.read_number(false)
      }

    // Negative numbers
    ['-', '0'..='9', ..] =>
      match self.view() {
        ['-', .. rest] => {
          self.update_view(rest)
          self.read_number(true)
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }

    // Handle negative special float values (-inf, -nan)
    ['-', 'i', 'n', 'f', ..] =>
      match self.view() {
        ['-', 'i', 'n', 'f', .. rest] => {
          self.update_view(rest)
          FloatToken(-1.0 / 0.0) // negative infinity
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }
    ['-', 'n', 'a', 'n', ..] =>
      match self.view() {
        ['-', 'n', 'a', 'n', .. rest] => {
          self.update_view(rest)
          FloatToken(0.0 / 0.0) // NaN
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }

    // Handle positive special float values (+inf, +nan) 
    ['+', 'i', 'n', 'f', ..] =>
      match self.view() {
        ['+', 'i', 'n', 'f', .. rest] => {
          self.update_view(rest)
          FloatToken(1.0 / 0.0) // positive infinity
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }
    ['+', 'n', 'a', 'n', ..] =>
      match self.view() {
        ['+', 'n', 'a', 'n', .. rest] => {
          self.update_view(rest)
          FloatToken(0.0 / 0.0) // NaN
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }

    // Identifiers and keywords
    ['a'..='z' | 'A'..='Z' | '_', ..] => {
      let identifier = self.read_identifier()
      match identifier {
        "true" => BooleanToken(true)
        "false" => BooleanToken(false)
        "inf" => FloatToken(1.0 / 0.0) // positive infinity
        "nan" => FloatToken(0.0 / 0.0) // NaN
        _ => Identifier(identifier)
      }
    }

    // Unexpected characters
    [ch, ..] => fail("Unexpected character: '\{ch}'")
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
  lexer.expect_string("\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1\nline2")
}

///| Test multiline literal string
test "multiline literal string" {
  let lexer = Lexer::new("'''line1\nline2'''")
  lexer.expect_string("'''")
  let result = lexer.read_multiline_literal_string()
  inspect(result, content="line1\nline2")
}

///| Test line ending backslash in multiline string
test "line ending backslash" {
  let lexer = Lexer::new("\"\"\"line1\\\n   line2\"\"\"")
  lexer.expect_string("\"\"\"")
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
  let result = lexer.read_hex_number()
  inspect(result, content="3735928559")
}

///| Test octal number parsing  
test "octal number parsing" {
  let lexer = Lexer::new("0o755")
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///| Test binary number parsing
test "binary number parsing" {
  let lexer = Lexer::new("0b1010")
  let result = lexer.read_binary_number()
  inspect(result, content="10")
}

///| Test datetime tokenization
test "datetime tokenization" {
  let tokens = tokenize("date = 1979-05-27T07:32:00Z")
  @json.inspect(tokens, content=[
    ["Identifier", "date"],
    "Equals",
    ["DateTimeToken", ["OffsetDateTime", "1979-05-27T07:32:00Z"]],
    "EOF",
  ])
}
