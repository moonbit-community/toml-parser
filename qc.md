# QuickCheck Roundtrip Testing

This project uses the QuickCheck framework that ships with the MoonBit core
library (`moonbitlang/core/quickcheck`, introduced by
[moonbitlang/core#3955](https://github.com/moonbitlang/core/pull/3955)) to
verify that the TOML serializer produces output the parser can round-trip
correctly. No third-party dependency is needed.

## How It Works

The test generates random TOML documents, serializes them to strings, parses the strings back, and checks that the result matches the original.

```mermaid
flowchart LR
    A[Generate random\nSimpleDocument] --> B[Convert to\nTomlValue]
    B --> C[Serialize via\nto_string]
    C --> D[Parse back via\n@toml.parse]
    D --> E[Convert back to\nSimpleDocument]
    E --> F{Original ==\nRoundtripped?}
    F -->|Yes| G[Pass]
    F -->|No| H[Shrink & retry]
    H --> A
```

## Architecture

The test uses a **simplified document model** (`SimpleDocument` / `SimpleValue`) rather than the full `TomlValue` type. This avoids generating values that are hard to round-trip (floats, datetimes) and focuses on the structural correctness of the serializer.

```mermaid
classDiagram
    class SimpleDocument {
        fields: Map~String, SimpleValue~
        to_toml_value() TomlValue
    }
    class SimpleValue {
        <<enum>>
        SString(String)
        SInteger(Int64)
        SBoolean(Bool)
        SEmptyArray
        SStringArray(Array~String~)
        SIntegerArray(Array~Int64~)
        SBooleanArray(Array~Bool~)
        STable(Map~String, SimpleValue~)
    }
    SimpleDocument --> SimpleValue : contains
    SimpleValue --> SimpleValue : STable nests
```

## QuickCheck Components

The QuickCheck plumbing lives in the `internal/qc_model` package:

- `internal/qc_model/generator.mbt` defines the generators and the
  `Arbitrary` impl for `SimpleDocument`.
- `internal/qc_model/shrink.mbt` defines the shrinkers and the `Shrink`
  impl for `SimpleDocument`.
- `internal/qc_model/roundtrip_test.mbt` drives the round-trip property
  with `@qc.report`, classifying every case via `observe`, and snapshots
  the whole report (pass status plus structural coverage).

The test implements four key pieces required by the quickcheck framework:

### 1. Generators (`@qc.Generator`)

Generators produce random values. Each type needs a custom generator.

```mermaid
flowchart TD
    subgraph "Key Generators"
        BK[bare_key_gen\na-z, 0-9, -, _] --> SK[simple_key_gen]
        CK[complex_key_gen\nspaces, dots, quotes, etc.] --> SK
    end

    subgraph "Value Generators"
        SV[string_value_gen]
        IV[integer_value_gen]
        BV[boolean_value_gen]
        SA[string_array_value_gen]
        IA[integer_array_value_gen]
        BA[boolean_array_value_gen]
        TV[table_value_gen]
    end

    SV & IV & BV & SA & IA & BA --> SOAV[scalar_or_array_value_gen]
    SOAV & TV --> SVG[simple_value_gen]
    SK & SVG --> EG[simple_entry_gen]
    EG --> DG[simple_document_gen]
```

Key generator patterns used:

| Pattern | Example | Purpose |
|---------|---------|---------|
| `spawn()` (local helper) | `(spawn() : @qc.Generator[String])` | Use the built-in Arbitrary instance |
| `@qc.one_of([...])` | `one_of([pure('-'), pure('_')])` | Choose uniformly from options |
| `@qc.frequency([...])` | `frequency([(3U, bare), (2U, complex)])` | Weighted random choice |
| `@qc.char_range(lo, hi)` | `char_range('a', 'z')` | Characters in an inclusive range |
| `.map(fn)` | `gen.map(x => SString(x))` | Transform generated values |
| `.flat_map(fn)` | `gen.flat_map(n => ...)` | Chain dependent generators |
| `.zip(g)` / `.zip_with(g, f)` / `.zip_with3(g2, g3, f)` | `key_gen.zip(val_gen)` | Combine generators applicatively |
| `.scale(fn)` | `gen.scale(s => min(s, 8))` | Control size parameter |
| `.array_with_size(n)` | `gen.array_with_size(len)` | Generate fixed-size arrays |
| `@qc.sized(fn)` | `sized(size => ...)` | Access the current size |

`spawn` (a generator from an `Arbitrary` instance) is the only remaining
local helper; the core package covers everything else directly.

### 2. Shrinker (`impl @shrink.Shrink for SimpleDocument`)

When a test fails, quickcheck uses shrinkers to find the **minimal** failing case. The shrinker tries:
- Removing individual entries from tables
- Shrinking individual values within entries

```moonbit
fn shrink_simple_value(value : SimpleValue) -> Iter[SimpleValue] {
  match value {
    SString(s) => @shrink.Shrink::shrink(s).map(next => SString(next))
    STable(fields) =>
      shrink_table_entries(fields.to_array()).map(next_entries => STable(
        Map::from_array(next_entries),
      ))
    // ...
  }
}
```

### 3. Property (`(SimpleDocument) -> Bool raise?`)

The property is a plain function; on failure it raises with the rendered
TOML so the counterexample text appears in the failure report:

```moonbit
(doc : @qc_model.SimpleDocument) => {
  let rendered = doc.to_toml().to_string()
  match simple_document_roundtrip_check(doc, rendered) {
    Ok(_) => true
    Err(message) => fail(message)
  }
}
```

The core driver reports the shrunk counterexample via `Debug` alongside
the raised message.

### 4. Running and Coverage (`@qc.report` + `observe`)

The driver's `observe` parameter classifies every accepted case, so one
run both checks the property and tracks structural coverage. The test
snapshots the entire report:

```moonbit
test "quickcheck simple document roundtrip" {
  let result = @qc.report(
    roundtrip_property,
    observe=doc => [
      @qc.classify(doc.contains_table(), "contains-table"),
      @qc.classify(doc.contains_array(), "contains-array"),
      // ... six more classifiers
    ],
    count=2000,
    max_size=12,
  )
  debug_inspect(result, content=...)
}
```

A passing run snapshots as `Passed(tests=2000, observations={ classes:
{ "contains-table": 570, "contains-array": 1218, ... } })` — ~29% of
generated documents contain nested tables and ~61% contain arrays. If a
generator change shifts the distribution, the snapshot fails and the new
counts must be reviewed. A failing run renders the shrunk counterexample
and the raised message (which carries the rendered TOML) instead.

## Size Control

The generators use `capped_size` to keep documents manageable:

- Keys: max 5 characters (`capped_size(size, 4)` for tail)
- Strings: max 8 characters (`.scale(fn(s) { capped_size(s, 8) })`)
- Table fields: max 4-5 entries
- Nesting: halved at each level (`size / 2`)

This prevents exponential blowup while still generating interesting structures.
