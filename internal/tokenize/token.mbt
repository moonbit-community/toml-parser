///|
typealias @lexer.Position

///|
pub(all) struct Loc {
  start : Position
  end : Position
} derive(Eq, Show)

///|
/// minimal format for visual debugging
/// # Example
/// ```
/// let loc = Loc::{start: {line:1, column:1}, end: {line:1, column:10}}
/// @json.inspect(loc, content = "1:1-1:10")
/// ```
///
pub impl ToJson for Loc with to_json(self) {
  "\{self.start.line}:\{self.start.column}-\{self.end.line}:\{self.end.column}"
}
// impl ToJson for Loc with to_json(self) {
//   ["Loc", self.start, self.end]
// }

///|
/// Token types for the lexer
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
} derive(Eq, Show, ToJson)

///|
/// DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Show, ToJson)

///|
pub fn Token::loc(self : Self) -> Loc {
  match self {
    StringToken(_, loc~) => loc
    IntegerToken(_, loc~) => loc
    FloatToken(_, loc~) => loc
    BooleanToken(_, loc~) => loc
    DateTimeToken(_, loc~) => loc
    LeftBracket(loc~) => loc
    RightBracket(loc~) => loc
    LeftBrace(loc~) => loc
    RightBrace(loc~) => loc
    Equals(loc~) => loc
    Comma(loc~) => loc
    Dot(loc~) => loc
    Identifier(_, loc~) => loc
    Newline(loc~) => loc
    EOF(loc~) => loc
  }
}
