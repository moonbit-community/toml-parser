///|
pub fn shrink_table_entries(
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
pub impl @qc.Shrink for SimpleValue with shrink(self) {
  match self {
    SString(value) => @qc.Shrink::shrink(value).map(fn(next) { SString(next) })
    SInteger(value) =>
      @qc.Shrink::shrink(value).map(fn(next) { SInteger(next) })
    SBoolean(value) =>
      @qc.Shrink::shrink(value).map(fn(next) { SBoolean(next) })
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
        STable(Map::from_array(next_entries[:]))
      })
  }
}

///|
pub impl @qc.Shrink for SimpleDocument with shrink(self) {
  shrink_table_entries(self.fields.to_array()).map(fn(next_entries) {
    { fields: Map::from_array(next_entries[:]) }
  })
}
