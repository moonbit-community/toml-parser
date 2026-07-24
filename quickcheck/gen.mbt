///|
/// Generators for the *round-trip-safe* fragment of `@toml.TomlValue`.
///
/// These are plain `@gen.Gen` values, so they compose with the full
/// quickcheck API directly — pass one to `@qc.forall_shrink`, or reach for the
/// `RoundTrippable` newtype (see `roundtrippable.mbt`) to drive the
/// trait-based `@qc.quick_check_fn` runner.
///
/// The fragment deliberately excludes `TomlFloat` (formatting loses exact
/// equality) and heterogeneous arrays (rejected by TOML), so every value this
/// module produces satisfies the law `parse(v.to_string()) == v`.

///|
fn capped(size : Int, cap : Int) -> Int {
  if size < cap {
    size
  } else {
    cap
  }
}

// ---------------------------------------------------------------------------
// Keys
// ---------------------------------------------------------------------------

///|
fn key_from_parts(head : Char, tail : Array[Char]) -> String {
  let builder = StringBuilder()
  builder.write_char(head)
  for ch in tail {
    builder.write_char(ch)
  }
  builder.to_string()
}

///|
fn bare_key_char() -> @gen.Gen[Char] {
  @gen.one_of([
    @gen.char_range('a', 'z'),
    @gen.char_range('0', '9'),
    @gen.pure('-'),
    @gen.pure('_'),
  ])
}

///|
/// A TOML "bare" identifier: a leading letter followed by up to a few
/// `[a-z0-9_-]` characters.
fn bare_key() -> @gen.Gen[String] {
  @gen.sized(fn(size) {
    @gen.int_range(0, capped(size, 4) + 1).bind(fn(tail_len) {
      @gen.liftA2(
        key_from_parts,
        @gen.char_range('a', 'z'),
        bare_key_char().array_with_size(tail_len),
      )
    })
  })
}

///|
fn key_with_middle(middle : Char) -> @gen.Gen[String] {
  @gen.liftA3(
    fn(left : String, mid : Char, right : String) {
      left + mid.to_string() + right
    },
    bare_key(),
    @gen.pure(middle),
    bare_key(),
  )
}

///|
/// A key that forces the serializer to quote it (embedded space, dot, or
/// quote character).
fn complex_key() -> @gen.Gen[String] {
  @gen.frequency([
    (2U, key_with_middle(' ')),
    (2U, key_with_middle('.')),
    (1U, key_with_middle('"')),
  ])
}

///|
/// A key that looks like a negative float literal (e.g. `-3e7`). These collide
/// with the float grammar at the lexer level and are a classic ambiguity trap.
fn negative_exponent_like_key() -> @gen.Gen[String] {
  @gen.liftA2(
    fn(significand : Int, exponent : Int) { "-\{significand}e\{exponent}" },
    @gen.int_range(1, 1000),
    @gen.int_range(0, 1000),
  )
}

///|
fn key() -> @gen.Gen[String] {
  @gen.frequency([
    (3U, bare_key()),
    (2U, complex_key()),
    (1U, negative_exponent_like_key()),
  ])
}

// ---------------------------------------------------------------------------
// Datetimes
// ---------------------------------------------------------------------------

