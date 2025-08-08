///| Tests for main demo functionality
test "test TomlString to_string" {
  let str_val = @toml.TomlString("Hello, TOML!")
  inspect(str_val.to_string(), content="\"Hello, TOML!\"")
}

///|
test "test TomlInteger to_string" {
  let int_val = @toml.TomlInteger(42L)
  inspect(int_val.to_string(), content="42")
}

///|
test "test TomlBoolean to_string" {
  let bool_val = @toml.TomlBoolean(true)
  inspect(bool_val.to_string(), content="true")
  let bool_val_false = @toml.TomlBoolean(false)
  inspect(bool_val_false.to_string(), content="false")
}

///|
test "test TomlArray to_string" {
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  inspect(array_val.to_string(), content="[1, 2, 3]")
}

///|
test "test simple TOML parsing as in main demo" {
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  try {
    let result = @toml.parse(toml_input)
    // Should parse successfully
    let expected_content = result.to_string()
    inspect(expected_content.contains("John Doe"), content="true")
    inspect(expected_content.contains("30"), content="true")
    inspect(expected_content.contains("true"), content="true")
  } catch {
    _ => fail("Should parse successfully")
  }
}

///|
test "test TOML with array parsing as in main demo" {
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  try {
    let result = @toml.parse(toml_array)
    // Should parse successfully
    let result_str = result.to_string()
    inspect(result_str.contains("numbers"), content="true")
    inspect(result_str.contains("[1, 2, 3, 4, 5]"), content="true")
  } catch {
    _ => fail("Should parse successfully")
  }
}

///|
test "test TOML with inline table parsing as in main demo" {
  let toml_table = "person = {name = \"Alice\", age = 25}"
  try {
    let result = @toml.parse(toml_table)
    // Should parse successfully
    let result_str = result.to_string()
    inspect(result_str.contains("person"), content="true")
    inspect(result_str.contains("Alice"), content="true")
    inspect(result_str.contains("25"), content="true")
  } catch {
    _ => fail("Should parse successfully")
  }
}

///|
test "test error handling in parsing" {
  let invalid_toml = "invalid = "
  try {
    let result = @toml.parse(invalid_toml)
    ignore(result)
    fail("Should fail to parse invalid TOML")
  } catch {
    _ => inspect(true, content="true") // Expected to catch error
  }
}
