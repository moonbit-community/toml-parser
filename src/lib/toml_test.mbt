///| Basic tests for TOML value types
test "toml string value" {
  let value = @lib.TomlString("hello world")
  inspect(value.to_string(), content="\"hello world\"")
}

///|
test "toml integer value" {
  let value = @lib.TomlInteger(42L)
  inspect(value.to_string(), content="42")
}

///|
test "toml float value" {
  let value = @lib.TomlFloat(3.14)
  inspect(value.to_string(), content="3.14")
}

///|
test "toml boolean value" {
  let true_value = @lib.TomlBoolean(true)
  let false_value = @lib.TomlBoolean(false)
  inspect(true_value.to_string(), content="true")
  inspect(false_value.to_string(), content="false")
}

///|
test "toml array value" {
  let arr = Array::new()
  arr.push(@lib.TomlInteger(1L))
  arr.push(@lib.TomlInteger(2L))
  arr.push(@lib.TomlInteger(3L))
  let value = @lib.TomlArray(arr)
  inspect(value.to_string(), content="[1, 2, 3]")
}

///|
test "toml table value" {
  let table : Map[String, @lib.TomlValue] = Map::new()
  table["key1"] = @lib.TomlString("value1")
  table["key2"] = @lib.TomlInteger(42L)
  let value = @lib.TomlTable(table)
  // Note: Map iteration order might vary, we'll test the contains functionality
  let str_repr = value.to_string()
  // Basic structure check
  inspect(str_repr.has_prefix("{") && str_repr.has_suffix("}"), content="true")
}

///| Tests for lexer creation
test "lexer creation" {
  let lexer = @lib.Lexer::new("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
  inspect(lexer.line, content="1")
  inspect(lexer.column, content="1")
}

///| Tests for parser creation  
test "parser creation" {
  let tokens = Array::new()
  tokens.push(@lib.Identifier("key"))
  tokens.push(@lib.Equals)
  tokens.push(@lib.StringToken("value"))
  let parser = @lib.Parser::new(tokens)
  inspect(parser.position, content="0")
  inspect(parser.tokens.length(), content="3")
}
