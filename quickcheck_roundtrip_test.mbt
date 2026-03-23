///|
struct SimpleDocument {
  fields : Map[String, SimpleValue]
} derive(Eq, Show, ToJson)

///|
enum SimpleValue {
  SString(String)
  SInteger(Int64)
  SBoolean(Bool)
  SEmptyArray
  SStringArray(Array[String])
  SIntegerArray(Array[Int64])
  SBooleanArray(Array[Bool])
  STable(Map[String, SimpleValue])
} derive(Eq, Show, ToJson)

///|
fn capped_size(size : Int, cap : Int) -> Int {
  if size < cap {
    size
  } else {
    cap
  }
}

///|
fn string_from_parts(head : Char, tail : Array[Char]) -> String {
  let builder = StringBuilder::new()
  builder.write_char(head)
  for ch in tail {
    builder.write_char(ch)
  }
  builder.to_string()
}

///|
fn simple_key_tail_char_gen() -> @qc.Gen[Char] {
  @qc.one_of([
    @qc.char_range('a', 'z'),
    @qc.char_range('0', '9'),
    @qc.pure('-'),
    @qc.pure('_'),
  ])
}

///|
fn bare_key_gen() -> @qc.Gen[String] {
  @qc.sized(fn(size) {
    let max_tail = capped_size(size, 4)
    @qc.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @qc.liftA2(
        string_from_parts,
        @qc.char_range('a', 'z'),
        simple_key_tail_char_gen().array_with_size(tail_len),
      )
    })
  })
}

///|
fn string_with_middle_char(
  left : String,
  middle : Char,
  right : String,
) -> String {
  left + middle.to_string() + right
}

///|
fn key_with_middle_char_gen(middle : @qc.Gen[Char]) -> @qc.Gen[String] {
  @qc.liftA3(string_with_middle_char, bare_key_gen(), middle, bare_key_gen())
}

///|
fn padded_key_gen() -> @qc.Gen[String] {
  @qc.liftA3(
    string_with_middle_char,
    @qc.one_of([@qc.pure(""), bare_key_gen()]),
    @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
    bare_key_gen(),
  ).bind(fn(prefix_padded) {
    @qc.one_of([
      @qc.pure(prefix_padded),
      @qc.liftA2(
        fn(inner : String, suffix : Char) { inner + suffix.to_string() },
        @qc.pure(prefix_padded),
        @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
      ),
    ])
  })
}

///|
fn complex_key_gen() -> @qc.Gen[String] {
  @qc.frequency([
    (2U, key_with_middle_char_gen(@qc.pure(' '))),
    (2U, key_with_middle_char_gen(@qc.pure('.'))),
    (1U, key_with_middle_char_gen(@qc.pure('"'))),
    (1U, key_with_middle_char_gen(@qc.pure('#'))),
    (1U, key_with_middle_char_gen(@qc.pure('\\'))),
    (1U, key_with_middle_char_gen(@qc.pure('\n'))),
    (1U, key_with_middle_char_gen(@qc.pure('\t'))),
    (1U, padded_key_gen()),
    (1U, @qc.pure("")),
  ])
}

///|
fn simple_key_gen() -> @qc.Gen[String] {
  @qc.frequency([(3U, bare_key_gen()), (2U, complex_key_gen())])
}

///|
fn string_value_gen() -> @qc.Gen[SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  strings
  .scale(fn(size) { capped_size(size, 8) })
  .fmap(fn(value) { SString(value) })
}

///|
fn integer_value_gen() -> @qc.Gen[SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  integers.fmap(fn(value) { SInteger(value) })
}

///|
fn boolean_value_gen() -> @qc.Gen[SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  booleans.fmap(fn(value) { SBoolean(value) })
}

///|
fn non_empty_length_gen(size : Int) -> @qc.Gen[Int] {
  let max_len = capped_size(size + 1, 4)
  @qc.int_range(1, max_len + 1)
}

///|
fn string_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  let strings = strings.scale(fn(n) { capped_size(n, 8) })
  non_empty_length_gen(size).bind(fn(len) {
    strings.array_with_size(len).fmap(fn(values) { SStringArray(values) })
  })
}

///|
fn integer_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    integers.array_with_size(len).fmap(fn(values) { SIntegerArray(values) })
  })
}

///|
fn boolean_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    booleans.array_with_size(len).fmap(fn(values) { SBooleanArray(values) })
  })
}

///|
fn scalar_or_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  @qc.frequency([
    (3U, string_value_gen()),
    (2U, integer_value_gen()),
    (2U, boolean_value_gen()),
    (1U, @qc.pure(SEmptyArray)),
    (2U, string_array_value_gen(size)),
    (2U, integer_array_value_gen(size)),
    (2U, boolean_array_value_gen(size)),
  ])
}

