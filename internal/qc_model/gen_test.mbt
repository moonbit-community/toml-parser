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
fn negative_exponent_like_key_gen() -> @qc.Gen[String] {
  @qc.sized(fn(size) {
    let max_tail = capped_size(size, 4)
    let significand_gen = @qc.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @qc.liftA2(
        string_from_parts,
        @qc.char_range('1', '9'),
        @qc.char_range('0', '9').array_with_size(tail_len),
      )
    })
    let exponent_gen = @qc.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @qc.liftA2(
        string_from_parts,
        @qc.char_range('0', '9'),
        @qc.char_range('0', '9').array_with_size(tail_len),
      )
    })
    @qc.liftA3(
      fn(significand, negative_exponent, exponent) {
        let exponent_sign = if negative_exponent { "-" } else { "" }
        "-\{significand}e\{exponent_sign}\{exponent}"
      },
      significand_gen,
      @qc.one_of([@qc.pure(false), @qc.pure(true)]),
      exponent_gen,
    )
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
fn simple_key_gen() -> @qc.Gen[String] {
  @qc.frequency([
    (3U, bare_key_gen()),
    (2U, complex_key_gen()),
    (1U, negative_exponent_like_key_gen()),
  ])
}

///|
fn string_value_gen() -> @qc.Gen[@qc_model.SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  strings
  .scale(fn(size) { capped_size(size, 8) })
  .fmap(fn(value) { @qc_model.SString(value) })
}

///|
fn integer_value_gen() -> @qc.Gen[@qc_model.SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  integers.fmap(fn(value) { @qc_model.SInteger(value) })
}

///|
fn boolean_value_gen() -> @qc.Gen[@qc_model.SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  booleans.fmap(fn(value) { @qc_model.SBoolean(value) })
}

///|
fn pad2(value : Int) -> String {
  if value < 10 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn pad4(value : Int) -> String {
  if value < 10 {
    "000" + value.to_string()
  } else if value < 100 {
    "00" + value.to_string()
  } else if value < 1000 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn is_leap_year(year : Int) -> Bool {
  year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

///|
fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => abort("unreachable")
  }
}

///|
fn format_date(year : Int, month : Int, day : Int) -> String {
  "\{pad4(year)}-\{pad2(month)}-\{pad2(day)}"
}

///|
fn format_time(hour : Int, minute : Int, second : Int) -> String {
  "\{pad2(hour)}:\{pad2(minute)}:\{pad2(second)}"
}

///|
fn format_offset(sign : Char, hour : Int, minute : Int) -> String {
  "\{sign}\{pad2(hour)}:\{pad2(minute)}"
}

///|
fn date_string_gen() -> @qc.Gen[String] {
  @qc.int_range(1900, 2101).bind(fn(year) {
    @qc.int_range(1, 13).bind(fn(month) {
      @qc.int_range(1, days_in_month(year, month) + 1).fmap(fn(day) {
        format_date(year, month, day)
      })
    })
  })
}

///|
fn time_string_gen() -> @qc.Gen[String] {
  @qc.liftA2(
    fn(base : String, fractional : String) { base + fractional },
    @qc.liftA3(
      format_time,
      @qc.int_range(0, 24),
      @qc.int_range(0, 60),
      @qc.int_range(0, 60),
    ),
    @qc.frequency([
      (1U, @qc.pure("")),
      (
        1U,
        @qc.int_range(1, 10).bind(fn(len) {
          @qc.char_range('0', '9')
          .array_with_size(len)
          .fmap(fn(chars) {
            let builder = chars.fold(init=StringBuilder::new(), fn(
              builder,
              ch,
            ) {
              builder.write_char(ch)
              builder
            })
            "." + builder.to_string()
          })
        }),
      ),
    ]),
  )
}

///|
fn offset_suffix_gen() -> @qc.Gen[String] {
  @qc.frequency([
    (2U, @qc.pure("Z")),
    (
      1U,
      @qc.liftA3(
        format_offset,
        @qc.pure('+'),
        @qc.int_range(0, 24),
        @qc.int_range(0, 60),
      ),
    ),
    (
      1U,
      @qc.liftA3(
        format_offset,
        @qc.pure('-'),
        @qc.int_range(0, 24),
        @qc.int_range(0, 60),
      ),
    ),
  ])
}

///|
fn local_date_gen() -> @qc.Gen[@tokenize.TomlDateTime] {
  date_string_gen().fmap(fn(value) { @tokenize.LocalDate(value) })
}

///|
fn local_time_gen() -> @qc.Gen[@tokenize.TomlDateTime] {
  time_string_gen().fmap(fn(value) { @tokenize.LocalTime(value) })
}

///|
fn local_datetime_gen() -> @qc.Gen[@tokenize.TomlDateTime] {
  @qc.liftA2(
    fn(date : String, time : String) {
      @tokenize.LocalDateTime("\{date}T\{time}")
    },
    date_string_gen(),
    time_string_gen(),
  )
}

///|
fn offset_datetime_gen() -> @qc.Gen[@tokenize.TomlDateTime] {
  @qc.liftA3(
    fn(date : String, time : String, offset : String) {
      @tokenize.OffsetDateTime("\{date}T\{time}\{offset}")
    },
    date_string_gen(),
    time_string_gen(),
    offset_suffix_gen(),
  )
}

///|
fn toml_datetime_gen() -> @qc.Gen[@tokenize.TomlDateTime] {
  @qc.frequency([
    (2U, local_date_gen()),
    (2U, local_time_gen()),
    (2U, local_datetime_gen()),
    (2U, offset_datetime_gen()),
  ])
}

///|
fn datetime_value_gen() -> @qc.Gen[@qc_model.SimpleValue] {
  toml_datetime_gen().fmap(fn(value) { @qc_model.SDateTime(value) })
}

///|
fn datetime_array_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  non_empty_length_gen(size).bind(fn(len) {
    toml_datetime_gen()
    .array_with_size(len)
    .fmap(fn(values) { @qc_model.SDateTimeArray(values) })
  })
}

