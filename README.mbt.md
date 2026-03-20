# TOML Parser for MoonBit

A lightweight and efficient TOML parser written in MoonBit with TOML 1.1 support and **98.8% compliance** against the official [toml-test](https://github.com/toml-lang/toml-test) suite (736/745 tests pass, 262/262 valid tests at 100%).

## Features

- ✅ **TOML 1.1 Support** - Full TOML 1.0 + 1.1 features (optional seconds, inline table newlines, `\xHH` escapes)
- ✅ **100% Valid Test Compliance** - Every valid TOML document parses correctly (262/262)
- ✅ **All Data Types** - Strings, integers, floats, booleans, arrays, tables, and datetimes
- ✅ **Multiline Strings** - Basic (`"""..."""`) and literal (`'''...'''`) with consecutive quote support
- ✅ **Inline Tables** - With TOML 1.1 newlines and trailing commas
- ✅ **Dotted Key Notation** - Create nested structures easily (`a.b.c = value`)
- ✅ **Comprehensive Escape Sequences** - `\n`, `\t`, `\"`, `\\`, `\uXXXX`, `\UXXXXXXXX`, `\xHH`, `\e`
- ✅ **RFC 3339 DateTime Support** - All 4 datetime types with semantic validation (leap years, ranges)
- ✅ **Table Headers** - `[section]`, `[section.subsection]`, with duplicate detection
- ✅ **Array of Tables** - `[[section]]` with subtable reopening support
- ✅ **Validation** - Control characters, duplicate keys, inline table immutability, number formats
- ✅ **Special Float Values** - `inf`, `-inf`, `nan`, `+` prefix, exponent notation
- ✅ **Unicode Support** - International characters in keys and values
- ✅ **Precise Error Reporting** - Line and column information for all parse errors

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
moon add bobzhang/toml
```

Then add it directly to your `moon.mod.json`:

```json
{
  "deps": {
    "bobzhang/toml": "^0.2.0"
  }
}
```

## Quick Start

Parse a simple TOML string:

```mbt check
///|
test {
  // Quick start example - parsing and accessing values
  let config = @toml.parse(
    (
      #|title = "My App"
      #|version = "1.0.0"
      #|[database]
      #|host = "localhost"
      #|port = 5432
      #|
    ),
  )

  // Access values using nested pattern matching with literal values
  guard config
    is TomlTable(
      {
        "title": TomlString("My App"),
        "version": TomlString("1.0.0"),
        "database": TomlTable(
          { "host": TomlString("localhost"), "port": TomlInteger(5432L), .. }
        ),
        ..
      }
    ) else {
    fail("Expected config with title, version, and database")
  }
}
```

## API Reference

### Core Functions

**Parsing**:

- `parse(input : String) -> TomlValue raise` - Parse TOML string and return structured data. Raises errors with location information on invalid syntax.

**Validation**:

- `TomlValue::validate(self : TomlValue) -> Bool` - Validate parsed TOML structure for correctness (array homogeneity, etc.)

**Conversion**:

- `TomlValue::to_string(self : TomlValue) -> String` - Convert TomlValue back to a human-readable string representation

### TomlValue - The Core Data Type

`TomlValue` is the central enum type representing all possible TOML values. It is defined as:

```moonbit no-check
///|
pub(all) enum TomlValue {
  TomlString(String)
  TomlInteger(Int64)
  TomlFloat(Double)
  TomlBoolean(Bool)
  TomlArray(Array[TomlValue])
  TomlTable(Map[String, TomlValue])
  TomlDateTime(TomlDateTime)
} derive(Eq, ToJson)
```

You can construct `TomlValue` directly in code:

```mbt check
///|
test {
  // Constructing TomlValue programmatically
  let table : Map[String, @toml.TomlValue] = {
    "name": @toml.TomlString("Alice"),
    "age": @toml.TomlInteger(30L),
    "active": @toml.TomlBoolean(true),
    "scores": @toml.TomlArray([
      @toml.TomlInteger(95L),
      @toml.TomlInteger(87L),
      @toml.TomlInteger(92L),
    ]),
  }
  let value = @toml.TomlTable(table)

  // Validate and convert back to TOML string
  assert_true(value.validate())
  inspect(
    value.to_string(),
    content=(
      #|name = "Alice"
      #|age = 30
      #|active = true
      #|
      #|scores = [95, 87, 92]
      #|
    ),
  )
}
```

#### Variant Summary

| Variant                             | Description            | Example                      |
| ----------------------------------- | ---------------------- | ---------------------------- |
| `TomlString(String)`                | String values          | `"Hello World"`              |
| `TomlInteger(Int64)`                | 64-bit integers        | `42`, `-17`                  |
| `TomlFloat(Double)`                 | Floating-point numbers | `3.14`, `inf`, `-inf`, `nan` |
| `TomlBoolean(Bool)`                 | Boolean values         | `true`, `false`              |
| `TomlArray(Array[TomlValue])`       | Homogeneous arrays     | `[1, 2, 3]`                  |
| `TomlTable(Map[String, TomlValue])` | Key-value tables       | `{key = value}`              |
| `TomlDateTime(TomlDateTime)`        | RFC 3339 datetimes     | See below                    |

#### DateTime Variants

The `TomlDateTime` enum supports all 4 RFC 3339 datetime types:

- `OffsetDateTime` - With timezone (e.g., `1979-05-27T07:32:00Z`)
- `LocalDateTime` - Without timezone (e.g., `1979-05-27T07:32:00`)
- `LocalDate` - Date only (e.g., `1979-05-27`)
- `LocalTime` - Time only (e.g., `07:32:00`)

### Error Handling

The `parse` function uses MoonBit's checked exceptions. Handle errors using `try-catch` or `try?`:

```mbt check
///|
test {
  // Error handling with try-catch
  let invalid_toml = "invalid = [unclosed"
  let config = @toml.parse(invalid_toml) catch {
    _ => @toml.TomlTable(Map::new()) // Return default value on error
  }
  guard config is TomlTable(table) else { fail("Expected table") }
  assert_eq(table.length(), 0) // Empty table from error handler

  // Error handling with try? - converts to Result type
  let result = try? @toml.parse("key = \"value\"")
  guard result is Ok(TomlTable({ "key": _, .. })) else {
    fail("Should have parsed successfully with key")
  }

  // Parsing error example
  let bad_result = try? @toml.parse("bad syntax here")
  assert_true(bad_result is Err(_))
}
```

Errors include precise location information (line and column numbers) to help diagnose issues.

### Special Features

- **Special Float Values**: Support for `inf`, `-inf`, `nan` per TOML spec
- **Comments**: Full support for `# comment` syntax (line comments only)
- **Unicode Keys**: International character support in keys (e.g., `"café" = "coffee"`)
- **Escape Sequences**: Complete escape support: `\n`, `\t`, `\"`, `\\`, `\uXXXX`, `\UXXXXXXXX`
- **Error Location Tracking**: Precise line/column error reporting for debugging

## Examples

### Basic Key-Value Pairs

```mbt check
///|
test {
  // basic key-value pairs example
  let toml =
    #|title = "My Application"
    #|version = "1.0.0"
    #|debug = true
    #|max_connections = 100
    #|
  json_inspect(@toml.parse(toml), content=[
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

```mbt check
///|
test {
  // arrays with validation example
  let toml_arrays =
    #|numbers = [1, 2, 3, 4, 5]
    #|strings = ["red", "green", "blue"]
    #|booleans = [true, false, true]
    #|
  json_inspect(@toml.parse(toml_arrays), content=[
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
        [["TomlString", "red"], ["TomlString", "green"], ["TomlString", "blue"]],
      ],
      "booleans": [
        "TomlArray",
        [["TomlBoolean", true], ["TomlBoolean", false], ["TomlBoolean", true]],
      ],
    },
  ])
}
```

### Table Headers and Array of Tables

```mbt check
///|
test {
  // table headers and array of tables example
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
  json_inspect(@toml.parse(toml_tables), content=[
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

```mbt check
///|
test {
  // datetime support example
  let toml_datetime =
    #|created_at = 2023-01-01T00:00:00Z
    #|updated_at = 2023-01-02T12:30:45
    #|birth_date = 1990-05-15
    #|meeting_time = 14:30:00
    #|
  json_inspect(@toml.parse(toml_datetime), content=[
    "TomlTable",
    {
      "created_at": ["TomlDateTime", ["OffsetDateTime", "2023-01-01T00:00:00Z"]],
      "updated_at": ["TomlDateTime", ["LocalDateTime", "2023-01-02T12:30:45"]],
      "birth_date": ["TomlDateTime", ["LocalDate", "1990-05-15"]],
      "meeting_time": ["TomlDateTime", ["LocalTime", "14:30:00"]],
    },
  ])
}
```

<!-- TODO(upstream): fmt works for mbt.md -->

### Inline Tables

```mbt check
///|
test {
  // inline tables example
  let toml_inline =
    #|database = {server = "localhost", port = 5432}
    #|cache = {enabled = true, ttl = 300}
    #|
  json_inspect(@toml.parse(toml_inline), content=[
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
        { "enabled": ["TomlBoolean", true], "ttl": ["TomlInteger", "300"] },
      ],
    },
  ])
}
```

### Complex Configuration

```mbt check
///|
test {
  // complex configuration example
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
  let result = @toml.parse(config)
  assert_true(result.validate())
  // Verify the structure contains expected keys
  guard result
    is TomlTable(
      {
        "service_name": _,
        "http": TomlTable({ "port": TomlInteger(_), .. }),
        "database": _,
        "maintenance_schedule": _,
        ..
      }
    ) else {
    fail("Expected table")
  }
}
```

### Special Values and Advanced Features

```mbt check
///|
test {
  // special values and advanced features example
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
  json_inspect(@toml.parse(toml_advanced), content=[
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
toml-parser/
├── toml.mbt                              # Core TOML types and API
├── parser.mbt                            # TOML parsing logic
├── moon.mod.json                         # Project configuration
├── moon.pkg.json                         # Package configuration
├── LICENSE                               # Apache-2.0 license
├── README.mbt.md                         # Documentation with executable examples
├── todo.md                               # Development roadmap
│
├── internal/                             # Internal modules
│   └── tokenize/                         # Tokenization and lexical analysis
│       ├── tokenize.mbt                  # Main tokenizer implementation
│       ├── token.mbt                     # Token definitions
│       ├── lexer_test.mbt                # Lexer unit tests
│       ├── lexer_bug_test.mbt            # Lexer regression tests
│       └── moon.pkg.json                 # Tokenizer package config
│
├── cmd/                                  # Command-line tools and demos
│   └── main/                             # Demo application
│       ├── main.mbt                      # Interactive TOML parser demo
│       ├── main_test.mbt                 # Demo tests
│       └── moon.pkg.json                 # Main package config
│
├── Test Suite (8000+ lines of tests)    # Comprehensive testing
├── ├── toml_test.mbt                     # Basic TOML functionality tests
├── ├── parser_test.mbt                   # Parser-specific tests
├── ├── datetime_test.mbt                 # DateTime parsing tests
├── ├── datetime_extended_test.mbt        # Extended datetime scenarios
├── ├── comprehensive_test.mbt            # Complex real-world scenarios
├── ├── coverage_improvement_test.mbt     # Coverage enhancement tests
├── ├── coverage_improvement_comprehensive_test.mbt # Advanced coverage tests
├── ├── official_toml_test_suite_test.mbt # Official TOML spec compliance
├── ├── additional_official_tests_test.mbt # Extended official tests
├── └── special_value_validation_test.mbt # Special values (inf, nan) tests
│
└── target/                               # Build artifacts (generated)
    ├── wasm-gc/                          # WebAssembly build outputs
    └── packages.json                     # Package dependency info
```

### Key Components

- **Core Parser** (`toml.mbt`, `parser.mbt`) - Main TOML parsing implementation with full TOML 1.0 specification support, recursive descent parser with error recovery
- **Tokenizer** (`internal/tokenize/`) - Lexical analysis and tokenization engine supporting all TOML tokens including special float values (inf, nan)
- **Utilities** (`toml_utils.mbt`) - Helper functions for table creation, dotted key handling, and nested structure management
- **Demo Application** (`cmd/main/`) - Interactive command-line examples demonstrating parser capabilities
- **Comprehensive Test Suite** (8000+ lines) - Extensive coverage including:
  - Unit tests for all data types and features
  - Official TOML specification compliance tests
  - Edge case and boundary value tests
  - Real-world configuration file examples
- **Executable Documentation** (`README.mbt.md`) - This file contains runnable MoonBit code examples that are automatically tested

## Usage Tips

### Working with Tables

```mbt check
///|
test {
  // Working with nested tables
  let parsed_toml = @toml.parse(
    (
      #|[database]
      #|host = "localhost"
      #|port = 5432
      #|enabled = true
      #|
    ),
  )

  // Use guard with nested pattern matching and literal values
  guard parsed_toml
    is TomlTable(
      {
        "database": TomlTable(
          {
            "host": TomlString("localhost"),
            "port": TomlInteger(5432L),
            "enabled": TomlBoolean(true),
            ..
          }
        ),
        ..
      }
    ) else {
    fail(
      "Expected database configuration with host=localhost, port=5432, enabled=true",
    )
  }
}
```

### Validating Arrays

TOML requires arrays to be homogeneous (all elements same type). The parser validates this automatically:

```mbt check
///|
test {
  // Valid: all integers
  let valid = @toml.parse("numbers = [1, 2, 3]")
  assert_true(valid.validate())

  // Mixed types are allowed during parsing but fail validation
  let mixed = @toml.parse("mixed = [1, \"two\", 3.0]")
  assert_false(mixed.validate()) // Validation catches the type mismatch
}
```

### Working with DateTime Values

```mbt check
///|
test {
  // Working with all 4 datetime types
  let parsed_toml = @toml.parse(
    (
      #|offset_dt = 2023-01-15T10:30:00Z
      #|local_dt = 2023-01-15T10:30:00
      #|local_date = 2023-01-15
      #|local_time = 10:30:00
      #|
    ),
  )

  // Verify all datetime types are parsed correctly
  json_inspect(parsed_toml, content=[
    "TomlTable",
    {
      "offset_dt": ["TomlDateTime", ["OffsetDateTime", "2023-01-15T10:30:00Z"]],
      "local_dt": ["TomlDateTime", ["LocalDateTime", "2023-01-15T10:30:00"]],
      "local_date": ["TomlDateTime", ["LocalDate", "2023-01-15"]],
      "local_time": ["TomlDateTime", ["LocalTime", "10:30:00"]],
    },
  ])
}
```

## Development Status

**Current Release**: v0.2.0
**Repository**: https://github.com/moonbit-community/toml-parser
**Status**: Production-ready with TOML 1.1 support

### toml-test Compliance

| Suite | Passed | Total | Rate |
|-------|--------|-------|------|
| Valid | 262 | 262 | **100%** |
| Invalid | 474 | 483 | 98.1% |
| **Total** | **736** | **745** | **98.8%** |

The 9 remaining invalid "failures" are TOML 1.0-only restrictions for features we intentionally support (TOML 1.1: optional seconds, inline table newlines/trailing commas, `\xHH` escapes).

### Running Tests

```bash
moon test                              # unit tests (224 tests)
moon test e2e -v --target native       # e2e toml-test suite (745 tests)
```

### Running the Demo

```bash
moon run cmd/main
```

### Building

```bash
moon build
```

## Common Pitfalls and Best Practices

### ✅ DO:

1. **Always validate after parsing**:

   ```moonbit nocheck
   let toml = @toml.parse(input)
   assert_true(toml.validate())  // Ensures data integrity
   ```

2. **Use pattern matching for type safety**:

   ```moonbit nocheck
   match config {
     TomlTable(table) => {
       match table.get("port") {
         Some(TomlInteger(port)) => use_port(port)
         _ => use_default_port()
       }
     }
     _ => ()
   }
   ```

3. **Handle errors appropriately**:
   ```moonbit nocheck
   ///|
   let config = @toml.parse(file_content) catch {
     err => {
       logger.error("Config parse failed: \{err}")
       load_default_config()
     }
   }
   ```

### ❌ DON'T:

1. **Don't mix types in arrays** - TOML requires homogeneous arrays:

   ```toml
   # ❌ Invalid
   mixed = [1, "two", 3.0]

   # ✅ Valid
   integers = [1, 2, 3]
   strings = ["one", "two", "three"]
   ```

2. **Don't redefine keys** - Each key must be unique within its scope:

   ```toml
   # ❌ Invalid
   name = "foo"
   name = "bar"  # Error: key redefined

   # ✅ Valid
   first_name = "foo"
   last_name = "bar"
   ```

3. **Don't confuse table types**:

   ```toml
   # ❌ Invalid - can't mix inline and standard tables
   [server]
   host = "localhost"
   server.port = 8080  # Error: server already defined as table

   # ✅ Valid - use dotted keys before table header
   server.host = "localhost"
   server.port = 8080
   ```

## TOML Specification Compliance

This parser implements the complete TOML 1.0 specification plus TOML 1.1 features:

- ✅ **All basic data types** (strings, integers, floats, booleans)
- ✅ **Complete datetime support** with semantic validation (leap years, ranges)
- ✅ **Multiline strings** — basic and literal, with consecutive quote support
- ✅ **Inline tables** with TOML 1.1 newlines and trailing commas
- ✅ **Number validation** — underscore placement, leading zeros, exponent format
- ✅ **Control character rejection** in strings and comments
- ✅ **Duplicate key detection** and inline table immutability
- ✅ **Table redefinition prevention** and dotted-key scope tracking
- ✅ **`\xHH` hex escapes** and **`\e` ESC escape** (TOML 1.1)
- ✅ **Optional seconds** in datetime values (TOML 1.1)
- ✅ **98.8% toml-test compliance** — 262/262 valid, 474/483 invalid

## Roadmap

All planned features are complete:

- [x] Table headers `[section]` and `[section.subsection]`
- [x] Array of tables `[[section]]` with subtable reopening
- [x] All 4 RFC 3339 datetime types with semantic validation
- [x] Dotted key notation with duplicate detection
- [x] Multiline basic and literal strings
- [x] Complete escape sequences including `\xHH` and `\e` (TOML 1.1)
- [x] Special float values (inf, nan) and exponent notation
- [x] Comments handling
- [x] Inline table newlines and trailing commas (TOML 1.1)
- [x] Optional seconds in datetime (TOML 1.1)
- [x] Control character validation
- [x] Inline table and static array immutability
- [x] 98.8% toml-test compliance (262/262 valid, 474/483 invalid)

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
