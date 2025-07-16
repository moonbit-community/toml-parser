///| Comprehensive test demonstrating the TOML parser capabilities
test "complex TOML document" {
  // For now, let's test a simpler version since we haven't implemented [section] syntax yet
  let simple_toml = "title = \"TOML Example\"\nversion = 1.0\nenabled = true\nports = [8000, 8001, 8002]"
  match @lib.parse(simple_toml) {
    Ok(result) =>
      match result {
        @lib.TomlTable(table) => {
          inspect(table.size(), content="4")

          // Check title
          match table.get("title") {
            Some(@lib.TomlString(value)) =>
              inspect(value, content="TOML Example")
            _ => fail("Expected string value for 'title'")
          }

          // Check version (will be parsed as float)
          match table.get("version") {
            Some(@lib.TomlFloat(value)) => inspect(value, content="1")
            Some(@lib.TomlInteger(value)) => inspect(value, content="1")
            _ => fail("Expected numeric value for 'version'")
          }

          // Check enabled boolean
          match table.get("enabled") {
            Some(@lib.TomlBoolean(value)) => inspect(value, content="true")
            _ => fail("Expected boolean value for 'enabled'")
          }

          // Check ports array
          match table.get("ports") {
            Some(@lib.TomlArray(arr)) => inspect(arr.length(), content="3")
            _ => fail("Expected array value for 'ports'")
          }
        }
        _ => fail("Expected table result")
      }
    Err(msg) => fail("Parse failed: " + msg)
  }
}

///|
test "error handling" {
  // Test various error conditions

  // Missing value
  match @lib.parse("key =") {
    Ok(_) => fail("Should fail on missing value")
    Err(msg) =>
      // Should get an error message
      inspect(msg.length() > 0, content="true")
  }

  // Missing key
  match @lib.parse("= \"value\"") {
    Ok(_) => fail("Should fail on missing key")
    Err(msg) =>
      // Should get an error message  
      inspect(msg.length() > 0, content="true")
  }

  // Unterminated string
  match @lib.parse("key = \"unterminated") {
    Ok(_) => fail("Should fail on unterminated string")
    Err(msg) =>
      // Should get an error message
      inspect(msg.length() > 0, content="true")
  }
}

///|
test "edge cases" {
  // Empty input  
  match @lib.parse("") {
    Ok(@lib.TomlTable(table)) => inspect(table.size(), content="0")
    _ => fail("Empty input should result in empty table")
  }

  // Only comments and whitespace
  match @lib.parse("# Just a comment\n  \n# Another comment") {
    Ok(@lib.TomlTable(table)) => inspect(table.size(), content="0")
    _ => fail("Comments and whitespace should result in empty table")
  }

  // Mixed quotes
  match @lib.parse("single = 'value'\ndouble = \"value\"") {
    Ok(@lib.TomlTable(table)) => {
      inspect(table.size(), content="2")
      match table.get("single") {
        Some(@lib.TomlString(value)) => inspect(value, content="value")
        _ => fail("Expected string value for 'single'")
      }
      match table.get("double") {
        Some(@lib.TomlString(value)) => inspect(value, content="value")
        _ => fail("Expected string value for 'double'")
      }
    }
    _ => fail("Mixed quotes should parse correctly")
  }
}
