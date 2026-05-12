///|
/// Half-open source span `[start, end)` measured in lexer `Position`s.
///
/// `start` is the position of the first character of the lexeme and `end`
/// is the position immediately after its last character. Two locations are
/// `adjacent` (no gap) when one's `end` equals the other's `start`, which
/// the parser uses to distinguish e.g. `[[` (array-of-tables) from `[ [`
/// (a nested array literal opening a normal table header).
pub(all) struct Loc {
  start : @lexer.Position
  end : @lexer.Position
} derive(Eq, Debug)

///|
/// Token types for the lexer
pub(all) enum Token {
  // Literals
  StringToken(String, loc~ : Loc, multiline~ : Bool)
  IntegerToken(Int64, loc~ : Loc)
  FloatToken(Double, loc~ : Loc, raw~ : String)
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
} derive(Eq, Debug)

///|
/// DateTime type for TOML datetime values
pub(all) enum TomlDateTime {
  OffsetDateTime(String) // e.g., "1979-05-27T07:32:00Z" or "1979-05-27T07:32:00+01:00"
  LocalDateTime(String) // e.g., "1979-05-27T07:32:00"
  LocalDate(String) // e.g., "1979-05-27"
  LocalTime(String) // e.g., "07:32:00"
} derive(Eq, Debug)

///|
/// Show impl for TomlDateTime - provides human-readable format
pub impl Show for TomlDateTime with output(self, logger) {
  match self {
    OffsetDateTime(s) =>
      logger
        <+
        $|OffsetDateTime("\{s}")
    LocalDateTime(s) =>
      logger
        <+
        $|LocalDateTime("\{s}")
    LocalDate(s) =>
      logger
        <+
        $|LocalDate("\{s}")
    LocalTime(s) =>
      logger
        <+
        $|LocalTime("\{s}")
  }
}

///|

///|
/// Check if two locations are adjacent (end of first equals start of second).
pub fn Loc::adjacent(self : Loc, other : Loc) -> Bool {
  self.end.equal(other.start)
}

///|
/// Return the source `Loc` carried by this token.
///
/// Every `Token` variant records the span of the lexeme it was produced
/// from, so error messages can point back into the original input
/// regardless of which alternative matched.
pub fn Token::loc(self : Self) -> Loc {
  match self {
    StringToken(_, loc~, ..) => loc
    IntegerToken(_, loc~) => loc
    FloatToken(_, loc~, ..) => loc
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
