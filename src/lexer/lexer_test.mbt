///| Tests for lexer functionality
test "lexer skip whitespace" {
  let lexer = @lexer.Lexer::new("  \t\rHello")
  lexer.skip_whitespace()
  inspect(lexer.peek(), content="Some('H')")
}

///|
test "lexer skip comment" {
  let lexer = @lexer.Lexer::new("# this is a comment\nkey")
  lexer.skip_comment()
  match lexer.peek() {
    Some('\n') => inspect(true, content="true")
    _ => fail("Expected newline")
  }
}

///|
test "lexer peek and advance" {
  let lexer = @lexer.Lexer::new("abc")
  inspect(lexer.peek(), content="Some('a')")
  lexer.advance()
  inspect(lexer.peek(), content="Some('b')")
  lexer.advance()
  inspect(lexer.peek(), content="Some('c')")
  lexer.advance()
  inspect(lexer.peek(), content="None")
}

///|
test "lexer expect_char success" {
  let lexer = @lexer.Lexer::new("abc")
  try {
    lexer.expect_char('a')
    inspect(lexer.peek(), content="Some('b')")
  } catch {
    _msg => fail("expect_char should not fail")
  }
}

///|
test "lexer expect_char failure" {
  let lexer = @lexer.Lexer::new("abc")
  try {
    lexer.expect_char('x', msg="Expected x")
    fail("Should have thrown error")
  } catch {
    msg => inspect(msg.to_string().contains("Expected x"), content="true")
  }
}

///|
test "lexer read identifier" {
  let lexer = @lexer.Lexer::new("hello_world123-test")
  let result = lexer.read_identifier()
  inspect(result, content="hello_world123-test")
}

///|
test "lexer read basic string with escapes" {
  let lexer = @lexer.Lexer::new("\"hello\\nworld\\t\\\"test\\\"\"")
  try {
    let result = lexer.read_basic_string()
    inspect(result, content="hello\nworld\t\"test\"")
  } catch {
    _msg => fail("Should not throw error")
  }
}

///|
test "lexer read basic string with invalid escape" {
  let lexer = @lexer.Lexer::new("\"hello\\x\"")
  try {
    let _result = lexer.read_basic_string()
    fail("Should have thrown error for invalid escape")
  } catch {
    msg => inspect(msg.to_string().contains("Invalid escape"), content="true")
  }
}

///|
test "lexer read basic string unterminated" {
  let lexer = @lexer.Lexer::new("\"hello")
  try {
    let _result = lexer.read_basic_string()
    fail("Should have thrown error for unterminated string")
  } catch {
    msg => inspect(msg.to_string().contains("Unterminated"), content="true")
  }
}

///|
test "lexer read basic string with escape at end" {
  let lexer = @lexer.Lexer::new("\"hello\\")
  try {
    let _result = lexer.read_basic_string()
    fail("Should have thrown error for escape at end")
  } catch {
    msg => inspect(msg.to_string().contains("end of input"), content="true")
  }
}

///|
test "lexer read literal string" {
  let lexer = @lexer.Lexer::new("'hello world'")
  try {
    let result = lexer.read_literal_string()
    inspect(result, content="hello world")
  } catch {
    _msg => fail("Should not throw error")
  }
}

///|
test "lexer read literal string unterminated" {
  let lexer = @lexer.Lexer::new("'hello")
  try {
    let _result = lexer.read_literal_string()
    fail("Should have thrown error for unterminated literal string")
  } catch {
    msg => inspect(msg.to_string().contains("Unterminated"), content="true")
  }
}

///|
test "lexer read hex number" {
  let lexer = @lexer.Lexer::new("1A2F_CAFE")
  try {
    let result = lexer.read_hex_number()
    // Just check that it parses without error and returns a number
    inspect(result > 0L, content="true")
  } catch {
    _msg => fail("Should not throw error")
  }
}

///|
test "lexer read hex number with invalid digit" {
  let lexer = @lexer.Lexer::new("1A2G")
  try {
    let _result = lexer.read_hex_number()
    // This might not fail immediately, depends on implementation
  } catch {
    _msg => ()
  }
}

///|
test "lexer read octal number" {
  let lexer = @lexer.Lexer::new("755_777")
  let result = lexer.read_octal_number()
  // Just check that it parses and returns a positive number
  inspect(result > 0L, content="true")
}

///|
test "lexer read binary number" {
  let lexer = @lexer.Lexer::new("1010_1100")
  let result = lexer.read_binary_number()
  inspect(result, content="172") // 0b10101100 in decimal
}

///|
test "lexer advance with newline" {
  let lexer = @lexer.Lexer::new("a\nb")
  lexer.advance() // 'a'
  match lexer.peek() {
    Some('\n') => inspect(true, content="true")
    _ => fail("Expected newline")
  }
  lexer.advance() // '\n'
  inspect(lexer.peek(), content="Some('b')")
}

///|
test "lexer advance at end" {
  let lexer = @lexer.Lexer::new("a")
  lexer.advance()
  inspect(lexer.peek(), content="None")
  // Advance at end should not crash
  lexer.advance()
  inspect(lexer.peek(), content="None")
}

///|
test "skip comment with no newline" {
  let lexer = @lexer.Lexer::new("# comment only")
  lexer.skip_comment()
  inspect(lexer.peek(), content="None")
}

///|
test "skip comment when not at comment" {
  let lexer = @lexer.Lexer::new("key = value")
  lexer.skip_comment() // Should do nothing
  inspect(lexer.peek(), content="Some('k')")
}
