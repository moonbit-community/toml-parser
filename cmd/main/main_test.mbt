///|
/// Tests for main demo functionality
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
  let toml_input =
    #|name = "John Doe"
    #|age = 30
    #|enabled = true
    #|
  let result = try? @toml.parse(toml_input)
  guard result
    is Ok(
      TomlTable(
        {
          "name": TomlString("John Doe"),
          "age": TomlInteger(30L),
          "enabled": TomlBoolean(true),
          ..
        },
      ),
    ) else {
    fail("Should parse to table with name, age, enabled")
  }
}

///|
test "test TOML with array parsing as in main demo" {
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  let result = try? @toml.parse(toml_array)
  guard result
    is Ok(
      TomlTable(
        {
          "numbers": TomlArray(
            [
              TomlInteger(1L),
              TomlInteger(2L),
              TomlInteger(3L),
              TomlInteger(4L),
              TomlInteger(5L),
            ],
          ),
          ..
        },
      ),
    ) else {
    fail("Should parse to table with numbers array [1,2,3,4,5]")
  }
}

///|
test "test TOML with inline table parsing as in main demo" {
  let toml_table =
    #|person = {name = "Alice", age = 25}
    #|
  let result = try? @toml.parse(toml_table)
  guard result
    is Ok(
      TomlTable(
        {
          "person": TomlTable(
            { "name": TomlString("Alice"), "age": TomlInteger(25L), .. },
          ),
          ..
        },
      ),
    ) else {
    fail("Should parse to table with person={name=Alice, age=25}")
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
