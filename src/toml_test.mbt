///| Basic tests for TOML value types
test "toml string value" {
  let value = @toml.TomlString("hello world")
  inspect(value.to_string(), content="\"hello world\"")
}

///|
test "toml integer value" {
  let value = @toml.TomlInteger(42L)
  inspect(value.to_string(), content="42")
}

///|
test "toml float value" {
  let value = @toml.TomlFloat(3.14)
  inspect(value.to_string(), content="3.14")
}

///|
test "toml boolean value" {
  let true_value = @toml.TomlBoolean(true)
  let false_value = @toml.TomlBoolean(false)
  inspect(true_value.to_string(), content="true")
  inspect(false_value.to_string(), content="false")
}

///|
test "toml array value" {
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let value = @toml.TomlArray(arr)
  inspect(value.to_string(), content="[1, 2, 3]")
}

///|
test "toml table value" {
  let table : Map[String, @toml.TomlValue] = Map::new()
  table["key1"] = @toml.TomlString("value1")
  table["key2"] = @toml.TomlInteger(42L)
  let value = @toml.TomlTable(table)
  // Note: Map iteration order might vary, we'll test the contains functionality
  let str_repr = value.to_string()
  // Basic structure check
  inspect(str_repr.has_prefix("{") && str_repr.has_suffix("}"), content="true")
}

///| Tests for lexer creation
test "lexer creation" {
  let lexer = @toml.Lexer::new("key = value")
  inspect(lexer.input, content="key = value")
  inspect(lexer.position, content="0")
  inspect(lexer.line, content="1")
  inspect(lexer.column, content="1")
}

///| Tests for parser creation  
test "parser creation" {
  let tokens = Array::new()
  tokens.push(@toml.Identifier("key"))
  tokens.push(@toml.Equals)
  tokens.push(@toml.StringToken("value"))
  let parser = @toml.Parser::new(tokens)
  inspect(parser.position, content="0")
  inspect(parser.tokens.length(), content="3")
}
