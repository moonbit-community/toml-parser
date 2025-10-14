///|
typealias @lexer.Lexer

///|
/// Default location for testing and compatibility
pub fn default_loc() -> Loc {
  let pos : @lexer.Position = { line: 1, column: 1 }
  { start: pos, end: pos }
}

///|
/// Create a location from lexer positions
fn make_loc(start_pos : @lexer.Position, end_pos : @lexer.Position) -> Loc {
  { start: start_pos, end: end_pos }
}

///|
/// Parse an identifier or keyword
fn Lexer::read_identifier(self : Lexer) -> String {

  // TODO(upstream): error message improved for `longest` with 
  // empty branches or single branch with _ => ... 
  lexmatch self.view() using longest {
    // TODO(upstream): allow `(` `)`
    (("[a-zA-Z]" "[a-zA-Z0-9_\-]*") as identifier, rest) => {
      self.update_view(rest)
      identifier.to_string()
    }
    _ => "" //  never going to happen
  }
}

///| Check if the next character is a valid token separator

///|
/// Valid separators are: whitespace, newline, EOF, or TOML punctuation
fn is_valid_separator(ch : Char) -> Bool {
  match ch {
    ' ' | '\t' | '\n' | '\r' => true // whitespace
    '=' | ',' | ']' | '}' | '#' => true // TOML punctuation
    _ => false
  }
}

///|
/// Validate that a special value token (inf, nan) is properly terminated
fn Lexer::validate_special_value_termination(self : Lexer) -> Unit raise {
  match self.view() {
    [] => () // EOF is valid
    [ch, ..] if is_valid_separator(ch) => () // Valid separator
    [ch, ..] =>
      fail(self.error("Invalid character '\{ch}' after special value"))
  }
}

///|
///  calculate the code point using a0, a1, a2, a3
fn Char::is_hex(ch : Char) -> Int? {
  match ch {
    '0'..='9' => Some(ch.to_int() - '0')
    'a'..='f' => Some(ch.to_int() - 'a' + 10)
    'A'..='F' => Some(ch.to_int() - 'A' + 10)
    _ => None
  }
}

///|
/// Parse Unicode escape sequence \uXXXX
fn Lexer::read_unicode_4_escape(self : Lexer) -> Char raise {
  let code = match self.view() {
    [
      // '\\',
      // 'u',
      a0,
      a1,
      a2,
      a3,
      .. rest,
    ] if a0.is_hex() is Some(a0) &&
      a1.is_hex() is Some(a1) &&
      a2.is_hex() is Some(a2) &&
      a3.is_hex() is Some(a3) => {
      self.update_view(rest)
      let code = a0 * 16 * 16 * 16 + a1 * 16 * 16 + a2 * 16 + a3
      code
    }
    _ =>
      fail(self.error("Invalid Unicode escape sequence: expected 4 hex digits"))
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: \{code}"))
  }
}

///|
/// Parse Unicode escape sequence \UXXXXXXXX
fn Lexer::read_unicode_8_escape(self : Lexer) -> Char raise {
  let code = match self.view() {
    [
      // '\\',
      // 'U',
      a0,
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      .. rest,
    ] if a0.is_hex() is Some(a0) &&
      a1.is_hex() is Some(a1) &&
      a2.is_hex() is Some(a2) &&
      a3.is_hex() is Some(a3) &&
      a4.is_hex() is Some(a4) &&
      a5.is_hex() is Some(a5) &&
      a6.is_hex() is Some(a6) &&
      a7.is_hex() is Some(a7) => {
      self.update_view(rest)
      let code = a0 * 16 * 16 * 16 * 16 * 16 * 16 * 16 +
        a1 * 16 * 16 * 16 * 16 * 16 * 16 +
        a2 * 16 * 16 * 16 * 16 * 16 +
        a3 * 16 * 16 * 16 * 16 +
        a4 * 16 * 16 * 16 +
        a5 * 16 * 16 +
        a6 * 16 +
        a7
      code
    }
    _ =>
      fail(self.error("Invalid Unicode escape sequence: expected 8 hex digits"))
  }
  if code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF) {
    fail(self.error("Invalid Unicode code point: \{code}"))
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid Unicode code point: \{code}"))
  }
}

