///|
/// Shrinkers for the QuickCheck model, expressed as
/// `moonbitlang/core/quickcheck/shrink` trait impls so the core `@qc.check`
/// driver can minimize failing documents.

///|
fn shrink_simple_value(value : SimpleValue) -> Iter[SimpleValue] {
  match value {
    SString(s) => @shrink.Shrink::shrink(s).map(next => SString(next))
    SInteger(n) => @shrink.Shrink::shrink(n).map(next => SInteger(next))
    SBoolean(b) => @shrink.Shrink::shrink(b).map(next => SBoolean(next))
    SDateTime(_) => Iter::empty()
    SDateTimeArray(values) =>
      shrink_datetime_values(values).map(next_values => {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SDateTimeArray(next_values)
        }
      })
    SEmptyArray => Iter::empty()
    SStringArray(values) =>
      @shrink.Shrink::shrink(values).map(next_values => {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SStringArray(next_values)
        }
      })
    SIntegerArray(values) =>
      @shrink.Shrink::shrink(values).map(next_values => {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SIntegerArray(next_values)
        }
      })
    SBooleanArray(values) =>
      @shrink.Shrink::shrink(values).map(next_values => {
        if next_values.is_empty() {
          SEmptyArray
        } else {
          SBooleanArray(next_values)
        }
      })
    STable(fields) =>
      shrink_table_entries(fields.to_array()).map(next_entries => {
        STable(Map::from_array(next_entries))
      })
  }
}

///|
fn shrink_datetime_values(
  values : Array[@datetime.TomlDateTime],
) -> Iter[Array[@datetime.TomlDateTime]] {
  Array::makei(values.length(), i => {
    let next = values.copy()
    next.remove(i) |> ignore
    next
  }).iter()
}

///|
fn shrink_table_entries(
  entries : Array[(String, SimpleValue)],
) -> Iter[Array[(String, SimpleValue)]] {
  let removed_entries = Array::makei(entries.length(), i => {
    let next = entries.copy()
    next.remove(i) |> ignore
    next
  }).iter()
  let shrunk_values = Array::makei(entries.length(), i => {
      let (key, value) = entries[i]
      shrink_simple_value(value)
      .map(next_value => {
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
pub impl @shrink.Shrink for SimpleDocument with fn shrink(self) {
  shrink_table_entries(self.fields.to_array()).map(next_entries => {
    fields: Map::from_array(next_entries),
  })
}

///|
#deprecated("shrinking is driven by `@qc.check`; the Shrink impl is unaffected")
pub extend SimpleDocument with @shrink.Shrink::{shrink}
