///|
/// TOML Value types that represent different TOML data types
pub(all) enum TomlValue {
  TomlString(String)
  TomlInteger(Int64)
  TomlFloat(Double)
  TomlBoolean(Bool)
  TomlArray(Array[TomlValue])
  TomlTable(Map[String, TomlValue])
  TomlDateTime(TomlDateTime)
} derive(Eq, Show, ToJson)

///|
/// Parser state (will implement methods later)
pub struct Parser {
  tokens : Array[Token]
  mut position : Int
}

///|
pub fn Parser::view(self : Parser) -> ArrayView[Token] {
  self.tokens[self.position:]
}

///|
/// FIXME: expose upstream in the core
fn[T] ArrayView::start(self : ArrayView[T]) -> Int = "%arrayview.start"

///|
pub fn Parser::update_view(self : Parser, view : ArrayView[Token]) -> Unit {
  let new_offset = view.start() // consistent
  self.position = new_offset
}

///|
/// Create a new parser
pub fn Parser::new(tokens : Array[Token]) -> Parser {
  { tokens, position: 0 }
}

///|
/// Check if an array contains homogeneous types (TOML spec requirement)
pub fn TomlValue::is_homogeneous_array(arr : Array[TomlValue]) -> Bool {
  match arr {
    [] => true
    [first, .. rest] => {
      fn type_id(value : TomlValue) -> Int {
        match value {
          TomlString(_) => 0
          TomlInteger(_) => 1
          TomlFloat(_) => 2
          TomlBoolean(_) => 3
          TomlArray(_) => 4
          TomlTable(_) => 5
          TomlDateTime(_) => 6
        }
      }

      let first_type = type_id(first)
      rest.all(x => type_id(x) == first_type)
    }
  }
}

///|
/// Validate that a TomlValue follows TOML specification rules
pub fn TomlValue::validate(self : TomlValue) -> Bool {
  match self {
    TomlArray(arr) => {
      // Check homogeneity
      if not(TomlValue::is_homogeneous_array(arr)) {
        return false
      }
      // Recursively validate nested values
      for i = 0; i < arr.length(); i = i + 1 {
        if not(arr[i].validate()) {
          return false
        }
      }
      true
    }
    TomlTable(table) => {
      // Recursively validate all values in the table
      let mut valid = true
      table.each(fn(_key, value) { if not(value.validate()) { valid = false } })
      valid
    }
    _ => true // All other types are always valid by themselves
  }
}
