///|
fn unwrap_failure_message(error : Error) -> String {
  let s = error.to_string()
  match s.after("FAILED: ") {
    Some(rest) =>
      match rest.rev_before("\")") {
        Some(clean) => clean.to_owned()
        None => rest.to_owned()
      }
    None => s
  }
}

///|
fn lexer_expect_to_fail(input : String) -> String {
  try @tokenize.tokenize(input) catch {
    error => unwrap_failure_message(error)
  } noraise {
    _ => abort("Expected lexer failure but tokenize succeeded")
  }
}

///|
test "verify lexer_expect_to_fail output" {
  inspect(
    lexer_expect_to_fail(
      (
        #|key @ value
      ),
    ),
    content=(
      #|Unexpected character: '@'
    ),
  )
}
