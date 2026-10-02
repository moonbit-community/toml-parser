///|
/// Shrinkers for the round-trip-safe fragment.
///
/// `TomlValue` has no `@qc.Shrink` instance of its own (a companion package
/// can't add one — orphan rule), so these are plain functions. They pair with
/// [`roundtrippable_document`] under `@qc.forall_shrink`, and back the
/// `@qc.Shrink` impl on [`RoundTrippable`].

///|
fn[T] drop_each(items : Array[T]) -> Iter[Array[T]] {
  Array::makei(items.length(), fn(i) {
    let next = items.copy()
    next.remove(i) |> ignore
    next
  }).iter()
}

///|
fn shrink_value(value : @toml.TomlValue) -> Iter[@toml.TomlValue] {
  match value {
    TomlString(s) => @qc.Shrink::shrink(s).map(fn(next) { TomlString(next) })
    TomlInteger(n) => @qc.Shrink::shrink(n).map(fn(next) { TomlInteger(next) })
    TomlBoolean(b) => @qc.Shrink::shrink(b).map(fn(next) { TomlBoolean(next) })
    // Atomic in this fragment: datetimes don't shrink, and floats are never
    // generated (kept here only for match exhaustiveness).
    TomlDateTime(_) | TomlFloat(_) => Iter::empty()
    // Arrays shrink by dropping elements (which preserves homogeneity);
    // an emptied array is still round-trippable.
    TomlArray(items) => drop_each(items).map(fn(next) { TomlArray(next) })
    TomlTable(fields) =>
      shrink_entries(fields.to_array()).map(fn(next) {
        TomlTable(Map::from_array(next))
      })
  }
}

///|
fn shrink_entries(
  entries : Array[(String, @toml.TomlValue)],
) -> Iter[Array[(String, @toml.TomlValue)]] {
  let removed = drop_each(entries)
  let shrunk_values = Array::makei(entries.length(), fn(i) {
      let (key, value) = entries[i]
      shrink_value(value)
      .map(fn(next_value) {
        let next = entries.copy()
        next[i] = (key, next_value)
        next
      })
      .to_array()
    })
    .flatten()
    .iter()
  removed.concat(shrunk_values)
}

///|
/// Shrink a top-level document toward smaller failing cases by removing table
/// entries and simplifying individual values.
pub fn shrink_document(document : @toml.TomlValue) -> Iter[@toml.TomlValue] {
  match document {
    TomlTable(fields) =>
      shrink_entries(fields.to_array()).map(fn(next) {
        TomlTable(Map::from_array(next))
      })
    _ => Iter::empty()
  }
}
