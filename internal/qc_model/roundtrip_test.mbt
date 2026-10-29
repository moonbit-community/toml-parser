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
      match @qc_model.SimpleDocument::from_toml(parsed) {
        Some(roundtripped) =>
          if roundtripped == doc {
            Ok(())
          } else {
            Err(
              "round-trip mismatch\nrendered:\n\{rendered}\noriginal:\n\{repr(doc)}\nparsed:\n\{repr(roundtripped)}",
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
/// Diagnose a document that failed the round-trip, for
/// `counterexample_context`. Only ever called on a shrunk counterexample,
/// so the `Ok` branch is unreachable in practice.
fn roundtrip_failure_context(doc : @qc_model.SimpleDocument) -> String {
  match simple_document_roundtrip_check(doc, doc.to_toml().to_string()) {
    Ok(_) => "document round-trips cleanly"
    Err(message) => message
  }
}

///|
/// Drive the round-trip property with the core QuickCheck driver. Require
/// every structural feature in at least 10% of generated documents, without
/// coupling the test to the generator's exact sample sequence.
/// Counterexamples retain the generated TOML and shrunk mismatch context.
test "quickcheck simple document roundtrip" {
  let coverage : Map[String, Int32] = Map([])
  @qc.check(
    (doc : @qc_model.SimpleDocument) => {
      simple_document_roundtrip_check(doc, doc.to_toml().to_string()) is Ok(_)
    },
    counterexample_context=roundtrip_failure_context,
    observe=doc => {
      let features = [
        (doc.contains_table(), "contains-table"),
        (doc.contains_array(), "contains-array"),
        (doc.contains_datetime_array(), "contains-datetime-array"),
        (doc.contains_fractional_datetime(), "contains-fractional-datetime"),
        (doc.contains_datetime(), "contains-datetime"),
        (
          doc.contains_negative_exponent_like_key(),
          "contains-negative-exponent-like-key",
        ),
        (doc.contains_complex_key(), "contains-complex-key"),
        (doc.contains_string(), "contains-string"),
      ]
      features.map(fn(feature) {
        let (present, label) = feature
        let count = coverage.get(label).unwrap_or(0)
        coverage[label] = count + (if present { 1 } else { 0 })
        @qc.classify(present, label)
      })
    },
    count=2000,
    max_size=12,
  )
  assert_eq(coverage.length(), 8)
  for label, count in coverage {
    assert_true(
      count >= 200,
      msg="insufficient coverage for \{label}: \{count}/2000",
    )
  }
}