///|
fn simple_entry_gen(size : Int) -> @qc.Gen[(String, SimpleValue)] {
  @qc.liftA2(
    fn(key, value) { (key, value) },
    simple_key_gen(),
    simple_value_gen(size),
  )
}

///|
fn table_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let next_size = size / 2
  let max_fields = capped_size(size + 1, 4)
  @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
    simple_entry_gen(next_size)
    .array_with_size(field_count)
    .fmap(fn(entries) { STable(Map::from_array(entries[:])) })
  })
}

///|
fn simple_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let leaf = scalar_or_array_value_gen(size)
  if size <= 0 {
    leaf
  } else {
    @qc.frequency([(9U, leaf), (2U, table_value_gen(size))])
  }
}

///|
fn simple_document_gen() -> @qc.Gen[SimpleDocument] {
  @qc.sized(fn(size) {
    let max_fields = capped_size(size + 1, 5)
    @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
      simple_entry_gen(size)
      .array_with_size(field_count)
      .fmap(fn(entries) { { fields: Map::from_array(entries[:]) } })
    })
  })
}

///|
fn shrink_table_entries(
  entries : Array[(String, SimpleValue)],
) -> Iter[Array[(String, SimpleValue)]] {
  let removed_entries = Array::makei(entries.length(), fn(i) {
    let next = entries.copy()
    next.remove(i) |> ignore
    next
  }).iter()
  let shrunk_values = Array::makei(entries.length(), fn(i) {
      let (key, value) = entries[i]
      @qc.Shrink::shrink(value)
      .map(fn(next_value) {
        let next = entries.copy()
        next[i] = (key, next_value)
        next
      })
      .to_array()
    })
    .flatten()
    .iter()
  removed_entries.concat(shrunk_values)
}

///|
impl @qc.Shrink for SimpleValue with shrink(self) {
  match self {
    SString(value) => @qc.Shrink::shrink(value).map(fn(next) { SString(next) })
    SInteger(value) =>
      @qc.Shrink::shrink(value).map(fn(next) { SInteger(next) })
    SBoolean(value) =>
      @qc.Shrink::shrink(value).map(fn(next) { SBoolean(next) })
    SEmptyArray => Iter::empty()
    SStringArray(values) =>
      @qc.Shrink::shrink(values).map(fn(next_values) {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SStringArray(next_values)
        }
      })
    SIntegerArray(values) =>
      @qc.Shrink::shrink(values).map(fn(next_values) {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SIntegerArray(next_values)
        }
      })
    SBooleanArray(values) =>
      @qc.Shrink::shrink(values).map(fn(next_values) {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SBooleanArray(next_values)
        }
      })
    STable(fields) =>
      shrink_table_entries(fields.to_array()).map(fn(next_entries) {
        STable(Map::from_array(next_entries[:]))
      })
  }
}

///|
impl @qc.Shrink for SimpleDocument with shrink(self) {
  shrink_table_entries(self.fields.to_array()).map(fn(next_entries) {
    { fields: Map::from_array(next_entries[:]) }
  })
}

///|
fn SimpleValue::to_toml_value(self : SimpleValue) -> @toml.TomlValue {
  match self {
    SString(value) => @toml.TomlString(value)
    SInteger(value) => @toml.TomlInteger(value)
    SBoolean(value) => @toml.TomlBoolean(value)
    SEmptyArray => @toml.TomlArray([])
    SStringArray(values) =>
      @toml.TomlArray(values.map(fn(value) { @toml.TomlString(value) }))
    SIntegerArray(values) =>
      @toml.TomlArray(values.map(fn(value) { @toml.TomlInteger(value) }))
    SBooleanArray(values) =>
      @toml.TomlArray(values.map(fn(value) { @toml.TomlBoolean(value) }))
    STable(fields) =>
      @toml.TomlTable(
        Map::from_array(
          fields
          .to_array()
          .map(fn(entry) {
            let (key, value) = entry
            (key, value.to_toml_value())
          })[:],
        ),
      )
  }
}

