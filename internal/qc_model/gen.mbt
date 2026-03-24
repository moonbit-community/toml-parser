///|
fn capped_size(size : Int, cap : Int) -> Int {
  if size < cap {
    size
  } else {
    cap
  }
}

///|
fn string_from_parts(head : Char, tail : Array[Char]) -> String {
  let builder = StringBuilder::new()
  builder.write_char(head)
  for ch in tail {
    builder.write_char(ch)
  }
  builder.to_string()
}

///|
fn simple_key_tail_char_gen() -> @qc.Gen[Char] {
  @qc.one_of([
    @qc.char_range('a', 'z'),
    @qc.char_range('0', '9'),
    @qc.pure('-'),
    @qc.pure('_'),
  ])
}

///|
fn bare_key_gen() -> @qc.Gen[String] {
  @qc.sized(fn(size) {
    let max_tail = capped_size(size, 4)
    @qc.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @qc.liftA2(
        string_from_parts,
        @qc.char_range('a', 'z'),
        simple_key_tail_char_gen().array_with_size(tail_len),
      )
    })
  })
}

///|
fn string_with_middle_char(
  left : String,
  middle : Char,
  right : String,
) -> String {
  left + middle.to_string() + right
}

///|
fn key_with_middle_char_gen(middle : @qc.Gen[Char]) -> @qc.Gen[String] {
  @qc.liftA3(string_with_middle_char, bare_key_gen(), middle, bare_key_gen())
}

///|
fn padded_key_gen() -> @qc.Gen[String] {
  @qc.liftA3(
    string_with_middle_char,
    @qc.one_of([@qc.pure(""), bare_key_gen()]),
    @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
    bare_key_gen(),
  ).bind(fn(prefix_padded) {
    @qc.one_of([
      @qc.pure(prefix_padded),
      @qc.liftA2(
        fn(inner : String, suffix : Char) { inner + suffix.to_string() },
        @qc.pure(prefix_padded),
        @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
      ),
    ])
  })
}

///|
fn complex_key_gen() -> @qc.Gen[String] {
  @qc.frequency([
    (2U, key_with_middle_char_gen(@qc.pure(' '))),
    (2U, key_with_middle_char_gen(@qc.pure('.'))),
    (1U, key_with_middle_char_gen(@qc.pure('"'))),
    (1U, key_with_middle_char_gen(@qc.pure('#'))),
    (1U, key_with_middle_char_gen(@qc.pure('\\'))),
    (1U, key_with_middle_char_gen(@qc.pure('\n'))),
    (1U, key_with_middle_char_gen(@qc.pure('\t'))),
    (1U, padded_key_gen()),
    (1U, @qc.pure("")),
  ])
}

///|
pub fn simple_key_gen() -> @qc.Gen[String] {
  @qc.frequency([(3U, bare_key_gen()), (2U, complex_key_gen())])
}

///|
fn string_value_gen() -> @qc.Gen[SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  strings
  .scale(fn(size) { capped_size(size, 8) })
  .fmap(fn(value) { SString(value) })
}

///|
fn integer_value_gen() -> @qc.Gen[SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  integers.fmap(fn(value) { SInteger(value) })
}

///|
fn boolean_value_gen() -> @qc.Gen[SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  booleans.fmap(fn(value) { SBoolean(value) })
}

///|
fn non_empty_length_gen(size : Int) -> @qc.Gen[Int] {
  let max_len = capped_size(size + 1, 4)
  @qc.int_range(1, max_len + 1)
}

///|
fn string_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  let strings = strings.scale(fn(n) { capped_size(n, 8) })
  non_empty_length_gen(size).bind(fn(len) {
    strings.array_with_size(len).fmap(fn(values) { SStringArray(values) })
  })
}

///|
fn integer_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    integers.array_with_size(len).fmap(fn(values) { SIntegerArray(values) })
  })
}

///|
fn boolean_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    booleans.array_with_size(len).fmap(fn(values) { SBooleanArray(values) })
  })
}

///|
fn scalar_or_array_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  @qc.frequency([
    (3U, string_value_gen()),
    (2U, integer_value_gen()),
    (2U, boolean_value_gen()),
    (1U, @qc.pure(SEmptyArray)),
    (2U, string_array_value_gen(size)),
    (2U, integer_array_value_gen(size)),
    (2U, boolean_array_value_gen(size)),
  ])
}

///|
pub fn simple_entry_gen(size : Int) -> @qc.Gen[(String, SimpleValue)] {
  @qc.liftA2(
    fn(key, value) { (key, value) },
    simple_key_gen(),
    simple_value_gen(size),
  )
}

///|
fn table_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let next_size = size / 2
  let max_fields = capped_size(size + 1, 4)
  @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
    simple_entry_gen(next_size)
    .array_with_size(field_count)
    .fmap(fn(entries) { STable(Map::from_array(entries[:])) })
  })
}

///|
pub fn simple_value_gen(size : Int) -> @qc.Gen[SimpleValue] {
  let leaf = scalar_or_array_value_gen(size)
  if size <= 0 {
    leaf
  } else {
    @qc.frequency([(9U, leaf), (2U, table_value_gen(size))])
  }
}

///|
pub fn simple_document_gen() -> @qc.Gen[SimpleDocument] {
  @qc.sized(fn(size) {
    let max_fields = capped_size(size + 1, 5)
    @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
      simple_entry_gen(size)
      .array_with_size(field_count)
      .fmap(fn(entries) { { fields: Map::from_array(entries[:]) } })
    })
  })
}
