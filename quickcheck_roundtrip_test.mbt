///|
fn simple_value_to_toml(value : @qc_model.SimpleValue) -> @toml.TomlValue {
  match value {
    SString(s) => @toml.TomlString(s)
    SInteger(n) => @toml.TomlInteger(n)
    SBoolean(b) => @toml.TomlBoolean(b)
    SEmptyArray => @toml.TomlArray([])
    SStringArray(values) =>
      @toml.TomlArray(values.map(fn(v) { @toml.TomlString(v) }))
    SIntegerArray(values) =>
      @toml.TomlArray(values.map(fn(v) { @toml.TomlInteger(v) }))
    SBooleanArray(values) =>
      @toml.TomlArray(values.map(fn(v) { @toml.TomlBoolean(v) }))
    STable(fields) =>
      @toml.TomlTable(
        Map::from_array(
          fields
          .to_array()
          .map(fn(entry) {
            let (key, v) = entry
            (key, simple_value_to_toml(v))
          })[:],
        ),
      )
  }
}

///|
fn simple_document_to_toml(doc : @qc_model.SimpleDocument) -> @toml.TomlValue {
  @toml.TomlTable(
    Map::from_array(
      doc.fields
      .to_array()
      .map(fn(entry) {
        let (key, v) = entry
        (key, simple_value_to_toml(v))
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
fn simple_table_entries_from_toml(
  entries : ArrayView[(String, @toml.TomlValue)],
) -> Array[(String, @qc_model.SimpleValue)]? {
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
fn simple_value_from_toml(value : @toml.TomlValue) -> @qc_model.SimpleValue? {
  match value {
    @toml.TomlString(text) => Some(@qc_model.SString(text))
    @toml.TomlInteger(number) => Some(@qc_model.SInteger(number))
    @toml.TomlBoolean(boolean) => Some(@qc_model.SBoolean(boolean))
    @toml.TomlArray(values) =>
      match values {
        [] => Some(@qc_model.SEmptyArray)
        [@toml.TomlString(_), ..] =>
          collect_toml_array(values[:], simple_string_from_toml).map(fn(items) {
            @qc_model.SStringArray(items)
          })
        [@toml.TomlInteger(_), ..] =>
          collect_toml_array(values[:], simple_integer_from_toml).map(fn(
            items,
          ) {
            @qc_model.SIntegerArray(items)
          })
        [@toml.TomlBoolean(_), ..] =>
          collect_toml_array(values[:], simple_boolean_from_toml).map(fn(
            items,
          ) {
            @qc_model.SBooleanArray(items)
          })
        _ => None
      }
    @toml.TomlTable(fields) =>
      match simple_table_entries_from_toml(fields.to_array()[:]) {
        Some(entries) => Some(@qc_model.STable(Map::from_array(entries[:])))
        None => None
      }
    _ => None
  }
}

///|
fn simple_document_from_toml(
  value : @toml.TomlValue,
) -> @qc_model.SimpleDocument? {
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
fn simple_document_roundtrip_check(
  doc : @qc_model.SimpleDocument,
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
fn simple_document_roundtrip_property(
  doc : @qc_model.SimpleDocument,
) -> @qc.Property {
  let rendered = simple_document_to_toml(doc).to_string()
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
        @qc_model.simple_document_gen(),
        @qc_model.SimpleDocument::shrink,
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
