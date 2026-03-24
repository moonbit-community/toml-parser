///|
test "serialize simple string" {
  let value = @toml.TomlString("hello world")
  inspect(value, content="\"hello world\"")
}

///|
test "serialize string with escapes" {
  let value = @toml.TomlString("hello\nworld\t\"quoted\"\\backslash")
  inspect(value, content="\"hello\\nworld\\t\\\"quoted\\\"\\\\backslash\"")
}

///|
test "serialize string with control characters" {
  let value = @toml.TomlString("null:\u0000 bell:\u0007 delete:\u007F")
  inspect(value, content="\"null:\\u0000 bell:\\u0007 delete:\\u007F\"")
}

///|
test "serialize integers" {
  inspect(@toml.TomlInteger(42L), content="42")
  inspect(@toml.TomlInteger(-1234L), content="-1234")
  inspect(@toml.TomlInteger(0L), content="0")
}

///|
test "serialize floats" {
  inspect(@toml.TomlFloat(3.14), content="3.14")
  inspect(@toml.TomlFloat(-0.001), content="-0.001")
  inspect(@toml.TomlFloat(6.0), content="6.0")
}

///|
test "serialize special float values" {
  inspect(@toml.TomlFloat(1.0 / 0.0), content="inf")
  inspect(@toml.TomlFloat(-1.0 / 0.0), content="-inf")
  inspect(@toml.TomlFloat(0.0 / 0.0), content="nan")
}

///|
test "serialize booleans" {
  inspect(@toml.TomlBoolean(true), content="true")
  inspect(@toml.TomlBoolean(false), content="false")
}

///|
test "serialize datetime values" {
  inspect(
    @toml.TomlDateTime(@tokenize.OffsetDateTime("1979-05-27T07:32:00Z")),
    content="1979-05-27T07:32:00Z",
  )
  inspect(
    @toml.TomlDateTime(@tokenize.LocalDateTime("1979-05-27T07:32:00")),
    content="1979-05-27T07:32:00",
  )
  inspect(
    @toml.TomlDateTime(@tokenize.LocalDate("1979-05-27")),
    content="1979-05-27",
  )
  inspect(
    @toml.TomlDateTime(@tokenize.LocalTime("07:32:00")),
    content="07:32:00",
  )
}

///|
test "serialize inline array" {
  let array = @toml.TomlArray([
    @toml.TomlInteger(1L),
    @toml.TomlInteger(2L),
    @toml.TomlInteger(3L),
  ])
  inspect(array, content="[1, 2, 3]")
}

///|
test "serialize mixed type inline array" {
  let array = @toml.TomlArray([
    @toml.TomlString("hello"),
    @toml.TomlString("world"),
  ])
  inspect(array, content="[\"hello\", \"world\"]")
}

///|
test "serialize nested array" {
  let array = @toml.TomlArray([
    @toml.TomlArray([@toml.TomlInteger(1L), @toml.TomlInteger(2L)]),
    @toml.TomlArray([@toml.TomlInteger(3L), @toml.TomlInteger(4L)]),
  ])
  inspect(array, content="[[1, 2], [3, 4]]")
}

///|
test "serialize multiline array" {
  let array = @toml.TomlArray([
    @toml.TomlInteger(1L),
    @toml.TomlInteger(2L),
    @toml.TomlInteger(3L),
    @toml.TomlInteger(4L),
    @toml.TomlInteger(5L),
    @toml.TomlInteger(6L),
  ])
  inspect(
    array,
    content=(
      #|[
      #|  1,
      #|  2,
      #|  3,
      #|  4,
      #|  5,
      #|  6
      #|]
    ),
  )
}

///|
test "serialize simple table" {
  let table = Map::from_array([
    ("name", @toml.TomlString("Alice")),
    ("age", @toml.TomlInteger(30L)),
    ("active", @toml.TomlBoolean(true)),
  ])
  inspect(
    @toml.TomlTable(table),
    content=(
      #|name = "Alice"
      #|age = 30
      #|active = true
      #|
    ),
  )
}

///|
test "serialize table with arrays" {
  let table = Map::from_array([
    ("title", @toml.TomlString("Example")),
    (
      "numbers",
      @toml.TomlArray([
        @toml.TomlInteger(1L),
        @toml.TomlInteger(2L),
        @toml.TomlInteger(3L),
      ]),
    ),
  ])
  inspect(
    @toml.TomlTable(table),
    content=(
      #|title = "Example"
      #|
      #|numbers = [1, 2, 3]
      #|
    ),
  )
}

///|
test "serialize nested table" {
  let inner_table = Map::from_array([
    ("x", @toml.TomlInteger(1L)),
    ("y", @toml.TomlInteger(2L)),
  ])
  let outer_table = Map::from_array([
    ("name", @toml.TomlString("test")),
    ("position", @toml.TomlTable(inner_table)),
  ])
  inspect(
    @toml.TomlTable(outer_table),
    content=(
      #|name = "test"
      #|
      #|[position]
      #|x = 1
      #|y = 2
      #|
    ),
  )
}

