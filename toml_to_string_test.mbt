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
    @toml.TomlDateTime(OffsetDateTime("1979-05-27T07:32:00Z")),
    content="1979-05-27T07:32:00Z",
  )
  inspect(
    @toml.TomlDateTime(LocalDateTime("1979-05-27T07:32:00")),
    content="1979-05-27T07:32:00",
  )
  inspect(@toml.TomlDateTime(LocalDate("1979-05-27")), content="1979-05-27")
  inspect(@toml.TomlDateTime(LocalTime("07:32:00")), content="07:32:00")
}

///|
test "serialize inline array" {
  let array = @toml.TomlArray([
    TomlInteger(1L),
    TomlInteger(2L),
    TomlInteger(3L),
  ])
  inspect(array, content="[1, 2, 3]")
}

///|
test "serialize mixed type inline array" {
  let array = @toml.TomlArray([TomlString("hello"), TomlString("world")])
  inspect(array, content="[\"hello\", \"world\"]")
}

///|
test "serialize nested array" {
  let array = @toml.TomlArray([
    TomlArray([TomlInteger(1L), TomlInteger(2L)]),
    TomlArray([TomlInteger(3L), TomlInteger(4L)]),
  ])
  inspect(array, content="[[1, 2], [3, 4]]")
}

///|
test "serialize multiline array" {
  let array = @toml.TomlArray([
    TomlInteger(1L),
    TomlInteger(2L),
    TomlInteger(3L),
    TomlInteger(4L),
    TomlInteger(5L),
    TomlInteger(6L),
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
    ("age", TomlInteger(30L)),
    ("active", TomlBoolean(true)),
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
    ("numbers", TomlArray([TomlInteger(1L), TomlInteger(2L), TomlInteger(3L)])),
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
    ("y", TomlInteger(2L)),
  ])
  let outer_table = Map::from_array([
    ("name", @toml.TomlString("test")),
    ("position", TomlTable(inner_table)),
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
    ("sub", TomlTable(level2)),
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
    ("score", TomlInteger(100L)),
  ])
  let table2 = Map::from_array([
    ("name", @toml.TomlString("Bob")),
    ("score", TomlInteger(95L)),
  ])
  let root = Map::from_array([
    ("title", @toml.TomlString("High Scores")),
    ("players", TomlArray([TomlTable(table1), TomlTable(table2)])),
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
    ("port", TomlInteger(5432L)),
    ("username", TomlString("admin")),
    ("password", TomlString("secret123")),
  ])
  let server = Map::from_array([
    ("ip", @toml.TomlString("0.0.0.0")),
    ("port", TomlInteger(8080L)),
    ("timeout", TomlInteger(30L)),
  ])
  let staging = Map::from_array([
    ("url", @toml.TomlString("https://staging.example.com")),
    ("debug", TomlBoolean(true)),
  ])
  let production = Map::from_array([
    ("url", @toml.TomlString("https://example.com")),
    ("debug", TomlBoolean(false)),
  ])
  let environments = Map::from_array([
    ("staging", @toml.TomlTable(staging)),
    ("production", TomlTable(production)),
  ])
  let root = Map::from_array([
    ("title", @toml.TomlString("Application Config")),
    ("version", TomlString("1.0.0")),
    ("database", TomlTable(database)),
    ("server", TomlTable(server)),
    ("environments", TomlTable(environments)),
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
    ("key with spaces", TomlString("value2")),
    ("key.with.dots", TomlString("value3")),
    ("key\"with\"quotes", TomlString("value4")),
    ("key#with#hash", TomlString("value5")),
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
  inspect(@toml.TomlTable(Map([])), content="")
}

///|
test "serialize array with tables should be multiline" {
  let table1 = Map::from_array([("a", @toml.TomlInteger(1L))])
  let array = @toml.TomlArray([TomlTable(table1), TomlInteger(2L)])
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
    ("sku", TomlInteger(738594937L)),
  ])
  let product2 = Map::from_array([
    ("name", @toml.TomlString("Nail")),
    ("sku", TomlInteger(284758393L)),
    ("color", TomlString("gray")),
  ])
  let root = Map::from_array([
    ("products", @toml.TomlArray([TomlTable(product1), TomlTable(product2)])),
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
  guard roundtripped is TomlTable(t) else { fail("expected table") }
  guard t.get("pos_inf") is Some(TomlFloat(f)) else { fail("expected float") }
  assert_true(f.is_inf() && f > 0.0)
  guard t.get("nan_val") is Some(TomlFloat(n)) else { fail("expected float") }
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
      TomlTable(
        Map::from_array([
          ("name", TomlString("Tom Preston-Werner")),
          ("dob", TomlDateTime(OffsetDateTime("1979-05-27T07:32:00-08:00"))),
        ]),
      ),
    ),
    (
      "database",
      TomlTable(
        Map::from_array([
          ("enabled", TomlBoolean(true)),
          (
            "ports",
            TomlArray([
              TomlInteger(8000L),
              TomlInteger(8001L),
              TomlInteger(8002L),
            ]),
          ),
          (
            "temp_targets",
            TomlTable(
              Map::from_array([
                ("cpu", TomlFloat(79.5)),
                ("case", TomlFloat(72.0)),
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
