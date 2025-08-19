///|
fn main {
  println("TOML Parser Demo")

  // Demo 1: Basic value types
  println("\n--- Basic Value Types ---")
  let str_val = @toml.TomlString("Hello, TOML!")
  let int_val = @toml.TomlInteger(42L)
  let bool_val = @toml.TomlBoolean(true)
  println("String value: \{str_val}")
  println("Integer value: \{int_val}")
  println("Boolean value: \{bool_val}")

  // Demo 2: Array example
  println("\n--- Array Example ---")
  let arr = Array::new()
  arr.push(@toml.TomlInteger(1L))
  arr.push(@toml.TomlInteger(2L))
  arr.push(@toml.TomlInteger(3L))
  let array_val = @toml.TomlArray(arr)
  println("Array value: \{array_val}")

  // Demo 3: Parse simple TOML
  println("\n--- Parse Simple TOML ---")
  let toml_input = "name = \"John Doe\"\nage = 30\nenabled = true"
  println("Input TOML:")
  println(toml_input)
  try {
    let result = @toml.parse(toml_input)
    println("\nParsed result:")
    println(result.to_string())
  } catch {
    msg => println("Parse error: \{msg}")
  }

  // Demo 4: Parse with array
  println("\n--- Parse TOML with Array ---")
  let toml_array = "numbers = [1, 2, 3, 4, 5]"
  println("Input TOML:")
  println(toml_array)
  try {
    let result = @toml.parse(toml_array)
    println("\nParsed result:")
    println(result.to_string())
  } catch {
    msg => println("Parse error: \{msg}")
  }

  // Demo 5: Parse with inline table
  println("\n--- Parse TOML with Inline Table ---")
  let toml_table = "person = {name = \"Alice\", age = 25}"
  println("Input TOML:")
  println(toml_table)
  try {
    let result = @toml.parse(toml_table)
    println("\nParsed result:")
    println(result.to_string())
  } catch {
    msg => println("Parse error: \{msg}")
  }

  // Demo 6: Parse with comments
  println("\n--- Parse TOML with Comments ---")
  let toml_with_comments =
    #|# This is a comment
    #|name = "John Doe" # This is an inline comment
    #|age = 30
    #|# Another comment
    #|enabled = true
    #|
  println("Input TOML with comments:")
  println(toml_with_comments)
  try {
    let result = @toml.parse(toml_with_comments)
    println("\nParsed result (comments should be ignored):")
    println(result.to_string())
  } catch {
    msg => println("Parse error: " + msg.to_string())
  }
}
