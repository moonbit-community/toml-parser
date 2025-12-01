///|
/// Helper function to escape strings according to TOML spec
fn escape_toml_string(s : String) -> String {
  let result = StringBuilder::new()
  for char in s {
    match char {
      '\b' => result.write_string("\\b")
      '\t' => result.write_string("\\t")
      '\n' => result.write_string("\\n")
      '\f' => result.write_string("\\f")
      '\r' => result.write_string("\\r")
      '"' => result.write_string("\\\"")
      '\\' => result.write_string("\\\\")
      // Control characters (U+0000 to U+001F) except the above
      c if c >= '\u0000' && c <= '\u001F' => {
        result.write_string("\\u")
        let code = c.to_int()
        // Format as 4-digit hex manually
        let hex = StringBuilder::new()
        for i = 3; i >= 0; i = i - 1 {
          let digit = (code >> (i * 4)) & 0xF
          if digit < 10 {
            hex.write_char(Int::unsafe_to_char('0'.to_int() + digit))
          } else {
            hex.write_char(Int::unsafe_to_char('A'.to_int() + digit - 10))
          }
        }
        result.write_string(hex.to_string())
      }
      // DEL character (U+007F)
      '\u007F' => result.write_string("\\u007F")
      c => result.write_char(c)
    }
  }
  result.to_string()
}

///|
/// Check if a string needs to be quoted (contains special characters or starts/ends with whitespace)
fn needs_quoting(s : String) -> Bool {
  if s.is_empty() {
    return true
  }

  // Check for leading/trailing whitespace
  if s.code_unit_at(0) == ' ' ||
    s.code_unit_at(0) == '\t' ||
    s.code_unit_at(s.length() - 1) == ' ' ||
    s.code_unit_at(s.length() - 1) == '\t' {
    return true
  }

  // Check for special characters
  for char in s {
    match char {
      '\n'
      | '\r'
      | '\t'
      | '"'
      | '\\'
      | '['
      | ']'
      | '{'
      | '}'
      | '='
      | ','
      | '#' => return true
      c if c >= '\u0000' && c <= '\u001F' => return true
      '\u007F' => return true
      _ => continue
    }
  }
  false
}

///|
/// Format a key for TOML output
fn format_toml_key(key : String) -> String {
  if needs_quoting(key) {
    "\"\{escape_toml_string(key)}\""
  } else {
    key
  }
}

///|
/// Helper to check if an array should be formatted inline
fn should_format_inline(arr : Array[TomlValue]) -> Bool {
  // Empty arrays or arrays with more than 5 elements should be multiline
  if arr.is_empty() || arr.length() > 5 {
    return arr.is_empty()
  }

  // Arrays containing tables should be multiline
  for value in arr {
    match value {
      TomlTable(_) => return false
      TomlArray(inner) if not(should_format_inline(inner)) => return false
      _ => continue
    }
  }
  true
}

///|
/// Convert a TomlValue to its string representation in TOML format
pub fn TomlValue::to_string(self : TomlValue) -> String {
  let result = StringBuilder::new()
  self.write_toml(result, [])
  result.to_string()
}

///|
/// TODO: the logger interface is good?
pub impl Show for TomlValue with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Internal helper to write TOML with proper formatting
fn TomlValue::write_toml(
  self : TomlValue,
  output : StringBuilder,
  path : Array[String], // Current table path for nested tables
) -> Unit {
  match self {
    TomlString(s) => output.write_string("\"\{escape_toml_string(s)}\"")
    TomlInteger(i) => output.write_string(i.to_string())
    TomlFloat(f) =>
      // Handle special float values
      if f.is_nan() {
        output.write_string("nan")
      } else if f.is_inf() {
        if f < 0.0 {
          output.write_string("-inf")
        } else {
          output.write_string("inf")
        }
      } else {
        // Ensure floats always have decimal point
        let s = f.to_string()
        if not(s.contains(".")) && not(s.contains("e")) && not(s.contains("E")) {
          output.write_string(s + ".0")
        } else {
          output.write_string(s)
        }
      }
    TomlBoolean(b) => output.write_string(if b { "true" } else { "false" })
    TomlDateTime(dt) =>
      match dt {
        OffsetDateTime(s) | LocalDateTime(s) | LocalDate(s) | LocalTime(s) =>
          output.write_string(s)
      }
    TomlArray(arr) =>
      if should_format_inline(arr) {
        // Inline array
        output.write_string("[")
        for i = 0; i < arr.length(); i = i + 1 {
          if i > 0 {
            output.write_string(", ")
          }
          arr[i].write_toml(output, path)
        }
        output.write_string("]")
      } else {
        // Multiline array
        output.write_string("[\n")
        for i = 0; i < arr.length(); i = i + 1 {
          output.write_string("  ")
          arr[i].write_toml(output, path)
          if i < arr.length() - 1 {
            output.write_string(",")
          }
          output.write_string("\n")
        }
        output.write_string("]")
      }
    TomlTable(table) =>
      if path.is_empty() {
        // Root table - format as top-level TOML document
        write_table_contents(table, output, path)
      } else {
        // Inline table for nested tables
        write_inline_table(table, output)
      }
  }
}

