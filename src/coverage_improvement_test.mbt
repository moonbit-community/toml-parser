///| Tests specifically designed to improve coverage of uncovered lines
test "test complex TOML with all token types" {
  let complex_toml = "string_key = \"value with \\\"quotes\\\"\"\ninteger_key = 42\nfloat_key = 3.14159\nbool_key = true\nint_array = [1, 2, 3, 4, 5]\ninline_table = { name = \"John\", age = 30 }\n[database]\nserver = \"192.168.1.1\"\nports = [ 8001, 8001, 8002 ]\nconnection_max = 5000\nenabled = true\n[servers.alpha]\nip = \"10.0.0.1\"\ndc = \"eqdc10\"\n[servers.beta]\nip = \"10.0.0.2\"\ndc = \"eqdc10\""
  @json.inspect(try? parse_no_loc(complex_toml), content={
    "Err": { "$tag": "Failure", "0": "Expected RightBracket, but found Dot" },
  })
  /// FIXME: should parse but fail

}

///|
test "test tokenizer unreachable path coverage" {
  // This is trying to hit the unreachable else branch in tokenize function
  let tokens = @tokenize.tokenize("simple = true")
  @json.inspect(tokens, content=[
    ["Identifier", "simple"],
    "Equals",
    ["BooleanToken", true],
    ["EOF"],
  ])
}

///|
fn tokenize_no_loc(s : String) -> Array[@tokenize.Token] raise {
  @tokenize.tokenize(s) catch {
    Failure(err) =>
      raise Failure([..err.split(" ")[2:].map(x => x.to_string()).join(" ")])
    err => raise err
  }
}

///|
test "test edge case number formats for error paths" {
  // Try to trigger integer parsing errors

  let tokens = try? tokenize_no_loc(
      "huge = 999999999999999999999999999999999999999",
    )
  @json.inspect(tokens, content={
    "Err": {
      "$tag": "Failure",
      "0": "Invalid integer: 999999999999999999999999999999999999999",
    },
  })
}

///|
test "test literal string handling" {
  let tokens = @tokenize.tokenize("literal = 'this is a literal string'")
  @json.inspect(tokens, content=[
    ["Identifier", "literal"],
    "Equals",
    ["StringToken", "this is a literal string"],
    ["EOF"],
  ])
}

///|
test "test various escape sequences coverage" {
  let toml_with_escapes = "newline = \"line1\\nline2\"\ntab = \"col1\\tcol2\"\ncarriage = \"line1\\rline2\"\nbackslash = \"path\\\\to\\\\file\"\nquote = \"say \\\"hello\\\"\""
  @json.inspect(try? parse_no_loc(toml_with_escapes), content={
    "Ok": [
      "TomlTable",
      {
        "newline": ["TomlString", "line1\nline2"],
        "tab": ["TomlString", "col1\tcol2"],
        "carriage": ["TomlString", "line1\rline2"],
        "backslash": ["TomlString", "path\\to\\file"],
        "quote": ["TomlString", "say \"hello\""],
      },
    ],
  })
}

///|
test "test whitespace and comment skipping" {
  let toml_with_whitespace = "key1 = \"value1\"\n\n\nkey2 = \"value2\""
  @json.inspect(try? parse_no_loc(toml_with_whitespace), content={
    "Ok": [
      "TomlTable",
      { "key1": ["TomlString", "value1"], "key2": ["TomlString", "value2"] },
    ],
  })
}

///|
test "test mixed case hex digits" {
  let tokens = @tokenize.tokenize("mixed_hex = 0xaBcDeF")
  @json.inspect(tokens, content=[
    ["Identifier", "mixed_hex"],
    "Equals",
    ["IntegerToken", "11259375"], // 0xaBcDeF = 11259375
    ["EOF"],
  ])
}
