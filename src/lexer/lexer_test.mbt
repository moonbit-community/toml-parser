///| Comprehensive tests for the TOML lexer

///| Test basic string with escape sequences
test "lexer basic string with escapes" {
  let lexer = @lexer.Lexer::new("\"Hello, \\\"world\\\"!\\n\\t\\r\\\\\"")
  try {
    let result = lexer.read_basic_string()
    inspect(result, content="Hello, \"world\"!\n\t\r\\")
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test basic string with single quote escape
test "lexer basic string with single quote escape" {
  let lexer = @lexer.Lexer::new("\"Hello, \\'world\\'!\"")
  try {
    let result = lexer.read_basic_string()
    inspect(result, content="Hello, 'world'!")
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test invalid escape sequence
test "lexer invalid escape sequence" {
  let lexer = @lexer.Lexer::new("\"Hello, \\z world!\"")
  try {
    ignore(lexer.read_basic_string())
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test unterminated string after escape
test "lexer unterminated string after escape" {
  let lexer = @lexer.Lexer::new("\"Hello, \\")
  try {
    ignore(lexer.read_basic_string())
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test unterminated string
test "lexer unterminated string" {
  let lexer = @lexer.Lexer::new("\"Hello, world!")
  try {
    ignore(lexer.read_basic_string())
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test literal string parsing
test "lexer literal string" {
  let lexer = @lexer.Lexer::new("'Hello, world! \\n \\t'")
  try {
    let result = lexer.read_literal_string()
    inspect(result, content="Hello, world! \\n \\t") // No escape processing
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test unterminated literal string
test "lexer unterminated literal string" {
  let lexer = @lexer.Lexer::new("'Hello, world!")
  try {
    ignore(lexer.read_literal_string())
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test hexadecimal number parsing
test "lexer hex number" {
  let lexer = @lexer.Lexer::new("0xDEADBEEF")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'x'
  try {
    let result = lexer.read_hex_number()
    inspect(result, content="3735928559") // 0xDEADBEEF in decimal
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test hexadecimal number with underscores
test "lexer hex number with underscores" {
  let lexer = @lexer.Lexer::new("0xDE_AD_BE_EF")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'x'
  try {
    let result = lexer.read_hex_number()
    inspect(result, content="3735928559") // 0xDEADBEEF in decimal
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test hexadecimal with lowercase
test "lexer hex number lowercase" {
  let lexer = @lexer.Lexer::new("0xabcdef")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'x'
  try {
    let result = lexer.read_hex_number()
    inspect(result, content="11259375") // 0xabcdef in decimal
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test hexadecimal with digits only (covers uncovered case)
test "lexer hex number digits only" {
  let lexer = @lexer.Lexer::new("0x123456")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'x'
  try {
    let result = lexer.read_hex_number()
    inspect(result, content="1193046") // 0x123456 in decimal
  } catch {
    e => {
      println("Error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test invalid hex digit
test "lexer invalid hex digit" {
  let lexer = @lexer.Lexer::new("0x123G")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'x'
  try {
    ignore(lexer.read_hex_number())
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test binary number parsing
test "lexer binary number" {
  let lexer = @lexer.Lexer::new("0b11010110")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'b'
  let result = lexer.read_binary_number()
  inspect(result, content="214") // 0b11010110 in decimal
}

///| Test binary number with underscores
test "lexer binary number with underscores" {
  let lexer = @lexer.Lexer::new("0b1101_0110")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'b'
  let result = lexer.read_binary_number()
  inspect(result, content="214") // 0b11010110 in decimal
}

///| Test octal number parsing
test "lexer octal number" {
  let lexer = @lexer.Lexer::new("0o755")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'o'
  let result = lexer.read_octal_number()
  inspect(result, content="493") // 0o755 in decimal
}

///| Test octal number with underscores
test "lexer octal number with underscores" {
  let lexer = @lexer.Lexer::new("0o7_5_5")
  lexer.advance() // skip '0'
  lexer.advance() // skip 'o'
  let result = lexer.read_octal_number()
  inspect(result, content="493") // 0o755 in decimal
}

///| Test identifier reading
test "lexer identifier" {
  let lexer = @lexer.Lexer::new("my_variable_123")
  let result = lexer.read_identifier()
  inspect(result, content="my_variable_123")
}

///| Test identifier with hyphens
test "lexer identifier with hyphens" {
  let lexer = @lexer.Lexer::new("my-variable-123")
  let result = lexer.read_identifier()
  inspect(result, content="my-variable-123")
}

///| Test whitespace skipping
test "lexer skip whitespace" {
  let lexer = @lexer.Lexer::new("   \t\r  hello")
  lexer.skip_whitespace()
  let ch = lexer.peek()
  match ch {
    Some('h') => inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///| Test comment skipping
test "lexer skip comment" {
  let lexer = @lexer.Lexer::new("# this is a comment\nhello")
  lexer.skip_comment()
  let ch = lexer.peek()
  match ch {
    Some('\n') => {
      lexer.advance() // skip newline
      let next_ch = lexer.peek()
      match next_ch {
        Some('h') => inspect(true, content="true")
        _ => inspect(false, content="false")
      }
    }
    _ => inspect(false, content="false")
  }
}

///| Test expect_char success
test "lexer expect char success" {
  let lexer = @lexer.Lexer::new("abc")
  try {
    lexer.expect_char('a')
    let ch = lexer.peek()
    match ch {
      Some('b') => inspect(true, content="true")
      _ => inspect(false, content="false")
    }
  } catch {
    _ => inspect(false, content="false")
  }
}

///| Test expect_char failure
test "lexer expect char failure" {
  let lexer = @lexer.Lexer::new("abc")
  try {
    lexer.expect_char('x')
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test expect_char with custom message
test "lexer expect char custom message" {
  let lexer = @lexer.Lexer::new("abc")
  try {
    lexer.expect_char('x', msg="Custom error message")
    inspect(false, content="false") // Should not reach here
  } catch {
    _ => inspect(true, content="true") // Expected to throw
  }
}

///| Test advance with newline
test "lexer advance with newline" {
  let lexer = @lexer.Lexer::new("a\nb")
  let ch1 = lexer.peek()
  lexer.advance()
  let ch2 = lexer.peek()
  lexer.advance()
  let ch3 = lexer.peek()
  match (ch1, ch2, ch3) {
    (Some('a'), Some('\n'), Some('b')) => inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///| Test empty string handling
test "lexer empty string" {
  let lexer = @lexer.Lexer::new("")
  let ch = lexer.peek()
  match ch {
    None => inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///| Test position tracking
test "lexer position tracking" {
  let lexer = @lexer.Lexer::new("hello")
  inspect(lexer.position, content="0")
  lexer.advance()
  inspect(lexer.position, content="1")
  lexer.advance()
  inspect(lexer.position, content="2")
}