///|
test "serialize deeply nested tables" {
  let level3 = Map::from_array([("deep", @toml.TomlString("value"))])
  let level2 = Map::from_array([("nested", @toml.TomlTable(level3))])
  let level1 = Map::from_array([
    ("top", @toml.TomlString("level")),
    ("sub", @toml.TomlTable(level2)),
  ])
  inspect(
    @toml.TomlTable(level1),
    content=(
      #|top = "level"
      #|
      #|[sub]
      #|[sub.nested]
      #|deep = "value"
      #|
    ),
  )
}

///|
test "serialize array of tables" {
  let table1 = Map::from_array([
    ("name", @toml.TomlString("Alice")),
    ("score", @toml.TomlInteger(100L)),
  ])
  let table2 = Map::from_array([
    ("name", @toml.TomlString("Bob")),
    ("score", @toml.TomlInteger(95L)),
  ])
  let root = Map::from_array([
    ("title", @toml.TomlString("High Scores")),
    (
      "players",
      @toml.TomlArray([@toml.TomlTable(table1), @toml.TomlTable(table2)]),
    ),
  ])
  inspect(
    @toml.TomlTable(root),
    content=(
      #|title = "High Scores"
      #|
      #|[[players]]
      #|name = "Alice"
      #|score = 100
      #|
      #|[[players]]
      #|name = "Bob"
      #|score = 95
      #|
    ),
  )
}

///|
test "serialize complex nested structure" {
  let database = Map::from_array([
    ("host", @toml.TomlString("localhost")),
    ("port", @toml.TomlInteger(5432L)),
    ("username", @toml.TomlString("admin")),
    ("password", @toml.TomlString("secret123")),
  ])
  let server = Map::from_array([
    ("ip", @toml.TomlString("0.0.0.0")),
    ("port", @toml.TomlInteger(8080L)),
    ("timeout", @toml.TomlInteger(30L)),
  ])
  let staging = Map::from_array([
    ("url", @toml.TomlString("https://staging.example.com")),
    ("debug", @toml.TomlBoolean(true)),
  ])
  let production = Map::from_array([
    ("url", @toml.TomlString("https://example.com")),
    ("debug", @toml.TomlBoolean(false)),
  ])
  let environments = Map::from_array([
    ("staging", @toml.TomlTable(staging)),
    ("production", @toml.TomlTable(production)),
  ])
  let root = Map::from_array([
    ("title", @toml.TomlString("Application Config")),
    ("version", @toml.TomlString("1.0.0")),
    ("database", @toml.TomlTable(database)),
    ("server", @toml.TomlTable(server)),
    ("environments", @toml.TomlTable(environments)),
  ])
  inspect(
    @toml.TomlTable(root),
    content=(
      #|title = "Application Config"
      #|version = "1.0.0"
      #|
      #|[database]
      #|host = "localhost"
      #|port = 5432
      #|username = "admin"
      #|password = "secret123"
      #|
      #|[server]
      #|ip = "0.0.0.0"
      #|port = 8080
      #|timeout = 30
      #|
      #|[environments]
      #|[environments.staging]
      #|url = "https://staging.example.com"
      #|debug = true
      #|
      #|[environments.production]
      #|url = "https://example.com"
      #|debug = false
      #|
    ),
  )
}

///|
test "serialize table with special key names" {
  let table = Map::from_array([
    ("normal-key", @toml.TomlString("value1")),
    ("key with spaces", @toml.TomlString("value2")),
    ("key.with.dots", @toml.TomlString("value3")),
    ("key\"with\"quotes", @toml.TomlString("value4")),
    ("key#with#hash", @toml.TomlString("value5")),
  ])
  inspect(
    @toml.TomlTable(table),
    content=(
      #|normal-key = "value1"
      #|"key with spaces" = "value2"
      #|"key.with.dots" = "value3"
      #|"key\"with\"quotes" = "value4"
      #|"key#with#hash" = "value5"
      #|
    ),
  )
}

///|
test "serialize empty structures" {
  inspect(@toml.TomlArray([]), content="[]")
  inspect(@toml.TomlTable(Map::new()), content="")
}

///|
test "serialize array with tables should be multiline" {
  let table1 = Map::from_array([("a", @toml.TomlInteger(1L))])
  let array = @toml.TomlArray([@toml.TomlTable(table1), @toml.TomlInteger(2L)])
  inspect(
    array,
    content=(
      #|[
      #|  a = 1
      #|,
      #|  2
      #|]
    ),
  )
}

