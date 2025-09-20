///|
test "serialize simple string" {
  let value = @toml.TomlString("hello world")
  inspect(
    value.to_string(),
    content=(
      #|"hello world"
    ),
  )
}

///|
test "serialize string with escapes" {
  let value = @toml.TomlString("hello\nworld\t\"quoted\"\\backslash")
  inspect(
    value.to_string(),
    content=(
      #|"hello\nworld\t\"quoted\"\\backslash"
    ),
  )
}

///|
test "serialize string with control characters" {
  let value = @toml.TomlString("null:\u0000 bell:\u0007 delete:\u007F")
  inspect(
    value.to_string(),
    content=(
      #|"null:\u0000 bell:\u0007 delete:\u007F"
    ),
  )
}

///|
test "serialize integers" {
  let value1 = @toml.TomlInteger(42L)
  let value2 = @toml.TomlInteger(-1234L)
  let value3 = @toml.TomlInteger(0L)
  inspect(value1.to_string(), content="42")
  inspect(value2.to_string(), content="-1234")
  inspect(value3.to_string(), content="0")
}

///|
test "serialize floats" {
  let value1 = @toml.TomlFloat(3.14)
  let value2 = @toml.TomlFloat(-0.001)
  let value3 = @toml.TomlFloat(6.0)
  inspect(value1.to_string(), content="3.14")
  inspect(value2.to_string(), content="-0.001")
  inspect(value3.to_string(), content="6.0")
}

///|
test "serialize special float values" {
  let inf_pos = @toml.TomlFloat(1.0 / 0.0)
  let inf_neg = @toml.TomlFloat(-1.0 / 0.0)
  let nan = @toml.TomlFloat(0.0 / 0.0)
  inspect(inf_pos.to_string(), content="inf")
  inspect(inf_neg.to_string(), content="-inf")
  inspect(nan.to_string(), content="nan")
}

///|
test "serialize booleans" {
  let true_val = @toml.TomlBoolean(true)
  let false_val = @toml.TomlBoolean(false)
  inspect(true_val.to_string(), content="true")
  inspect(false_val.to_string(), content="false")
}

///|
test "serialize datetime values" {
  let offset_dt = @toml.TomlDateTime(
    @tokenize.OffsetDateTime("1979-05-27T07:32:00Z"),
  )
  let local_dt = @toml.TomlDateTime(
    @tokenize.LocalDateTime("1979-05-27T07:32:00"),
  )
  let local_date = @toml.TomlDateTime(@tokenize.LocalDate("1979-05-27"))
  let local_time = @toml.TomlDateTime(@tokenize.LocalTime("07:32:00"))
  inspect(offset_dt.to_string(), content="1979-05-27T07:32:00Z")
  inspect(local_dt.to_string(), content="1979-05-27T07:32:00")
  inspect(local_date.to_string(), content="1979-05-27")
  inspect(local_time.to_string(), content="07:32:00")
}

///|
test "serialize inline array" {
  let array = @toml.TomlArray([
    @toml.TomlInteger(1L),
    @toml.TomlInteger(2L),
    @toml.TomlInteger(3L),
  ])
  inspect(array.to_string(), content="[1, 2, 3]")
}

///|
test "serialize mixed type inline array" {
  let array = @toml.TomlArray([
    @toml.TomlString("hello"),
    @toml.TomlString("world"),
  ])
  inspect(
    array.to_string(),
    content=(
      #|["hello", "world"]
    ),
  )
}

///|
test "serialize nested array" {
  let array = @toml.TomlArray([
    @toml.TomlArray([@toml.TomlInteger(1L), @toml.TomlInteger(2L)]),
    @toml.TomlArray([@toml.TomlInteger(3L), @toml.TomlInteger(4L)]),
  ])
  inspect(array.to_string(), content="[[1, 2], [3, 4]]")
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
    array.to_string(),
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
  let value = @toml.TomlTable(table)
  inspect(
    value.to_string(),
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
  let value = @toml.TomlTable(table)
  inspect(
    value.to_string(),
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
  let value = @toml.TomlTable(outer_table)
  inspect(
    value.to_string(),
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
  let value = @toml.TomlTable(level1)
  inspect(
    value.to_string(),
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
  let value = @toml.TomlTable(root)
  inspect(
    value.to_string(),
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
  // Create a complex structure like a configuration file
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
  let value = @toml.TomlTable(root)
  inspect(
    value.to_string(),
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
  let value = @toml.TomlTable(table)
  inspect(
    value.to_string(),
    content=(
      #|normal-key = "value1"
      #|key with spaces = "value2"
      #|key.with.dots = "value3"
      #|"key\"with\"quotes" = "value4"
      #|"key#with#hash" = "value5"
      #|
    ),
  )
}

///|
test "serialize empty structures" {
  let empty_array = @toml.TomlArray([])
  let empty_table = @toml.TomlTable(Map::new())
  inspect(empty_array.to_string(), content="[]")
  inspect(empty_table.to_string(), content="")
}

///|
test "serialize array with tables should be multiline" {
  let table1 = Map::from_array([("a", @toml.TomlInteger(1L))])
  let array = @toml.TomlArray([@toml.TomlTable(table1), @toml.TomlInteger(2L)])
  inspect(
    array.to_string(),
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
test "roundtrip simple example" {
  // Test that we can serialize and the output looks like valid TOML
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
    value.to_string(),
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
  let value = @toml.TomlTable(root)
  inspect(
    value.to_string(),
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
