///|
/// A document that exercises every kind of token: bare and quoted keys,
/// strings with and without escapes, multi-line strings, numbers in each
/// radix, floats, booleans, datetimes, comments, tables and arrays.
fn bench_document() -> String {
  let sb = StringBuilder()
  for i in 0..<500 {
    sb.write_string("# section \{i}: a comment 😈\n")
    sb.write_string("[table_\{i}.\"quoted key\"]\n")
    sb.write_string("key_\{i} = \"value 😈 \{i}\" # trailing comment\n")
    sb.write_string("escaped = \"tab\\there \\u00e9 \\\"quoted\\\"\"\n")
    sb.write_string("literal = 'C:\\Users\\nodejs\\templates'\n")
    sb.write_string(
      "multi = \"\"\"\nline one\nline two \\\n  continued\"\"\"\n",
    )
    sb.write_string("raw = '''\nfirst\nsecond'''\n")
    sb.write_string("int = 1_000_\{i}\nhex = 0xDEAD_BEEF\nneg = -\{i}\n")
    sb.write_string("float = 6.626e-34\nflag = true\n")
    sb.write_string("when = 1979-05-27T07:32:00.999-07:00\nday = 1979-05-27\n")
    sb.write_string("arr = [ 1, 2, 3, \"four\", { x = 5, y = 6 } ]\n")
  }
  sb.to_string()
}

///|
test "bench tokenize document" (it : @bench.T) {
  let doc = bench_document()
  it.bench(
    () => it.keep(Ok(@tokenize.tokenize(doc)) catch { e => Err(e) }),
    count=20,
  )
}
