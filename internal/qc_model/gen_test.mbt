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
  let builder = StringBuilder()
  builder.write_char(head)
  for ch in tail {
    builder.write_char(ch)
  }
  builder.to_string()
}

///|
fn simple_key_tail_char_gen() -> @gen.Gen[Char] {
  @gen.one_of([
    @gen.char_range('a', 'z'),
    @gen.char_range('0', '9'),
    @gen.pure('-'),
    @gen.pure('_'),
  ])
}

///|
fn bare_key_gen() -> @gen.Gen[String] {
  @gen.sized(fn(size) {
    let max_tail = capped_size(size, 4)
    @gen.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @gen.liftA2(
        string_from_parts,
        @gen.char_range('a', 'z'),
        simple_key_tail_char_gen().array_with_size(tail_len),
      )
    })
  })
}

///|
fn negative_exponent_like_key_gen() -> @gen.Gen[String] {
  @gen.sized(fn(size) {
    let max_tail = capped_size(size, 4)
    let significand_gen = @gen.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @gen.liftA2(
        string_from_parts,
        @gen.char_range('1', '9'),
        @gen.char_range('0', '9').array_with_size(tail_len),
      )
    })
    let exponent_gen = @gen.int_range(0, max_tail + 1).bind(fn(tail_len) {
      @gen.liftA2(
        string_from_parts,
        @gen.char_range('0', '9'),
        @gen.char_range('0', '9').array_with_size(tail_len),
      )
    })
    @gen.liftA3(
      fn(significand, negative_exponent, exponent) {
        let exponent_sign = if negative_exponent { "-" } else { "" }
        "-\{significand}e\{exponent_sign}\{exponent}"
      },
      significand_gen,
      @gen.one_of([@gen.pure(false), @gen.pure(true)]),
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
fn key_with_middle_char_gen(middle : @gen.Gen[Char]) -> @gen.Gen[String] {
  @gen.liftA3(string_with_middle_char, bare_key_gen(), middle, bare_key_gen())
}

///|
fn padded_key_gen() -> @gen.Gen[String] {
  @gen.liftA3(
    string_with_middle_char,
    @gen.one_of([@gen.pure(""), bare_key_gen()]),
    @gen.one_of([@gen.pure(' '), @gen.pure('\t')]),
    bare_key_gen(),
  ).bind(fn(prefix_padded) {
    @gen.one_of([
      @gen.pure(prefix_padded),
      @gen.liftA2(
        fn(inner : String, suffix : Char) { inner + suffix.to_string() },
        @gen.pure(prefix_padded),
        @gen.one_of([@gen.pure(' '), @gen.pure('\t')]),
      ),
    ])
  })
}

///|
fn complex_key_gen() -> @gen.Gen[String] {
  @gen.frequency([
    (2U, key_with_middle_char_gen(@gen.pure(' '))),
    (2U, key_with_middle_char_gen(@gen.pure('.'))),
    (1U, key_with_middle_char_gen(@gen.pure('"'))),
    (1U, key_with_middle_char_gen(@gen.pure('#'))),
    (1U, key_with_middle_char_gen(@gen.pure('\\'))),
    (1U, key_with_middle_char_gen(@gen.pure('\n'))),
    (1U, key_with_middle_char_gen(@gen.pure('\t'))),
    (1U, padded_key_gen()),
    (1U, @gen.pure("")),
  ])
}

///|
fn simple_key_gen() -> @gen.Gen[String] {
  @gen.frequency([
    (3U, bare_key_gen()),
    (2U, complex_key_gen()),
    (1U, negative_exponent_like_key_gen()),
  ])
}

///|
fn string_value_gen() -> @gen.Gen[@qc_model.SimpleValue] {
  let strings : @gen.Gen[String] = @gen.Gen::spawn()
  strings
  .scale(fn(size) { capped_size(size, 8) })
  .fmap(fn(value) { SString(value) })
}

///|
fn integer_value_gen() -> @gen.Gen[@qc_model.SimpleValue] {
  let integers : @gen.Gen[Int64] = @gen.Gen::spawn()
  integers.fmap(fn(value) { SInteger(value) })
}

///|
fn boolean_value_gen() -> @gen.Gen[@qc_model.SimpleValue] {
  let booleans : @gen.Gen[Bool] = @gen.Gen::spawn()
  booleans.fmap(fn(value) { SBoolean(value) })
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
fn date_string_gen() -> @gen.Gen[String] {
  @gen.int_range(1900, 2101).bind(fn(year) {
    @gen.int_range(1, 13).bind(fn(month) {
      @gen.int_range(1, days_in_month(year, month) + 1).fmap(fn(day) {
        format_date(year, month, day)
      })
    })
  })
}

///|
fn time_string_gen() -> @gen.Gen[String] {
  @gen.liftA2(
    fn(base : String, fractional : String) { base + fractional },
    @gen.liftA3(
      format_time,
      @gen.int_range(0, 24),
      @gen.int_range(0, 60),
      @gen.int_range(0, 60),
    ),
    @gen.frequency([
      (1U, @gen.pure("")),
      (
        1U,
        @gen.int_range(1, 10).bind(fn(len) {
          @gen.char_range('0', '9')
          .array_with_size(len)
          .fmap(fn(chars) {
            let builder = chars.fold(init=StringBuilder(), fn(builder, ch) {
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
fn offset_suffix_gen() -> @gen.Gen[String] {
  @gen.frequency([
    (2U, @gen.pure("Z")),
    (
      1U,
      @gen.liftA3(
        format_offset,
        @gen.pure('+'),
        @gen.int_range(0, 24),
        @gen.int_range(0, 60),
      ),
    ),
    (
      1U,
      @gen.liftA3(
        format_offset,
        @gen.pure('-'),
        @gen.int_range(0, 24),
        @gen.int_range(0, 60),
      ),
    ),
  ])
}

///|
fn local_date_gen() -> @gen.Gen[@datetime.TomlDateTime] {
  date_string_gen().fmap(fn(value) { LocalDate(value) })
}

///|
fn local_time_gen() -> @gen.Gen[@datetime.TomlDateTime] {
  time_string_gen().fmap(fn(value) { LocalTime(value) })
}

///|
fn local_datetime_gen() -> @gen.Gen[@datetime.TomlDateTime] {
  @gen.liftA2(
    fn(date : String, time : String) { LocalDateTime("\{date}T\{time}") },
    date_string_gen(),
    time_string_gen(),
  )
}

///|
fn offset_datetime_gen() -> @gen.Gen[@datetime.TomlDateTime] {
  @gen.liftA3(
    fn(date : String, time : String, offset : String) {
      OffsetDateTime("\{date}T\{time}\{offset}")
    },
    date_string_gen(),
    time_string_gen(),
    offset_suffix_gen(),
  )
}

///|
fn toml_datetime_gen() -> @gen.Gen[@datetime.TomlDateTime] {
  @gen.frequency([
    (2U, local_date_gen()),
    (2U, local_time_gen()),
    (2U, local_datetime_gen()),
    (2U, offset_datetime_gen()),
  ])
}

///|
fn datetime_value_gen() -> @gen.Gen[@qc_model.SimpleValue] {
  toml_datetime_gen().fmap(fn(value) { SDateTime(value) })
}

///|
fn datetime_array_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  non_empty_length_gen(size).bind(fn(len) {
    toml_datetime_gen()
    .array_with_size(len)
    .fmap(fn(values) { SDateTimeArray(values) })
  })
}

///|
fn non_empty_length_gen(size : Int) -> @gen.Gen[Int] {
  let max_len = capped_size(size + 1, 4)
  @gen.int_range(1, max_len + 1)
}

///|
fn string_array_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  let strings : @gen.Gen[String] = @gen.Gen::spawn()
  let strings = strings.scale(fn(n) { capped_size(n, 8) })
  non_empty_length_gen(size).bind(fn(len) {
    strings.array_with_size(len).fmap(fn(values) { SStringArray(values) })
  })
}

///|
fn integer_array_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  let integers : @gen.Gen[Int64] = @gen.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    integers.array_with_size(len).fmap(fn(values) { SIntegerArray(values) })
  })
}

///|
fn boolean_array_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  let booleans : @gen.Gen[Bool] = @gen.Gen::spawn()
  non_empty_length_gen(size).bind(fn(len) {
    booleans.array_with_size(len).fmap(fn(values) { SBooleanArray(values) })
  })
}

///|
fn scalar_or_array_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  @gen.frequency([
    (3U, string_value_gen()),
    (2U, integer_value_gen()),
    (2U, boolean_value_gen()),
    (2U, datetime_value_gen()),
    (1U, @gen.pure(SEmptyArray)),
    (2U, string_array_value_gen(size)),
    (2U, integer_array_value_gen(size)),
    (2U, boolean_array_value_gen(size)),
    (2U, datetime_array_value_gen(size)),
  ])
}

///|
fn simple_entry_gen(size : Int) -> @gen.Gen[(String, @qc_model.SimpleValue)] {
  @gen.liftA2(
    fn(key, value) { (key, value) },
    simple_key_gen(),
    simple_value_gen(size),
  )
}

///|
fn table_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  let next_size = size / 2
  let max_fields = capped_size(size + 1, 4)
  @gen.int_range(0, max_fields + 1).bind(fn(field_count) {
    simple_entry_gen(next_size)
    .array_with_size(field_count)
    .fmap(fn(entries) { STable(Map::from_array(entries)) })
  })
}

///|
fn simple_value_gen(size : Int) -> @gen.Gen[@qc_model.SimpleValue] {
  let leaf = scalar_or_array_value_gen(size)
  if size <= 0 {
    leaf
  } else {
    @gen.frequency([(9U, leaf), (2U, table_value_gen(size))])
  }
}

///|
fn simple_document_gen() -> @gen.Gen[@qc_model.SimpleDocument] {
  @gen.sized(fn(size) {
    let max_fields = capped_size(size + 1, 5)
    @gen.int_range(0, max_fields + 1).bind(fn(field_count) {
      simple_entry_gen(size)
      .array_with_size(field_count)
      .fmap(fn(entries) { { fields: Map::from_array(entries) } })
    })
  })
}
