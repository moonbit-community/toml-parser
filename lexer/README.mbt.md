# bobzhang/lexer

A generic lexer library for building handwritten lexers in MoonBit. This library provides essential lexing utilities including position tracking, character advancement, whitespace handling, and error reporting.

## Features

- **Position Tracking**: Accurate line and column tracking for better error reporting
- **Unicode Support**: Proper handling of surrogate pairs and multi-byte characters
- **Flexible Character Handling**: Peek, advance, and expect specific characters or strings
- **Whitespace Management**: Skip whitespace while preserving significant newlines
- **String View Integration**: Efficient string processing using MoonBit's string views
- **Error Reporting**: Detailed error messages with position information

## Installation

```bash
moon add bobzhang/lexer
```

## Types

### Position

The `Position` struct tracks location information in the input:

```moonbit nocheck
///|
#valtype
pub(all) struct Position {
  line : Int
  column : Int
} derive(Eq, Debug)
```

### Lexer

The main lexer struct maintains state and position:

- `input: String` - The input text being lexed
- `position: Int` - Current byte position in input  
- `line: Int` - Current line number (1-based)
- `column: Int` - Current column position (1-based)

## Quick Start

```moonbit check
///|
test "quick start example" {
  let lexer = Lexer::new("key = value")

  // Peek at current character without advancing
  match lexer.peek() {
    Some('k') => inspect("Found 'k'", content="Found 'k'")
    _ => ()
  }

  // Advance through characters
  lexer.advance() // moves to 'e'
  lexer.advance() // moves to 'y'
  lexer.advance() // moves to ' '

  // Skip whitespace
  lexer.skip_whitespace() // skips spaces, tabs, carriage returns

  // Expect specific characters or strings
  lexer.expect_char('=') // advances if '=' is found, otherwise raises error
  lexer.skip_whitespace()
  lexer.expect_string("value") // expects and consumes "value"

  // Get current position for error reporting
  let pos = lexer.get_loc() // returns Position { line: 1, column: 12 }
  inspect(pos.line, content="1")
  inspect(pos.column, content="12")
}
```

## Basic Usage

### Creating a Lexer

```moonbit check
///|
test "creating a lexer" {
  let lexer = Lexer::new("key = value")
  inspect(lexer.get_position(), content="0")
  inspect(lexer.get_loc().line, content="1")
  inspect(lexer.get_loc().column, content="1")
}
```

### Position Tracking

```moonbit check
///|
test "position tracking example" {
  let lexer = Lexer::new("hello\nworld")
  inspect(lexer.get_loc().line, content="1")
  inspect(lexer.get_loc().column, content="1")

  // Advance through characters
  lexer.advance() // h
  inspect(lexer.get_loc().column, content="2")

  // Handle newlines explicitly
  lexer.advance() // move past \n
  lexer.new_line() // update line tracking
  inspect(lexer.get_loc().line, content="2")
  inspect(lexer.get_loc().column, content="1")
}
```

## API Reference

### Methods

#### Creation
- `Lexer::new(input : String) -> Lexer` - Create a new lexer with the given input

#### Character Operations
- `peek() -> Char?` - Get current character without advancing
- `advance() -> Unit` - Advance to next character (handles Unicode properly)
- `expect_char(ch : Char, msg? : String) -> Unit raise` - Expect and consume a specific character

#### String Operations
- `expect_string(str : String, msg? : String) -> Unit raise` - Expect and consume a specific string
- `view() -> StringView` - Get a view of the remaining input
- `update_view(view : StringView) -> Unit` - Update position based on a new view

#### Whitespace Handling
- `skip_whitespace() -> Unit` - Skip spaces, tabs, and carriage returns (not newlines)
- `skip_single_newline() -> Unit` - Skip a single newline and update line tracking

#### Position Tracking
- `get_loc() -> Position` - Get current line and column position
- `get_position() -> Int` - Get current byte position in input
- `new_line() -> Unit` - Explicitly advance to new line (updates line/column tracking)

#### Error Handling
- `error(msg : String) -> String` - Create detailed error message with position info

## Core Methods

```moonbit check
///|
test "core methods example" {
  let lexer = Lexer::new("hello\nworld")
  inspect(lexer.get_loc().line, content="1")
  inspect(lexer.get_loc().column, content="1")

  // Advance through characters
  lexer.advance() // h
  inspect(lexer.get_loc().column, content="2")

  // Handle newlines explicitly
  lexer.advance() // move past \n
  lexer.new_line() // update line tracking
  inspect(lexer.get_loc().line, content="2")
  inspect(lexer.get_loc().column, content="1")
}
```

