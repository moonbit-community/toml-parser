///|
/// Default location for testing and compatibility
pub fn default_loc() -> Loc {
  let pos = Position::{ line: 1, column: 1, }
  { start: pos, end: pos, }
}

///|
const START : Regex = re"^"

///|
/// TOML date: `YYYY-MM-DD`.
const DATE : Regex = re"[0-9]{4}-[0-9]{2}-[0-9]{2}"

///|
/// TOML time: `HH:MM` with optional `:SS` and `.fff` fraction.
const TIME : Regex = re"[0-9]{2}:[0-9]{2}" + re"(:[0-9]{2})?(\.[0-9]+)?"

///|
/// A decimal number as the tokenizer sees it: digits and underscores, an
/// optional `.` with digits and underscores, and an optional exponent. Where
/// the underscores and the dot go is validated by the parser, and only when
/// the token is used as a value, because the same text can be a bare key.
const DECIMAL : Regex = re"[+\-]?[0-9][0-9_]*" +
  re"(\.[0-9_]*)?" +
  re"([eE][+\-]?[0-9][0-9_]*)?"

///|
/// Skip comments and whitespace but not newline characters
fn Lexer::skip_comments_or_whitespace(self : Lexer) -> Unit raise {
  lexscan self with longest {
    // A comment runs to the end of its line or of the input; a control
    // character stops the match early, and is an error.
    re"^[ \t]*#[^\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]*" =>
      match self.peek() {
        None | Some('\n') => ()
        Some('\r') if self.input.get_char(self.offset + 1) is Some('\n') => ()
        Some(ch) => {
          self.offset += 1
          fail(self.error(control_char_message("comment", ch)))
        }
      }
    re"^[ \t]*" => ()
  }
}

///|
/// Get the next token
///
/// The first code unit picks one of a few small DFAs: a single DFA for every
/// token is slower on the native backend, where its cost grows with the
/// number of cases.
fn Lexer::next_token(self : Lexer) -> Token raise {
  self.skip_comments_or_whitespace()
  let start = self.loc()
  guard self.offset < self.input.length() else {
    EOF(loc={ start, end: start, })
  }
  match self.input.unsafe_get(self.offset) {
    'a'..<='z' | 'A'..<='Z' | '_' => self.bare_key(start)
    '0'..<='9' | '+' | '-' => self.number_or_key(start)
    '"' => self.basic_string(start)
    '\'' => self.literal_string(start)
    _ => self.punctuation(start)
  }
}

///|
/// Lexes a bare key starting with a letter or `_`, or `true` or `false`.
fn Lexer::bare_key(self : Lexer, start : Position) -> Token {
  lexscan self with longest {
    re"^[A-Za-z0-9_\-]+" as identifier => {
      let loc = self.span(start)
      match identifier {
        "true" => BooleanToken(true, loc~)
        "false" => BooleanToken(false, loc~)
        _ => Identifier(identifier.to_owned(), loc~)
      }
    }
    _ => panic()
  }
}

///|
/// Lexes a newline or a punctuation token.
fn Lexer::punctuation(self : Lexer, start : Position) -> Token raise {
  let c = self.input.unsafe_get(self.offset)
  self.offset += 1
  match c {
    '[' => LeftBracket(loc=self.span(start))
    ']' => RightBracket(loc=self.span(start))
    '{' => LeftBrace(loc=self.span(start))
    '}' => RightBrace(loc=self.span(start))
    '=' => Equals(loc=self.span(start))
    ',' => Comma(loc=self.span(start))
    '.' => Dot(loc=self.span(start))
    '\n' => {
      self.new_line()
      Newline(loc=self.span(start))
    }
    '\r' if self.peek() is Some('\n') => {
      self.offset += 1
      self.new_line()
      Newline(loc=self.span(start))
    }
    _ => {
      self.offset -= 1
      fail("Unexpected character: '\{self.peek().unwrap()}'")
    }
  }
}

///|
/// Lexes a basic string, single-line or multi-line. A string with no escapes
/// is taken in one match; anything else goes to the slower lexer, which also
/// reports errors.
fn Lexer::basic_string(self : Lexer, start : Position) -> Token raise {
  lexscan self with longest {
    re"^\"" + (re"[^\"\\\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]*" as value) + re"\"" =>
      StringToken(value.to_owned(), loc=self.span(start), multiline=false)
    re"^\"\"\"" => {
      let value = self.read_multiline_basic_string()
      StringToken(value, loc=self.span(start), multiline=true)
    }
    _ => {
      self.offset += 1
      let value = self.read_basic_string()
      StringToken(value, loc=self.span(start), multiline=false)
    }
  }
}