///|
/// Write table contents as key-value pairs
fn write_table_contents(
  table : Map[String, TomlValue],
  output : StringBuilder,
  path : Array[String],
) -> Unit {
  let simple_pairs : Array[(String, TomlValue)] = []
  let array_pairs : Array[(String, TomlValue)] = []
  let table_pairs : Array[(String, TomlValue)] = []

  // Categorize entries
  table.each(fn(key, value) {
    match value {
      TomlTable(_) => table_pairs.push((key, value))
      TomlArray(arr) => {
        // Check if it's an array of tables
        let mut is_table_array = true
        for item in arr {
          match item {
            TomlTable(_) => continue
            _ => {
              is_table_array = false
              break
            }
          }
        }
        if is_table_array && arr.length() > 0 {
          table_pairs.push((key, value))
        } else {
          array_pairs.push((key, value))
        }
      }
      _ => simple_pairs.push((key, value))
    }
  })

  // Write simple key-value pairs first
  for i = 0; i < simple_pairs.length(); i = i + 1 {
    let (key, value) = simple_pairs[i]
    output.write_string(format_toml_key(key))
    output.write_string(" = ")
    value.write_toml(output, path)
    output.write_string("\n")
  }

  // Write arrays
  for i = 0; i < array_pairs.length(); i = i + 1 {
    let (key, value) = array_pairs[i]
    if i > 0 || simple_pairs.length() > 0 {
      output.write_string("\n")
    }
    output.write_string(format_toml_key(key))
    output.write_string(" = ")
    value.write_toml(output, path)
    output.write_string("\n")
  }

  // Write nested tables
  for i = 0; i < table_pairs.length(); i = i + 1 {
    let (key, value) = table_pairs[i]
    if i > 0 || simple_pairs.length() > 0 || array_pairs.length() > 0 {
      output.write_string("\n")
    }
    match value {
      TomlArray(arr) =>
        // Array of tables
        for j = 0; j < arr.length(); j = j + 1 {
          if j > 0 {
            output.write_string("\n")
          }
          output.write_string("[[")
          write_table_path(path, output)
          if path.length() > 0 {
            output.write_string(".")
          }
          output.write_string(format_toml_key(key))
          output.write_string("]]\n")
          match arr[j] {
            TomlTable(t) => {
              let new_path = path.copy()
              new_path.push(key)
              write_table_contents(t, output, new_path)
            }
            _ => () // Should not happen if properly validated
          }
        }
      TomlTable(t) => {
        // Regular nested table
        output.write_string("[")
        write_table_path(path, output)
        if path.length() > 0 {
          output.write_string(".")
        }
        output.write_string(format_toml_key(key))
        output.write_string("]\n")
        let new_path = path.copy()
        new_path.push(key)
        write_table_contents(t, output, new_path)
      }
      _ => () // Should not happen
    }
  }
}

///|
/// Write an inline table
fn write_inline_table(
  table : Map[String, TomlValue],
  output : StringBuilder,
) -> Unit {
  output.write_string("{ ")
  let mut first = true
  table.each(fn(key, value) {
    if not(first) {
      output.write_string(", ")
    }
    first = false
    output.write_string(format_toml_key(key))
    output.write_string(" = ")

    // For inline tables, nested tables should also be inline
    match value {
      TomlTable(t) => write_inline_table(t, output)
      _ => value.write_toml(output, [])
    }
  })
  output.write_string(" }")
}

///|
/// Write the table path for section headers
fn write_table_path(path : Array[String], output : StringBuilder) -> Unit {
  for i = 0; i < path.length(); i = i + 1 {
    if i > 0 {
      output.write_string(".")
    }
    output.write_string(format_toml_key(path[i]))
  }
}