///|
fn non_empty_length_gen(size : Int) -> @qc.Gen[Int] {
  let max_len = capped_size(size + 1, 4)
  @qc.int_range(1, max_len + 1)
}

///|
fn string_array_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  let strings : @qc.Gen[String] = @qc.Gen::spawn()
  let strings = strings.scale(fn(n) { capped_size(n, 8) })
  non_empty_length_gen(size).bind(fn(len) {
    strings
    .array_with_size(len)
    .fmap(fn(values) { @qc_model.SStringArray(values) })
  })
}

///|
fn integer_array_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  let integers : @qc.Gen[Int64] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    integers
    .array_with_size(len)
    .fmap(fn(values) { @qc_model.SIntegerArray(values) })
  })
}

///|
fn boolean_array_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  let booleans : @qc.Gen[Bool] = @qc.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    booleans
    .array_with_size(len)
    .fmap(fn(values) { @qc_model.SBooleanArray(values) })
  })
}

///|
fn scalar_or_array_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  @qc.frequency([
    (3U, string_value_gen()),
    (2U, integer_value_gen()),
    (2U, boolean_value_gen()),
    (2U, datetime_value_gen()),
    (1U, @qc.pure(@qc_model.SEmptyArray)),
    (2U, string_array_value_gen(size)),
    (2U, integer_array_value_gen(size)),
    (2U, boolean_array_value_gen(size)),
    (2U, datetime_array_value_gen(size)),
  ])
}

///|
fn simple_entry_gen(size : Int) -> @qc.Gen[(String, @qc_model.SimpleValue)] {
  @qc.liftA2(
    fn(key, value) { (key, value) },
    simple_key_gen(),
    simple_value_gen(size),
  )
}

///|
fn table_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  let next_size = size / 2
  let max_fields = capped_size(size + 1, 4)
  @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
    simple_entry_gen(next_size)
    .array_with_size(field_count)
    .fmap(fn(entries) { @qc_model.STable(Map::from_array(entries)) })
  })
}

///|
fn simple_value_gen(size : Int) -> @qc.Gen[@qc_model.SimpleValue] {
  let leaf = scalar_or_array_value_gen(size)
  if size <= 0 {
    leaf
  } else {
    @qc.frequency([(9U, leaf), (2U, table_value_gen(size))])
  }
}

///|
fn simple_document_gen() -> @qc.Gen[@qc_model.SimpleDocument] {
  @qc.sized(fn(size) {
    let max_fields = capped_size(size + 1, 5)
    @qc.int_range(0, max_fields + 1).bind(fn(field_count) {
      simple_entry_gen(size)
      .array_with_size(field_count)
      .fmap(fn(entries) {
        @qc_model.SimpleDocument::{ fields: Map::from_array(entries) }
      })
    })
  })
}
