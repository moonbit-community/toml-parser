///|
test "serialize simple string" {
  let value = @toml.TomlString("hello world")
  debug_inspect(
    value.to_string(),
    content=(
      #|"\"hello world\""
    ),
  )
}

///|
test "serialize string with escapes" {
  let value = @toml.TomlString("hello\nworld\t\"quoted\"\\backslash")
  debug_inspect(
    value.to_string(),
    content=(
      #|"\"hello\\nworld\\t\\\"quoted\\\"\\\\backslash\""
    ),
  )
}

///|
test "serialize string with control characters" {
  let value = @toml.TomlString("null:\u0000 bell:\u0007 delete:\u007F")
  debug_inspect(
    value.to_string(),
    content=(
      #|"\"null:\\u0000 bell:\\u0007 delete:\\u007F\""
    ),
  )
}

///|
test "serialize integers" {
  let value1 = @toml.TomlInteger(42L)
  let value2 = @toml.TomlInteger(-1234L)
  let value3 = @toml.TomlInteger(0L)
  debug_inspect(
    value1.to_string(),
    content=(
      #|"42"
    ),
  )
  debug_inspect(
    value2.to_string(),
    content=(
      #|"-1234"
    ),
  )
  debug_inspect(
    value3.to_string(),
    content=(
      #|"0"
    ),
  )
}

///|
test "serialize floats" {
  let value1 = @toml.TomlFloat(3.14)
  let value2 = @toml.TomlFloat(-0.001)
  let value3 = @toml.TomlFloat(6.0)
  debug_inspect(
    value1.to_string(),
    content=(
      #|"3.14"
    ),
  )
  debug_inspect(
    value2.to_string(),
    content=(
      #|"-0.001"
    ),
  )
  debug_inspect(
    value3.to_string(),
    content=(
      #|"6.0"
    ),
  )
}

///|
test "serialize special float values" {
  let inf_pos = @toml.TomlFloat(1.0 / 0.0)
  let inf_neg = @toml.TomlFloat(-1.0 / 0.0)
  let nan = @toml.TomlFloat(0.0 / 0.0)
  debug_inspect(
    inf_pos.to_string(),
    content=(
      #|"inf"
    ),
  )
  debug_inspect(
    inf_neg.to_string(),
    content=(
      #|"-inf"
    ),
  )
  debug_inspect(
    nan.to_string(),
    content=(
      #|"nan"
    ),
  )
}

///|
test "serialize booleans" {
  let true_val = @toml.TomlBoolean(true)
  let false_val = @toml.TomlBoolean(false)
  debug_inspect(
    true_val.to_string(),
    content=(
      #|"true"
    ),
  )
  debug_inspect(
    false_val.to_string(),
    content=(
      #|"false"
    ),
  )
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
  debug_inspect(
    offset_dt.to_string(),
    content=(
      #|"1979-05-27T07:32:00Z"
    ),
  )
  debug_inspect(
    local_dt.to_string(),
    content=(
      #|"1979-05-27T07:32:00"
    ),
  )
  debug_inspect(
    local_date.to_string(),
    content=(
      #|"1979-05-27"
    ),
  )
  debug_inspect(
    local_time.to_string(),
    content=(
      #|"07:32:00"
    ),
  )
}

///|
test "serialize inline array" {
  let array = @toml.TomlArray([
    @toml.TomlInteger(1L),
    @toml.TomlInteger(2L),
    @toml.TomlInteger(3L),
  ])
  debug_inspect(
    array.to_string(),
    content=(
      #|"[1, 2, 3]"
    ),
  )
}

///|
test "serialize mixed type inline array" {
  let array = @toml.TomlArray([
    @toml.TomlString("hello"),
    @toml.TomlString("world"),
  ])
  debug_inspect(
    array.to_string(),
    content=(
      #|"[\"hello\", \"world\"]"
    ),
  )
}

///|
test "serialize nested array" {
  let array = @toml.TomlArray([
    @toml.TomlArray([@toml.TomlInteger(1L), @toml.TomlInteger(2L)]),
    @toml.TomlArray([@toml.TomlInteger(3L), @toml.TomlInteger(4L)]),
  ])
  debug_inspect(
    array.to_string(),
    content=(
      #|"[[1, 2], [3, 4]]"
    ),
  )
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
  debug_inspect(
    array.to_string(),
    content=(
      #|"[\n  1,\n  2,\n  3,\n  4,\n  5,\n  6\n]"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"name = \"Alice\"\nage = 30\nactive = true\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"title = \"Example\"\n\nnumbers = [1, 2, 3]\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"name = \"test\"\n\n[position]\nx = 1\ny = 2\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"top = \"level\"\n\n[sub]\n[sub.nested]\ndeep = \"value\"\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"title = \"High Scores\"\n\n[[players]]\nname = \"Alice\"\nscore = 100\n\n[[players]]\nname = \"Bob\"\nscore = 95\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"title = \"Application Config\"\nversion = \"1.0.0\"\n\n[database]\nhost = \"localhost\"\nport = 5432\nusername = \"admin\"\npassword = \"secret123\"\n\n[server]\nip = \"0.0.0.0\"\nport = 8080\ntimeout = 30\n\n[environments]\n[environments.staging]\nurl = \"https://staging.example.com\"\ndebug = true\n\n[environments.production]\nurl = \"https://example.com\"\ndebug = false\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"normal-key = \"value1\"\nkey with spaces = \"value2\"\nkey.with.dots = \"value3\"\n\"key\\\"with\\\"quotes\" = \"value4\"\n\"key#with#hash\" = \"value5\"\n"
    ),
  )
}

///|
test "serialize empty structures" {
  let empty_array = @toml.TomlArray([])
  let empty_table = @toml.TomlTable(Map::new())
  debug_inspect(
    empty_array.to_string(),
    content=(
      #|"[]"
    ),
  )
  debug_inspect(
    empty_table.to_string(),
    content=(
      #|""
    ),
  )
}

///|
test "serialize array with tables should be multiline" {
  let table1 = Map::from_array([("a", @toml.TomlInteger(1L))])
  let array = @toml.TomlArray([@toml.TomlTable(table1), @toml.TomlInteger(2L)])
  debug_inspect(
    array.to_string(),
    content=(
      #|"[\n  a = 1\n,\n  2\n]"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"title = \"TOML Example\"\n\n[owner]\nname = \"Tom Preston-Werner\"\ndob = 1979-05-27T07:32:00-08:00\n\n[database]\nenabled = true\n\nports = [8000, 8001, 8002]\n\n[database.temp_targets]\ncpu = 79.5\ncase = 72.0\n"
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
  debug_inspect(
    value.to_string(),
    content=(
      #|"[[products]]\nname = \"Hammer\"\nsku = 738594937\n\n[[products]]\nname = \"Nail\"\nsku = 284758393\ncolor = \"gray\"\n"
    ),
  )
}
