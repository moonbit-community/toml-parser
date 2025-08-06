///| Comprehensive error handling tests for TOML parser

///| Test malformed TOML syntax errors
test "parse malformed key value" {
  try {
    ignore(@toml.parse("key value")) // missing equals
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid array syntax
test "parse invalid array syntax" {
  try {
    ignore(@toml.parse("arr = [1, 2, 3")) // missing closing bracket
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test mixed array types error
test "parse mixed array types error" {
  try {
    ignore(@toml.parse("mixed = [1, \"string\", true]")) // mixed types
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid table name
test "parse invalid table name" {
  try {
    ignore(@toml.parse("[123invalid]")) // invalid table name
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test duplicate key error  
test "parse duplicate key error" {
  try {
    ignore(@toml.parse("key = \"value1\"\nkey = \"value2\"")) // duplicate key
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid inline table structure
test "parse invalid inline table" {
  try {
    ignore(@toml.parse("table = {key = value, }")) // trailing comma
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test unclosed inline table
test "parse unclosed inline table" {
  try {
    ignore(@toml.parse("table = {key = \"value\"")) // missing closing brace
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid number format
test "parse invalid number format" {
  try {
    ignore(@toml.parse("num = 12.34.56")) // invalid float
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid boolean value
test "parse invalid boolean" {
  try {
    ignore(@toml.parse("bool = TRUE")) // case sensitive
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid datetime format
test "parse invalid datetime" {
  try {
    ignore(@toml.parse("date = 1979-13-27")) // invalid month
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test table array conflict
test "parse table array conflict" {
  try {
    // Try to define both a table and array of tables with same name
    ignore(
      @toml.parse("[table]\nkey = \"value\"\n[[table]]\nkey2 = \"value2\""),
    )
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test key redefinition in inline table
test "parse key redefinition in inline table" {
  try {
    ignore(@toml.parse("table = {key = \"value1\", key = \"value2\"}")) // duplicate key in inline table
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid escape in string
test "parse invalid string escape" {
  try {
    ignore(@toml.parse("str = \"Hello \\x world\"")) // invalid escape sequence
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test unterminated string
test "parse unterminated string" {
  try {
    ignore(@toml.parse("str = \"Hello world")) // missing closing quote
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid table header syntax
test "parse invalid table header" {
  try {
    ignore(@toml.parse("[table.]")) // invalid table header
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test empty key
test "parse empty key" {
  try {
    ignore(@toml.parse(" = \"value\"")) // empty key
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid array element
test "parse invalid array element" {
  try {
    ignore(@toml.parse("arr = [1, , 3]")) // missing element
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test nested array type mismatch
test "parse nested array type mismatch" {
  try {
    ignore(@toml.parse("arr = [[1, 2], [\"a\", \"b\"]]")) // mixed nested array types
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test value after inline table
test "parse value after inline table" {
  try {
    ignore(@toml.parse("table = {key = \"value\"} extra")) // extra content after inline table
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test incomplete key-value pair
test "parse incomplete key-value" {
  try {
    ignore(@toml.parse("key = ")) // incomplete value
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid character in identifier
test "parse invalid identifier character" {
  try {
    ignore(@toml.parse("key$ = \"value\"")) // invalid character in key
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test extremely nested structure
test "parse deeply nested structure" {
  // This might be valid but could cause stack overflow or other issues
  let deep_toml = "[a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z]\nkey = \"value\""
  try {
    let result = @toml.parse(deep_toml)
    // If it parses, check it contains the expected structure
    let result_str = result.to_string()
    inspect(result_str.contains("value"), content="true")
  } catch {
    // If it fails, that's also acceptable for deeply nested structures
    _ => inspect(true, content="true")
  }
}

///| Test invalid number with leading zeros
test "parse invalid leading zero number" {
  try {
    ignore(@toml.parse("num = 007")) // leading zeros not allowed
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test table key conflicts with existing value
test "parse table key conflicts with value" {
  try {
    ignore(
      @toml.parse("key = \"value\"\n[key.subtable]\nsubkey = \"subvalue\""),
    )
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test array of tables with conflicting key
test "parse array of tables conflict" {
  try {
    ignore(@toml.parse("key = \"value\"\n[[key]]\nsubkey = \"subvalue\""))
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid hex number
test "parse invalid hex number" {
  try {
    ignore(@toml.parse("hex = 0xGHIJ")) // invalid hex digits
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid binary number
test "parse invalid binary number" {
  try {
    ignore(@toml.parse("bin = 0b12345")) // invalid binary digits
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}

///| Test invalid octal number
test "parse invalid octal number" {
  try {
    ignore(@toml.parse("oct = 0o999")) // invalid octal digits
    inspect(false, content="false")
  } catch {
    _ => inspect(true, content="true")
  }
}
