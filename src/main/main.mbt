///|
fn main {
  println("TOML Parser Demo")

  // Demo 1: Basic value types
  println("\n--- Basic Value Types ---")
  let str_val = @toml.TomlString("Hello, TOML!")
  let int_val = @toml.TomlInteger(42L)
  let bool_val = @toml.TomlBoolean(true)
  println("String value: " + str_val.to_string())
  println("Integer value: " + int_val.to_string())
  println("Boolean value: " + bool_val.to_string())

  // Demo 2: Array example
  println("\n--- Array Example ---")
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  println("Array value: " + array_val.to_string())

  // Demo 3: Parse simple TOML
  println("\n--- Parse Simple TOML ---")
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  println("Input TOML:")
  println(toml_input)
  match @toml.parse(toml_input) {
    Ok(result) => {
      println("\nParsed result:")
      println(result.to_string())
    }
    Err(msg) => println("Parse error: " + msg)
  }

  // Demo 4: Parse with array
  println("\n--- Parse TOML with Array ---")
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  println("Input TOML:")
  println(toml_array)
  match @toml.parse(toml_array) {
    Ok(result) => {
      println("\nParsed result:")
      println(result.to_string())
    }
    Err(msg) => println("Parse error: " + msg)
  }

  // Demo 5: Parse with inline table
  println("\n--- Parse TOML with Inline Table ---")
  let toml_table = "person = {name = \"Alice\", age = 25}"
  println("Input TOML:")
  println(toml_table)
  match @toml.parse(toml_table) {
    Ok(result) => {
      println("\nParsed result:")
      println(result.to_string())
    }
    Err(msg) => println("Parse error: " + msg)
  }
}
