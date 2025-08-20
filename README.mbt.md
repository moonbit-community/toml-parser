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
- ✅ Comprehensive test suite (8000+ lines of test code)

## Supported TOML Features

### Data Types
- **Strings**: `"Hello, World!"` with full escape sequence support
- **Integers**: `42`, `-17`
- **Floats**: `3.14`, `-0.01`, `inf`, `-inf`, `nan`
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
- Comments: `# This is a comment` (✅ **Supported**)
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
    "bob/toml": "^0.1.4"
  }
}
```

## API Reference

### Core Functions

The main parsing function:
- `parse(input : String) -> TomlValue raise` - Parse TOML string and return TomlValue
- `TomlValue::validate(self : TomlValue) -> Bool` - Validate parsed TOML structure  
- `TomlValue::to_string(self : TomlValue) -> String` - Convert TomlValue to string representation

### Data Types

The parser uses the following data types:
- `TomlString(String)` - String values
- `TomlInteger(Int64)` - Integer values 
- `TomlFloat(Double)` - Float values including special values (inf, nan)
- `TomlBoolean(Bool)` - Boolean values
- `TomlArray(Array[TomlValue])` - Arrays with homogeneity validation
- `TomlTable(Map[String, TomlValue])` - Tables and inline tables
- `TomlDateTime(TomlDateTime)` - All 4 RFC 3339 datetime types

### Special Features

- **Special Float Values**: Support for `inf`, `-inf`, `nan` 
- **Comments**: Full support for `# comment` syntax
- **Unicode Keys**: International character support in keys
- **Escape Sequences**: Complete `\n`, `\t`, `\"`, `\\`, `\uXXXX`, `\UXXXXXXXX` support
- **Error Location Tracking**: Precise line/column error reporting


## Examples

### Basic Key-Value Pairs

```moonbit
test "basic key-value pairs example" {
  let toml = 
    #|title = "My Application"
    #|version = "1.0.0"
    #|debug = true
    #|max_connections = 100
    #|
  @json.inspect(parse(toml), content=[
    "TomlTable",
    {
      "title": ["TomlString", "My Application"],
      "version": ["TomlString", "1.0.0"],
      "debug": ["TomlBoolean", true],
      "max_connections": ["TomlInteger", "100"],
    },
  ])
}
```

### Arrays with Validation

```moonbit
test "arrays with validation example" {
  let toml_arrays = 
    #|numbers = [1, 2, 3, 4, 5]
    #|strings = ["red", "green", "blue"]
    #|booleans = [true, false, true]
    #|
  @json.inspect(parse(toml_arrays), content=[
    "TomlTable",
    {
      "numbers": [
        "TomlArray",
        [
          ["TomlInteger", "1"],
          ["TomlInteger", "2"],
          ["TomlInteger", "3"],
          ["TomlInteger", "4"],
          ["TomlInteger", "5"],
        ],
      ],
      "strings": [
        "TomlArray",
        [
          ["TomlString", "red"],
          ["TomlString", "green"],
          ["TomlString", "blue"],
        ],
      ],
      "booleans": [
        "TomlArray",
        [
          ["TomlBoolean", true],
          ["TomlBoolean", false],
          ["TomlBoolean", true],
        ],
      ],
    },
  ])
}
```

### Table Headers and Array of Tables

```moonbit
test "table headers and array of tables example" {
  let toml_tables = 
    #|title = "Configuration Example"
    #|
    #|[database]
    #|server = "192.168.1.1"
    #|port = 5432
    #|
    #|[[products]]
    #|name = "Hammer"
    #|sku = 738594937
    #|
    #|[[products]]
    #|name = "Nail"
    #|sku = 284758393
    #|
  @json.inspect(parse(toml_tables), content=[
    "TomlTable",
    {
      "title": ["TomlString", "Configuration Example"],
      "database": [
        "TomlTable",
        {
          "server": ["TomlString", "192.168.1.1"],
          "port": ["TomlInteger", "5432"],
        },
      ],
      "products": [
        "TomlArray",
        [
          [
            "TomlTable",
            {
              "name": ["TomlString", "Hammer"],
              "sku": ["TomlInteger", "738594937"],
            },
          ],
          [
            "TomlTable",
            {
              "name": ["TomlString", "Nail"],
              "sku": ["TomlInteger", "284758393"],
            },
          ],
        ],
      ],
    },
  ])
}
```

### DateTime Support

```moonbit
test "datetime support example" {
  let toml_datetime = 
    #|created_at = 2023-01-01T00:00:00Z
    #|updated_at = 2023-01-02T12:30:45
    #|birth_date = 1990-05-15
    #|meeting_time = 14:30:00
    #|
  @json.inspect(parse(toml_datetime), content=[
    "TomlTable",
    {
      "created_at": [
        "TomlDateTime",
        {
          "$tag": "OffsetDateTime",
          "0": {
            "year": 2023,
            "month": 1,
            "day": 1,
            "hour": 0,
            "minute": 0,
            "second": 0,
            "offset_hour": 0,
            "offset_minute": 0,
          },
        },
      ],
      "birth_date": [
        "TomlDateTime",
        {
          "$tag": "LocalDate",
          "0": { "year": 1990, "month": 5, "day": 15 },
        },
      ],
    },
  ])
}
```