///|
/// Parse a basic string (double quotes) with escape sequences
fn Lexer::read_basic_string(self : Lexer) -> String raise {
  self.advance() // consume opening quote
  let sb = StringBuilder::new()
  let next_view = loop self.view() {
    ['"', .. rest] => rest // exit
    ['\\', peeked, .. rest] as current =>
      match peeked {
        'n' => {
          sb.write_char('\n')
          continue rest
        }
        't' => {
          sb.write_char('\t')
          continue rest
        }
        'r' => {
          sb.write_char('\r')
          continue rest
        }
        '\\' => {
          sb.write_char('\\')
          continue rest
        }
        '"' => {
          sb.write_char('"')
          continue rest
        }
        '\'' => {
          sb.write_char('\'')
          continue rest
        }
        'b' => {
          sb.write_char('\u0008')
          continue rest
        }
        'f' => {
          sb.write_char('\u000C')
          continue rest
        }
        'u' => {
          self.update_view(rest)
          sb.write_char(self.read_unicode_4_escape())
          continue self.view()
        }
        'U' => {
          self.update_view(rest)
          // this may affect error message about location
          // we may fix this by storing the beginnning position 
          // of the string
          sb.write_char(self.read_unicode_8_escape())
          continue self.view()
        }
        _ => {
          // fix the error message location
          self.update_view(current)
          fail(self.error("Invalid escape sequence: \\\{peeked}"))
        }
      }
    [ch, .. rest] => {
      sb.write_char(ch)
      continue rest
    }
    [] => fail(self.error("Unterminated string"))
  }
  self.update_view(next_view)
  sb.to_string()
}

///|
/// Parse a literal string (single quotes) without escape sequences
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

///|
/// Parse a multi-line basic string (triple double quotes) with escape sequences
/// The openining triple quotes are already consumed by the caller
fn Lexer::read_multiline_basic_string(self : Lexer) -> String raise {
  self.skip_single_newline()
  let sb = StringBuilder::new()
  loop self.view() {
    [.. "\"\"\"", .. rest] => {
      // Check for closing triple quotes  
      self.update_view(rest)
      break sb.to_string()
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
          let next_view = loop self.view() {
            [' ' | '\t', .. rest] => continue rest
            rest => rest
          }
          self.update_view(next_view)
        }
        _ => fail(self.error("Invalid escape sequence: \\\{escaped}"))
      }
      continue self.view()
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
      continue self.view()
    }
    [] => fail(self.error("Unterminated multiline string"))
  }
}

///|
/// Parse a multi-line literal string (triple single quotes) without escape sequences
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
  loop self.view() {
    [.. "'''", .. rest] => {
      // finish reading the string
      self.update_view(rest)
      break sb.to_string()
    }
    [.. "\r\n", .. rest] => {
      sb.write_string("\r\n")
      self.update_view(rest)
      self.new_line()
      continue self.view()
    }
    // TODO: support .. ("\n"|"\r\n")
    // CR: zhangyu

    [ch, .. rest] => {
      if ch is '\n' {
        self.new_line()
      }
      self.update_view(rest)
      sb.write_char(ch)
      continue self.view()
    }
    [] => fail(self.error("Unterminated multiline literal string"))
  }
}

///|
/// Parse hexadecimal number
fn Lexer::read_hex_number(self : Lexer) -> Int64 raise {

  // (?:[0-9a-fA-F][0-9a-fA-F]*)(?:_[0-9a-fA-F][0-9a-fA-F]*)*
  // TODO(upstream): support non capturing group
  let mut result = 0L
  // 0xA__FF_12 is invalid according to spec
  lexmatch self.view() using longest {
    ("0[xX]" ("[0-9a-fA-F]+(_[0-9a-fA-F]+)*" as hex_digits), rest) => {
      for i = 0; i < hex_digits.length(); i = i + 1 {
        let ch = hex_digits[i]
        if ch is '_' {
          continue
        }
        let digit_value = match ch {
          '0'..='9' => (ch - '0').to_int64()
          'a'..='f' => (ch - 'a').to_int64() + 10L
          'A'..='F' => (ch - 'A').to_int64() + 10L
          _ => fail(self.error("Invalid hex digit"))
        }
        result = result * 16L + digit_value
      }
      self.update_view(rest)
    }
    _ => fail(self.error("Invalid hex number format"))
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
            "Invalid char '\{delimited}', expected whitespace, comma, or end of input after 0x...",
          ),
        )
      }
  }
}

