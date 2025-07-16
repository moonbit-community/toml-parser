/// TOML Value types that represent different TOML data types
pub(all) enum TomlValue {
  TomlString(String)
  TomlInteger(Int64)  
  TomlFloat(Double)
  TomlBoolean(Bool)
  TomlArray(Array[TomlValue])
  TomlTable(Map[String, TomlValue])
}

/// Result type for parsing operations
pub(all) enum ParseResult[T] {
  Ok(T)
  Err(String)
}

/// Token types for the lexer
pub(all) enum Token {
  // Literals
  StringToken(String)
  IntegerToken(Int64)
  FloatToken(Double)
  BooleanToken(Bool)
  
  // Symbols
  LeftBracket    // [
  RightBracket   // ]
  LeftBrace      // {
  RightBrace     // }
  Equals         // =
  Comma          // ,
  Dot            // .
  
  // Identifiers and keywords
  Identifier(String)
  
  // Special
  Newline
  EOF
} derive(Eq, Show)

/// Position information for error reporting
pub struct Position {
  line : Int
  column : Int
}

/// Lexer state (will implement methods later)
pub struct Lexer {
  input : String
  mut position : Int
  mut line : Int
  mut column : Int
}

/// Parser state (will implement methods later)
pub struct Parser {
  tokens : Array[Token]
  mut position : Int
}

/// Convert TomlValue to string representation
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
        if i > 0 { result = result + ", " }
        result = result + items[i]
      }
      result + "]"
    }
    TomlTable(table) => {
      let items = Array::new()
      table.each(fn(key, value) {
        items.push(key + " = " + value.to_string())
      })
      let mut result = "{"
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 { result = result + ", " }
        result = result + items[i]
      }
      result + "}"
    }
  }
}

/// Create a new lexer
pub fn Lexer::new(input : String) -> Lexer {
  { input, position: 0, line: 1, column: 1 }
}

/// Create a new parser
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, position: 0 }
}