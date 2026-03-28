///|
fn parse_expect_to_fail(input : String) -> String {
  try @toml.parse(input) catch {
    e => {
      let s = e.to_string()
      // e.to_string() gives: Failure("...FAILED: actual_message")
      // We want just actual_message
      match s.after("FAILED: ") {
        Some(rest) =>
          // Remove trailing ") left over from Failure("...") wrapping
          match rest.rev_before("\")") {
            Some(clean) => clean.to_string()
            None => rest.to_string()
          }
        None => s
      }
    }
  } noraise {
    _ => abort("Expected parse failure but parse succeeded")
  }
}

///|
test "verify parse_expect_to_fail output" {
  inspect(
    parse_expect_to_fail("key ="),
    content=(
      #|Expected value at { start: { line: 1, column: 6 }, end: { line: 1, column: 6 } }
    ),
  )
}
