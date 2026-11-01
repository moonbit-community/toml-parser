///|
/// A document big enough (and with enough astral characters) to exercise the
/// lexer's view handling end to end.
fn bench_document() -> String {
  let sb = StringBuilder()
  for i in 0..<800 {
    sb.write_string("key_\{i} = \"value 😈 \{i}\"\n")
    sb.write_string("num_\{i} = \{i}.5\n")
    sb.write_string("flag_\{i} = true\n")
    sb.write_string("[table_\{i}]\n")
    sb.write_string("emoji = \"😈😈😈\"\n")
    sb.write_string("arr = [1, 2, 3, 400, 5000]\n")
  }
  sb.to_string()
}

///|
/// End-to-end parse cost, guarding how `Lexer::view` and `expect_string` build
/// their subviews. On the ~90k-code-unit document below, `exact_view` parses
/// 2-3% faster than `clamped_view` (slicing), and within noise of `unsafe_view`,
/// which would give up bounds checking for it.
test "bench parse document" (it : @bench.T) {
  let doc = bench_document()
  println(
    "document: \{doc.length()} code units, \{doc.char_length()} characters",
  )
  it.bench(() => it.keep(Ok(@toml.parse(doc)) catch { e => Err(e) }), count=20)
}
