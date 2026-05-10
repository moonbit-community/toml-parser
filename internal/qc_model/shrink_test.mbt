///|
fn shrink_simple_value(
  value : @qc_model.SimpleValue,
) -> Iter[@qc_model.SimpleValue] {
  match value {
    SString(s) => @qc.Shrink::shrink(s).map(fn(next) { SString(next) })
    SInteger(n) => @qc.Shrink::shrink(n).map(fn(next) { SInteger(next) })
    SBoolean(b) => @qc.Shrink::shrink(b).map(fn(next) { SBoolean(next) })
    SDateTime(_) => Iter::empty()
    SDateTimeArray(values) =>
      shrink_datetime_values(values).map(fn(next_values) {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SDateTimeArray(next_values)
        }
      })
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
        STable(Map::from_array(next_entries))
      })
  }
}

///|
fn shrink_datetime_values(
  values : Array[@tokenize.TomlDateTime],
) -> Iter[Array[@tokenize.TomlDateTime]] {
  Array::makei(values.length(), fn(i) {
    let next = values.copy()
    next.remove(i) |> ignore
    next
  }).iter()
}

///|
fn shrink_table_entries(
  entries : Array[(String, @qc_model.SimpleValue)],
) -> Iter[Array[(String, @qc_model.SimpleValue)]] {
  let removed_entries = Array::makei(entries.length(), fn(i) {
    let next = entries.copy()
    next.remove(i) |> ignore
    next
  }).iter()
  let shrunk_values = Array::makei(entries.length(), fn(i) {
      let (key, value) = entries[i]
      shrink_simple_value(value)
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
fn shrink_simple_document(
  doc : @qc_model.SimpleDocument,
) -> Iter[@qc_model.SimpleDocument] {
  shrink_table_entries(doc.fields.to_array()).map(next_entries => {
    fields: Map::from_array(next_entries),
  })
}