///|
fn SimpleDocument::to_toml_value(self : SimpleDocument) -> @toml.TomlValue {
  @toml.TomlTable(
    Map::from_array(
      self.fields
      .to_array()
      .map(fn(entry) {
        let (key, value) = entry
        (key, value.to_toml_value())
      })[:],
    ),
  )
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
fn simple_string_from_toml(value : @toml.TomlValue) -> String? {
  match value {
    @toml.TomlString(text) => Some(text)
    _ => None
  }
}

///|
fn simple_integer_from_toml(value : @toml.TomlValue) -> Int64? {
  match value {
    @toml.TomlInteger(number) => Some(number)
    _ => None
  }
}

///|
fn simple_boolean_from_toml(value : @toml.TomlValue) -> Bool? {
  match value {
    @toml.TomlBoolean(boolean) => Some(boolean)
    _ => None
  }
}

///|
fn is_bare_key_char(ch : Char) -> Bool {
  match ch {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-' => true
    _ => false
  }
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
fn simple_table_entries_from_toml(
  entries : ArrayView[(String, @toml.TomlValue)],
) -> Array[(String, SimpleValue)]? {
  match entries {
    [] => Some([])
    [(key, value), .. rest] =>
      match
        (simple_value_from_toml(value), simple_table_entries_from_toml(rest)) {
        (Some(simple), Some(next)) => Some([(key, simple), ..next])
        _ => None
      }
  }
}

///|
fn simple_value_from_toml(value : @toml.TomlValue) -> SimpleValue? {
  match value {
    @toml.TomlString(text) => Some(SString(text))
    @toml.TomlInteger(number) => Some(SInteger(number))
    @toml.TomlBoolean(boolean) => Some(SBoolean(boolean))
    @toml.TomlArray(values) =>
      match values {
        [] => Some(SEmptyArray)
        [@toml.TomlString(_), ..] =>
          collect_toml_array(values[:], simple_string_from_toml).map(fn(items) {
            SStringArray(items)
          })
        [@toml.TomlInteger(_), ..] =>
          collect_toml_array(values[:], simple_integer_from_toml).map(fn(
            items,
          ) {
            SIntegerArray(items)
          })
        [@toml.TomlBoolean(_), ..] =>
          collect_toml_array(values[:], simple_boolean_from_toml).map(fn(
            items,
          ) {
            SBooleanArray(items)
          })
        _ => None
      }
    @toml.TomlTable(fields) =>
      match simple_table_entries_from_toml(fields.to_array()[:]) {
        Some(entries) => Some(STable(Map::from_array(entries[:])))
        None => None
      }
    _ => None
  }
}

///|
fn simple_document_from_toml(value : @toml.TomlValue) -> SimpleDocument? {
  match value {
    @toml.TomlTable(fields) =>
      match simple_table_entries_from_toml(fields.to_array()[:]) {
        Some(entries) => Some({ fields: Map::from_array(entries[:]) })
        None => None
      }
    _ => None
  }
}

///|
fn SimpleValue::contains_table(self : SimpleValue) -> Bool {
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
fn SimpleValue::contains_array(self : SimpleValue) -> Bool {
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
fn SimpleValue::contains_string(self : SimpleValue) -> Bool {
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
fn SimpleValue::contains_complex_key(self : SimpleValue) -> Bool {
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
fn SimpleDocument::contains_table(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_table()
  })
}

///|
fn SimpleDocument::contains_array(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_array()
  })
}

///|
fn SimpleDocument::contains_string(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (_key, value) = entry
    value.contains_string()
  })
}

///|
fn SimpleDocument::contains_complex_key(self : SimpleDocument) -> Bool {
  self.fields
  .to_array()
  .any(fn(entry) {
    let (key, value) = entry
    !is_bare_key(key) || value.contains_complex_key()
  })
}

///|
fn simple_document_roundtrip_check(
  doc : SimpleDocument,
  rendered : String,
) -> Result[Unit, String] {
  try @toml.parse(rendered) catch {
    error =>
      Err(
        "parser rejected generated TOML\nrendered:\n\{rendered}\nerror:\n\{error}",
      )
  } noraise {
    parsed =>
      match simple_document_from_toml(parsed) {
        Some(roundtripped) =>
          if roundtripped == doc {
            Ok(())
          } else {
            Err(
              "round-trip mismatch\nrendered:\n\{rendered}\noriginal:\n\{doc}\nparsed:\n\{roundtripped}",
            )
          }
        None =>
          Err(
            "parsed document escaped the simple fragment\nrendered:\n\{rendered}\nparsed:\n\{parsed}",
          )
      }
  }
}

///|
fn simple_document_roundtrip_property(doc : SimpleDocument) -> @qc.Property {
  let rendered = doc.to_toml_value().to_string()
  let checked = simple_document_roundtrip_check(doc, rendered)
  @qc.counterexample(
    @qc.classify(
      @qc.classify(
        @qc.classify(
          @qc.classify(checked, doc.contains_table(), "contains-table"),
          doc.contains_array(),
          "contains-array",
        ),
        doc.contains_complex_key(),
        "contains-complex-key",
      ),
      doc.contains_string(),
      "contains-string",
    ),
    rendered,
  )
}

///|
test "quickcheck simple document roundtrip" {
  inspect(
    @qc.quick_check_silence(
      @qc.forall_shrink(
        simple_document_gen(),
        SimpleDocument::shrink,
        simple_document_roundtrip_property,
      ),
      max_success=2000,
      max_size=12,
    ),
    content=(
      #|+++ [2000/0/2000] Ok, passed!
      #|49.85% : contains-string
      #|56.2% : contains-complex-key
      #|60.550000000000004% : contains-array
      #|29.15% : contains-table
    ),
  )
}
