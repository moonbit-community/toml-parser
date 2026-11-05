///|
/// Property: every document from the round-trip-safe fragment survives
/// `to_string` -> `@toml.parse` unchanged.
///
/// This is the trait-driven idiom — `quick_check_fn` pulls the generator and
/// shrinker straight off the `RoundTrippable` instances, so the call names
/// only the property.
fn roundtrip_property(document : @quickcheck.RoundTrippable) -> @qc.Property {
  let value = document.0
  let rendered = value.to_string()
  check_roundtrip(value, rendered)
  |> @qc.classify(is_nested(value), "nested-table")
  |> @qc.counterexample(rendered)
}

///|
fn check_roundtrip(
  value : @toml.TomlValue,
  rendered : String,
) -> Result[Unit, String] {
  try @toml.parse(rendered) catch {
    error => Err("parser rejected generated TOML\n\{rendered}\n---\n\{error}")
  } noraise {
    parsed =>
      if parsed == value {
        Ok(())
      } else {
        Err("round-trip mismatch\nrendered:\n\{rendered}\nparsed:\n\{parsed}")
      }
  }
}

///|
fn is_nested(value : @toml.TomlValue) -> Bool {
  match value {
    TomlTable(fields) => fields.values().any(fn(v) { v is TomlTable(_) })
    _ => false
  }
}

///|
test "round-trip law via quick_check_fn (trait-driven)" {
  @qc.quick_check_fn_silence(roundtrip_property, max_success=500, max_size=10)
  |> ignore
}

///|
/// The same property expressed with the explicit-value idiom: hand the
/// generator and shrinker to `forall_shrink` directly. Useful when a type has
/// several generation strategies and no single canonical instance fits.
test "round-trip law via forall_shrink (explicit generators)" {
  @qc.quick_check_silence(
    @qc.forall_shrink(
      @quickcheck.roundtrippable_document(),
      @quickcheck.shrink_document,
      fn(value) {
        let rendered = value.to_string()
        check_roundtrip(value, rendered) |> @qc.counterexample(rendered)
      },
    ),
    max_success=500,
    max_size=10,
  )
  |> ignore
}