## Core Methods

### Character Access

```moonbit check
///|
test "character access example" {
  let lexer = Lexer::new("Hello")
  inspect(lexer.peek(), content="Some('H')")
  lexer.advance()
  inspect(lexer.peek(), content="Some('e')")
}
```

### String Views

The lexer integrates with MoonBit's string views for efficient processing:

```moonbit check
///|
test "string views example" {
  let lexer = Lexer::new("😈x中world!")
  match lexer.view() {
    [.. "😈x", .. rest] => lexer.update_view(rest)
    _ => ()
  }
  inspect(lexer.peek(), content="Some('中')")
}
```

### Whitespace Handling

```moonbit check
///|
test "whitespace handling example" {
  let lexer = Lexer::new("  \t\rHello, world!")
  lexer.skip_whitespace()
  inspect(lexer.peek(), content="Some('H')")
}
```

### Expectations and Error Handling

The lexer provides methods to expect specific characters or strings:

```moonbit check
///|
test "expectations example" {
  let lexer = Lexer::new("=true")
  // Expect a specific character
  lexer.expect_char('=', msg="Expected equals sign")

  // Expect a string
  lexer.expect_string("true", msg="Expected boolean value")

  // Error messages include precise position information
  let error_msg = lexer.error("Unexpected character")
  inspect(error_msg, content="Unexpected character at line 1, column 6")
}
```

## Advanced Usage

### Unicode Support

The lexer properly handles Unicode characters including surrogate pairs:

```moonbit check
///|
test "unicode support example" {
  let lexer = Lexer::new("😈x")
  inspect(lexer.get_position(), content="0")
  lexer.advance() // Correctly advances past the 2-byte emoji
  inspect(lexer.get_position(), content="2") // 2 bytes for emoji
  inspect(lexer.peek(), content="Some('x')")
}
```

### Position Management

Get current position information:

```moonbit check
///|
test "position management example" {
  let lexer = Lexer::new("test")
  let pos = lexer.get_loc() // Get Position struct
  let offset = lexer.get_position() // Get byte offset
  inspect(pos.line, content="1")
  inspect(pos.column, content="1")
  inspect(offset, content="0")
}
```

### Position-Aware Error Handling

```moonbit check
///|
test "position aware error handling example" {
  let lexer = Lexer::new("abc")
  lexer.advance() // move to 'b'
  lexer.advance() // move to 'c'
  let start_pos = lexer.get_loc()
  let msg = "Invalid identifier at line " + start_pos.line.to_string()
  inspect(msg, content="Invalid identifier at line 1")
}
```

### Custom Lexer Implementation

```moonbit check
///|
test "custom lexer implementation example" {
  let lexer = Lexer::new("a=b")
  let tokens = []

  // Simple tokenization - process each character
  while lexer.peek() is Some(_) {
    lexer.skip_whitespace()
    match lexer.peek() {
      None => ()
      Some('=') => {
        lexer.advance()
        tokens.push("EQUALS")
      }
      Some(c) if c.is_ascii_alphabetic() => {
        let mut identifier = ""
        while lexer.peek() is Some(ch) && ch.is_ascii_alphabetic() {
          identifier = identifier + Char::to_string(ch)
          lexer.advance()
        }
        tokens.push("ID:" + identifier)
      }
      Some(_) => lexer.advance() // skip unknown characters
    }
  }
  inspect(tokens, content="[\"ID:a\", \"EQUALS\", \"ID:b\"]")
}
```

## Example: Basic Parsing

```moonbit check
///|
test "basic parsing example" {
  let lexer = Lexer::new("key = \"value\"")

  // Skip initial whitespace
  lexer.skip_whitespace()

  // Parse key name
  let mut key = ""
  while lexer.peek() is Some(ch) && ch != ' ' {
    key = key + Char::to_string(ch)
    lexer.advance()
  }

  // Skip whitespace and expect equals
  lexer.skip_whitespace()
  lexer.expect_char('=')
  lexer.skip_whitespace()

  // Expect quoted string
  lexer.expect_char('"')
  let mut value = ""
  while lexer.peek() is Some(ch) && ch != '"' {
    value = value + Char::to_string(ch)
    lexer.advance()
  }
  lexer.expect_char('"')
  inspect(key, content="key")
  inspect(value, content="value")
}
```

## License

Apache-2.0
