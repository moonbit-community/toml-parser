# TOML Parser Development Todo

This todo file follows a two-level structure where **first-level tasks** should be completed in order (they have dependencies), while **second-level subtasks** can be tackled in parallel by different agents.

## 1. Core Parser Improvements (🔴 High Priority)

### 1.1 Error Handling & Diagnostics
- [ ] Add line/column tracking to lexer for better error messages
- [ ] Implement `ParseError` type with detailed location information
- [ ] Add error recovery mechanisms for graceful parsing failures
- [ ] Create comprehensive error message templates with examples

### 1.2 String Processing Enhancements  
- [ ] Implement multi-line string support (`"""` syntax)
- [x] ~~Add escape sequence handling in strings (`\n`, `\t`, `\"`, etc.)~~ ✅ **Completed**
- [x] ~~Support literal strings with single quotes~~ ✅ **Completed**
- [x] ~~Add Unicode escape sequences (`\uXXXX`, `\UXXXXXXXX`)~~ ✅ **Completed**

### 1.3 Comments System
- [ ] Implement comment parsing in lexer (ignore `# comment` lines)
- [ ] Handle inline comments (`key = value # comment`)
- [ ] Preserve comments for potential serialization back to TOML
- [ ] Add tests for edge cases with comments in arrays/tables

## 2. Advanced TOML Features (🟡 Medium Priority)

### 2.1 Dotted Key Support
- [x] ~~Implement dotted key notation parsing (`a.b.c = value`)~~ ✅ **Completed**
- [x] ~~Add nested table creation from dotted keys~~ ✅ **Completed**
- [x] ~~Handle conflicts between dotted keys and explicit tables~~ ✅ **Completed**
- [x] ~~Add validation for duplicate key definitions~~ ✅ **Completed**

### 2.2 Table Processing Improvements
- [ ] Enhance table header validation and error messages
- [ ] Implement table redefinition detection and prevention
- [ ] Add support for deeply nested table structures
- [ ] Optimize table lookup performance for large configurations

### 2.3 Array of Tables Enhancements
- [ ] Improve array of tables (`[[section]]`) validation
- [ ] Add support for mixed table array scenarios
- [ ] Implement proper ordering preservation
- [ ] Add comprehensive test cases for edge cases

## 3. Performance & Optimization (🟢 Low Priority)

### 3.1 Lexer Optimizations
- [ ] Implement streaming lexer for large files
- [ ] Add token lookahead caching
- [ ] Optimize string allocation during tokenization
- [ ] Profile and benchmark lexer performance

### 3.2 Parser Optimizations  
- [ ] Implement recursive descent optimizations
- [ ] Add memoization for repeated parsing patterns
- [ ] Optimize table creation and access patterns
- [ ] Memory usage profiling and optimization

### 3.3 Value Processing
- [ ] Optimize TomlValue creation and manipulation
- [ ] Implement lazy evaluation for large structures
- [ ] Add streaming validation for memory efficiency
- [ ] Benchmark against other TOML parsers

## 4. Testing & Quality Assurance (🔴 High Priority)

### 4.1 Test Suite Expansion
- [ ] Add official TOML test suite integration
- [ ] Create property-based testing for edge cases
- [ ] Add performance regression tests
- [ ] Implement fuzz testing for parser robustness

### 4.2 Coverage & Validation
- [ ] Achieve 90%+ code coverage across all modules
- [ ] Add tests for all error conditions
- [ ] Create integration tests with real-world TOML files
- [ ] Add specification compliance validation tests

### 4.3 Documentation Tests
- [ ] Ensure all README examples compile and run
- [ ] Add docstring examples to all public APIs
- [ ] Create comprehensive usage tutorials
- [ ] Add troubleshooting guide for common issues

## 5. API & Developer Experience (🟡 Medium Priority)

### 5.1 API Improvements
- [ ] Add convenience methods for common access patterns
- [ ] Implement builder pattern for complex TOML construction
- [ ] Add serialization support (TOML → String)
- [ ] Create type-safe value extraction methods

### 5.2 Integration Features
- [ ] Add JSON interoperability (TOML ↔ JSON conversion)
- [ ] Implement configuration file watching/reloading
- [ ] Add schema validation capabilities
- [ ] Create CLI tool for TOML validation and conversion

### 5.3 Documentation & Examples
- [ ] Create comprehensive API documentation
- [ ] Add cookbook with common usage patterns
- [ ] Create migration guide from other TOML parsers
- [ ] Add performance comparison benchmarks

## 6. Advanced Features & Future Work (🟢 Low Priority)

### 6.1 Extended Functionality
- [ ] Add TOML v1.1 feature support when available
- [ ] Implement custom date/time format support
- [ ] Add support for environment variable substitution
- [ ] Create plugin system for custom value types

### 6.2 Tooling & Ecosystem
- [ ] Create VS Code extension for TOML syntax highlighting
- [ ] Add language server protocol support
- [ ] Implement formatter/prettifier for TOML files
- [ ] Create integration with popular MoonBit frameworks

### 6.3 Community & Distribution
- [ ] Publish to MoonBit package registry
- [ ] Create contribution guidelines and templates
- [ ] Set up continuous integration/deployment
- [ ] Add security vulnerability scanning

---

## Task Dependencies

**Sequential Dependencies (Complete in Order):**
1. Core Parser Improvements → Advanced TOML Features → API & Developer Experience
2. Testing & Quality Assurance should run parallel to all development
3. Performance & Optimization should come after core functionality is stable

**Parallel Work Opportunities:**
- Multiple agents can work on different subsections (1.1, 1.2, 1.3) simultaneously
- Testing tasks (4.x) can be developed alongside feature tasks (1.x-3.x)
- Documentation and examples can be written while features are being implemented
- Different agents can focus on different modules (lexer, parser, API)

## Current Status
- ✅ Basic TOML parsing with most data types
- ✅ DateTime support (all 4 RFC 3339 types)
- ✅ Table headers and array of tables
- ✅ Inline tables and arrays with homogeneity validation
- ❌ Comments (not implemented)
- ❌ Multi-line strings (not implemented)
- ❌ Dotted key notation (not implemented)
- ❌ Comprehensive error messages with locations