///|
/// Parse octal number
fn Lexer::read_octal_number(self : Lexer) -> Int64 raise {

  // (?:[0-7][0-7]*)(?:_[0-7][0-7]*)*
  // TODO(upstream): support non capturing group
  let mut result = 0L
  // 0o7__55_44 is invalid according to spec
  lexmatch self.view() using longest {
    ("0[oO]" ("[0-7]+(_[0-7]+)*" as octal_digits), rest) => {
      for i = 0; i < octal_digits.length(); i = i + 1 {
        let ch = octal_digits[i]
        if ch is '_' {
          continue
        }
        result = result * 8L + (ch - '0').to_int64()
      }
      self.update_view(rest)
    }
    _ => fail(self.error("Invalid octal number format"))
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
            "Invalid char '\{delimited}', expected whitespace, comma, or end of input after 0o...",
          ),
        )
      }
  }
}

///|
test {
  let lexer = @lexer.Lexer::new(
    (
      #|0o755
    ),
  )
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///|
/// Parse binary number
fn Lexer::read_binary_number(self : Lexer) -> Int64 raise {

  // (?:[01][01]*)(?:_[01][01]*)*
  // TODO(upstream): support non capturing group
  // TODO(upstream): `self.view()` is not needed
  // `match self` directly
  let mut result = 0L
  // 0b1__00_11 is invalid according to spec
  lexmatch self.view() using longest {
    ("0[bB]" ("[01]+(_[01]+)*" as binary_digits), rest) => {
      for i = 0; i < binary_digits.length(); i = i + 1 {
        let ch = binary_digits[i]
        if ch is '_' {
          continue
        }
        result = result * 2L + (ch - '0').to_int64()
      }
      self.update_view(rest)
    }
    _ => fail(self.error("Invalid binary number format"))
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
            "Invalid char '\{delimited}', expected whitespace, comma, or end of input after 0b...",
          ),
        )
      }
  }
}

///|
/// Check if the current input matches a datetime pattern without consuming characters
fn Lexer::is_datetime_pattern(self : Lexer) -> Bool {
  // Check for datetime patterns using regex
  lexmatch self.view() using longest {
    // LocalTime pattern: HH:MM:SS[.fff] followed by valid terminator
    ("[0-9]{2}:[0-9]{2}:[0-9]{2}" "(\.[0-9]+)?", rest) =>
      check_datetime_terminator_string(rest)
    // LocalDate pattern: YYYY-MM-DD (always valid, may continue with T for datetime)
    ("[0-9]{4}-[0-9]{2}-[0-9]{2}", _) => true
    _ => false
  }
}

///|
/// Check if characters after a potential datetime are valid terminators
fn check_datetime_terminator_string(view : StringView) -> Bool {
  match view {
    [] | [' ' | '\t' | '\n' | '\r' | '=' | ',' | ']' | '}', ..] => true
    _ => false
  }
}

