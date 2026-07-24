///|
/// A `TomlValue` drawn from the round-trip-safe fragment, wrapped so it can
/// carry the quickcheck trait instances.
///
/// A companion package cannot implement the foreign `@core_qc.Arbitrary` /
/// `@qc.Shrink` traits directly on the foreign `@toml.TomlValue` (orphan
/// rule), so we wrap it in a local newtype — the same pattern the quickcheck
/// library uses for its own modifiers (`Positive`, `NonEmptyArray`, ...).
/// With the instances attached, downstream tests get the ergonomic runner:
///
/// ```mbt nocheck
/// test {
///   @qc.quick_check_fn(fn(doc : @quickcheck.RoundTrippable) {
///     let value = doc.inner()
///     @toml.parse(value.to_string()) == value
///   })
/// }
/// ```
pub(all) struct RoundTrippable(@toml.TomlValue) derive(Eq, Debug)

///|
pub extend RoundTrippable with Eq::{not_equal, equal}

///|
pub extend RoundTrippable with Debug::{to_repr}

///|
/// Unwrap to the underlying `TomlValue`.
pub fn RoundTrippable::inner(self : RoundTrippable) -> @toml.TomlValue {
  let RoundTrippable(value) = self
  value
}

///|
pub impl @core_qc.Arbitrary for RoundTrippable with fn arbitrary(size, rng) {
  RoundTrippable(roundtrippable_document().run(size, rng))
}

///|
#deprecated("resolve through the Arbitrary trait, e.g. via @qc.quick_check_fn")
pub extend RoundTrippable with @core_qc.Arbitrary::{arbitrary}

///|
pub impl @qc.Shrink for RoundTrippable with fn shrink(self) {
  shrink_document(self.inner()).map(fn(value) { RoundTrippable(value) })
}

///|
#deprecated("resolve through the Shrink trait")
pub extend RoundTrippable with @qc.Shrink::{shrink}
