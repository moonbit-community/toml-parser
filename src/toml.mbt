///| DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Show)

///|
pub impl ToJson for TomlDateTime with to_json(self) {
  match self {
    OffsetDateTime(s) => ["OffsetDateTime", s]
    LocalDateTime(s) => ["LocalDateTime", s]
    LocalDate(s) => ["LocalDate", s]
    LocalTime(s) => ["LocalTime", s]
  }
}

///| TOML Value types that represent different TOML data types
pub(all) enum TomlValue {
  TomlString(String)
  TomlInteger(Int64)
  TomlFloat(Double)
  TomlBoolean(Bool)
  TomlArray(Array[TomlValue])
  TomlTable(Map[String, TomlValue])
  TomlDateTime(TomlDateTime)
} derive(Eq, Show)

///|
pub impl ToJson for TomlValue with to_json(self) {
  match self {
    TomlString(s) => ["TomlString", s]
    TomlInteger(i) => ["TomlInteger", i]
    TomlFloat(f) => ["TomlFloat", f]
    TomlBoolean(b) => ["TomlBoolean", b]
    TomlArray(arr) => ["TomlArray", arr]
    TomlTable(table) => ["TomlTable", table]
    TomlDateTime(dt) => ["TomlDateTime", dt]
  }
}

///| Removed ParseResult typealias - now using checked exceptions

///| Token types for the lexer
pub(all) enum Token {
  // Literals
  StringToken(String)
  IntegerToken(Int64)
  FloatToken(Double)
  BooleanToken(Bool)
  DateTimeToken(TomlDateTime)

  // Symbols
  LeftBracket // [
  RightBracket // ]
  LeftBrace // {
  RightBrace // }
  Equals // =
  Comma // ,
  Dot // .

  // Identifiers and keywords
  Identifier(String)

  // Special
  Newline
  EOF
} derive(Eq, Show)

///|
pub impl ToJson for Token with to_json(self) {
  match self {
    StringToken(s) => ["StringToken", s]
    IntegerToken(i) => ["IntegerToken", i]
    FloatToken(f) => ["FloatToken", f]
    BooleanToken(b) => ["BooleanToken", b]
    DateTimeToken(dt) => ["DateTimeToken", dt]
    LeftBracket => "LeftBracket"
    RightBracket => "RightBracket"
    LeftBrace => "LeftBrace"
    RightBrace => "RightBrace"
    Equals => "Equals"
    Comma => "Comma"
    Dot => "Dot"
    Identifier(s) => ["Identifier", s]
    Newline => "Newline"
    EOF => ["EOF"]
  }
}

///| Lexer state (will implement methods later)
pub struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
}

///| Parser state (will implement methods later)
pub struct Parser {
  tokens : Array[Token]
  mut position : Int
}

///| Convert TomlValue to string representation
pub fn TomlValue::to_string(self : TomlValue) -> String {
  match self {
    TomlString(s) => "\"" + s + "\""
    TomlInteger(i) => i.to_string()
    TomlFloat(f) => f.to_string()
    TomlBoolean(b) => if b { "true" } else { "false" }
    TomlArray(arr) => {
      let items = Array::new()
      for i = 0; i < arr.length(); i = i + 1 {
        items.push(arr[i].to_string())
      }
      let mut result = "["
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 {
          result = result + ", "
        }
        result = result + items[i]
      }
      result + "]"
    }
    TomlTable(table) => {
      let items = Array::new()
      table.each(fn(key, value) { items.push(key + " = " + value.to_string()) })
      let mut result = "{"
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 {
          result = result + ", "
        }
        result = result + items[i]
      }
      result + "}"
    }
    TomlDateTime(dt) =>
      match dt {
        OffsetDateTime(s) => s
        LocalDateTime(s) => s
        LocalDate(s) => s
        LocalTime(s) => s
      }
  }
}

///| Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0, line: 1, column: 1 }
}

///| Create a new parser
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, position: 0 }
}

///| Check if an array contains homogeneous types (TOML spec requirement)
pub fn TomlValue::is_homogeneous_array(arr : Array[TomlValue]) -> Bool {
  if arr.length() == 0 {
    return true // Empty arrays are considered homogeneous
  }
  let first_type = match arr[0] {
    TomlString(_) => "string"
    TomlInteger(_) => "integer"
    TomlFloat(_) => "float"
    TomlBoolean(_) => "boolean"
    TomlArray(_) => "array"
    TomlTable(_) => "table"
    TomlDateTime(_) => "datetime"
  }
  for i = 1; i < arr.length(); i = i + 1 {
    let current_type = match arr[i] {
      TomlString(_) => "string"
      TomlInteger(_) => "integer"
      TomlFloat(_) => "float"
      TomlBoolean(_) => "boolean"
      TomlArray(_) => "array"
      TomlTable(_) => "table"
      TomlDateTime(_) => "datetime"
    }
    if current_type != first_type {
      return false
    }
  }
  true
}

///| Validate that a TomlValue follows TOML specification rules
pub fn TomlValue::validate(self : TomlValue) -> Bool {
  match self {
    TomlArray(arr) => {
      // Check homogeneity
      if not(TomlValue::is_homogeneous_array(arr)) {
        return false
      }
      // Recursively validate nested values
      for i = 0; i < arr.length(); i = i + 1 {
        if not(arr[i].validate()) {
          return false
        }
      }
      true
    }
    TomlTable(table) => {
      // Recursively validate all values in the table
      let mut valid = true
      table.each(fn(_key, value) { if not(value.validate()) { valid = false } })
      valid
    }
    _ => true // All other types are always valid by themselves
  }
}
