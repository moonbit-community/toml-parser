///|
pub(all) struct SimpleDocument {
  fields : Map[String, SimpleValue]
} derive(Eq, Debug)

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
} derive(Eq, Debug)

///|
pub impl Show for SimpleDocument with output(self, logger) {
  Debug::to_repr(self).output(logger)
}

///|
pub impl Show for SimpleValue with output(self, logger) {
  Debug::to_repr(self).output(logger)
}

///|
pub fn SimpleValue::to_toml(self : SimpleValue) -> @toml.TomlValue {
  match self {
    SString(s) => TomlString(s)
    SInteger(n) => TomlInteger(n)
    SBoolean(b) => TomlBoolean(b)
    SDateTime(value) => TomlDateTime(value)
    SDateTimeArray(values) => TomlArray([ for v in values => TomlDateTime(v) ])
    SEmptyArray => TomlArray([])
    SStringArray(values) => TomlArray([ for v in values => TomlString(v) ])
    SIntegerArray(values) => TomlArray([ for v in values => TomlInteger(v) ])
    SBooleanArray(values) => TomlArray([ for v in values => TomlBoolean(v) ])
    STable(fields) =>
      TomlTable(Map::from_array([ for k, v in fields => (k, v.to_toml()) ]))
  }
}

///|
pub fn SimpleDocument::to_toml(self : SimpleDocument) -> @toml.TomlValue {
  TomlTable(Map::from_array([ for k, v in self.fields => (k, v.to_toml()) ]))
}

///|
fn[A] collect_toml_array(
  values : ArrayView[@toml.TomlValue],
  project : (@toml.TomlValue) -> A?,
) -> Array[A]? {
  match values {
    [] => Some([])
    [value, .. rest] =>
      match (project(value), collect_toml_array(rest, project)) {
        (Some(projected), Some(next)) => Some([projected, ..next])
        _ => None
      }
  }
}

///|
fn project_datetime(value : @toml.TomlValue) -> @tokenize.TomlDateTime? {
  match value {
    TomlDateTime(dt) => Some(dt)
    _ => None
  }
}

///|
fn project_string(value : @toml.TomlValue) -> String? {
  match value {
    TomlString(s) => Some(s)
    _ => None
  }
}

///|
fn project_integer(value : @toml.TomlValue) -> Int64? {
  match value {
    TomlInteger(n) => Some(n)
    _ => None
  }
}

///|
fn project_boolean(value : @toml.TomlValue) -> Bool? {
  match value {
    TomlBoolean(b) => Some(b)
    _ => None
  }
}

///|
pub fn SimpleValue::from_toml(value : @toml.TomlValue) -> SimpleValue? {
  match value {
    TomlString(text) => Some(SString(text))
    TomlInteger(number) => Some(SInteger(number))
    TomlBoolean(boolean) => Some(SBoolean(boolean))
    TomlDateTime(datetime) => Some(SDateTime(datetime))
    TomlArray(values) =>
      match values {
        [] => Some(SEmptyArray)
        [TomlDateTime(_), ..] =>
          collect_toml_array(values, project_datetime).map(items => {
            SDateTimeArray(items)
          })
        [TomlString(_), ..] =>
          collect_toml_array(values, project_string).map(items => {
            SStringArray(items)
          })
        [TomlInteger(_), ..] =>
          collect_toml_array(values, project_integer).map(items => {
            SIntegerArray(items)
          })
        [TomlBoolean(_), ..] =>
          collect_toml_array(values, project_boolean).map(items => {
            SBooleanArray(items)
          })
        _ => None
      }
    TomlTable(fields) =>
      simple_table_entries_from_toml(fields.to_array()).map(entries => {
        STable(Map::from_array(entries))
      })
    _ => None
  }
}

///|
fn simple_table_entries_from_toml(
  entries : ArrayView[(String, @toml.TomlValue)],
) -> Array[(String, SimpleValue)]? {
  match entries {
    [] => Some([])
    [(key, value), .. rest] =>
      match
        (SimpleValue::from_toml(value), simple_table_entries_from_toml(rest)) {
        (Some(simple), Some(next)) => Some([(key, simple), ..next])
        _ => None
      }
  }
}

