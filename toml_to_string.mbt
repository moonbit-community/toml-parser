///|
/// Convert TomlValue to string representation
pub fn TomlValue::to_string(self : TomlValue) -> String {
  match self {
    TomlString(s) => "\"\{s}\""
    TomlInteger(i) => i.to_string()
    TomlFloat(f) => f.to_string()
    TomlBoolean(b) => if b { "true" } else { "false" }
    TomlArray(arr) => "[" + arr.map(x => x.to_string()).join(", ") + "]"
    TomlTable(table) => {
      let items = []
      table.each(fn(key, value) { items.push("\{key} = \{value.to_string()}") })
      "{" + items.join(", ") + "}"
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
