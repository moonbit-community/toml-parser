///| Tests for uncovered tokenize functionality and error cases
///| This tests error handling and edge cases to improve coverage

test "test dot tokenization" {
  // Test the uncovered Dot token parsing
  let tokens = @tokenize.tokenize(".")
  assert_eq(tokens.length(), 2) // Should have Dot and EOF
  assert_eq(tokens[0], @tokenize.Dot)
  assert_eq(tokens[1], @tokenize.EOF)
}

test "test dash followed by non-numeric character throws error" {
  // Test the uncovered error case for dash not followed by number
  try {
    let _tokens = @tokenize.tokenize("-x")
    assert_true(false) // Should not reach here
  } catch {
    _ => assert_true(true) // Should throw error
  }
}

test "test unexpected character throws error" {
  // Test the uncovered error case for unexpected characters
  try {
    let _tokens = @tokenize.tokenize("@")
    assert_true(false) // Should not reach here
  } catch {
    _ => assert_true(true) // Should throw error
  }
}

test "test float tokenization" {
  // Test float tokenization which covers the float parsing path
  let tokens = @tokenize.tokenize("123.456")
  assert_eq(tokens.length(), 2) // FloatToken and EOF
  match tokens[0] {
    @tokenize.FloatToken(value) => assert_eq(value, 123.456)
    _ => assert_true(false)
  }
}

test "test integer tokenization" {
  // Test integer tokenization which covers the integer parsing path
  let tokens = @tokenize.tokenize("123")
  assert_eq(tokens.length(), 2) // IntegerToken and EOF
  match tokens[0] {
    @tokenize.IntegerToken(value) => assert_eq(value, 123L)
    _ => assert_true(false)
  }
}

test "test tokenize unreachable code path" {
  // Test normal tokenization to ensure the while loop works correctly
  let tokens = @tokenize.tokenize("key = \"value\"")
  assert_true(tokens.length() > 0)
  assert_eq(tokens[tokens.length() - 1], @tokenize.EOF)
}

test "test brace tokenization" {
  // Test left and right brace tokenization 
  let tokens = @tokenize.tokenize("{}")
  assert_eq(tokens.length(), 3) // LeftBrace, RightBrace, EOF
  assert_eq(tokens[0], @tokenize.LeftBrace)
  assert_eq(tokens[1], @tokenize.RightBrace)
  assert_eq(tokens[2], @tokenize.EOF)
}