///|
pub fn SimpleDocument::from_toml(value : @toml.TomlValue) -> SimpleDocument? {
  match value {
    TomlTable(fields) =>
      simple_table_entries_from_toml(fields.to_array()).map(entries => {
        fields: Map::from_array(entries),
      })
    _ => None
  }
}

///|
fn SimpleValue::contains_table(self : SimpleValue) -> Bool {
  match self {
    STable(_) => true
    _ => false
  }
}

///|
fn SimpleValue::contains_array(self : SimpleValue) -> Bool {
  match self {
    SEmptyArray
    | SStringArray(_)
    | SIntegerArray(_)
    | SBooleanArray(_)
    | SDateTimeArray(_) => true
    STable(fields) => fields.values().any(value => value.contains_array())
    _ => false
  }
}

///|
fn SimpleValue::contains_string(self : SimpleValue) -> Bool {
  match self {
    SString(_) | SStringArray(_) => true
    STable(fields) => fields.values().any(value => value.contains_string())
    _ => false
  }
}

///|
fn SimpleValue::contains_datetime(self : SimpleValue) -> Bool {
  match self {
    SDateTime(_) | SDateTimeArray(_) => true
    STable(fields) => fields.values().any(value => value.contains_datetime())
    _ => false
  }
}

///|
fn datetime_has_fractional_seconds(datetime : @tokenize.TomlDateTime) -> Bool {
  match datetime {
    OffsetDateTime(text) | LocalDateTime(text) | LocalTime(text) =>
      text.contains(".")
    LocalDate(_) => false
  }
}

///|
fn SimpleValue::contains_datetime_array(self : SimpleValue) -> Bool {
  match self {
    SDateTimeArray(_) => true
    STable(fields) =>
      fields.values().any(value => value.contains_datetime_array())
    _ => false
  }
}

///|
fn SimpleValue::contains_fractional_datetime(self : SimpleValue) -> Bool {
  match self {
    SDateTime(datetime) => datetime_has_fractional_seconds(datetime)
    SDateTimeArray(values) => values.any(datetime_has_fractional_seconds)
    STable(fields) =>
      fields.values().any(value => value.contains_fractional_datetime())
    _ => false
  }
}

///|
fn SimpleValue::contains_complex_key(self : SimpleValue) -> Bool {
  match self {
    STable(fields) =>
      fields
      .iter()
      .any(entry => !is_bare_key(entry.0) || entry.1.contains_complex_key())
    _ => false
  }
}

///|
fn SimpleValue::contains_negative_exponent_like_key(self : SimpleValue) -> Bool {
  match self {
    STable(fields) =>
      fields
      .iter()
      .any(entry => {
        is_negative_exponent_like_key(entry.0) ||
        entry.1.contains_negative_exponent_like_key()
      })
    _ => false
  }
}

///|
pub fn SimpleDocument::contains_table(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_table())
}

///|
pub fn SimpleDocument::contains_array(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_array())
}

///|
pub fn SimpleDocument::contains_string(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_string())
}

///|
pub fn SimpleDocument::contains_datetime(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_datetime())
}

///|
pub fn SimpleDocument::contains_datetime_array(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_datetime_array())
}

///|
pub fn SimpleDocument::contains_fractional_datetime(
  self : SimpleDocument,
) -> Bool {
  self.fields.values().any(value => value.contains_fractional_datetime())
}

///|
pub fn SimpleDocument::contains_complex_key(self : SimpleDocument) -> Bool {
  self.fields
  .iter()
  .any(entry => !is_bare_key(entry.0) || entry.1.contains_complex_key())
}

///|
pub fn SimpleDocument::contains_negative_exponent_like_key(
  self : SimpleDocument,
) -> Bool {
  self.fields
  .iter()
  .any(entry => {
    is_negative_exponent_like_key(entry.0) ||
    entry.1.contains_negative_exponent_like_key()
  })
}

///|
fn is_bare_key(key : String) -> Bool {
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
