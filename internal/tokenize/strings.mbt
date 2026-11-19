///|
/// The message for a control character `ch` (U+0000-U+001F except tab, and
/// U+007F), which TOML does not allow in `place`.
fn control_char_message(place : String, ch : Char) -> String {
  let code = ch.to_int().to_string(radix=16).to_upper().pad_start(4, '0')
  "Invalid control character in \{place}: U+\{code}"
}

///|
/// The value of the hex digits in `hex`, wrapping like `Int` arithmetic.
fn hex_value(hex : StringView) -> Int32 {
  let mut code = 0
  for ch in hex {
    let digit = match ch {
      '0'..<='9' => ch.to_int() - '0'
      'a'..<='f' => ch.to_int() - 'a' + 10
      _ => ch.to_int() - 'A' + 10
    }
    code = code * 16 + digit
  }
  code
}

///|
/// Lexes an escape sequence; the cursor is just past the backslash, and not
/// at the end of the input. An invalid escape is reported at the backslash,
/// or past the escaped character if `report_after`.
fn Lexer::read_escape(
  self : Lexer,
  sb : StringBuilder,
  report_after~ : Bool,
) -> Unit raise {
  lexscan self with longest {
    re"^n" => sb.write_char('\n')
    re"^t" => sb.write_char('\t')
    re"^r" => sb.write_char('\r')
    re"^\\" => sb.write_char('\\')
    re"^\"" => sb.write_char('"')
    re"^b" => sb.write_char('\u0008')
    re"^f" => sb.write_char('\u000C')
    re"^e" => sb.write_char('\u001B')
    re"^x" + (re"[0-9a-fA-F]{2}" as hex) =>
      // Two hex digits are always a valid character.
      sb.write_char(hex_value(hex).unsafe_to_char())
    re"^x" =>
      fail(self.error("Invalid hex escape sequence: expected 2 hex digits"))
    re"^u" + (re"[0-9a-fA-F]{4}" as hex) => {
      let code = hex_value(hex)
      match code.to_char() {
        Some(ch) => sb.write_char(ch)
        None => fail(self.error("Invalid Unicode code point: \{code}"))
      }
    }
    re"^u" =>
      fail(self.error("Invalid Unicode escape sequence: expected 4 hex digits"))
    re"^U" + (re"[0-9a-fA-F]{8}" as hex) => {
      let code = hex_value(hex)
      match code.to_char() {
        Some(ch) if code <= 0x10FFFF => sb.write_char(ch)
        _ => fail(self.error("Invalid Unicode code point: \{code}"))
      }
    }
    re"^U" =>
      fail(self.error("Invalid Unicode escape sequence: expected 8 hex digits"))
    _ => {
      let ch = self.peek().unwrap()
      if report_after {
        self.offset += if ch.to_int() > 0xFFFF { 2 } else { 1 }
      } else {
        self.offset -= 1
      }
      fail(self.error("Invalid escape sequence: \\\{ch}"))
    }
  }
}

///|
/// Lexes the rest of a basic string that the fast path in `next_token` did
/// not take: one with escapes, or a malformed one. The cursor is just past
/// the opening quote.
fn Lexer::read_basic_string(self : Lexer) -> String raise {
  let content_start = self.loc()
  let sb = StringBuilder()
  while true {
    lexscan self with longest {
      re"^[^\"\\\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]+" as chunk =>
        sb.write_view(chunk)
      re"^\"" => break
      re"^\\" =>
        if self.offset < self.input.length() {
          self.read_escape(sb, report_after=false)
        } else {
          fail(content_start.message("Unterminated string"))
        }
      re"^[\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]" as ch =>
        fail(self.error(control_char_message("basic string", ch)))
      _ => fail(content_start.message("Unterminated string"))
    }
  }
  sb.to_string()
}

///|
/// Reports the error in a literal string that the fast path in `next_token`
/// did not take. The cursor is just past the opening quote.
fn[T] Lexer::literal_string_error(self : Lexer) -> T raise {
  let content_start = self.loc()
  lexscan self with longest {
    re"^[^'\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]*" +
    (re"[\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]" as ch) =>
      fail(self.error(control_char_message("literal string", ch)))
    _ => fail(content_start.message("Unterminated string"))
  }
}

///|
/// Skips the line terminator right after the opening delimiter of a
/// multi-line string, if any.
fn Lexer::skip_single_newline(self : Lexer) -> Unit {
  lexscan self with longest {
    re"^\r?\n" => self.new_line()
    _ => ()
  }
}

///|
/// Lexes a multi-line basic string; the opening `"""` is consumed.
fn Lexer::read_multiline_basic_string(self : Lexer) -> String raise {
  self.skip_single_newline()
  let sb = StringBuilder()
  while true {
    lexscan self with longest {
      re"^[^\"\\\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]+" as chunk =>
        sb.write_view(chunk)
      re"^\r?\n" => {
        sb.write_char('\n')
        self.new_line()
      }
      // Up to two quotes are content; `"""` closes the string, and up to two
      // more quotes before it are content too.
      re"^\"\"?" as quotes => sb.write_view(quotes)
      re"^\"\"\"" => break
      re"^\"\"\"\"" => {
        sb.write_char('"')
        break
      }
      re"^\"\"\"\"\"" => {
        sb <+ "\"\""
        break
      }
      // A line ending backslash trims the newline (LF or CRLF) and all the
      // whitespace and newlines after it.
      re"^\\[ \t]*\r?\n([ \t]|\r?\n)*" as trimmed =>
        self.count_new_lines(trimmed)
      re"^\\[ \t]*\r" =>
        fail(self.error("Invalid escape: backslash followed by a bare CR"))
      re"^\\[ \t]" =>
        fail(
          self.error(
            "Invalid escape: backslash followed by whitespace but no newline",
          ),
        )
      re"^\\" =>
        if self.offset < self.input.length() {
          self.read_escape(sb, report_after=true)
        } else {
          fail(self.error("Unexpected end of input after escape character"))
        }
      re"^[\u{0}-\u{8}\u{b}-\u{1f}\u{7f}]" as ch =>
        fail(self.error(control_char_message("multiline string", ch)))
      _ => fail(self.error("Unterminated multiline string"))
    }
  }
  sb.to_string()
}

///|
/// Lexes a multi-line literal string; the opening `'''` is consumed.
fn Lexer::read_multiline_literal_string(self : Lexer) -> String raise {
  self.skip_single_newline()
  let sb = StringBuilder()
  while true {
    lexscan self with longest {
      re"^[^'\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]+" as chunk => sb.write_view(chunk)
      re"^\n" => {
        sb.write_char('\n')
        self.new_line()
      }
      re"^\r\n" => {
        sb <+ "\r\n"
        self.new_line()
      }
      re"^''?" as quotes => sb.write_view(quotes)
      re"^'''" => break
      re"^''''" => {
        sb.write_char('\'')
        break
      }
      re"^'''''" => {
        sb <+ "''"
        break
      }
      re"^[\u{0}-\u{8}\u{b}-\u{1f}\u{7f}]" as ch =>
        fail(self.error(control_char_message("multiline literal string", ch)))
      _ => fail(self.error("Unterminated multiline literal string"))
    }
  }
  sb.to_string()
}
