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
} derive(Eq, Show, ToJson(style="flat"))

///| DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Show, ToJson(style="flat"))
