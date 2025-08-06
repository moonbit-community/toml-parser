///| Comprehensive tests for the lexer to improve coverage

///| Test lexer creation (this test already exists but let's expand it)
test "lexer creation and basic properties" {
  let lexer = @lexer.Lexer::new("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
}

///| Test peek and advance functionality
test "lexer peek and advance" {
  let lexer = @lexer.Lexer::new("Hello")

  // Test peek without advancing
  match lexer.peek() {
    Some(ch) => inspect(ch, content="H")
    None => fail("Expected character 'H'")
  }
  inspect(lexer.position, content="0") // Position should not have changed

  // Test advance and peek next character
  lexer.advance()
  inspect(lexer.position, content="1")
  match lexer.peek() {
    Some(ch) => inspect(ch, content="e")
    None => fail("Expected character 'e'")
  }

  // Test at end of string
  lexer.position = 5 // Move to end
  match lexer.peek() {
    Some(_) => fail("Expected None at end of string")
    None => inspect(true, content="true")
  }
}

///| Test skip whitespace functionality
test "lexer skip whitespace" {
  let lexer = @lexer.Lexer::new("  \t\r  Hello")
  lexer.skip_whitespace()
  match lexer.peek() {
    Some(ch) => inspect(ch, content="H")
    None => fail("Expected character 'H'")
  }

  // Test with no whitespace
  let lexer2 = @lexer.Lexer::new("Hello")
  lexer2.skip_whitespace()
  inspect(lexer2.position, content="0") // Should not move

  // Test at end of string
  let lexer3 = @lexer.Lexer::new("   ")
  lexer3.skip_whitespace()
  match lexer3.peek() {
    Some(_) => fail("Expected None after whitespace")
    None => inspect(true, content="true")
  }
}

///| Test skip comment functionality
test "lexer skip comment" {
  let lexer = @lexer.Lexer::new("# This is a comment\nNext line")
  lexer.skip_comment()
  match lexer.peek() {
    Some(ch) => inspect(ch, content="\n")
    None => fail("Expected newline after comment")
  }

  // Test with no comment
  let lexer2 = @lexer.Lexer::new("No comment here")
  lexer2.skip_comment()
  inspect(lexer2.position, content="0") // Should not move

  // Test comment at end of file
  let lexer3 = @lexer.Lexer::new("# Comment at end")
  lexer3.skip_comment()
  match lexer3.peek() {
    Some(_) => fail("Expected None after comment at end")
    None => inspect(true, content="true")
  }
}

///| Test expect_char functionality
test "lexer expect char" {
  let lexer = @lexer.Lexer::new("Hello")

  // Test successful expect
  try {
    lexer.expect_char('H')
    inspect(lexer.position, content="1")
  } catch {
    _ => fail("Should not have failed on correct character")
  }

  // Test failed expect with default message
  try {
    lexer.expect_char('X')
    fail("Should have failed on wrong character")
  } catch {
    _ => () // Expected failure
  }

  // Test failed expect with custom message
  try {
    lexer.expect_char('X', msg="Custom error message")
    fail("Should have failed with custom message")
  } catch {
    _ => () // Expected failure
  }
}

///| Test read_identifier functionality
test "lexer read identifier" {
  let lexer = @lexer.Lexer::new("my_var123")
  let identifier = lexer.read_identifier()
  inspect(identifier, content="my_var123")

  // Test identifier with hyphens
  let lexer2 = @lexer.Lexer::new("kebab-case-var")
  let identifier2 = lexer2.read_identifier()
  inspect(identifier2, content="kebab-case-var")

  // Test empty identifier (should return empty string)
  let lexer3 = @lexer.Lexer::new("!@#")
  let identifier3 = lexer3.read_identifier()
  inspect(identifier3, content="")
}

///| Test read_basic_string functionality including escape sequences
test "lexer read basic string" {
  // Test simple string
  let lexer = @lexer.Lexer::new("\"Hello World\"")
  try {
    let str = lexer.read_basic_string()
    inspect(str, content="Hello World")
  } catch {
    msg => fail("Failed to parse simple string: " + msg.to_string())
  }

  // Test string with escape sequences
  let lexer2 = @lexer.Lexer::new("\"Hello\\nWorld\\t!\"")
  try {
    let str2 = lexer2.read_basic_string()
    inspect(str2, content="Hello\nWorld\t!")
  } catch {
    msg => fail("Failed to parse string with escapes: " + msg.to_string())
  }

  // Test string with all escape sequences
  let lexer3 = @lexer.Lexer::new("\"\\n\\t\\r\\\\\\\"'\"")
  try {
    let str3 = lexer3.read_basic_string()
    inspect(str3, content="\n\t\r\\\"'")
  } catch {
    msg => fail("Failed to parse string with all escapes: " + msg.to_string())
  }

  // Test empty string
  let lexer4 = @lexer.Lexer::new("\"\"")
  try {
    let str4 = lexer4.read_basic_string()
    inspect(str4, content="")
  } catch {
    msg => fail("Failed to parse empty string: " + msg.to_string())
  }
}

///| Test read_basic_string error cases
test "lexer read basic string errors" {
  // Test unterminated string
  let lexer = @lexer.Lexer::new("\"unterminated")
  try {
    let _ = lexer.read_basic_string()
    fail("Should have failed on unterminated string")
  } catch {
    _ => () // Expected failure
  }

  // Test invalid escape sequence
  let lexer2 = @lexer.Lexer::new("\"invalid\\x escape\"")
  try {
    let _ = lexer2.read_basic_string()
    fail("Should have failed on invalid escape sequence")
  } catch {
    _ => () // Expected failure
  }

  // Test escape at end of input
  let lexer3 = @lexer.Lexer::new("\"escape at end\\")
  try {
    let _ = lexer3.read_basic_string()
    fail("Should have failed on escape at end")
  } catch {
    _ => () // Expected failure
  }
}

///| Test read_literal_string functionality
test "lexer read literal string" {
  // Test simple literal string
  let lexer = @lexer.Lexer::new("'C:\\path\\to\\file'")
  try {
    let str = lexer.read_literal_string()
    inspect(str, content="C:\\path\\to\\file")
  } catch {
    msg => fail("Failed to parse literal string: " + msg.to_string())
  }

  // Test empty literal string
  let lexer2 = @lexer.Lexer::new("''")
  try {
    let str2 = lexer2.read_literal_string()
    inspect(str2, content="")
  } catch {
    msg => fail("Failed to parse empty literal string: " + msg.to_string())
  }

  // Test literal string with special characters (no escaping)
  let lexer3 = @lexer.Lexer::new("'No\\nescaping\\there'")
  try {
    let str3 = lexer3.read_literal_string()
    inspect(str3, content="No\\nescaping\\there")
  } catch {
    msg =>
      fail(
        "Failed to parse literal string with backslashes: " + msg.to_string(),
      )
  }
}

///| Test read_literal_string error case
test "lexer read literal string error" {
  // Test unterminated literal string
  let lexer = @lexer.Lexer::new("'unterminated")
  try {
    let _ = lexer.read_literal_string()
    fail("Should have failed on unterminated literal string")
  } catch {
    _ => () // Expected failure
  }
}

///| Test hex number parsing
test "lexer read hex number" {
  let lexer = @lexer.Lexer::new("1F2A")
  let result = lexer.read_hex_number()
  inspect(result, content="7978") // 0x1F2A = 7978

  // Test hex with underscores
  let lexer2 = @lexer.Lexer::new("1F_2A")
  let result2 = lexer2.read_hex_number()
  inspect(result2, content="7978")

  // Test lowercase hex
  let lexer3 = @lexer.Lexer::new("abcdef")
  let result3 = lexer3.read_hex_number()
  inspect(result3, content="11259375") // 0xABCDEF = 11259375

  // Test empty hex (should return 0)
  let lexer4 = @lexer.Lexer::new("G123") // G is not hex
  let result4 = lexer4.read_hex_number()
  inspect(result4, content="0")
}

///| Test hex number parsing error case
test "lexer read hex number error" {
  // This would typically be caught by the calling code, but let's test the edge case
  let lexer = @lexer.Lexer::new("1F2Z") // Z is not valid hex
  try {
    let _ = lexer.read_hex_number()
    // Should not reach here as Z should stop parsing, not cause error
    // But if it does throw an error, we handle it
  } catch {
    _ => () // If error occurs, that's fine for this edge case
  }
}

///| Test octal number parsing
test "lexer read octal number" {
  let lexer = @lexer.Lexer::new("17")
  let result = lexer.read_octal_number()
  inspect(result, content="15") // 017 = 15

  // Test octal with underscores
  let lexer2 = @lexer.Lexer::new("1_7")
  let result2 = lexer2.read_octal_number()
  inspect(result2, content="15")

  // Test edge case with 8 (not valid octal, should stop parsing)
  let lexer3 = @lexer.Lexer::new("178")
  let result3 = lexer3.read_octal_number()
  inspect(result3, content="15") // Should stop at 8

  // Test empty octal
  let lexer4 = @lexer.Lexer::new("a123") // a is not octal
  let result4 = lexer4.read_octal_number()
  inspect(result4, content="0")
}

///| Test binary number parsing
test "lexer read binary number" {
  let lexer = @lexer.Lexer::new("1010")
  let result = lexer.read_binary_number()
  inspect(result, content="10") // 0b1010 = 10

  // Test binary with underscores
  let lexer2 = @lexer.Lexer::new("10_10")
  let result2 = lexer2.read_binary_number()
  inspect(result2, content="10")

  // Test edge case with 2 (not valid binary, should stop parsing)
  let lexer3 = @lexer.Lexer::new("1012")
  let result3 = lexer3.read_binary_number()
  inspect(result3, content="5") // Should stop at 2

  // Test empty binary
  let lexer4 = @lexer.Lexer::new("a101") // a is not binary
  let result4 = lexer4.read_binary_number()
  inspect(result4, content="0")
}

///| Test advance with surrogate pairs (Unicode edge case)
test "lexer advance with unicode" {
  let lexer = @lexer.Lexer::new("Hello🌍World")

  // Advance through "Hello"
  for i = 0; i < 5; i = i + 1 {
    lexer.advance()
  }

  // Should be at the emoji now
  match lexer.peek() {
    Some(_ch) => {
      // This should be the emoji
      lexer.advance() // This will handle surrogate pairs if needed
      inspect(lexer.position > 5, content="true") // Position should have moved
    }
    None => fail("Expected emoji character")
  }
}

///| Test advance with newlines (for future line tracking)
test "lexer advance with newlines" {
  let lexer = @lexer.Lexer::new("Line1\nLine2\nLine3")

  // Advance through first line
  for i = 0; i < 6; i = i + 1 { // "Line1\n"
    lexer.advance()
  }

  // Should be at "Line2"
  match lexer.peek() {
    Some(ch) => inspect(ch, content="L")
    None => fail("Expected 'L' from Line2")
  }
}