///|
/// Read a complete datetime token
fn Lexer::read_datetime_with_loc(
  self : Lexer,
  start_pos : @lexer.Position,
) -> Token {

  // Use regex to match and capture different datetime patterns
  lexmatch self.view() with longest {
    // LocalTime: HH:MM:SS[.fff]
    (("[0-9]{2}:[0-9]{2}:[0-9]{2}" "(\.[0-9]+)?") as time, rest) => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      return DateTimeToken(
        LocalTime(time.to_string()),
        loc=make_loc(start_pos, end_pos),
      )
    }
    // OffsetDateTime with Z: YYYY-MM-DDTHH:MM:SS[.fff]Z
    (("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}" "(\.[0-9]+)?Z") as datetime, rest) => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      return DateTimeToken(
        OffsetDateTime(datetime.to_string()),
        loc=make_loc(start_pos, end_pos),
      )
    }
    // OffsetDateTime with offset: YYYY-MM-DDTHH:MM:SS[.fff]±HH:MM
    ((
      "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"
      "(\.[0-9]+)?[+\-][0-9]{2}:[0-9]{2}"
    ) as datetime, rest) => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      return DateTimeToken(
        OffsetDateTime(datetime.to_string()),
        loc=make_loc(start_pos, end_pos),
      )
    }
    // LocalDateTime: YYYY-MM-DDTHH:MM:SS[.fff]
    (("[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}" "(\.[0-9]+)?") as datetime, rest) => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      return DateTimeToken(
        LocalDateTime(datetime.to_string()),
        loc=make_loc(start_pos, end_pos),
      )
    }
    // LocalDate: YYYY-MM-DD
    ("[0-9]{4}-[0-9]{2}-[0-9]{2}" as date, rest) => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      return DateTimeToken(
        LocalDate(date.to_string()),
        loc=make_loc(start_pos, end_pos),
      )
    }
    _ => {
      // This shouldn't happen if is_datetime_pattern was called first
      let end_pos = self.get_loc()
      return DateTimeToken(LocalDate(""), loc=make_loc(start_pos, end_pos))
    }
  }
}

///|
/// Parse a number (integer or float), with optional negative sign
fn Lexer::read_number_with_loc(
  self : Lexer,
  is_negative : Bool,
  start_pos : @lexer.Position,
) -> Token raise {
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
        let end_pos = self.get_loc()
        return IntegerToken(
          if is_negative {
            -value
          } else {
            value
          },
          loc=make_loc(start_pos, end_pos),
        )
      }
      ['0', 'o' | 'O', ..] => {
        let value = self.read_octal_number()
        let end_pos = self.get_loc()
        return IntegerToken(
          if is_negative {
            -value
          } else {
            value
          },
          loc=make_loc(start_pos, end_pos),
        )
      }
      ['0', 'b' | 'B', ..] => {
        let value = self.read_binary_number()
        let end_pos = self.get_loc()
        return IntegerToken(
          if is_negative {
            -value
          } else {
            value
          },
          loc=make_loc(start_pos, end_pos),
        )
      }
      _ => () // continue with non binary mode
    }
  }
  // Read digits
  let next_view = loop self.view() {
    ['0'..='9' | '_' as ch, .. rest] => {
      if ch != '_' {
        sb.write_char(ch)
      }
      continue rest
    }
    rest => rest
  }
  self.update_view(next_view)

  // Check for decimal point
  match self.view() {
    ['.', .. rest] => {
      is_float = true
      self.update_view(rest)
      sb.write_char('.')
      let next_view = loop self.view() {
        ['0'..='9' | '_' as ch, .. rest] => {
          if ch != '_' {
            sb.write_char(ch)
          }
          continue rest
        }
        rest => rest
      }
      self.update_view(next_view)
    }
    _ => ()
  }
  let s = sb.to_string()
  let end_pos = self.get_loc()
  let loc = make_loc(start_pos, end_pos)
  if is_float {
    FloatToken(@strconv.parse_double(s), loc~) catch {
      _ => fail("Invalid float: \{s}")
    }
  } else {
    IntegerToken(@strconv.parse_int64(s), loc~) catch {
      _ => fail("Invalid integer: \{s}")
    }
  }
}

///|
/// Backward compatibility wrapper for read_number
fn Lexer::read_number(self : Lexer, is_negative : Bool) -> Token raise {
  let start_pos = self.get_loc()
  self.read_number_with_loc(is_negative, start_pos)
}

///|
test "read_number" {
  let lexer = Lexer::new("123")
  inspect(
    lexer.read_number(false),
    content="IntegerToken(123, loc={start: {line: 1, column: 1}, end: {line: 1, column: 4}})",
  )
}

