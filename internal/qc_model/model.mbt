///|
/// A simplified TOML document used as the QuickCheck property-test model.
///
/// `SimpleDocument` mirrors a top-level TOML table whose values are drawn
/// from a deliberately restricted grammar (`SimpleValue`). The restriction
/// makes generation, shrinking, and round-trip checks tractable while
/// still covering every case the parser must handle in practice.
pub(all) struct SimpleDocument {
  fields : Map[String, SimpleValue]
} derive(Eq, Debug)

///|
/// Restricted value space for the QuickCheck model.
///
/// The variants mirror TOML's primitive types plus four homogeneous array
/// shapes (`SStringArray`, `SIntegerArray`, `SBooleanArray`,
/// `SDateTimeArray`) and a literally empty array (`SEmptyArray`). Mixed
/// arrays are intentionally excluded — they are forbidden by TOML — and
/// floats are excluded so that round-trip equality stays exact under
/// pretty-printing. `STable` allows nested tables for recursive structure.
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
/// Lift a model value into the parser's `TomlValue` representation.
///
/// This is the encoding side of the round-trip: `to_toml` builds a
/// `TomlValue` that pretty-prints to a TOML document that, when parsed and
/// re-projected via `from_toml`, must yield the original `SimpleValue`.
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
/// Lift the model document into a `TomlValue` table.
///
/// Always returns a `TomlTable` whose keys come straight from `fields` and
/// whose values are produced by `SimpleValue::to_toml`. Use this to render
/// a generated document to TOML text via `.to_toml().to_string()`.
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
/// Try to project a `TomlValue` back into the model's restricted grammar.
///
/// Returns `None` when the input falls outside what `SimpleValue` can
/// represent — most commonly a heterogeneous array, a `TomlFloat`, or a
/// table whose contents project to `None` recursively. A successful
/// projection followed by `to_toml` must produce a value structurally
/// equal to the input; that property is what the round-trip test checks.
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
/// Try to project a `TomlValue` back into a `SimpleDocument`.
///
/// Returns `None` if the input is not a top-level `TomlTable` or if any
/// field fails to project via `SimpleValue::from_toml`.
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
// Coverage classifiers used by the QuickCheck round-trip property.
//
// Each `contains_*` predicate searches the document recursively and
// reports whether the corresponding feature is exercised. The property
// test classifies generated cases by these flags so that the report
// shows feature coverage and shrinking can preserve the targeted shape.

///|
/// Whether the document nests at least one sub-table.
pub fn SimpleDocument::contains_table(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_table())
}

///|
/// Whether any field (recursively) is one of the array variants, including
/// `SEmptyArray`.
pub fn SimpleDocument::contains_array(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_array())
}

///|
/// Whether any field (recursively) carries a string scalar or a string array.
pub fn SimpleDocument::contains_string(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_string())
}

///|
/// Whether any field (recursively) carries a datetime scalar or array.
pub fn SimpleDocument::contains_datetime(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_datetime())
}

///|
/// Whether any field (recursively) is specifically an array of datetimes
/// (the empty array does not count).
pub fn SimpleDocument::contains_datetime_array(self : SimpleDocument) -> Bool {
  self.fields.values().any(value => value.contains_datetime_array())
}

///|
/// Whether any datetime in the document carries a fractional-seconds part.
///
/// This targets the TOML 1.1 path where the lexer must accept and preserve
/// sub-second precision in `OffsetDateTime`, `LocalDateTime`, and
/// `LocalTime` values.
pub fn SimpleDocument::contains_fractional_datetime(
  self : SimpleDocument,
) -> Bool {
  self.fields.values().any(value => value.contains_fractional_datetime())
}

///|
/// Whether any key (at this level or in a nested table) requires quoting
/// rather than being a TOML "bare" identifier.
pub fn SimpleDocument::contains_complex_key(self : SimpleDocument) -> Bool {
  self.fields
  .iter()
  .any(entry => !is_bare_key(entry.0) || entry.1.contains_complex_key())
}

///|
/// Whether any key looks like a negative exponent literal (e.g. `-1e2`).
///
/// Such keys collide with the float grammar at the lexer level and have
/// historically been a source of ambiguity, so the round-trip property
/// classifies them separately to track that their handling stays correct.
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
