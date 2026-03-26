///|
pub(all) struct SimpleDocument {
  fields : Map[String, SimpleValue]
} derive(Eq, Show, Debug)

///|
pub(all) enum SimpleValue {
  SString(String)
  SInteger(Int64)
  SBoolean(Bool)
  SDateTime(@tokenize.TomlDateTime)
  SDateTimeArray(Array[@tokenize.TomlDateTime])
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
    SEmptyArray
    | SStringArray(_)
    | SIntegerArray(_)
    | SBooleanArray(_)
    | SDateTimeArray(_) => true
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
pub fn SimpleValue::contains_datetime(self : SimpleValue) -> Bool {
  match self {
    SDateTime(_) | SDateTimeArray(_) => true
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) {
        let (_key, value) = entry
        value.contains_datetime()
      })
    _ => false
  }
}

///|
fn datetime_has_fractional_seconds(datetime : @tokenize.TomlDateTime) -> Bool {
  match datetime {
    @tokenize.OffsetDateTime(text)
    | @tokenize.LocalDateTime(text)
    | @tokenize.LocalTime(text) => text.contains(".")
    @tokenize.LocalDate(_) => false
  }
}

///|
pub fn SimpleValue::contains_datetime_array(self : SimpleValue) -> Bool {
  match self {
    SDateTimeArray(_) => true
    STable(fields) =>
      fields.to_array().any(fn(entry) { entry.1.contains_datetime_array() })
    _ => false
  }
}

///|
pub fn SimpleValue::contains_fractional_datetime(self : SimpleValue) -> Bool {
  match self {
    SDateTime(datetime) => datetime_has_fractional_seconds(datetime)
    SDateTimeArray(values) => values.any(datetime_has_fractional_seconds)
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) { entry.1.contains_fractional_datetime() })
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
pub fn SimpleValue::contains_negative_exponent_like_key(
  self : SimpleValue,
) -> Bool {
  match self {
    STable(fields) =>
      fields
      .to_array()
      .any(fn(entry) {
        let (key, value) = entry
        is_negative_exponent_like_key(key) ||
        value.contains_negative_exponent_like_key()
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
pub fn SimpleDocument::contains_datetime(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_datetime()
  })
}

///|
pub fn SimpleDocument::contains_datetime_array(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_datetime_array()
  })
}

///|
pub fn SimpleDocument::contains_fractional_datetime(
  self : SimpleDocument,
) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_fractional_datetime()
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
pub fn SimpleDocument::contains_negative_exponent_like_key(
  self : SimpleDocument,
) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (key, value) = entry
    is_negative_exponent_like_key(key) ||
    value.contains_negative_exponent_like_key()
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
fn is_negative_exponent_like_key(key : String) -> Bool {
  if key.length() < 4 || key[0] != '-' || !(key[1] is ('1'..='9')) {
    false
  } else {
    let mut significand_end = 2
    while significand_end < key.length() && key[significand_end] is ('0'..='9') {
      significand_end += 1
    }
    if significand_end >= key.length() || !(key[significand_end] is ('e' | 'E')) {
      return false
    }
    let exponent_start = if significand_end + 1 < key.length() &&
      key[significand_end + 1] == '-' {
      significand_end + 2
    } else {
      significand_end + 1
    }
    if exponent_start >= key.length() {
      return false
    }
    let mut i = exponent_start
    while i < key.length() {
      if !(key[i] is ('0'..='9')) {
        return false
      }
      i += 1
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
