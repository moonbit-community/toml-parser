///|
using @lexer {type Lexer}

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
  if self.view()
    // TODO(upstream): allow `(` `)`
    lexmatch? (("[a-zA-Z_\-]" "[a-zA-Z0-9_\-]*") as identifier, rest) {
    self.update_view(rest)
    identifier.to_string()
  } else {
    ""
  } //  never going to happen
}

///|
/// Check if a character is a disallowed control character in TOML strings.
/// Control chars U+0000-U+001F (except \t = U+0009) and U+007F (DEL) are banned.
fn is_control_char(ch : Char) -> Bool {
  let code : Int = ch.to_int()
  (code >= 0 && code <= 0x1F && code != 0x09) || code == 0x7F
}

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
/// Parse hex escape sequence \xHH (TOML 1.1)
fn Lexer::read_hex_2_escape(self : Lexer) -> Char raise {
  let code = match self.view() {
    [a0, a1, .. rest] if a0.is_hex() is Some(a0) && a1.is_hex() is Some(a1) => {
      self.update_view(rest)
      a0 * 16 + a1
    }
    _ => fail(self.error("Invalid hex escape sequence: expected 2 hex digits"))
  }
  match code.to_char() {
    Some(ch) => ch
    None => fail(self.error("Invalid hex code point: \{code}"))
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
        'e' => {
          sb.write_char('\u001B') // ESC
          continue rest
        }
        'x' => {
          self.update_view(rest)
          sb.write_char(self.read_hex_2_escape())
          continue self.view()
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
      if is_control_char(ch) {
        self.update_view(rest)
        fail(
          self.error(
            "Invalid control character in basic string: U+\{ch.to_int().to_string().pad_start(4, '0')}",
          ),
        )
      }
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
      if is_control_char(ch) {
        self.update_view(rest)
        fail(
          self.error(
            "Invalid control character in literal string: U+\{ch.to_int().to_string().pad_start(4, '0')}",
          ),
        )
      }
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
    [.. "\"\"\"\"\"", .. rest] => {
      // 5 quotes: 2 content quotes + closing triple quotes
      sb.write_string("\"\"")
      self.update_view(rest)
      break sb.to_string()
    }
    [.. "\"\"\"\"", .. rest] => {
      // 4 quotes: 1 content quote + closing triple quotes
      sb.write_char('"')
      self.update_view(rest)
      break sb.to_string()
    }
    [.. "\"\"\"", .. rest] => {
      // Closing triple quotes
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
        'e' => sb.write_char('\u001B') // ESC
        'x' => sb.write_char(self.read_hex_2_escape())
        'u' => sb.write_char(self.read_unicode_4_escape())
        'U' => sb.write_char(self.read_unicode_8_escape())
        // Line ending backslash: \ at end of line trims newline + whitespace
        '\n' => {
          self.new_line()
          // Skip all whitespace and newlines until non-whitespace content
          let next_view = loop self.view() {
            ['\n', .. rest] => {
              self.new_line()
              continue rest
            }
            ['\r', '\n', .. rest] => {
              self.new_line()
              continue rest
            }
            [' ' | '\t' | '\r', .. rest] => continue rest
            rest => rest
          }
          self.update_view(next_view)
        }
        '\r' => {
          self.new_line()
          match self.view() {
            ['\n', .. rest] => self.update_view(rest)
            _ => ()
          }
          let next_view = loop self.view() {
            ['\n', .. rest] => {
              self.new_line()
              continue rest
            }
            ['\r', '\n', .. rest] => {
              self.new_line()
              continue rest
            }
            [' ' | '\t' | '\r', .. rest] => continue rest
            rest => rest
          }
          self.update_view(next_view)
        }
        ' ' | '\t' => {
          // \ followed by space/tab: must be followed by only whitespace then newline
          let found_newline = loop self.view() {
            [' ' | '\t', .. rest] => continue rest
            ['\n', ..] | ['\r', ..] => true
            _ => false
          }
          if !found_newline {
            fail(
              self.error(
                "Invalid escape: backslash followed by whitespace but no newline",
              ),
            )
          }
          // Now consume the newline and following whitespace
          let next_view = loop self.view() {
            ['\n', .. rest] => {
              self.new_line()
              continue rest
            }
            ['\r', '\n', .. rest] => {
              self.new_line()
              continue rest
            }
            [' ' | '\t' | '\r', .. rest] => continue rest
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
    ['\r', '\n', .. rest] => {
      // CRLF in multiline string
      self.update_view(rest)
      sb.write_char('\n')
      self.new_line()
      continue self.view()
    }
    [ch, .. rest] => {
      // Allow \n in multiline strings, reject bare \r and other control chars
      if ch != '\n' && is_control_char(ch) {
        self.update_view(rest)
        fail(
          self.error(
            "Invalid control character in multiline string: U+\{ch.to_int().to_string().pad_start(4, '0')}",
          ),
        )
      }
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
    [.. "'''''", .. rest] => {
      // 5 quotes: 2 content quotes + closing triple quotes
      sb.write_string("''")
      self.update_view(rest)
      break sb.to_string()
    }
    [.. "''''", .. rest] => {
      // 4 quotes: 1 content quote + closing triple quotes
      sb.write_char('\'')
      self.update_view(rest)
      break sb.to_string()
    }
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
      // Allow \n in multiline literal strings, reject bare \r and other control chars
      if ch != '\n' && is_control_char(ch) {
        self.update_view(rest)
        fail(
          self.error(
            "Invalid control character in multiline literal string: U+\{ch.to_int().to_string().pad_start(4, '0')}",
          ),
        )
      }
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
  guard self.view()
    lexmatch? ("0[xX]" ("[0-9a-fA-F]+(_[0-9a-fA-F]+)*" as hex_digits), rest) else {
    fail(self.error("Invalid hex number format"))
  }
  for ch in hex_digits {
    if ch is '_' {
      continue
    }
    let digit_value = match ch {
      '0'..='9' => (ch.to_int() - '0'.to_int()).to_int64()
      'a'..='f' => (ch.to_int() - 'a'.to_int()).to_int64() + 10L
      'A'..='F' => (ch.to_int() - 'A'.to_int()).to_int64() + 10L
      _ => fail(self.error("Invalid hex digit"))
    }
    result = result * 16L + digit_value
  }
  self.update_view(rest)

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
  guard self.view()
    lexmatch? ("0[oO]" ("[0-7]+(_[0-7]+)*" as octal_digits), rest) else {
    fail(self.error("Invalid octal number format"))
  }
  for ch in octal_digits {
    if ch is '_' {
      continue
    }
    result = result * 8L + (ch.to_int() - '0').to_int64()
  }
  self.update_view(rest)

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
  debug_inspect(result, content="493")
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
  guard self.view()
    lexmatch? ("0[bB]" ("[01]+(_[01]+)*" as binary_digits), rest) else {
    fail(self.error("Invalid binary number format"))
  }
  for ch in binary_digits {
    if ch is '_' {
      continue
    }
    result = result * 2L + (ch.to_int() - '0').to_int64()
  }
  self.update_view(rest)

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
  lexmatch self.view() {
    (
      "[0-9]{2}:[0-9]{2}"
      "(:[0-9]{2})?(\.[0-9]+)?",
      // LocalTime pattern: HH:MM[:SS[.fff]] followed by valid terminator
      rest
    ) => check_datetime_terminator_string(rest)
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
) -> Token raise {
  // Try patterns in order - no need for `with longest` since patterns are
  // naturally disambiguated by structure:
  // - LocalTime: HH:MM:SS (starts with 2 digits, has colons)
  // - Date-based: YYYY-MM-DD (starts with 4 digits)
  //   - Check what follows T to determine: LocalDate, LocalDateTime, or OffsetDateTime
  lexmatch self.view() {
    // LocalTime: HH:MM[:SS[.fff]] - must check first (2-digit start vs 4-digit)
    (("[0-9]{2}:[0-9]{2}" "(:[0-9]{2})?(\.[0-9]+)?") as time, rest) => {
      self.update_view(rest)
      let time_str = time.to_string()
      validate_time(time_str)
      let end_pos = self.get_loc()
      DateTimeToken(LocalTime(time_str), loc=make_loc(start_pos, end_pos))
    }
    // Date-based patterns: lex YYYY-MM-DD first, then check continuation
    ("[0-9]{4}-[0-9]{2}-[0-9]{2}" as date, rest) => {
      self.update_view(rest)
      let date_str = date.to_string()
      validate_date(date_str)
      // Check for time component: T/t/space followed by HH:MM[:SS[.fff]]
      if self.view()
        lexmatch? (
          ("[Tt ][0-9]{2}:[0-9]{2}" "(:[0-9]{2})?(\.[0-9]+)?") as time_with_t,
          rest2
        ) {
        self.update_view(rest2)
        let time_part = time_with_t.to_string()
        // Validate time portion (skip the T/t/space separator)
        validate_time(time_part[1:].to_string())
        let datetime_str = "\{date_str}\{time_part}"
        // Check for timezone: Z or ±HH:MM
        if self.view() lexmatch? ("[Zz]", rest3) {
          self.update_view(rest3)
          let end_pos = self.get_loc()
          DateTimeToken(
            OffsetDateTime("\{datetime_str}Z"),
            loc=make_loc(start_pos, end_pos),
          )
        } else if self.view()
          lexmatch? ("[+\-][0-9]{2}:[0-9]{2}" as offset, rest3) {
          self.update_view(rest3)
          let offset_str = offset.to_string()
          validate_timezone_offset(offset_str)
          let end_pos = self.get_loc()
          DateTimeToken(
            OffsetDateTime("\{datetime_str}\{offset_str}"),
            loc=make_loc(start_pos, end_pos),
          )
        } else {
          // No timezone - LocalDateTime
          let end_pos = self.get_loc()
          DateTimeToken(
            LocalDateTime(datetime_str),
            loc=make_loc(start_pos, end_pos),
          )
        }
      } else {
        // Just date, no time component - LocalDate
        let end_pos = self.get_loc()
        DateTimeToken(LocalDate(date_str), loc=make_loc(start_pos, end_pos))
      }
    }
    _ => {
      // This shouldn't happen if is_datetime_pattern was called first
      let end_pos = self.get_loc()
      DateTimeToken(LocalDate(""), loc=make_loc(start_pos, end_pos))
    }
  }
}

///|
/// Parse a number (integer or float), with optional negative sign
fn Lexer::read_number_with_loc(
  self : Lexer,
  is_negative : Bool,
  start_pos : @lexer.Position,
  has_sign? : Bool = false,
) -> Token raise {
  let sb = StringBuilder::new()
  if is_negative {
    sb.write_char('-')
  }
  let mut is_float = false

  // Check if this might be a special format number (0x, 0o, 0b)
  if !is_negative {
    match self.view() {
      ['0', 'x', ..] => {
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
      ['0', 'o', ..] => {
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
      ['0', 'b', ..] => {
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
  let raw = StringBuilder::new()
  if is_negative {
    raw.write_char('-')
  }
  let next_view = loop self.view() {
    ['0'..='9' | '_' as ch, .. rest] => {
      raw.write_char(ch)
      if ch != '_' {
        sb.write_char(ch)
      }
      continue rest
    }
    rest => rest
  }
  self.update_view(next_view)

  // Leading-zero numbers (e.g. 0123, -01, 01.23) are not valid TOML values,
  // but they are valid bare keys. Produce Identifier to preserve the text.
  // Check this BEFORE trying to read decimal point so "01.23" doesn't
  // become a float.
  let digits_so_far = sb.to_string()
  let digit_start = if is_negative { 1 } else { 0 }
  if digits_so_far.length() - digit_start > 1 &&
    digits_so_far[digit_start] == '0' {
    let end_pos = self.get_loc()
    let loc = make_loc(start_pos, end_pos)
    return Identifier(digits_so_far, loc~)
  }

  // Check for decimal point
  match self.view() {
    ['.', .. rest] => {
      is_float = true
      self.update_view(rest)
      sb.write_char('.')
      raw.write_char('.')
      let next_view = loop self.view() {
        ['0'..='9' | '_' as ch, .. rest] => {
          raw.write_char(ch)
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
  // Check for exponent notation (e/E followed by optional +/- and digits)
  match self.view() {
    ['e' | 'E', '+' | '-', '0'..='9', ..] | ['e' | 'E', '0'..='9', ..] => {
      is_float = true
      // Consume e/E
      match self.view() {
        ['e' | 'E' as ch, .. rest] => {
          sb.write_char(ch)
          raw.write_char(ch)
          self.update_view(rest)
        }
        _ => ()
      }
      // Consume optional sign
      match self.view() {
        ['+' | '-' as ch, .. rest] => {
          sb.write_char(ch)
          raw.write_char(ch)
          self.update_view(rest)
        }
        _ => ()
      }
      // Consume exponent digits
      let next_view = loop self.view() {
        ['0'..='9' | '_' as ch, .. rest] => {
          raw.write_char(ch)
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
  // If followed by identifier chars (a-z, A-Z, _, -), this is a bare key
  // like "1key" or "2000-datetime", not a number value.
  // Use raw string (preserves underscores) for the identifier.
  match self.view() {
    ['a'..='z' | 'A'..='Z' | '_' | '-', ..] if !is_negative => {
      let next_view = loop self.view() {
        ['a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-' as ch, .. rest] => {
          raw.write_char(ch)
          continue rest
        }
        rest => rest
      }
      self.update_view(next_view)
      let end_pos = self.get_loc()
      let loc = make_loc(start_pos, end_pos)
      return Identifier(raw.to_string(), loc~)
    }
    _ => ()
  }
  let s = sb.to_string()
  let raw_s = raw.to_string()
  // If the number is in key position (followed by = after whitespace),
  // and the raw string contains characters that would be lost in numeric conversion
  // (underscores, exponent notation), produce an Identifier to preserve the text.
  let has_lossy_chars = raw_s != s || (is_float && !raw_s.contains("."))
  if !is_negative && !has_sign && has_lossy_chars {
    let is_key = loop self.view() {
      [' ' | '\t', .. rest] => continue rest
      ['=' | '.', ..] => true // key = value or dotted.key
      // ] followed by newline/EOF indicates table header [key], not array
      [']', '\n' | '\r', ..] | [']'] => true
      _ => false
    }
    if is_key {
      let end_pos = self.get_loc()
      let loc = make_loc(start_pos, end_pos)
      return Identifier(raw_s, loc~)
    }
  }
  if is_float {
    validate_float_string(s, raw_s) catch {
      e => fail(self.error(e.to_string()))
    }
  } else {
    validate_integer_string(raw_s) catch {
      e => fail(self.error(e.to_string()))
    }
  }
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
/// Validate a float string for TOML spec compliance.
/// `s` is the stripped string (no underscores), `raw` has underscores preserved.
fn validate_float_string(s : String, raw : String) -> Unit raise {
  // Check for trailing dot (e.g. "1.")
  if s.has_suffix(".") {
    raise Failure::Failure("Invalid float: trailing dot")
  }
  // Check for dot followed immediately by 'e' (e.g. "1.e2")
  for i = 0; i < s.length() - 1; i = i + 1 {
    if s[i] == '.' && (s[i + 1] == 'e' || s[i + 1] == 'E') {
      raise Failure::Failure("Invalid float: no digits after decimal point")
    }
  }
  // Validate underscore placement in raw string
  validate_underscores(raw)
}

///|
/// Validate a decimal integer string for underscore placement.
fn validate_integer_string(raw : String) -> Unit raise {
  validate_underscores(raw)
}

///|
/// Validate a date string YYYY-MM-DD.
fn validate_date(s : String) -> Unit raise {
  // s is "YYYY-MM-DD" (10 chars)
  if s.length() < 10 {
    raise Failure::Failure("Invalid date: '\{s}'")
  }
  let year = parse_int_substr(s, 0, 4)
  let month = parse_int_substr(s, 5, 7)
  let day = parse_int_substr(s, 8, 10)
  if month < 1 || month > 12 {
    raise Failure::Failure("Invalid date: month \{month} out of range")
  }
  if day < 1 {
    raise Failure::Failure("Invalid date: day must be >= 1")
  }
  let max_day = days_in_month(year, month)
  if day > max_day {
    raise Failure::Failure(
      "Invalid date: day \{day} exceeds max \{max_day} for month \{month}",
    )
  }
}

///|
/// Validate a time string HH:MM or HH:MM:SS[.fff].
fn validate_time(s : String) -> Unit raise {
  if s.length() < 5 {
    raise Failure::Failure("Invalid time: '\{s}'")
  }
  let hour = parse_int_substr(s, 0, 2)
  let minute = parse_int_substr(s, 3, 5)
  if hour > 23 {
    raise Failure::Failure("Invalid time: hour \{hour} out of range")
  }
  if minute > 59 {
    raise Failure::Failure("Invalid time: minute \{minute} out of range")
  }
  if s.length() >= 8 {
    let second = parse_int_substr(s, 6, 8)
    if second > 60 {
      // 60 is allowed for leap seconds
      raise Failure::Failure("Invalid time: second \{second} out of range")
    }
  }
}

///|
/// Parse an integer from a substring.
fn parse_int_substr(s : String, start : Int, end : Int) -> Int {
  let mut result = 0
  for i = start; i < end && i < s.length(); i = i + 1 {
    let c = s[i]
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - 48)
    }
  }
  result
}

///|
/// Return max days in a given month, accounting for leap years.
fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 31
  }
}

///|
/// Validate timezone offset ±HH:MM (hour 0-23, minute 0-59).
fn validate_timezone_offset(s : String) -> Unit raise {
  // s is like "+25:00" or "-12:60" (6 chars)
  let hour = parse_int_substr(s, 1, 3)
  let minute = parse_int_substr(s, 4, 6)
  if hour > 23 {
    raise Failure::Failure("Invalid timezone offset: hour \{hour} out of range")
  }
  if minute > 59 {
    raise Failure::Failure(
      "Invalid timezone offset: minute \{minute} out of range",
    )
  }
}

///|
fn is_leap_year(year : Int) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
/// Validate underscore placement: no leading, trailing, or adjacent underscores,
/// no underscore next to dot or e/E or sign.
fn validate_underscores(raw : String) -> Unit raise {
  let len = raw.length()
  for i = 0; i < len; i = i + 1 {
    if raw[i] == '_' {
      // Trailing underscore
      if i == len - 1 {
        raise Failure::Failure("Invalid number: trailing underscore")
      }
      // Leading underscore (after optional sign)
      if i == 0 || (i == 1 && raw[0] == '-') {
        raise Failure::Failure("Invalid number: leading underscore")
      }
      // Underscore adjacent to non-digit
      let prev = raw[i - 1]
      let next = raw[i + 1]
      if !(prev >= '0' && prev <= '9') {
        raise Failure::Failure("Invalid number: underscore not between digits")
      }
      if !(next >= '0' && next <= '9') {
        raise Failure::Failure("Invalid number: underscore not between digits")
      }
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
  debug_inspect(
    lexer.read_number(false),
    content=(
      #|IntegerToken(
      #|  123,
      #|  loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|)
    ),
  )
}

///|
/// Skip comments and whitespace but not newline characters
fn Lexer::skip_comments_or_whitespace(self : Lexer) -> Unit raise {
  let next = loop self.view() {
    ['\r', '\n', ..] | ['\n', ..] | [] as rest => rest
    [' ' | '\t', .. rest] => continue rest
    ['\r', ..] as rest => rest // bare \r stops here, will be rejected by next_token
    ['#', .. next] =>
      loop next {
        ['\r', '\n', ..] | ['\n', ..] | [] as rest => rest
        [ch, .. rest] => {
          if is_control_char(ch) {
            self.update_view(rest)
            fail(
              self.error(
                "Invalid control character in comment: U+\{ch.to_int().to_string().pad_start(4, '0')}",
              ),
            )
          }
          continue rest
        }
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

    // Newline (LF or CRLF)
    ['\r', '\n', .. rest] | ['\n', .. rest] => {
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
      StringToken(value, loc=make_loc(start_pos, end_pos), multiline=true)
    }
    ['"', ..] => {
      let value = self.read_basic_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos), multiline=false)
    }
    [.. "'''", .. rest] => {
      self.update_view(rest)
      let value = self.read_multiline_literal_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos), multiline=true)
    }
    ['\'', ..] => {
      let value = self.read_literal_string()
      let end_pos = self.get_loc()
      StringToken(value, loc=make_loc(start_pos, end_pos), multiline=false)
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

    // Positive numbers with explicit '+' (only decimal, not 0x/0o/0b).
    // '+' is not a valid bare key character, so +number in key position
    // (followed by = or ]) should be rejected.
    ['+', '0'..='9', ..] => {
      // Peek ahead: skip digits/underscores, then check for key indicators
      let is_key_context = loop self.view()[1:] {
        ['0'..='9' | '_', .. rest] => continue rest
        [' ' | '\t', .. rest] => continue rest
        ['=' | ']', ..] => true // +num= or [+num] are both invalid
        _ => false
      }
      if is_key_context {
        fail("Unexpected character: '+'")
      }
      match self.view() {
        ['+', '0', 'x' | 'o' | 'b', ..] => fail("Unexpected character: '+'")
        ['+', .. rest] => {
          self.update_view(rest)
          self.read_number_with_loc(false, start_pos)
        }
        _ => abort("Internal error: pattern matching inconsistency")
      }
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

    // Identifiers and keywords (bare keys: A-Za-z0-9_-)
    ['a'..='z' | 'A'..='Z' | '_' | '-', ..] => {
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
test "read_number 2" {
  let lexer = Lexer::new("123")
  debug_inspect(
    lexer.read_number(false),
    content=(
      #|IntegerToken(
      #|  123,
      #|  loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|)
    ),
  )
}

///|
/// Test Unicode escape sequences
test "unicode escape sequences" {
  let lexer1 = Lexer::new("\"\\u0041\"") // 'A'
  let result1 = lexer1.read_basic_string()
  debug_inspect(
    result1,
    content=(
      #|"A"
    ),
  )
  let lexer2 = Lexer::new("\"\\U00000041\"") // 'A'
  let result2 = lexer2.read_basic_string()
  debug_inspect(
    result2,
    content=(
      #|"A"
    ),
  )
}

///|
/// Test multiline basic string
test "multiline basic string" {
  let lexer = Lexer::new("\"\"\"line1\nline2\"\"\"")
  lexer.expect_string("\"\"\"")
  let result = lexer.read_multiline_basic_string()
  debug_inspect(
    result,
    content=(
      #|"line1\nline2"
    ),
  )
}

///|
/// Test multiline literal string
test "multiline literal string" {
  let lexer = Lexer::new("'''line1\nline2'''")
  lexer.expect_string("'''")
  let result = lexer.read_multiline_literal_string()
  debug_inspect(
    result,
    content=(
      #|"line1\nline2"
    ),
  )
}

///|
/// Test line ending backslash in multiline string
test "line ending backslash" {
  let lexer = Lexer::new("\"\"\"line1\\\n   line2\"\"\"")
  lexer.expect_string("\"\"\"")
  let result = lexer.read_multiline_basic_string()
  debug_inspect(
    result,
    content=(
      #|"line1line2"
    ),
  ) // whitespace should be trimmed
}

///|
/// Test basic string parsing
test "basic string parsing" {
  let lexer = Lexer::new("\"Hello, \\\"world\\\"!\"")
  let result = lexer.read_basic_string()
  debug_inspect(
    result,
    content=(
      #|"Hello, \"world\"!"
    ),
  )
}

///|
/// Test literal string parsing  
test "literal string parsing" {
  let lexer = Lexer::new("'Hello, world!'")
  let result = lexer.read_literal_string()
  debug_inspect(
    result,
    content=(
      #|"Hello, world!"
    ),
  )
}

///|
/// Test identifier parsing
test "identifier parsing" {
  let lexer = Lexer::new("hello-world_123")
  let result = lexer.read_identifier()
  debug_inspect(
    result,
    content=(
      #|"hello-world_123"
    ),
  )
}

///|
/// Test hex number parsing
test "hex number parsing" {
  let lexer = Lexer::new("0xDEADBEEF")
  let result = lexer.read_hex_number()
  debug_inspect(result, content="3735928559")
}

///|
/// Test octal number parsing  
test "octal number parsing" {
  let lexer = Lexer::new("0o755")
  let result = lexer.read_octal_number()
  debug_inspect(result, content="493")
}

///|
/// Test binary number parsing
test "binary number parsing" {
  let lexer = Lexer::new("0b1010")
  let result = lexer.read_binary_number()
  debug_inspect(result, content="10")
}

///|
/// Test datetime tokenization
test "datetime tokenization" {
  let tokens = tokenize("date = 1979-05-27T07:32:00Z")
  json_inspect(tokens, content=[
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
