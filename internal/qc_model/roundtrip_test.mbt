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
/// Drive the round-trip property with the core QuickCheck driver and
/// snapshot the whole report: the `observe` classifications double as a
/// structural-coverage regression net, and `counterexample_context`
/// renders the rendered TOML and mismatch detail for a shrunk failure.
test "quickcheck simple document roundtrip" {
  let result = @qc.report(
    (doc : @qc_model.SimpleDocument) => {
      simple_document_roundtrip_check(doc, doc.to_toml().to_string()) is Ok(_)
    },
    counterexample_context=roundtrip_failure_context,
    observe=doc => {
      [
        @qc.classify(doc.contains_table(), "contains-table"),
        @qc.classify(doc.contains_array(), "contains-array"),
        @qc.classify(doc.contains_datetime_array(), "contains-datetime-array"),
        @qc.classify(
          doc.contains_fractional_datetime(),
          "contains-fractional-datetime",
        ),
        @qc.classify(doc.contains_datetime(), "contains-datetime"),
        @qc.classify(
          doc.contains_negative_exponent_like_key(),
          "contains-negative-exponent-like-key",
        ),
        @qc.classify(doc.contains_complex_key(), "contains-complex-key"),
        @qc.classify(doc.contains_string(), "contains-string"),
      ]
    },
    count=2000,
    max_size=12,
  )
  debug_inspect(
    result,
    content=(
      #|Passed(
      #|  tests=2000,
      #|  observations={
      #|    classes: {
      #|      "contains-table": 570,
      #|      "contains-array": 1218,
      #|      "contains-datetime-array": 448,
      #|      "contains-fractional-datetime": 408,
      #|      "contains-datetime": 752,
      #|      "contains-negative-exponent-like-key": 652,
      #|      "contains-complex-key": 1024,
      #|      "contains-string": 890,
      #|    },
      #|  },
      #|)
    ),
  )
}
