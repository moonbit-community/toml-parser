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
              "round-trip mismatch\nrendered:\n\{rendered}\noriginal:\n\{doc}\nparsed:\n\{roundtripped}",
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
fn roundtrip_property(doc : @qc_model.SimpleDocument) -> @qc.Property {
  let rendered = doc.to_toml().to_string()
  let checked = simple_document_roundtrip_check(doc, rendered)
  let classified = checked
    |> @qc.classify(doc.contains_table(), "contains-table")
    |> @qc.classify(doc.contains_array(), "contains-array")
    |> @qc.classify(doc.contains_datetime_array(), "contains-datetime-array")
    |> @qc.classify(
      doc.contains_fractional_datetime(),
      "contains-fractional-datetime",
    )
    |> @qc.classify(doc.contains_datetime(), "contains-datetime")
    |> @qc.classify(
      doc.contains_negative_exponent_like_key(),
      "contains-negative-exponent-like-key",
    )
    |> @qc.classify(doc.contains_complex_key(), "contains-complex-key")
    |> @qc.classify(doc.contains_string(), "contains-string")
  @qc.counterexample(classified, rendered)
}

///|
test "quickcheck simple document roundtrip" {
  inspect(
    @qc.quick_check_silence(
      @qc.forall_shrink(
        simple_document_gen(),
        shrink_simple_document,
        roundtrip_property,
      ),
      max_success=2000,
      max_size=12,
    ),
    content=(
      #|+++ [2000/0/2000] Ok, passed!
      #|44.4% : contains-string
      #|52.55% : contains-complex-key
      #|33.15% : contains-negative-exponent-like-key
      #|36.7% : contains-datetime
      #|22.05% : contains-fractional-datetime
      #|21.05% : contains-datetime-array
      #|61% : contains-array
      #|29.15% : contains-table
    ),
  )
}