///|
/// Lexes a literal string, single-line or multi-line.
fn Lexer::literal_string(self : Lexer, start : Position) -> Token raise {
  lexscan self with longest {
    re"^'" + (re"[^'\u{0}-\u{8}\u{a}-\u{1f}\u{7f}]*" as value) + re"'" =>
      StringToken(value.to_owned(), loc=self.span(start), multiline=false)
    re"^'''" => {
      let value = self.read_multiline_literal_string()
      StringToken(value, loc=self.span(start), multiline=true)
    }
    _ => {
      self.offset += 1
      self.literal_string_error()
    }
  }
}

///|
/// Lexes what starts with a digit, `+` or `-`: a number, a date or time, a
/// special float, or a bare key such as `1key` or `-abc`.
fn Lexer::number_or_key(self : Lexer, start : Position) -> Token raise {
  let start_offset = self.offset
  lexscan self with longest {
    // Dates and times win over numbers, being longer.
    START +
    (
      (
        DATE +
        re"([Tt ][0-9]{2}:[0-9]{2}(:[0-9]{2})?(\.[0-9]+)?([Zz]|[+\-][0-9]{2}:[0-9]{2})?)?"
      ) as datetime
    ) => self.datetime_token(datetime, start)
    (START + TIME) as time =>
      match self.peek() {
        None | Some(' ' | '\t' | '\n' | '\r' | '=' | ',' | ']' | '}') => {
          validate_time(time)
          DateTimeToken(LocalTime(time.to_owned()), loc=self.span(start))
        }
        Some(_) => {
          // Not a time: lex the digits as a number instead.
          self.offset = start_offset
          lexscan self with longest {
            (START + DECIMAL) as raw => self.decimal_number(raw, start)
            _ => panic()
          }
        }
      }

    // Only the lowercase radix prefixes are numbers: `0X5` goes to the bare
    // key path, so `x = 0X5` errors while `[0XAB]` is a valid key.
    START + ((re"0x" + re"[0-9a-fA-F]+(_[0-9a-fA-F]+)*") as raw) =>
      self.radix_number(raw, 16, "hex", start)
    START + ((re"0o" + re"[0-7]+(_[0-7]+)*") as raw) =>
      self.radix_number(raw, 8, "octal", start)
    START + ((re"0b" + re"[01]+(_[01]+)*") as raw) =>
      self.radix_number(raw, 2, "binary", start)
    re"^0x" => fail(start.message("Invalid hex number format"))
    re"^0o" => fail(start.message("Invalid octal number format"))
    re"^0b" => fail(start.message("Invalid binary number format"))
    re"^\+0[xXoObB]" => fail("Unexpected character: '+'")
    (START + DECIMAL) as raw => self.decimal_number(raw, start)

    // Special float values. The bare key characters after them are matched
    // only to beat the bare key case below, and reported as an error.
    START + (re"[+\-](inf|nan)" as raw) + re"[A-Za-z0-9_\-]*" => {
      self.offset = start_offset + 4
      match self.peek() {
        None | Some(' ' | '\t' | '\n' | '\r' | '=' | ',' | ']' | '}' | '#') =>
          ()
        Some(ch) =>
          fail(self.error("Invalid character '\{ch}' after special value"))
      }
      let value = match raw {
        "-inf" => -1.0 / 0.0
        "+inf" => 1.0 / 0.0
        _ => 0.0 / 0.0
      }
      FloatToken(value, loc=self.span(start), raw=raw.to_owned())
    }

    // A bare key starting with `-`. A `-` followed by a digit starts a number
    // instead.
    START + (re"-([A-Za-z_\-][A-Za-z0-9_\-]*)?" as identifier) =>
      Identifier(identifier.to_owned(), loc=self.span(start))
    _ => fail("Unexpected character: '\{self.peek().unwrap()}'")
  }
}

