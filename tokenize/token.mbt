///|
typealias @lexer.Position

///|
pub(all) struct Loc {
  start : Position
  end : Position
} derive(Eq, Show)

///| minimal format for visual debugging
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
    StringToken(s, loc~) => ["StringToken", s, { "loc": loc }]
    IntegerToken(i, loc~) => ["IntegerToken", i, { "loc": loc }]
    FloatToken(f, loc~) => ["FloatToken", f, { "loc": loc }]
    BooleanToken(b, loc~) => ["BooleanToken", b, { "loc": loc }]
    DateTimeToken(dt, loc~) => ["DateTimeToken", dt, { "loc": loc }]
    LeftBracket(loc~) => ["LeftBracket", { "loc": loc }]
    RightBracket(loc~) => ["RightBracket", { "loc": loc }]
    LeftBrace(loc~) => ["LeftBrace", { "loc": loc }]
    RightBrace(loc~) => ["RightBrace", { "loc": loc }]
    Equals(loc~) => ["Equals", { "loc": loc }]
    Comma(loc~) => ["Comma", { "loc": loc }]
    Dot(loc~) => ["Dot", { "loc": loc }]
    Identifier(s, loc~) => ["Identifier", s, { "loc": loc }]
    Newline(loc~) => ["Newline", { "loc": loc }]
    EOF(loc~) => ["EOF", { "loc": loc }]
  }
}

///| DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Show, ToJson(style="flat"))

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
