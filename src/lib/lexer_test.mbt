/// Tests for the TOML lexer

test "tokenize simple key-value" {
  match @lib.tokenize("key = \"value\"") {
    Ok(tokens) => {
      inspect(tokens.length(), content="4")  // key, =, "value", EOF
      inspect(tokens[0], content="Identifier(\"key\")")
      inspect(tokens[1], content="Equals")
      inspect(tokens[2], content="StringToken(\"value\")")
      inspect(tokens[3], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize integer" {
  match @lib.tokenize("number = 42") {
    Ok(tokens) => {
      inspect(tokens.length(), content="4")
      inspect(tokens[0], content="Identifier(\"number\")")
      inspect(tokens[1], content="Equals")
      inspect(tokens[2], content="IntegerToken(42)")
      inspect(tokens[3], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize float" {
  match @lib.tokenize("pi = 3.14") {
    Ok(tokens) => {
      inspect(tokens.length(), content="4")
      inspect(tokens[0], content="Identifier(\"pi\")")
      inspect(tokens[1], content="Equals") 
      inspect(tokens[2], content="FloatToken(3.14)")
      inspect(tokens[3], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize boolean" {
  match @lib.tokenize("enabled = true") {
    Ok(tokens) => {
      inspect(tokens.length(), content="4")
      inspect(tokens[0], content="Identifier(\"enabled\")")
      inspect(tokens[1], content="Equals")
      inspect(tokens[2], content="BooleanToken(true)")
      inspect(tokens[3], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize array syntax" {
  match @lib.tokenize("[1, 2, 3]") {
    Ok(tokens) => {
      inspect(tokens.length(), content="8")  // [, 1, ,, 2, ,, 3, ], EOF
      inspect(tokens[0], content="LeftBracket")
      inspect(tokens[1], content="IntegerToken(1)")
      inspect(tokens[2], content="Comma")
      inspect(tokens[3], content="IntegerToken(2)")
      inspect(tokens[4], content="Comma")
      inspect(tokens[5], content="IntegerToken(3)")
      inspect(tokens[6], content="RightBracket")
      inspect(tokens[7], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize with comments" {
  match @lib.tokenize("key = \"value\" # this is a comment") {
    Ok(tokens) => {
      inspect(tokens.length(), content="4")  // key, =, "value", EOF (comment ignored)
      inspect(tokens[0], content="Identifier(\"key\")")
      inspect(tokens[1], content="Equals")
      inspect(tokens[2], content="StringToken(\"value\")")
      inspect(tokens[3], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}

test "tokenize multiline" {
  match @lib.tokenize("key1 = \"value1\"\nkey2 = 42") {
    Ok(tokens) => {
      inspect(tokens.length(), content="8")  // Includes newline token
      inspect(tokens[0], content="Identifier(\"key1\")")
      inspect(tokens[1], content="Equals")
      inspect(tokens[2], content="StringToken(\"value1\")")
      inspect(tokens[3], content="Newline")
      inspect(tokens[4], content="Identifier(\"key2\")")
      inspect(tokens[5], content="Equals")
      inspect(tokens[6], content="IntegerToken(42)")
      inspect(tokens[7], content="EOF")
    }
    Err(msg) => {
      fail("Tokenization failed: " + msg)
    }
  }
}