///|
/// Builds the token for a date `text`, optionally followed by a time and an
/// offset, as `next_token` matched it.
fn Lexer::datetime_token(
  self : Lexer,
  text : StringView,
  start : Position,
) -> Token raise {
  let len = text.length()
  let date = text.unsafe_view(start=0, end=10)
  validate_date(date)
  if len == 10 {
    return DateTimeToken(LocalDate(date.to_owned()), loc=self.span(start))
  }
  // The time starts after the T/t/space separator, and runs to the offset.
  let offset_start = for i = 11; i < len; i = i + 1 {
    if text[i] is ('Z' | 'z' | '+' | '-') {
      break i
    }
  } nobreak {
    len
  }
  validate_time(text.unsafe_view(start=11, end=offset_start))
  let datetime = text.unsafe_view(start=0, end=offset_start)
  let value : @datetime.TomlDateTime = if offset_start == len {
    LocalDateTime(datetime.to_owned())
  } else if text[offset_start] is ('Z' | 'z') {
    OffsetDateTime("\{datetime}Z")
  } else {
    let offset = text.unsafe_view(start=offset_start, end=len)
    validate_timezone_offset(offset)
    OffsetDateTime("\{datetime}\{offset}")
  }
  DateTimeToken(value, loc=self.span(start))
}

///|
/// Builds the token for a radix-prefixed integer `raw` (prefix, then digits
/// and single underscores), which ends at the cursor. The raw text is kept so
/// that the parser can still use the token as a bare key.
fn Lexer::radix_number(
  self : Lexer,
  raw : StringView,
  base : Int64,
  name : String,
  start : Position,
) -> Token raise {
  let mut result = 0L
  for ch in raw.unsafe_view(start=2, end=raw.length()) {
    let digit = match ch {
      '_' => continue
      '0'..<='9' => (ch.to_int() - '0').to_int64()
      'a'..<='f' => (ch.to_int() - 'a').to_int64() + 10L
      _ => (ch.to_int() - 'A').to_int64() + 10L
    }
    if result > (INT64_MAX - digit) / base {
      fail(start.message("Invalid \{name} number: value out of Int64 range"))
    }
    result = result * base + digit
  }
  // A '.' means a dotted bare key like `0xAB.cd`; the parser splits the raw
  // text, so this is not an error here.
  match self.peek() {
    None | Some('.' | ' ' | '\t' | '\r' | '\n' | ',' | ']' | '}' | '#') =>
      IntegerToken(result, loc=self.span(start), raw=raw.to_owned())
    Some(ch) => {
      let prefix = raw.unsafe_view(start=0, end=2)
      fail(
        self.error(
          "Invalid char '\{ch}', expected whitespace, comma, or end of input after \{prefix}...",
        ),
      )
    }
  }
}

///|
/// Builds the token for a decimal number `raw` (see `DECIMAL`), which ends
/// at the cursor.
///
/// Text that is not a number value is often still a bare key, so it becomes
/// an `Identifier`: an integer part with a leading zero (`0123`, `-01`), or a
/// number followed by bare key characters (`1key`, `2000-datetime`, `-5y`).
fn Lexer::decimal_number(
  self : Lexer,
  raw : StringView,
  start : Position,
) -> Token {
  let has_sign = raw is ['+', ..]
  let is_negative = raw is ['-', ..]
  let digits_start = if has_sign || is_negative { 1 } else { 0 }
  let int_end = for i = digits_start; i < raw.length(); i = i + 1 {
    if !(raw[i] is ('0'..<='9' | '_')) {
      break i
    }
  } nobreak {
    raw.length()
  }
  // A leading zero makes a bare key; checked before the decimal point, so
  // `01.23` is not a float.
  if raw[digits_start] == '0' &&
    raw
    .unsafe_view(start=digits_start + 1, end=int_end)
    .contains_any(chars="0123456789") {
    self.offset = raw.start_offset() + int_end
    // A sign is kept so that the parser rejects the token as a key.
    let name = strip_underscores(raw.unsafe_view(start=0, end=int_end))
    return Identifier(name, loc=self.span(start))
  }
  let has_dot = int_end < raw.length() && raw[int_end] == '.'
  // '+' is never a bare key character, and "1.5x" is a float followed by an
  // identifier, which the parser rejects.
  if !has_sign &&
    !has_dot &&
    self.peek() is Some('A'..<='Z' | 'a'..<='z' | '_' | '-') {
    lexscan self with longest {
      re"^[A-Za-z_\-][A-Za-z0-9_\-]*" as suffix =>
        return Identifier("\{raw}\{suffix}", loc=self.span(start))
      _ => ()
    }
  }
  let loc = self.span(start)
  // The number without its `+` and underscores.
  let s = raw.unsafe_view(start=if has_sign { 1 } else { 0 }, end=raw.length())
  let s = if s.contains_char('_') { strip_underscores(s)[:] } else { s }
  if int_end < raw.length() {
    FloatToken(
      @string.parse_double(s) catch {
        // Overflow (e.g. -31e368) → ±infinity, matching IEEE 754 behaviour.
        _ => if is_negative { -1.0 / 0.0 } else { 1.0 / 0.0 }
      },
      loc~,
      raw=raw.to_owned(),
    )
  } else {
    // Saturate on Int64 overflow so the token always carries a value; the
    // parser never observes it because it range-checks the raw text first.
    IntegerToken(
      @string.parse_int64(s) catch {
        _ => if is_negative { INT64_MIN } else { INT64_MAX }
      },
      loc~,
      raw=raw.to_owned(),
    )
  }
}