///|
fn pad2(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
fn pad4(value : Int) -> String {
  if value < 10 {
    "000\{value}"
  } else if value < 100 {
    "00\{value}"
  } else if value < 1000 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
// Day is capped at 28 so every (year, month) pair is valid without a
// days-in-month / leap-year table.
fn date_string() -> @gen.Gen[String] {
  @gen.liftA3(
    fn(year, month, day) { "\{pad4(year)}-\{pad2(month)}-\{pad2(day)}" },
    @gen.int_range(1, 10000),
    @gen.int_range(1, 13),
    @gen.int_range(1, 29),
  )
}

///|
fn fractional_seconds() -> @gen.Gen[String] {
  @gen.frequency([
    (2U, @gen.pure("")),
    (
      1U,
      @gen.int_range(1, 7).bind(fn(len) {
        @gen.char_range('0', '9')
        .array_with_size(len)
        .fmap(fn(digits) {
          let builder = StringBuilder()
          builder.write_char('.')
          for digit in digits {
            builder.write_char(digit)
          }
          builder.to_string()
        })
      }),
    ),
  ])
}

///|
fn time_string() -> @gen.Gen[String] {
  @gen.liftA2(
    fn(base, fraction) { base + fraction },
    @gen.liftA3(
      fn(hour, minute, second) {
        "\{pad2(hour)}:\{pad2(minute)}:\{pad2(second)}"
      },
      @gen.int_range(0, 24),
      @gen.int_range(0, 60),
      @gen.int_range(0, 60),
    ),
    fractional_seconds(),
  )
}

///|
fn offset_string() -> @gen.Gen[String] {
  @gen.frequency([
    (2U, @gen.pure("Z")),
    (
      1U,
      @gen.liftA2(
        fn(hour, minute) { "+\{pad2(hour)}:\{pad2(minute)}" },
        @gen.int_range(0, 24),
        @gen.int_range(0, 60),
      ),
    ),
    (
      1U,
      @gen.liftA2(
        fn(hour, minute) { "-\{pad2(hour)}:\{pad2(minute)}" },
        @gen.int_range(0, 24),
        @gen.int_range(0, 60),
      ),
    ),
  ])
}

///|
fn datetime() -> @gen.Gen[@datetime.TomlDateTime] {
  @gen.frequency([
    (2U, date_string().fmap(fn(text) { LocalDate(text) })),
    (2U, time_string().fmap(fn(text) { LocalTime(text) })),
    (
      2U,
      @gen.liftA2(
        fn(date, time) { LocalDateTime("\{date}T\{time}") },
        date_string(),
        time_string(),
      ),
    ),
    (
      2U,
      @gen.liftA3(
        fn(date, time, offset) { OffsetDateTime("\{date}T\{time}\{offset}") },
        date_string(),
        time_string(),
        offset_string(),
      ),
    ),
  ])
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------

///|
fn string_value() -> @gen.Gen[@toml.TomlValue] {
  let strings : @gen.Gen[String] = @gen.Gen::spawn()
  strings.scale(fn(n) { capped(n, 8) }).fmap(fn(s) { TomlString(s) })
}

///|
fn integer_value() -> @gen.Gen[@toml.TomlValue] {
  let integers : @gen.Gen[Int64] = @gen.Gen::spawn()
  integers.fmap(fn(n) { TomlInteger(n) })
}

///|
fn boolean_value() -> @gen.Gen[@toml.TomlValue] {
  let booleans : @gen.Gen[Bool] = @gen.Gen::spawn()
  booleans.fmap(fn(b) { TomlBoolean(b) })
}

///|
fn datetime_value() -> @gen.Gen[@toml.TomlValue] {
  datetime().fmap(fn(dt) { TomlDateTime(dt) })
}

///|
fn non_empty_length(size : Int) -> @gen.Gen[Int] {
  @gen.int_range(1, capped(size + 1, 4) + 1)
}

///|
fn homogeneous_array(
  size : Int,
  element : @gen.Gen[@toml.TomlValue],
) -> @gen.Gen[@toml.TomlValue] {
  non_empty_length(size).bind(fn(len) {
    element.array_with_size(len).fmap(fn(items) { TomlArray(items) })
  })
}

///|
fn scalar_or_array(size : Int) -> @gen.Gen[@toml.TomlValue] {
  @gen.frequency([
    (3U, string_value()),
    (2U, integer_value()),
    (2U, boolean_value()),
    (2U, datetime_value()),
    (1U, @gen.pure(TomlArray([]))),
    (2U, homogeneous_array(size, string_value())),
    (2U, homogeneous_array(size, integer_value())),
    (2U, homogeneous_array(size, boolean_value())),
    (2U, homogeneous_array(size, datetime_value())),
  ])
}

///|
fn entry(size : Int) -> @gen.Gen[(String, @toml.TomlValue)] {
  @gen.liftA2(fn(k, v) { (k, v) }, key(), value(size))
}

///|
fn table_value(size : Int) -> @gen.Gen[@toml.TomlValue] {
  let next_size = size / 2
  @gen.int_range(0, capped(size + 1, 4) + 1).bind(fn(count) {
    entry(next_size)
    .array_with_size(count)
    .fmap(fn(entries) { TomlTable(Map::from_array(entries)) })
  })
}

///|
fn value(size : Int) -> @gen.Gen[@toml.TomlValue] {
  let leaf = scalar_or_array(size)
  if size <= 0 {
    leaf
  } else {
    @gen.frequency([(9U, leaf), (2U, table_value(size))])
  }
}

///|
/// Generate a top-level TOML document (always a `TomlTable`) drawn from the
/// round-trip-safe fragment. This is the reusable entry point: feed it to
/// `@qc.forall_shrink` together with [`shrink_document`], or use the
/// [`RoundTrippable`] newtype for the trait-driven runner.
pub fn roundtrippable_document() -> @gen.Gen[@toml.TomlValue] {
  @gen.sized(fn(size) {
    @gen.int_range(0, capped(size + 1, 5) + 1).bind(fn(count) {
      entry(size)
      .array_with_size(count)
      .fmap(fn(entries) { TomlTable(Map::from_array(entries)) })
    })
  })
}