///|
/// Skip comments and whitespace but not newline characters
fn Lexer::skip_comments_or_whitespace(self : Lexer) -> Unit {
  let next = loop self.view() {
    ['\r', '\n', ..] | ['\n', ..] | [] as rest => rest
    [' ' | '\t' | '\r', .. rest] => continue rest
    ['#', .. next] =>
      loop next {
        ['\r', '\n', ..] | ['\n', ..] | [] as rest => rest
        [_, .. rest] => continue rest
      }
    rest => rest
  }
  self.update_view(next)
}

///|
/// Get the next token
fn Lexer::next_token(self : Lexer) -> Token raise {
  self.skip_comments_or_whitespace()
  let start_pos = self.get_loc()
  match self.view() {
    // End of input
    [] => {
      let end_pos = self.get_loc()
      EOF(loc=make_loc(start_pos, end_pos))
    }

    // Newline
    ['\n', .. rest] => {
      self.update_view(rest)
      self.new_line()
      let end_pos = self.get_loc()
      Newline(loc=make_loc(start_pos, end_pos))
    }

    // Single character tokens
    ['[', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      LeftBracket(loc=make_loc(start_pos, end_pos))
    }
    [']', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      RightBracket(loc=make_loc(start_pos, end_pos))
    }
    ['{', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      LeftBrace(loc=make_loc(start_pos, end_pos))
    }
    ['}', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      RightBrace(loc=make_loc(start_pos, end_pos))
    }
    ['=', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      Equals(loc=make_loc(start_pos, end_pos))
    }
    [',', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      Comma(loc=make_loc(start_pos, end_pos))
    }
    ['.', .. rest] => {
      self.update_view(rest)
      let end_pos = self.get_loc()
      Dot(loc=make_loc(start_pos, end_pos))
    }

    // String literals
    [.. "\"\"\"", .. rest] => {
      self.update_view(rest)
      let value = self.read_multiline_basic_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos))
    }
    ['"', ..] => {
      let value = self.read_basic_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos))
    }
    [.. "'''", .. rest] => {
      self.update_view(rest)
      let value = self.read_multiline_literal_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos))
    }
    ['\'', ..] => {
      let value = self.read_literal_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos))
    }

    // DateTime patterns (check before numbers)
    ['0'..='9', ..] =>
      if self.is_datetime_pattern() {
        self.read_datetime_with_loc(start_pos)
      } else {
        self.read_number_with_loc(false, start_pos)
      }

    // Negative numbers
    ['-', '0'..='9', ..] =>
      match self.view() {
        ['-', .. rest] => {
          self.update_view(rest)
          self.read_number_with_loc(true, start_pos)
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }

    // Handle negative special float values (-inf, -nan)
    ['-', 'i', 'n', 'f', .. rest] => {
      self.update_view(rest)
      self.validate_special_value_termination()
      let end_pos = self.get_loc()
      FloatToken(-1.0 / 0.0, loc=make_loc(start_pos, end_pos)) // negative infinity
    }
    ['-', 'n', 'a', 'n', .. rest] => {
      self.update_view(rest)
      self.validate_special_value_termination()
      let end_pos = self.get_loc()
      FloatToken(0.0 / 0.0, loc=make_loc(start_pos, end_pos)) // NaN
    }

    // Handle positive special float values (+inf, +nan) 
    ['+', 'i', 'n', 'f', .. rest] => {
      self.update_view(rest)
      self.validate_special_value_termination()
      let end_pos = self.get_loc()
      FloatToken(1.0 / 0.0, loc=make_loc(start_pos, end_pos)) // positive infinity
    }
    ['+', 'n', 'a', 'n', .. rest] => {
      self.update_view(rest)
      self.validate_special_value_termination()
      let end_pos = self.get_loc()
      FloatToken(0.0 / 0.0, loc=make_loc(start_pos, end_pos)) // NaN
    }

    // Identifiers and keywords
    ['a'..='z' | 'A'..='Z' | '_', ..] => {
      let identifier = self.read_identifier()
      let end_pos = self.get_loc()
      let loc = make_loc(start_pos, end_pos)
      match identifier {
        "true" => BooleanToken(true, loc~)
        "false" => BooleanToken(false, loc~)
        _ => Identifier(identifier, loc~)
      }
    }

    // Unexpected characters
    [ch, ..] => fail("Unexpected character: '\{ch}'")
  }
}

