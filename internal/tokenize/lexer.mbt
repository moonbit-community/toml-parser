///|
/// A 1-based source position. Columns count characters, so a surrogate pair
/// takes one column.
#derive(Eq, Debug)
#valtype
pub(all) struct Position {
  line : Int32
  column : Int32
}

///|
/// The tokenizer's cursor. It is the target of `lexscan` (see the
/// `Scannable` impl below), so the token DFAs advance `offset` in place,
/// without building a view per token.
///
/// Lines are counted as newlines are consumed (`new_line`). Columns are
/// computed lazily by `loc`, from the last offset whose column is known, so
/// moving the cursor costs nothing until a position is asked for.
priv struct Lexer {
  input : StringView
  /// The offset in `input` of the next code unit to read.
  mut offset : Int32
  mut line : Int32
  /// The column of `column_offset`.
  mut column : Int32
  mut column_offset : Int32
}

///|
fn Lexer::new(input : String) -> Lexer {
  {
    input: input.exact_view(),
    offset: 0,
    line: 1,
    column: 1,
    column_offset: 0,
  }
}

///|
impl @lexbuf.Scannable for Lexer with fn scan_input(self) {
  self.input
}

///|
impl @lexbuf.Scannable for Lexer with fn scan_cursor(self) {
  self.offset
}

///|
impl @lexbuf.Scannable for Lexer with fn set_scan_cursor(self, cursor) {
  self.offset = cursor
}

///|
/// Number of columns spanned by the UTF-16 range `[start, end)` of `input`:
/// the number of characters that *begin* in the range. Every code unit begins
/// a character except the trailing half of a surrogate pair.
///
/// Whether a unit begins a character depends only on `input`, so the width
/// is additive, and a column depends only on the offset it describes.
fn column_width(input : StringView, start : Int32, end : Int32) -> Int32 {
  let mut width = end - start
  for i in start..<end {
    if i > 0 &&
      input.unsafe_get(i).is_trailing_surrogate() &&
      input.unsafe_get(i - 1).is_leading_surrogate() {
      width -= 1
    }
  }
  width
}

///|
/// The position of the cursor.
fn Lexer::loc(self : Lexer) -> Position {
  let offset = self.offset
  if offset > self.column_offset {
    self.column += column_width(self.input, self.column_offset, offset)
  } else if offset < self.column_offset {
    self.column -= column_width(self.input, offset, self.column_offset)
  }
  self.column_offset = offset
  { line: self.line, column: self.column, }
}

///|
/// The span from `start` to the cursor.
fn Lexer::span(self : Lexer, start : Position) -> Loc {
  { start, end: self.loc(), }
}

///|
/// Starts a new line. Call it right after consuming a line terminator.
fn Lexer::new_line(self : Lexer) -> Unit {
  self.line += 1
  self.column = 1
  self.column_offset = self.offset
}

///|
/// Counts the line terminators in `text`, which the cursor has just passed:
/// `\n`, `\r\n`, and a `\r` on its own.
fn Lexer::count_new_lines(self : Lexer, text : StringView) -> Unit {
  let len = text.length()
  for i in 0..<len {
    let c = text.unsafe_get(i)
    if c == '\n' ||
      (c == '\r' && (i + 1 == len || text.unsafe_get(i + 1) != '\n')) {
      self.line += 1
      self.column = 1
      self.column_offset = text.start_offset() + i + 1
    }
  }
}

///|
/// `msg` with the position `pos` appended.
fn Position::message(self : Position, msg : String) -> String {
  "\{msg} at line \{self.line}, column \{self.column}"
}

///|
/// `msg` with the position of the cursor appended.
fn Lexer::error(self : Lexer, msg : String) -> String {
  self.loc().message(msg)
}

///|
/// The character at the cursor, if any.
fn Lexer::peek(self : Lexer) -> Char? {
  self.input.get_char(self.offset)
}

///|
test "columns count characters" {
  let lexer = Lexer::new("a😈b\ncd")
  lexer.offset = 3
  debug_inspect(lexer.loc(), content="{ line: 1, column: 3 }")
  lexer.offset = 1
  debug_inspect(lexer.loc(), content="{ line: 1, column: 2 }")
  lexer.offset = 5
  lexer.new_line()
  lexer.offset = 6
  debug_inspect(lexer.loc(), content="{ line: 2, column: 2 }")
}
