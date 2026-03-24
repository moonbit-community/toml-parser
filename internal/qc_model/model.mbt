///|
pub(all) struct SimpleDocument {
  fields : Map[String, SimpleValue]
} derive(Eq, Show, Debug)

///|
pub(all) enum SimpleValue {
  SString(String)
  SInteger(Int64)
  SBoolean(Bool)
  SEmptyArray
  SStringArray(Array[String])
  SIntegerArray(Array[Int64])
  SBooleanArray(Array[Bool])
  STable(Map[String, SimpleValue])
} derive(Eq, Show, Debug)

///|
pub fn SimpleValue::contains_table(self : SimpleValue) -> Bool {
  match self {
    STable(fields) =>
      true ||
      fields
      .to_array()
      .any(fn(entry) {
        let (_key, value) = entry
        value.contains_table()
      })
    _ => false
  }
}

///|
pub fn SimpleValue::contains_array(self : SimpleValue) -> Bool {
  match self {
    SEmptyArray | SStringArray(_) | SIntegerArray(_) | SBooleanArray(_) => true
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) {
        let (_key, value) = entry
        value.contains_array()
      })
    _ => false
  }
}

///|
pub fn SimpleValue::contains_string(self : SimpleValue) -> Bool {
  match self {
    SString(_) | SStringArray(_) => true
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) {
        let (_key, value) = entry
        value.contains_string()
      })
    _ => false
  }
}

///|
pub fn SimpleValue::contains_complex_key(self : SimpleValue) -> Bool {
  match self {
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) {
        let (key, value) = entry
        !is_bare_key(key) || value.contains_complex_key()
      })
    _ => false
  }
}

///|
pub fn SimpleDocument::contains_table(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_table()
  })
}

///|
pub fn SimpleDocument::contains_array(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_array()
  })
}

///|
pub fn SimpleDocument::contains_string(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_string()
  })
}

///|
pub fn SimpleDocument::contains_complex_key(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (key, value) = entry
    !is_bare_key(key) || value.contains_complex_key()
  })
}

///|
pub fn is_bare_key(key : String) -> Bool {
  if key.is_empty() {
    false
  } else {
    for ch in key {
      if !is_bare_key_char(ch) {
        return false
      }
    }
    true
  }
}

///|
fn is_bare_key_char(ch : Char) -> Bool {
  match ch {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-' => true
    _ => false
  }
}
