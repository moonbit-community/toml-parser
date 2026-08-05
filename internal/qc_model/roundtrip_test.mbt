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
/// Drive the round-trip property with the core QuickCheck driver. On
/// failure, the shrunk counterexample is reported via `Debug` and the
/// raised message carries the rendered TOML.
test "quickcheck simple document roundtrip" {
  @qc.check(
    (doc : @qc_model.SimpleDocument) => {
      let rendered = doc.to_toml().to_string()
      match simple_document_roundtrip_check(doc, rendered) {
        Ok(_) => true
        Err(message) => fail(message)
      }
    },
    count=2000,
    max_size=12,
  )
}

///|
/// Snapshot of the generator's structural coverage over a fixed seed, so
/// distribution regressions in the generators stay visible now that the
/// driver no longer prints classification stats.
test "generator coverage distribution" {
  let docs = @qc_model.simple_document_generator().samples(
    count=2000,
    size=12,
    seed=37,
  )
  let labels : Array[(String, (@qc_model.SimpleDocument) -> Bool)] = [
    ("contains-table", doc => doc.contains_table()),
    ("contains-array", doc => doc.contains_array()),
    ("contains-datetime-array", doc => doc.contains_datetime_array()),
    ("contains-fractional-datetime", doc => doc.contains_fractional_datetime()),
    ("contains-datetime", doc => doc.contains_datetime()),
    (
      "contains-negative-exponent-like-key",
      doc => doc.contains_negative_exponent_like_key(),
    ),
    ("contains-complex-key", doc => doc.contains_complex_key()),
    ("contains-string", doc => doc.contains_string()),
  ]
  let report = StringBuilder()
  for label in labels {
    let (name, predicate) = label
    let hits = docs.iter().filter(predicate).count()
    report <+ "\{hits}/\{docs.length()} : \{name}\n"
  }
  inspect(
    report.to_string(),
    content=(
      #|651/2000 : contains-table
      #|1338/2000 : contains-array
      #|519/2000 : contains-datetime-array
      #|548/2000 : contains-fractional-datetime
      #|855/2000 : contains-datetime
      #|767/2000 : contains-negative-exponent-like-key
      #|1210/2000 : contains-complex-key
      #|1030/2000 : contains-string
      #|
    ),
  )
}