///|
/// Tokenize entire input
pub fn tokenize(input : String) -> Array[Token] raise {
  let lexer = Lexer::new(input)
  let tokens = []
  while true {
    let token = lexer.next_token()
    tokens.push(token)
    if token is EOF(_) {
      break
    }
  }
  tokens
}

///|
/// The value of the only string token in `input`.
fn string_value(input : String) -> String raise {
  match tokenize(input) {
    [StringToken(value, ..), EOF(_)] => value
    tokens => fail("not a single string: \{tokens.length()} tokens")
  }
}

///|
test "string escapes" {
  debug_inspect(string_value("\"\\u0041\\U00000041\\x41\""), content="\"AAA\"")
  debug_inspect(
    string_value("\"Hello, \\\"world\\\"!\""),
    content=(
      #|"Hello, \"world\"!"
    ),
  )
  debug_inspect(string_value("'Hello, world!'"), content="\"Hello, world!\"")
}

///|
test "multiline strings" {
  debug_inspect(
    string_value("\"\"\"line1\nline2\"\"\""),
    content=(
      #|"line1\nline2"
    ),
  )
  debug_inspect(
    string_value("'''line1\nline2'''"),
    content=(
      #|"line1\nline2"
    ),
  )
  // A line ending backslash trims the whitespace after it.
  debug_inspect(
    string_value("\"\"\"line1\\\n   line2\"\"\""),
    content="\"line1line2\"",
  )
}

///|
test "numbers and identifiers" {
  debug_inspect(
    tokenize("123 hello-world_123 0xDEADBEEF 0o755 0b1010"),
    content=(
      #|[
      #|  IntegerToken(
      #|    123,
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 4 } },
      #|    raw="123",
      #|  ),
      #|  Identifier(
      #|    "hello-world_123",
      #|    loc={ start: { line: 1, column: 5 }, end: { line: 1, column: 20 } },
      #|  ),
      #|  IntegerToken(
      #|    3735928559,
      #|    loc={ start: { line: 1, column: 21 }, end: { line: 1, column: 31 } },
      #|    raw="0xDEADBEEF",
      #|  ),
      #|  IntegerToken(
      #|    493,
      #|    loc={ start: { line: 1, column: 32 }, end: { line: 1, column: 37 } },
      #|    raw="0o755",
      #|  ),
      #|  IntegerToken(
      #|    10,
      #|    loc={ start: { line: 1, column: 38 }, end: { line: 1, column: 44 } },
      #|    raw="0b1010",
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 44 }, end: { line: 1, column: 44 } }),
      #|]
    ),
  )
}

///|
/// Test datetime tokenization
test "datetime tokenization" {
  let tokens = tokenize("date = 1979-05-27T07:32:00Z")
  debug_inspect(
    tokens,
    content=(
      #|[
      #|  Identifier(
      #|    "date",
      #|    loc={ start: { line: 1, column: 1 }, end: { line: 1, column: 5 } },
      #|  ),
      #|  Equals(loc={ start: { line: 1, column: 6 }, end: { line: 1, column: 7 } }),
      #|  DateTimeToken(
      #|    OffsetDateTime("1979-05-27T07:32:00Z"),
      #|    loc={ start: { line: 1, column: 8 }, end: { line: 1, column: 28 } },
      #|  ),
      #|  EOF(loc={ start: { line: 1, column: 28 }, end: { line: 1, column: 28 } }),
      #|]
    ),
  )
}
