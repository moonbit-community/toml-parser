typealias @lexer.(Position)

pub(all) struct Loc {
  start : Position
  end : Position
} derive(Eq, Show, ToJson)

///| Token types for the lexer
pub(all) enum Token {
  // Literals
  StringToken(String, loc~ : Loc)
  IntegerToken(Int64, loc~ : Loc)
  FloatToken(Double, loc~ : Loc)
  BooleanToken(Bool, loc~ : Loc)
  DateTimeToken(TomlDateTime, loc~ : Loc)

  // Symbols
  LeftBracket(loc~ : Loc) // [
  RightBracket(loc~ : Loc) // ]
  LeftBrace(loc~ : Loc) // {
  RightBrace(loc~ : Loc) // }
  Equals(loc~ : Loc) // =
  Comma(loc~ : Loc) // ,
  Dot(loc~ : Loc) // .

  // Identifiers and keywords
  Identifier(String, loc~ : Loc)

  // Special
  Newline(loc~ : Loc)
  EOF(loc~ : Loc)
} derive(Eq, Show)

///| skip loc
pub impl ToJson for Token with to_json(self) {
  match self {
    StringToken(s, ..) => ["StringToken", s]
    IntegerToken(i, ..) => ["IntegerToken", i]
    FloatToken(f, ..) => ["FloatToken", f]
    BooleanToken(b, ..) => ["BooleanToken", b]
    DateTimeToken(dt, ..) => ["DateTimeToken", dt]
    LeftBracket(..) => "LeftBracket"
    RightBracket(..) => "RightBracket"
    LeftBrace(..) => "LeftBrace"
    RightBrace(..) => "RightBrace"
    Equals(..) => "Equals"
    Comma(..) => "Comma"
    Dot(..) => "Dot"
    Identifier(s, ..) => ["Identifier", s]
    Newline(..) => "Newline"
    EOF(..) => "EOF"
  }
}

///| DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Show, ToJson(style="flat"))