///|
/// Tokenize entire input
pub fn tokenize(input : String) -> Array[Token] raise {
  let lexer = Lexer::new(input)
  let tokens = Array::new()
  let mut current_token = lexer.next_token()
  loop current_token {
    EOF(_) as t => {
      tokens.push(t)
      break tokens
    }
    _ as t => {
      tokens.push(t)
      let next_token = lexer.next_token()
      current_token = next_token
      continue next_token
    }
  }
}

///|
/// Test read_number
test "read_number" {
  let lexer = Lexer::new("123")
  inspect(
    lexer.read_number(false),
    content="IntegerToken(123, loc={start: {line: 1, column: 1}, end: {line: 1, column: 4}})",
  )
}

///|
/// Test Unicode escape sequences
test "unicode escape sequences" {
  let lexer1 = Lexer::new("\"\\u0041\"") // 'A'
  let result1 = lexer1.read_basic_string()
  inspect(result1, content="A")
  let lexer2 = Lexer::new("\"\\U00000041\"") // 'A'
  let result2 = lexer2.read_basic_string()
  inspect(result2, content="A")
}

///|
/// Test multiline basic string
test "multiline basic string" {
  let lexer = Lexer::new("\"\"\"line1\nline2\"\"\"")
  lexer.expect_string("\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1\nline2")
}

///|
/// Test multiline literal string
test "multiline literal string" {
  let lexer = Lexer::new("'''line1\nline2'''")
  lexer.expect_string("'''")
  let result = lexer.read_multiline_literal_string()
  inspect(result, content="line1\nline2")
}

///|
/// Test line ending backslash in multiline string
test "line ending backslash" {
  let lexer = Lexer::new("\"\"\"line1\\\n   line2\"\"\"")
  lexer.expect_string("\"\"\"")
  let result = lexer.read_multiline_basic_string()
  inspect(result, content="line1line2") // whitespace should be trimmed
}

///|
/// Test basic string parsing
test "basic string parsing" {
  let lexer = Lexer::new("\"Hello, \\\"world\\\"!\"")
  let result = lexer.read_basic_string()
  inspect(result, content="Hello, \"world\"!")
}

///|
/// Test literal string parsing  
test "literal string parsing" {
  let lexer = Lexer::new("'Hello, world!'")
  let result = lexer.read_literal_string()
  inspect(result, content="Hello, world!")
}

///|
/// Test identifier parsing
test "identifier parsing" {
  let lexer = Lexer::new("hello-world_123")
  let result = lexer.read_identifier()
  inspect(result, content="hello-world_123")
}

///|
/// Test hex number parsing
test "hex number parsing" {
  let lexer = Lexer::new("0xDEADBEEF")
  let result = lexer.read_hex_number()
  inspect(result, content="3735928559")
}

///|
/// Test octal number parsing  
test "octal number parsing" {
  let lexer = Lexer::new("0o755")
  let result = lexer.read_octal_number()
  inspect(result, content="493")
}

///|
/// Test binary number parsing
test "binary number parsing" {
  let lexer = Lexer::new("0b1010")
  let result = lexer.read_binary_number()
  inspect(result, content="10")
}

///|
/// Test datetime tokenization
test "datetime tokenization" {
  let tokens = tokenize("date = 1979-05-27T07:32:00Z")
  @json.inspect(tokens, content=[
    ["Identifier", "date", { "loc": "1:1-1:5" }],
    ["Equals", { "loc": "1:6-1:7" }],
    [
      "DateTimeToken",
      ["OffsetDateTime", "1979-05-27T07:32:00Z"],
      { "loc": "1:8-1:28" },
    ],
    ["EOF", { "loc": "1:28-1:28" }],
  ])
}
