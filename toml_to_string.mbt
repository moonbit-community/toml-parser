///|
/// Convert TomlValue to string representation
pub fn TomlValue::to_string(self : TomlValue) -> String {
  match self {
    TomlString(s) => "\"\{s}\""
    TomlInteger(i) => i.to_string()
    TomlFloat(f) => f.to_string()
    TomlBoolean(b) => if b { "true" } else { "false" }
    TomlArray(arr) => {
      let items = Array::new()
      for i = 0; i < arr.length(); i = i + 1 {
        items.push(arr[i].to_string())
      }
      let mut result = "["
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 {
          result = result + ", "
        }
        result = result + items[i]
      }
      result + "]"
    }
    TomlTable(table) => {
      let items = Array::new()
      table.each(fn(key, value) { items.push("\{key} = \{value.to_string()}") })
      let mut result = "{"
      for i = 0; i < items.length(); i = i + 1 {
        if i > 0 {
          result = result + ", "
        }
        result = result + items[i]
      }
      result + "}"
    }
    TomlDateTime(dt) =>
      match dt {
        OffsetDateTime(s) => s
        LocalDateTime(s) => s
        LocalDate(s) => s
        LocalTime(s) => s
      }
  }
}