///|
test "serialize table with multiple array of tables" {
  let product1 = Map::from_array([
    ("name", @toml.TomlString("Hammer")),
    ("sku", @toml.TomlInteger(738594937L)),
  ])
  let product2 = Map::from_array([
    ("name", @toml.TomlString("Nail")),
    ("sku", @toml.TomlInteger(284758393L)),
    ("color", @toml.TomlString("gray")),
  ])
  let root = Map::from_array([
    (
      "products",
      @toml.TomlArray([@toml.TomlTable(product1), @toml.TomlTable(product2)]),
    ),
  ])
  inspect(
    @toml.TomlTable(root),
    content=(
      #|[[products]]
      #|name = "Hammer"
      #|sku = 738594937
      #|
      #|[[products]]
      #|name = "Nail"
      #|sku = 284758393
      #|color = "gray"
      #|
    ),
  )
}

///|
test "roundtrip simple key-value pairs" {
  let toml =
    #|title = "TOML Example"
    #|version = "1.0.0"
    #|debug = true
    #|max_connections = 100
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip nested tables" {
  let toml =
    #|[database]
    #|host = "localhost"
    #|port = 5432
    #|
    #|[database.credentials]
    #|user = "admin"
    #|password = "secret"
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip array of tables" {
  let toml =
    #|[[products]]
    #|name = "Hammer"
    #|sku = 738594937
    #|
    #|[[products]]
    #|name = "Nail"
    #|sku = 284758393
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip datetimes" {
  let toml =
    #|offset = 2023-01-15T10:30:00Z
    #|local_dt = 2023-01-15T10:30:00
    #|local_date = 2023-01-15
    #|local_time = 10:30:00
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip arrays" {
  let toml =
    #|numbers = [1, 2, 3, 4, 5]
    #|strings = ["hello", "world"]
    #|nested = [[1, 2], [3, 4]]
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip special floats" {
  let toml =
    #|pos_inf = inf
    #|neg_inf = -inf
    #|nan_val = nan
    #|pi = 3.14
    #|
  let parsed = @toml.parse(toml)
  // NaN != NaN, so compare non-NaN values and check NaN separately
  let serialized = parsed.to_string()
  let roundtripped = @toml.parse(serialized)
  // Check that the serialized form re-parses correctly
  inspect(
    serialized,
    content=(
      #|pos_inf = inf
      #|neg_inf = -inf
      #|nan_val = nan
      #|pi = 3.14
      #|
    ),
  )
  // Verify non-NaN values match
  guard roundtripped is @toml.TomlTable(t) else { fail("expected table") }
  guard t.get("pos_inf") is Some(@toml.TomlFloat(f)) else {
    fail("expected float")
  }
  assert_true(f.is_inf() && f > 0.0)
  guard t.get("nan_val") is Some(@toml.TomlFloat(n)) else {
    fail("expected float")
  }
  assert_true(n.is_nan())
}

///|
test "roundtrip complex config" {
  let toml =
    #|title = "Application Config"
    #|
    #|[owner]
    #|name = "Tom"
    #|dob = 1979-05-27T07:32:00-08:00
    #|
    #|[database]
    #|enabled = true
    #|ports = [8000, 8001, 8002]
    #|
    #|[[servers]]
    #|name = "alpha"
    #|ip = "10.0.0.1"
    #|
    #|[[servers]]
    #|name = "beta"
    #|ip = "10.0.0.2"
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip string escapes" {
  let toml =
    #|escaped = "hello\nworld\ttab\\backslash\"quote"
    #|
  let parsed = @toml.parse(toml)
  let roundtripped = @toml.parse(parsed.to_string())
  assert_eq(parsed, roundtripped)
}

///|
test "roundtrip simple example" {
  let doc = Map::from_array([
    ("title", @toml.TomlString("TOML Example")),
    (
      "owner",
      @toml.TomlTable(
        Map::from_array([
          ("name", @toml.TomlString("Tom Preston-Werner")),
          (
            "dob",
            @toml.TomlDateTime(
              @tokenize.OffsetDateTime("1979-05-27T07:32:00-08:00"),
            ),
          ),
        ]),
      ),
    ),
    (
      "database",
      @toml.TomlTable(
        Map::from_array([
          ("enabled", @toml.TomlBoolean(true)),
          (
            "ports",
            @toml.TomlArray([
              @toml.TomlInteger(8000L),
              @toml.TomlInteger(8001L),
              @toml.TomlInteger(8002L),
            ]),
          ),
          (
            "temp_targets",
            @toml.TomlTable(
              Map::from_array([
                ("cpu", @toml.TomlFloat(79.5)),
                ("case", @toml.TomlFloat(72.0)),
              ]),
            ),
          ),
        ]),
      ),
    ),
  ])
  let value = @toml.TomlTable(doc)
  inspect(
    value,
    content=(
      #|title = "TOML Example"
      #|
      #|[owner]
      #|name = "Tom Preston-Werner"
      #|dob = 1979-05-27T07:32:00-08:00
      #|
      #|[database]
      #|enabled = true
      #|
      #|ports = [8000, 8001, 8002]
      #|
      #|[database.temp_targets]
      #|cpu = 79.5
      #|case = 72.0
      #|
    ),
  )
  // Verify roundtrip
  let roundtripped = @toml.parse(value.to_string())
  assert_eq(value, roundtripped)
}
