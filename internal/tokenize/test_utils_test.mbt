///|
fn unwrap_failure_message(error : Error) -> String {
  let s = error.to_string()
  match s.after("FAILED: ") {
    Some(rest) =>
      match rest.rev_before("\")") {
        Some(clean) => clean.to_string()
        None => rest.to_string()
      }
    None => s
  }
}

///|
fn lexer_expect_to_fail(input : String) -> String {
  try tokenize(input) catch {
    error => unwrap_failure_message(error)
  } noraise {
    _ => abort("Expected lexer failure but tokenize succeeded")
  }
}

///|
fn[T] lexer_action_expect_to_fail(action : () -> T raise) -> String {
  try action() catch {
    error => unwrap_failure_message(error)
  } noraise {
    _ => abort("Expected lexer failure but action succeeded")
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

///|
test "verify lexer_action_expect_to_fail output" {
  let lexer = @lexer.Lexer::new(
    (
      #|hello world
    ),
  )
  inspect(
    lexer_action_expect_to_fail(fn() raise { lexer.expect_string("goodbye") }),
    content=(
      #|Expected string: goodbye at line 1, column 1
    ),
  )
}
