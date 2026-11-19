///|
/// Largest value a TOML integer can take (signed 64-bit).
const INT64_MAX = 9223372036854775807L

///|
/// Smallest value a TOML integer can take (signed 64-bit).
const INT64_MIN : Int64 = -9223372036854775807L - 1L

///|
/// Remove underscores from a numeric literal's raw text.
fn strip_underscores(raw : StringView) -> String {
  let sb = StringBuilder()
  for ch in raw {
    if ch != '_' {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

///|
/// Validate a decimal integer literal from its raw source text (optional
/// sign, underscores preserved): underscore placement and Int64 range.
///
/// The tokenizer emits decimal numeric tokens without validating them
/// because the same text can be a bare key, where TOML applies no numeric
/// rules. The parser calls this when — and only when — the token is used
/// as a value. Radix-prefixed literals (0x/0o/0b) are not covered: they
/// can never be confused with values here since the tokenizer already
/// validated them (digits, underscores, and Int64 range) at lex time.
pub fn validate_integer_literal(raw : String) -> Unit raise {
  if raw.has_prefix("0x") || raw.has_prefix("0o") || raw.has_prefix("0b") {
    return
  }
  validate_underscores(raw)
  let s = strip_underscores(raw)
  let _ = @string.parse_int64(s) catch {
    _ => raise Failure::Failure("Invalid integer: \{s}")
  }
}

///|
/// Validate a decimal float literal from its raw source text (optional
/// sign, underscores preserved): underscore placement and dot placement.
///
/// See validate_integer_literal for why validation is deferred to the
/// parser.
pub fn validate_float_literal(raw : String) -> Unit raise {
  validate_float_string(strip_underscores(raw), raw)
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
  // FIXME 0.. < s.length() - 1
  // weird error message 
  for i in 0..<(s.length() - 1) {
    if s[i] is '.' && s[i + 1] is ('e' | 'E') {
      raise Failure::Failure("Invalid float: no digits after decimal point")
    }
  }
  // Validate underscore placement in raw string
  validate_underscores(raw)
}

///|
/// Validate a date string YYYY-MM-DD.
fn validate_date(s : StringView) -> Unit raise {
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
fn validate_time(s : StringView) -> Unit raise {
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
fn parse_int_substr(s : StringView, start : Int32, end : Int32) -> Int32 {
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
fn days_in_month(year : Int32, month : Int32) -> Int32 {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 31
  }
}

///|
/// Validate timezone offset ±HH:MM (hour 0-23, minute 0-59).
fn validate_timezone_offset(s : StringView) -> Unit raise {
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
fn is_leap_year(year : Int32) -> Bool {
  (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

///|
/// Validate underscore placement: no leading, trailing, or adjacent underscores,
/// no underscore next to dot or e/E or sign.
fn validate_underscores(raw : String) -> Unit raise {
  let len = raw.length()
  for i in 0..<len {
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
