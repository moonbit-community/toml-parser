# TOML Parser for MoonBit

A lightweight and efficient TOML (Tom's Obvious Minimal Language) parser implementation written in MoonBit with full TOML 1.0 specification compliance.

## Features

- ✅ Parse basic TOML data types: strings, integers, floats, booleans
- ✅ Support for arrays with homogeneity validation (`[1, 2, 3]`)
- ✅ Support for inline tables (`{key = value, key2 = value2}`)
- ✅ **Dotted key notation** (`a.b.c = value` creates nested tables)
- ✅ **Escape sequence handling** (`\n`, `\t`, `\"`, `\\`, `\uXXXX`, `\UXXXXXXXX`)
- ✅ **Full datetime support** (RFC 3339 compliant)
- ✅ **Table headers** (`[section]` and `[section.subsection]`)
- ✅ **Array of tables** (`[[section]]` syntax)
- ✅ TOML 1.0 specification compliance validation
- ✅ Lexical analysis with proper tokenization
- ✅ Recursive descent parser
- ✅ Error handling with descriptive messages and location tracking
- ✅ JSON-compatible output format
- ✅ Comprehensive test suite (270+ tests)

## Supported TOML Features

### Data Types
- **Strings**: `"Hello, World!"` with full escape sequence support
- **Integers**: `42`, `-17`
- **Floats**: `3.14`, `-0.01`
- **Booleans**: `true`, `false`
- **Arrays**: `[1, 2, 3]`, `["a", "b", "c"]` (homogeneous types only)
- **Inline Tables**: `{name = "John", age = 30}`
- **Date & Time Types**:
  - **Offset Date-Time**: `1979-05-27T07:32:00Z`, `1979-05-27T07:32:00+01:00`
  - **Local Date-Time**: `1979-05-27T07:32:00`
  - **Local Date**: `1979-05-27`
  - **Local Time**: `07:32:00`

### Tables and Structure
- **Table headers**: `[section]`, `[section.subsection]`
- **Array of tables**: `[[products]]` for repeated table structures
- **Nested table access**: Full dotted path support

### Basic Syntax
- Key-value pairs: `key = value`
- Dotted key notation: `a.b.c = value` (creates nested tables)
- Comments: `# This is a comment` (planned)
- Multi-line support with proper whitespace handling
- TOML 1.0 specification compliance

### Escape Sequences
- **Basic Escapes**: `\n` (newline), `\t` (tab), `\r` (carriage return)
- **Quote Escapes**: `\"` (double quote), `\'` (single quote), `\\` (backslash)
- **Control Characters**: `\b` (backspace), `\f` (form feed)
- **Unicode Escapes**: `\uXXXX` (4-digit hex), `\UXXXXXXXX` (8-digit hex)
- **Line Continuation**: `\` at end of line in multiline strings

## Installation

Add this parser to your MoonBit project:

```bash
moon add bob/toml
```

Then add it directly to your `moon.mod.json`:
```json
{
  "deps": {
    "bob/toml": "^0.1.3"
  }
}
```

## API Reference


## Examples

### Basic Key-Value Pairs

```moonbit
test "basic key-value pairs example" {
  let toml = "title = \"My Application\"\nversion = \"1.0.0\"\ndebug = true\nmax_connections = 100"
  try {
    let result = parse(toml)
    match result {
      TomlTable(table) => {
        // Access parsed values
        match table.get("title") {
          Some(TomlString(s)) => println("Title: \{s}")
          _ => println("Title not found")
        }
      }
      _ => println("Expected table")
    }
  } catch {
    msg => println("Parse error: \{msg}")
  }
}
```

### Arrays with Validation

```moonbit
test "arrays with validation example" {
  let toml_arrays = "numbers = [1, 2, 3, 4, 5]"
  try {
    let result = parse(toml_arrays)
    if result.validate() {
      println("Valid TOML: \{result}")
    } else {
      println("Invalid TOML structure")
    }
  } catch {
    msg => println("Error: \{msg}")
  }
}
```

### Table Headers and Array of Tables

```moonbit
test "table headers and array of tables example" {
  let toml_tables = "title = \"Configuration Example\"\n\n[database]\nserver = \"192.168.1.1\"\nport = 5432\n\n[[products]]\nname = \"Hammer\"\nsku = 738594937\n\n[[products]]\nname = \"Nail\"\nsku = 284758393"
  try {
    let result = parse(toml_tables)
    match result {
      TomlTable(table) => {
        // Access nested table
        match table.get("database") {
          Some(db) => ignore(db)
          None => ()
        }
        // Access array of tables
        match table.get("products") {
          Some(products) => ignore(products)
          None => ()
        }
        println("Parsed complex TOML structure")
      }
      _ => println("Expected table")
    }
  } catch {
    msg => println("Parse error: \{msg}")
  }
}
```

### DateTime Support

```moonbit
test "datetime support example" {
  let toml_datetime = "created_at = 2023-01-01T00:00:00Z\nupdated_at = 2023-01-02T12:30:45\nbirth_date = 1990-05-15\nmeeting_time = 14:30:00"
  try {
    let result = parse(toml_datetime)
    match result {
      TomlTable(table) => {
        match table.get("created_at") {
          Some(TomlDateTime(OffsetDateTime(dt))) => 
            println("Created at: \{dt}")
          _ => println("Invalid datetime")
        }
      }
      _ => println("Expected table")
    }
  } catch {
    msg => println("Parse error: \{msg}")
  }
}
```

### Inline Tables

```moonbit
test "inline tables example" {
  let toml_inline = "database = {server = \"localhost\", port = 5432}"
  try {
    let result = parse(toml_inline)
    println(result.to_string())
  } catch {
    msg => println("Error: \{msg}")
  }
}
```

### Complex Configuration

```moonbit
test "complex configuration example" {
  let config = "service_name = \"user-service\"\nversion = \"2.1.0\"\ndeployed_at = 2023-06-15T14:30:00+00:00\n\nhttp = {port = 8080, host = \"0.0.0.0\", timeout = 30.0}\ndatabase = {url = \"postgresql://localhost:5432/users\", max_connections = 20}\n\nmaintenance_schedule = [\n  2023-06-20T02:00:00,\n  2023-07-20T02:00:00,\n  2023-08-20T02:00:00\n]"
  try {
    let result = parse(config)
    if result.validate() {
      println("Valid microservice configuration")
      println(result.to_string())
    }
  } catch {
    msg => println("Configuration error: \{msg}")
  }
}
```

## Project Structure

```
src/
├── toml.mbt              # Core types and API
├── lexer.mbt             # Tokenization logic
├── parser.mbt            # Parsing logic
├── toml_test.mbt         # Basic functionality tests
├── datetime_test.mbt     # Comprehensive datetime tests
├── parser_test.mbt       # Parser-specific tests
├── lexer_test.mbt        # Lexer-specific tests
├── comprehensive_test.mbt # Complex scenarios tests
├── moon.pkg.json         # Package configuration
└── main/
    ├── main.mbt          # Demo application
    └── moon.pkg.json     # Main package configuration
```

## Development Status

**Current Release**: v0.1.3 (Stable)  
**Active Development Branch**: `hongbo/fix_mulltipleline_string`  
**Status**: Actively developed with focus on multi-line string support and enhanced error reporting

### Recent Improvements
- ✅ Enhanced error location tracking in lexer and parser
- ✅ Comprehensive test suite expansion (260+ tests)  
- ✅ Official TOML test suite integration
- ✅ Unicode key support and complex escape sequences
- 🚧 Multi-line string parsing (in progress)

### Running Tests

```bash
moon test
```

Current test coverage: **260 tests** covering:
- Basic TOML data types
- DateTime functionality (all 4 types)
- Array homogeneity validation
- TOML 1.0 specification compliance
- Edge cases and real-world scenarios
- Error handling with location tracking
- Official TOML test suite integration
- Unicode key support and escape sequences
- Complex nested structures

### Running the Demo

```bash
moon run cmd/main
```

### Building

```bash
moon build
```

## TOML 1.0 Specification Compliance

This parser implements the complete TOML 1.0 specification including:

- ✅ **All basic data types** (strings, integers, floats, booleans)
- ✅ **Complete datetime support** (4 types: offset datetime, local datetime, local date, local time)
- ✅ **Array homogeneity validation** (arrays must contain single type)
- ✅ **Inline tables** with proper nesting
- ✅ **RFC 3339 datetime format** compliance
- ✅ **Recursive validation** for complex structures
- ✅ **Enhanced error reporting** with line/column location tracking
- ✅ **Unicode key support** for international characters
- ✅ **Comprehensive test coverage** with official TOML test suite integration

## Roadmap

- [x] ~~Support for table headers `[section]`~~ ✅ **Completed**
- [x] ~~Support for array of tables `[[section]]`~~ ✅ **Completed**
- [x] ~~Date and time types~~ ✅ **Completed**
- [x] ~~Better error messages with line/column information~~ ✅ **Completed**
- [x] ~~Dotted key notation~~ ✅ **Completed**
- [x] ~~Escape sequence handling in strings~~ ✅ **Completed**
- [ ] Multi-line strings (🚧 **In Progress**)
- [ ] Comments handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass with `moon test`
5. Submit a pull request

All contributions should maintain TOML 1.0 specification compliance and include comprehensive tests.

## License

Apache-2.0 License. See [LICENSE](LICENSE) for details.

## References

- [TOML Specification](https://toml.io/en/)
- [RFC 3339 (Date and Time on the Internet)](https://tools.ietf.org/html/rfc3339)
- [MoonBit Language Guide](https://www.moonbitlang.com/docs/)