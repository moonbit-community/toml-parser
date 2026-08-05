///|
/// Random generators for the QuickCheck model, built on
/// `moonbitlang/core/quickcheck`.
///
/// `simple_document_generator` is the entry point; the `Arbitrary` impl for
/// `SimpleDocument` delegates to it so the core `@qc.check` driver can
/// generate documents directly.

///|
fn[T : @qc.Arbitrary] spawn() -> @qc.Generator[T] {
  Generator(@qc.Arbitrary::arbitrary)
}

///|
fn char_range(lower : Char, upper : Char) -> @qc.Generator[Char] {
  @qc.int_range(lower.to_int(), upper.to_int() + 1).map(code => {
    code.unsafe_to_char()
  })
}

///|
fn[A, B, C] lift2(
  f : (A, B) -> C,
  ga : @qc.Generator[A],
  gb : @qc.Generator[B],
) -> @qc.Generator[C] {
  ga.flat_map(a => gb.map(b => f(a, b)))
}

///|
fn[A, B, C, D] lift3(
  f : (A, B, C) -> D,
  ga : @qc.Generator[A],
  gb : @qc.Generator[B],
  gc : @qc.Generator[C],
) -> @qc.Generator[D] {
  ga.flat_map(a => gb.flat_map(b => gc.map(c => f(a, b, c))))
}

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
fn simple_key_tail_char_gen() -> @qc.Generator[Char] {
  @qc.one_of([
    char_range('a', 'z'),
    char_range('0', '9'),
    @qc.pure('-'),
    @qc.pure('_'),
  ])
}

///|
fn bare_key_gen() -> @qc.Generator[String] {
  @qc.sized(size => {
    let max_tail = capped_size(size, 4)
    @qc.int_range(0, max_tail + 1).flat_map(tail_len => {
      lift2(
        string_from_parts,
        char_range('a', 'z'),
        simple_key_tail_char_gen().array_with_size(tail_len),
      )
    })
  })
}

