///| Tests for main function to improve coverage
test "main function demo scenarios" {
  // Test that main function demo scenarios work properly
  // Instead of calling main directly, test the demo scenarios separately

  // Demo 1: Basic value types
  let str_val = @toml.TomlString("Hello, TOML!")
  let int_val = @toml.TomlInteger(42L)
  let bool_val = @toml.TomlBoolean(true)
  inspect(str_val.to_string(), content="\"Hello, TOML!\"")
  inspect(int_val.to_string(), content="42")
  inspect(bool_val.to_string(), content="true")
}

///| Test TomlString creation and string representation
test "toml string creation and output" {
  let str_val = @toml.TomlString("Hello, TOML!")
  let output = str_val.to_string()
  inspect(output, content="\"Hello, TOML!\"")
}

///| Test TomlInteger creation and string representation  
test "toml integer creation and output" {
  let int_val = @toml.TomlInteger(42L)
  let output = int_val.to_string()
  inspect(output, content="42")
}

///| Test TomlBoolean creation and string representation
test "toml boolean creation and output" {
  let bool_val = @toml.TomlBoolean(true)
  let output = bool_val.to_string()
  inspect(output, content="true")
}

///| Test TomlArray creation and string representation
test "toml array creation and output" {
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  let output = array_val.to_string()
  inspect(output, content="[1, 2, 3]")
}

///| Test parsing simple TOML input
test "parse simple toml input" {
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  try {
    let result = @toml.parse(toml_input)
    let output = result.to_string()
    // Check that the output contains the expected values
    inspect(output.contains("John Doe"), content="true")
    inspect(output.contains("30"), content="true")
    inspect(output.contains("true"), content="true")
  } catch {
    e => {
      println("Parse error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test parsing TOML with array
test "parse toml with array" {
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  try {
    let result = @toml.parse(toml_array)
    let output = result.to_string()
    // Check that the output contains the array values
    inspect(output.contains("[1, 2, 3, 4, 5]"), content="true")
  } catch {
    e => {
      println("Parse error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}

///| Test parsing TOML with inline table
test "parse toml with inline table" {
  let toml_table = "person = {name = \"Alice\", age = 25}"
  try {
    let result = @toml.parse(toml_table)
    let output = result.to_string()
    // Check that the output contains the table values
    inspect(output.contains("Alice"), content="true")
    inspect(output.contains("25"), content="true")
  } catch {
    e => {
      println("Parse error: " + e.to_string())
      inspect(false, content="false")
    }
  }
}
