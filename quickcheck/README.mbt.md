# `bobzhang/toml/quickcheck`

Property-testing support for [`bobzhang/toml`](../), kept in a **companion
package** so the core parser stays free of any quickcheck dependency — you only
pull `moonbitlang/quickcheck` (and its transitive weight) when you actually
import this package.

## What it provides

- `roundtrippable_document() : @gen.Gen[@toml.TomlValue]` — a generator for the
  round-trip-safe fragment of TOML (every primitive, homogeneous arrays, nested
  tables, and adversarial keys; **no** floats or mixed arrays, so exact
  equality is meaningful).
- `shrink_document(doc) : Iter[@toml.TomlValue]` — the matching shrinker.
- `round_trips(value) : Bool` — the law `parse(v.to_string()) == v` as a
  predicate (parser errors caught as `false`).
- `RoundTrippable` — a newtype over `TomlValue` carrying the `Arbitrary` and
  `Shrink` trait instances, for the ergonomic `quick_check_fn` runner.

### Why a newtype?

A companion package cannot write `impl Arbitrary for TomlValue`: both the trait
(`moonbitlang/core/quickcheck`) and the type (`bobzhang/toml`) are foreign to
it, which the orphan rule forbids. Wrapping `TomlValue` in a **local** newtype
is the standard escape hatch — the same pattern `moonbitlang/quickcheck`'s own
`modifiers` package uses (`Positive`, `NonEmptyArray`, ...).

## Idiom 1 — trait-driven runner

`quick_check_fn` reads the generator and shrinker straight off the
`RoundTrippable` instances, so you only name the property:

```mbt check
///|
test "documents survive a parse round-trip" {
  @qc.quick_check_fn(
    fn(document : @quickcheck.RoundTrippable) {
      @quickcheck.round_trips(document.0)
    },
    max_success=100,
  )
}
```

## Idiom 2 — explicit generators

When you want to combine several generators, or skip the newtype, hand the
generator and shrinker to `forall_shrink` directly:

```mbt check
///|
test "documents survive a parse round-trip (explicit)" {
  @qc.quick_check(
    @qc.forall_shrink(
      @quickcheck.roundtrippable_document(),
      @quickcheck.shrink_document,
      fn(value) { @quickcheck.round_trips(value) },
    ),
    max_success=100,
  )
}
```