### Inline Tables

```moonbit
test "inline tables example" {
  let toml_inline = 
    #|database = {server = "localhost", port = 5432}
    #|cache = {enabled = true, ttl = 300}
    #|
  @json.inspect(parse(toml_inline), content=[
    "TomlTable",
    {
      "database": [
        "TomlTable",
        {
          "server": ["TomlString", "localhost"],
          "port": ["TomlInteger", "5432"],
        },
      ],
      "cache": [
        "TomlTable",
        {
          "enabled": ["TomlBoolean", true],
          "ttl": ["TomlInteger", "300"],
        },
      ],
    },
  ])
}
```

### Complex Configuration

```moonbit
test "complex configuration example" {
  let config = 
    #|service_name = "user-service"
    #|version = "2.1.0"
    #|deployed_at = 2023-06-15T14:30:00+00:00
    #|
    #|# Special float values
    #|timeout = 30.0
    #|max_retry = inf
    #|error_rate = nan
    #|
    #|http = {port = 8080, host = "0.0.0.0", timeout = 30.0}
    #|database = {url = "postgresql://localhost:5432/users", max_connections = 20}
    #|
    #|maintenance_schedule = [
    #|  2023-06-20T02:00:00,
    #|  2023-07-20T02:00:00,
    #|  2023-08-20T02:00:00
    #|]
    #|
  let result = parse(config)
  assert_true(result.validate())
  // Verify the structure contains expected keys
  match result {
    TomlTable(table) => {
      assert_true(table.contains("service_name"))
      assert_true(table.contains("http"))
      assert_true(table.contains("database"))
      assert_true(table.contains("maintenance_schedule"))
    }
    _ => fail("Expected table")
  }
}
```

### Special Values and Advanced Features

```moonbit
test "special values and advanced features example" {
  let toml_advanced = 
    #|# Configuration with comments
    #|app_name = "TOML Demo"
    #|version = "1.0.0"
    #|
    #|# Special float values
    #|max_timeout = inf
    #|min_timeout = -inf
    #|error_rate = nan
    #|
    #|# Unicode keys and values
    #|"café" = "☕ Coffee shop"
    #|"数量" = 42
    #|
    #|# Complex nested structure
    #|[server.database]
    #|host = "localhost"
    #|port = 5432
    #|
    #|[[server.replicas]]
    #|name = "primary"
    #|weight = 1.0
    #|
    #|[[server.replicas]]
    #|name = "secondary"
    #|weight = 0.5
    #|
  @json.inspect(parse(toml_advanced), content=[
    "TomlTable",
    {
      "app_name": ["TomlString", "TOML Demo"],
      "version": ["TomlString", "1.0.0"],
      "max_timeout": ["TomlFloat", @double.infinity],
      "min_timeout": ["TomlFloat", @double.neg_infinity],
      "error_rate": ["TomlFloat", @double.not_a_number],
      "café": ["TomlString", "☕ Coffee shop"],
      "数量": ["TomlInteger", "42"],
      "server": [
        "TomlTable",
        {
          "database": [
            "TomlTable",
            {
              "host": ["TomlString", "localhost"],
              "port": ["TomlInteger", "5432"],
            },
          ],
          "replicas": [
            "TomlArray",
            [
              [
                "TomlTable",
                {
                  "name": ["TomlString", "primary"],
                  "weight": ["TomlFloat", 1],
                },
              ],
              [
                "TomlTable",
                {
                  "name": ["TomlString", "secondary"],
                  "weight": ["TomlFloat", 0.5],
                },
              ],
            ],
          ],
        },
      ],
    },
  ])
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

**Current Release**: v0.1.4 (Stable)  
**Repository**: https://github.com/moonbit-community/toml-parser  
**Status**: Production-ready with comprehensive TOML 1.0 support

### Recent Improvements
- ✅ Enhanced error location tracking in lexer and parser
- ✅ Comprehensive test suite expansion (8000+ lines)  
- ✅ Official TOML test suite integration
- ✅ Unicode key support and complex escape sequences
- ✅ Special float values support (inf, -inf, nan)
- ✅ Advanced string escaping and literal strings
- ✅ Robust table and array of tables implementation

### Running Tests

```bash
moon test
```

Current test coverage: **8000+ lines of test code** covering:
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
- [x] ~~Special float values (inf, nan)~~ ✅ **Completed**
- [x] ~~Comments handling~~ ✅ **Completed**
- [ ] Multi-line strings (🚧 **In Progress**)

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