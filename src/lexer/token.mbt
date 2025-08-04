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
