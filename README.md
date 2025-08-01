# TOML Parser for MoonBit

A lightweight and efficient TOML (Tom's Obvious Minimal Language) parser implementation written in MoonBit.

## Features

- ✅ Parse basic TOML data types: strings, integers, floats, booleans
- ✅ Support for arrays (`[1, 2, 3]`)
- ✅ Support for inline tables (`{key = value, key2 = value2}`)
- ✅ Lexical analysis with proper tokenization
- ✅ Recursive descent parser
- ✅ Error handling with descriptive messages
- ✅ JSON-compatible output format

## Supported TOML Features

### Data Types
- **Strings**: `"Hello, World!"`
- **Integers**: `42`, `-17`
- **Floats**: `3.14`, `-0.01`
- **Booleans**: `true`, `false`
- **Arrays**: `[1, 2, 3]`, `["a", "b", "c"]`
- **Inline Tables**: `{name = "John", age = 30}`

### Basic Syntax
- Key-value pairs: `key = value`
- Comments: `# This is a comment` (planned)
- Multi-line support with proper whitespace handling

## Installation

Add this parser to your MoonBit project:

```bash
moon add username/toml-parser
```

## Quick Start

```moonbit


fn main {
  // Parse a simple TOML string
  let toml_content = "name = \"Alice\"\nage = 25\nenabled = true"  
  match @toml.parse(toml_content) {
    Ok(result) => println("Parsed: " + result.to_string())
    Err(error) => println("Error: " + error)
  }
}
```

## API Reference

### Core Types

```moonbit
/// Represents all possible TOML values
enum TomlValue {
  TomlString(String)
  TomlInteger(Int64) 
  TomlFloat(Double)
  TomlBoolean(Bool)
  TomlArray(Array[TomlValue])
  TomlTable(Map[String, TomlValue])
}

/// Parse result type
typealias ParseResult[T] = Result[T, String]
```

### Main Functions

```moonbit
/// Parse a TOML string into a TomlValue
pub fn parse(input: String) -> ParseResult[TomlValue]

/// Convert TomlValue to string representation
pub fn TomlValue::to_string(self: TomlValue) -> String
```

### Lexer & Parser

```moonbit
/// Create a new lexer instance
pub fn Lexer::new(input: String) -> Lexer

/// Create a new parser instance  
pub fn Parser::new(tokens: Array[Token]) -> Parser
```

## Examples

### Basic Key-Value Pairs

```moonbit
let toml = "
title = \"My Application\"
version = \"1.0.0\"
debug = true
max_connections = 100
"

match parse(toml) {
  Ok(TomlTable(table)) => {
    // Access parsed values
    println(table["title"])  // Output: "My Application"
  }
  Err(msg) => println("Parse error: " + msg)
}
```

### Arrays

```moonbit
let toml = "numbers = [1, 2, 3, 4, 5]"
match parse(toml) {
  Ok(result) => println(result.to_string())
  Err(msg) => println("Error: " + msg)
}
```

### Inline Tables

```moonbit
let toml = "database = {server = \"localhost\", port = 5432}"
match parse(toml) {
  Ok(result) => println(result.to_string())
  Err(msg) => println("Error: " + msg)
}
```

## Project Structure

```
src/
├── lib/
│   ├── toml.mbt           # Core types and API
│   ├── lexer.mbt          # Tokenization logic
│   ├── parser.mbt         # Parsing logic
│   ├── *_test.mbt         # Test files
│   └── moon.pkg.json      # Package configuration
└── main/
    ├── main.mbt           # Demo application
    └── moon.pkg.json      # Main package configuration
```

## Development

### Running Tests

```bash
moon test
```

### Running the Demo

```bash
moon run src/main
```

### Building

```bash
moon build
```

## Roadmap

- [ ] Support for table headers `[section]`
- [ ] Support for array of tables `[[section]]`
- [ ] Multi-line strings
- [ ] Comments handling
- [ ] Date and time types
- [ ] Dotted key notation
- [ ] Better error messages with line/column information

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass with `moon test`
5. Submit a pull request

## License

Apache-2.0 License. See [LICENSE](LICENSE) for details.

## References

- [TOML Specification](https://toml.io/en/)
- [MoonBit Language Guide](https://www.moonbitlang.com/docs/)