///|
fn negative_exponent_like_key_gen() -> @qc.Generator[String] {
  @qc.sized(size => {
    let max_tail = capped_size(size, 4)
    let significand_gen = @qc.int_range(0, max_tail + 1).flat_map(tail_len => {
      lift2(
        string_from_parts,
        char_range('1', '9'),
        char_range('0', '9').array_with_size(tail_len),
      )
    })
    let exponent_gen = @qc.int_range(0, max_tail + 1).flat_map(tail_len => {
      lift2(
        string_from_parts,
        char_range('0', '9'),
        char_range('0', '9').array_with_size(tail_len),
      )
    })
    lift3(
      (significand, negative_exponent, exponent) => {
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
fn key_with_middle_char_gen(
  middle : @qc.Generator[Char],
) -> @qc.Generator[String] {
  lift3(string_with_middle_char, bare_key_gen(), middle, bare_key_gen())
}

///|
fn padded_key_gen() -> @qc.Generator[String] {
  lift3(
    string_with_middle_char,
    @qc.one_of([@qc.pure(""), bare_key_gen()]),
    @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
    bare_key_gen(),
  ).flat_map(prefix_padded => {
    @qc.one_of([
      @qc.pure(prefix_padded),
      lift2(
        (inner : String, suffix : Char) => inner + suffix.to_string(),
        @qc.pure(prefix_padded),
        @qc.one_of([@qc.pure(' '), @qc.pure('\t')]),
      ),
    ])
  })
}

///|
fn complex_key_gen() -> @qc.Generator[String] {
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
fn simple_key_gen() -> @qc.Generator[String] {
  @qc.frequency([
    (3U, bare_key_gen()),
    (2U, complex_key_gen()),
    (1U, negative_exponent_like_key_gen()),
  ])
}

///|
fn string_value_gen() -> @qc.Generator[SimpleValue] {
  let strings : @qc.Generator[String] = spawn()
  strings.scale(size => capped_size(size, 8)).map(value => SString(value))
}

///|
fn integer_value_gen() -> @qc.Generator[SimpleValue] {
  let integers : @qc.Generator[Int64] = spawn()
  integers.map(value => SInteger(value))
}

///|
fn boolean_value_gen() -> @qc.Generator[SimpleValue] {
  let booleans : @qc.Generator[Bool] = spawn()
  booleans.map(value => SBoolean(value))
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
fn date_string_gen() -> @qc.Generator[String] {
  @qc.int_range(1900, 2101).flat_map(year => {
    @qc.int_range(1, 13).flat_map(month => {
      @qc.int_range(1, days_in_month(year, month) + 1).map(day => {
        format_date(year, month, day)
      })
    })
  })
}

///|
fn time_string_gen() -> @qc.Generator[String] {
  lift2(
    (base : String, fractional : String) => base + fractional,
    lift3(
      format_time,
      @qc.int_range(0, 24),
      @qc.int_range(0, 60),
      @qc.int_range(0, 60),
    ),
    @qc.frequency([
      (1U, @qc.pure("")),
      (
        1U,
        @qc.int_range(1, 10).flat_map(len => {
          char_range('0', '9')
          .array_with_size(len)
          .map(chars => {
            let builder = chars.fold(init=StringBuilder(), (builder, ch) => {
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
fn offset_suffix_gen() -> @qc.Generator[String] {
  @qc.frequency([
    (2U, @qc.pure("Z")),
    (
      1U,
      lift3(
        format_offset,
        @qc.pure('+'),
        @qc.int_range(0, 24),
        @qc.int_range(0, 60),
      ),
    ),
    (
      1U,
      lift3(
        format_offset,
        @qc.pure('-'),
        @qc.int_range(0, 24),
        @qc.int_range(0, 60),
      ),
    ),
  ])
}

///|
fn local_date_gen() -> @qc.Generator[@datetime.TomlDateTime] {
  date_string_gen().map(value => LocalDate(value))
}

///|
fn local_time_gen() -> @qc.Generator[@datetime.TomlDateTime] {
  time_string_gen().map(value => LocalTime(value))
}

///|
fn local_datetime_gen() -> @qc.Generator[@datetime.TomlDateTime] {
  lift2(
    (date : String, time : String) => LocalDateTime("\{date}T\{time}"),
    date_string_gen(),
    time_string_gen(),
  )
}

///|
fn offset_datetime_gen() -> @qc.Generator[@datetime.TomlDateTime] {
  lift3(
    (date : String, time : String, offset : String) => {
      OffsetDateTime("\{date}T\{time}\{offset}")
    },
    date_string_gen(),
    time_string_gen(),
    offset_suffix_gen(),
  )
}

///|
fn toml_datetime_gen() -> @qc.Generator[@datetime.TomlDateTime] {
  @qc.frequency([
    (2U, local_date_gen()),
    (2U, local_time_gen()),
    (2U, local_datetime_gen()),
    (2U, offset_datetime_gen()),
  ])
}

///|
fn datetime_value_gen() -> @qc.Generator[SimpleValue] {
  toml_datetime_gen().map(value => SDateTime(value))
}

///|
fn datetime_array_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  non_empty_length_gen(size).flat_map(len => {
    toml_datetime_gen()
    .array_with_size(len)
    .map(values => SDateTimeArray(values))
  })
}

///|
fn non_empty_length_gen(size : Int) -> @qc.Generator[Int] {
  let max_len = capped_size(size + 1, 4)
  @qc.int_range(1, max_len + 1)
}

///|
fn string_array_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  let strings : @qc.Generator[String] = spawn()
  let strings = strings.scale(n => capped_size(n, 8))
  non_empty_length_gen(size).flat_map(len => {
    strings.array_with_size(len).map(values => SStringArray(values))
  })
}

///|
fn integer_array_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  let integers : @qc.Generator[Int64] = spawn()
  non_empty_length_gen(size).flat_map(len => {
    integers.array_with_size(len).map(values => SIntegerArray(values))
  })
}

///|
fn boolean_array_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  let booleans : @qc.Generator[Bool] = spawn()
  non_empty_length_gen(size).flat_map(len => {
    booleans.array_with_size(len).map(values => SBooleanArray(values))
  })
}

///|
fn scalar_or_array_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  @qc.frequency([
    (3U, string_value_gen()),
    (2U, integer_value_gen()),
    (2U, boolean_value_gen()),
    (2U, datetime_value_gen()),
    (1U, @qc.pure(SEmptyArray)),
    (2U, string_array_value_gen(size)),
    (2U, integer_array_value_gen(size)),
    (2U, boolean_array_value_gen(size)),
    (2U, datetime_array_value_gen(size)),
  ])
}

///|
fn simple_entry_gen(size : Int) -> @qc.Generator[(String, SimpleValue)] {
  lift2((key, value) => (key, value), simple_key_gen(), simple_value_gen(size))
}

///|
fn table_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  let next_size = size / 2
  let max_fields = capped_size(size + 1, 4)
  @qc.int_range(0, max_fields + 1).flat_map(field_count => {
    simple_entry_gen(next_size)
    .array_with_size(field_count)
    .map(entries => STable(Map::from_array(entries)))
  })
}

///|
fn simple_value_gen(size : Int) -> @qc.Generator[SimpleValue] {
  let leaf = scalar_or_array_value_gen(size)
  if size <= 0 {
    leaf
  } else {
    @qc.frequency([(9U, leaf), (2U, table_value_gen(size))])
  }
}

///|
/// Generator for whole model documents; the entry point used by both the
/// round-trip property and the coverage snapshot.
pub fn simple_document_generator() -> @qc.Generator[SimpleDocument] {
  @qc.sized(size => {
    let max_fields = capped_size(size + 1, 5)
    @qc.int_range(0, max_fields + 1).flat_map(field_count => {
      simple_entry_gen(size)
      .array_with_size(field_count)
      .map(entries => { fields: Map::from_array(entries) })
    })
  })
}

///|
pub impl @qc.Arbitrary for SimpleDocument with fn arbitrary(size, state) {
  simple_document_generator().run(size, state)
}

///|
#deprecated("generate via `@qc.check` or `simple_document_generator`; the Arbitrary impl is unaffected")
pub extend SimpleDocument with @qc.Arbitrary::{arbitrary}
