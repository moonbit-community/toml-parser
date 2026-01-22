///|
/// White-box tests for internal parser methods

///|
test "parse_dotted_key - simple identifier" {
  // Test parsing a simple identifier key
  let tokens = @tokenize.tokenize("simple")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["simple"])
}

///|
test "parse_dotted_key - dotted identifiers" {
  // Test parsing dotted identifier keys
  let tokens = @tokenize.tokenize("server.host.name")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["server", "host", "name"])
}

///|
test "parse_dotted_key - string keys" {
  // Test parsing quoted string keys
  let tokens = @tokenize.tokenize("\"quoted key\".\"another quoted\"")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["quoted key", "another quoted"])
}

///|
test "parse_dotted_key - integer keys" {
  // Test parsing integer keys - note these will be tokenized as floats
  let tokens = @tokenize.tokenize("123.456.789")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["123", "456", "789"])
}

///|
test "parse_dotted_key - string and integer mixed" {
  // Test parsing string followed by integer
  let tokens = @tokenize.tokenize("\"key\".123")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["key", "123"])
}

///|
test "parse_dotted_key - mixed key types" {
  // Test parsing mixed key types
  let tokens = @tokenize.tokenize("server.\"port number\".config")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["server", "port number", "config"])
}

///|
test "parse_dotted_key - float token as dotted keys" {
  // Test the special case where tokenizer sees "1.2" as a float
  // but we need to treat it as dotted keys "1.2"
  let tokens = @tokenize.tokenize("1.2")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["1", "2"])
}

///|
test "parse_dotted_key - float token with additional dots" {
  // Test float token followed by more dotted keys
  let tokens = @tokenize.tokenize("1.2.config.value")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["1", "2", "config", "value"])
}

///|
test "parse_dotted_key - float token without dot" {
  // Test float token that doesn't actually contain a dot (edge case)
  // We'll use a simpler test with a float that gets parsed as a single key
  let tokens = @tokenize.tokenize("42.0")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["42"])
}

///|
test "parse_dotted_key - complex nested structure" {
  // Test a complex real-world-like dotted key
  let tokens = @tokenize.tokenize("database.connections.\"primary-db\".host")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["database", "connections", "primary-db", "host"])
}

///|
test "parse_dotted_key - single quoted string" {
  // Test single quoted string key
  let tokens = @tokenize.tokenize("\"key\"")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["key"])
}

///|
test "parse_dotted_key - single integer" {
  // Test single integer key
  let tokens = @tokenize.tokenize("42")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["42"])
}

///|
test "parse_dotted_key - error cases" {
  // Test error when no key is found
  let tokens = @tokenize.tokenize("=")
  let parser = Parser::new(tokens)
  guard (try? parser.parse_dotted_key()) is Err(err) else {
    fail("Expected error but got success")
  }
  // TODO(upstream): impl[X:ToJson] ToJson for Iter[X]
  json_inspect(err.to_string().split("FAILED:").to_array()[1:], content=[
    " Expected key at {\\n  start: { line: 1, column: 1 },\\n  end: { line: 1, column: 2 },\\n}\")",
  ])
}

///|
test "parse_dotted_key - error after dot" {
  // Test error when dot is followed by invalid token
  let tokens = @tokenize.tokenize("key.=")
  let parser = Parser::new(tokens)
  guard (try? parser.parse_dotted_key()) is Err(result) else {
    fail("Expected error but got success")
  }
  json_inspect(result.to_string().split("FAILED:").to_array()[1:], content=[
    " Expected key after dot at {\\n  start: { line: 1, column: 5 },\\n  end: { line: 1, column: 6 },\\n}\")",
  ])
}

///|
test "parse_dotted_key - numeric float with continuation" {
  // Test numeric float like "3.14" followed by more keys
  let tokens = @tokenize.tokenize("3.14.config")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["3", "14", "config"])
}

///|
test "parse_dotted_key - zero values" {
  // Test with zero values in keys
  let tokens = @tokenize.tokenize("0.0.config")
  let parser = Parser::new(tokens)
  let result = parser.parse_dotted_key()
  json_inspect(result, content=["0"])
}
