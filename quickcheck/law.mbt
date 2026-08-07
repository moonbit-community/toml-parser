///|
/// The round-trip law as a plain predicate: does `value` render and parse back
/// to an equal value?
///
/// Parser errors are caught and reported as `false`, so this composes with any
/// quickcheck runner without threading a `raise` effect through the property.
/// For richer failure output (which key/value diverged), catch `@toml.parse`
/// yourself and build a `Result[Unit, String]` counterexample instead.
pub fn round_trips(value : @toml.TomlValue) -> Bool {
  let rendered = value.to_string()
  try @toml.parse(rendered) catch {
    _ => false
  } noraise {
    parsed => parsed == value
  }
}
