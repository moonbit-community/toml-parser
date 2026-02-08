///|
/// Create or get a nested table structure from a path
fn create_nested_table(
  root_table : Map[String, TomlValue],
  path : Array[String],
) -> Map[String, TomlValue] raise TableConflicts {
  let mut current_table = root_table
  for key in path {
    match current_table.get(key) {
      Some(TomlTable(existing_table)) => current_table = existing_table
      Some(value) => raise ExpectedTable(key, value)
      // parse_error(
      //   error_tokens,
      //   "Table path conflicts with existing value: \{key}",
      // )
      None => {
        let new_table = Map::new()
        current_table[key] = TomlTable(new_table)
        current_table = new_table
      }
    }
  }
  current_table
}

///|
priv suberror TableConflicts {
  ExpectedTable(String, TomlValue)
  ExpectedArray(String, TomlValue)
} derive(ToJson, Debug)

///|
/// Show impl for error messages
impl Show for TableConflicts with output(self, logger) {
  match self {
    ExpectedTable(key, value) => {
      logger.write_string("ExpectedTable(\"")
      logger.write_string(key)
      logger.write_string("\", \"")
      logger.write_string(value.type_name())
      logger.write_string("\")")
    }
    ExpectedArray(key, value) => {
      logger.write_string("ExpectedArray(\"")
      logger.write_string(key)
      logger.write_string("\", \"")
      logger.write_string(value.type_name())
      logger.write_string("\")")
    }
  }
}

///|
/// Create or append to an array of tables structure in TOML.
/// 
/// This function handles the `[[table]]` syntax in TOML, which creates an array
/// of tables. If the array doesn't exist, it creates it with the first table.
/// If the array exists, it appends a new table to it.
/// 
/// ## Parameters
/// - `root_table`: The root table where the array of tables will be created/modified
/// - `path`: The dotted key path to the array (e.g., ["servers", "alpha"] for [[servers.alpha]])
/// - `error_tokens`: Token view for error reporting
/// 
/// ## Returns
/// The newly created empty table that was added to the array
/// 
/// ## Errors
/// - Raises if the path conflicts with existing non-table values
/// - Raises if the final key exists but is not an array
/// 
/// ## Example
/// ```
/// // For TOML: [[servers.alpha]]
/// // Creates: { servers: { alpha: [{}] } }
/// // Second call appends: { servers: { alpha: [{}, {}] } }
/// ```
fn create_array_of_tables(
  root_table : Map[String, TomlValue],
  path : Array[String],
) -> Map[String, TomlValue] raise TableConflicts {
  let mut current_table = root_table

  // Navigate to the parent of the final key
  for key in path[:-1] {
    match current_table.get(key) {
      Some(TomlTable(existing_table)) => current_table = existing_table
      Some(value) => raise ExpectedTable(key, value)
      None => {
        let new_table = Map::new()
        current_table[key] = TomlTable(new_table)
        current_table = new_table
      }
    }
  }

  // Handle the final key as an array of tables
  let final_key = path[path.length() - 1]
  let new_table = {}
  match current_table.get(final_key) {
    Some(TomlArray(existing_array)) => {
      // Append a new table to the existing array
      existing_array.push(TomlTable(new_table))
      new_table
    }
    Some(value) => raise ExpectedArray(final_key, value)
    None => {
      // Create new array with the first table
      let array = Array::new()
      array.push(TomlTable(new_table))
      current_table[final_key] = TomlArray(array)
      new_table
    }
  }
}

///|
test "create_array_of_tables - first table creation" {
  // Test creating the first table in an array of tables
  let root_table : Map[String, TomlValue] = {}

  // Create first table in array [[servers]]
  let new_table = create_array_of_tables(root_table, ["servers"])

  // Add some data to the new table
  new_table["name"] = TomlString("alpha")
  new_table["ip"] = TomlString("10.0.0.1")
  inspect(
    TomlTable(root_table),
    content=(
      #|[[servers]]
      #|name = "alpha"
      #|ip = "10.0.0.1"
      #|
    ),
  )
}

///|
test "create_array_of_tables - append to existing array" {
  // Test appending to an existing array of tables
  let root_table : Map[String, TomlValue] = {}

  // Create first table
  let table1 = create_array_of_tables(root_table, ["products"])
  table1["name"] = TomlString("Hammer")
  table1["sku"] = TomlInteger(738594937)

  // Append second table to same array
  let table2 = create_array_of_tables(root_table, ["products"])
  table2["name"] = TomlString("Nail")
  table2["sku"] = TomlInteger(284758393)

  // Append third table
  let table3 = create_array_of_tables(root_table, ["products"])
  table3["name"] = TomlString("Screwdriver")
  table3["sku"] = TomlInteger(987654321)
  inspect(
    TomlTable(root_table),
    content=(
      #|[[products]]
      #|name = "Hammer"
      #|sku = 738594937
      #|
      #|[[products]]
      #|name = "Nail"
      #|sku = 284758393
      #|
      #|[[products]]
      #|name = "Screwdriver"
      #|sku = 987654321
      #|
    ),
  )
}

///|
test "create_array_of_tables - nested path creation" {
  // Test creating array of tables with nested path
  let root_table : Map[String, TomlValue] = {}

  // Create [[fruit.physical.color]]
  let color_table1 = create_array_of_tables(root_table, [
    "fruit", "physical", "color",
  ])
  color_table1["name"] = TomlString("red")
  color_table1["code"] = TomlString("#FF0000")

  // Add another color
  let color_table2 = create_array_of_tables(root_table, [
    "fruit", "physical", "color",
  ])
  color_table2["name"] = TomlString("green")
  color_table2["code"] = TomlString("#00FF00")
  inspect(
    TomlTable(root_table),
    content=(
      #|[fruit]
      #|[fruit.physical]
      #|[[fruit.physical.color]]
      #|name = "red"
      #|code = "#FF0000"
      #|
      #|[[fruit.physical.color]]
      #|name = "green"
      #|code = "#00FF00"
      #|
    ),
  )
}

///|
test "create_array_of_tables - mixed with regular tables" {
  // Test array of tables mixed with regular tables
  let root_table : Map[String, TomlValue] = Map::new()

  // First create a regular table structure
  set_dotted_key_value(root_table, ["owner", "name"], TomlString("Tom"))
  set_dotted_key_value(root_table, ["owner", "dob"], TomlString("1979-05-27"))

  // Now create array of tables at a different path
  let db1 = create_array_of_tables(root_table, ["database", "servers"])
  db1["host"] = TomlString("192.168.1.1")
  db1["port"] = TomlInteger(5432)
  let db2 = create_array_of_tables(root_table, ["database", "servers"])
  db2["host"] = TomlString("192.168.1.2")
  db2["port"] = TomlInteger(5433)
  json_inspect(root_table, content={
    "owner": [
      "TomlTable",
      { "name": ["TomlString", "Tom"], "dob": ["TomlString", "1979-05-27"] },
    ],
    "database": [
      "TomlTable",
      {
        "servers": [
          "TomlArray",
          [
            [
              "TomlTable",
              {
                "host": ["TomlString", "192.168.1.1"],
                "port": ["TomlInteger", "5432"],
              },
            ],
            [
              "TomlTable",
              {
                "host": ["TomlString", "192.168.1.2"],
                "port": ["TomlInteger", "5433"],
              },
            ],
          ],
        ],
      },
    ],
  })
}

///|
#skip("error message is not correct")
test "create_array_of_tables - path conflicts with non-table" {
  // Test error when intermediate path conflicts with non-table value
  let root_table : Map[String, TomlValue] = Map::new()

  // Set a string value at "products"
  root_table["products"] = TomlString("not a table")

  // Try to create array of tables at ["products", "items"]
  // This should fail because "products" is not a table
  let result = try? create_array_of_tables(root_table, ["products", "items"])
  debug_inspect(
    result,
    content=(
      #|Err(Failure("/Users/hongbozhang/git/toml-parser/parser.mbt:1038:11-1038:45 FAILED: Array of tables path conflicts with existing value: products at the end of input"))
    ),
  )
}

///|
#skip("error message is not correct")
test "create_array_of_tables - final key conflicts with non-array" {
  // Test error when final key exists but is not an array
  let root_table : Map[String, TomlValue] = Map::new()

  // Create a regular table at servers.alpha
  set_dotted_key_value(
    root_table,
    ["servers", "alpha"],
    TomlTable(Map::from_array([("name", TomlString("main"))])),
  )

  // Try to treat servers.alpha as array of tables
  let result = try? create_array_of_tables(root_table, ["servers", "alpha"])
  debug_inspect(
    result,
    content=(
      #|Err(Failure("/Users/hongbozhang/git/toml-parser/parser.mbt:1049:11-1049:45 FAILED: Array of tables conflicts with existing non-array value: alpha at the end of input"))
    ),
  )
}

///|
test "create_array_of_tables - multiple nested arrays" {
  // Test creating multiple different arrays of tables
  let root_table : Map[String, TomlValue] = Map::new()

  // Create first [[fruits]]
  let fruit1 = create_array_of_tables(root_table, ["fruits"])
  fruit1["name"] = TomlString("apple")

  // Create second [[fruits]]
  let fruit2 = create_array_of_tables(root_table, ["fruits"])
  fruit2["name"] = TomlString("banana")

  // Create [[vegetables]]
  let veg1 = create_array_of_tables(root_table, ["vegetables"])
  veg1["name"] = TomlString("carrot")
  veg1["color"] = TomlString("orange")
  let veg2 = create_array_of_tables(root_table, ["vegetables"])
  veg2["name"] = TomlString("lettuce")
  veg2["color"] = TomlString("green")
  json_inspect(root_table, content={
    "fruits": [
      "TomlArray",
      [
        ["TomlTable", { "name": ["TomlString", "apple"] }],
        ["TomlTable", { "name": ["TomlString", "banana"] }],
      ],
    ],
    "vegetables": [
      "TomlArray",
      [
        [
          "TomlTable",
          {
            "name": ["TomlString", "carrot"],
            "color": ["TomlString", "orange"],
          },
        ],
        [
          "TomlTable",
          {
            "name": ["TomlString", "lettuce"],
            "color": ["TomlString", "green"],
          },
        ],
      ],
    ],
  })
}

///|
test "create_array_of_tables - empty table in array" {
  // Test that empty tables are correctly added to arrays
  let root_table : Map[String, TomlValue] = Map::new()

  // Create empty table in array
  let _empty_table1 = create_array_of_tables(root_table, ["empty", "tables"])
  // Don't add any fields

  let _empty_table2 = create_array_of_tables(root_table, ["empty", "tables"])
  // Also empty

  let table3 = create_array_of_tables(root_table, ["empty", "tables"])
  table3["has_content"] = TomlBoolean(true)
  json_inspect(root_table, content={
    "empty": [
      "TomlTable",
      {
        "tables": [
          "TomlArray",
          [
            ["TomlTable", {}],
            ["TomlTable", {}],
            ["TomlTable", { "has_content": ["TomlBoolean", true] }],
          ],
        ],
      },
    ],
  })
}

///|
/// Set a value using a dotted key path in a table
fn set_dotted_key_value(
  table : Map[String, TomlValue],
  key_path : Array[String],
  value : TomlValue,
) -> Unit raise TableConflicts {
  guard key_path.length() != 0
  if key_path.length() == 1 {
    // Simple key assignment
    table[key_path[0]] = value
    return
  }

  // Navigate through the dotted path, creating tables as needed
  let mut current_table = table
  for i = 0; i < key_path.length() - 1; i = i + 1 {
    let key = key_path[i]
    match current_table.get(key) {
      Some(TomlTable(existing_table)) => current_table = existing_table
      Some(value) => raise ExpectedTable(key, value)
      // parse_error(
      //   error_tokens,
      //   "Dotted key path conflicts with existing non-table value: \{key}",
      // )
      None => {
        // Create new nested table
        let new_table = Map::new()
        current_table[key] = TomlTable(new_table)
        current_table = new_table
      }
    }
  }

  // Set the final value
  let final_key = key_path[key_path.length() - 1]
  current_table[final_key] = value
}

///|
test "set dotted key value - simple key" {
  // Test setting a simple key (path length 1)
  let table : Map[String, TomlValue] = Map::new()
  set_dotted_key_value(table, ["name"], TomlString("Alice"))
  json_inspect(table, content={ "name": ["TomlString", "Alice"] })
}

///|
test "set dotted key value - nested keys creating tables" {
  // Test creating nested tables automatically
  let table : Map[String, TomlValue] = Map::new()
  set_dotted_key_value(table, ["server", "host"], TomlString("localhost"))
  set_dotted_key_value(table, ["server", "port"], TomlInteger(8080))
  json_inspect(table, content={
    "server": [
      "TomlTable",
      { "host": ["TomlString", "localhost"], "port": ["TomlInteger", "8080"] },
    ],
  })
}

///|
test "set dotted key value - deep nesting" {
  // Test deep nested table creation
  let table : Map[String, TomlValue] = Map::new()
  set_dotted_key_value(
    table,
    ["a", "b", "c", "d", "e"],
    TomlString("deep value"),
  )
  json_inspect(table, content={
    "a": [
      "TomlTable",
      {
        "b": [
          "TomlTable",
          {
            "c": [
              "TomlTable",
              { "d": ["TomlTable", { "e": ["TomlString", "deep value"] }] },
            ],
          },
        ],
      },
    ],
  })
}

///|
test "set dotted key value - multiple values same nested table" {
  // Test adding multiple values to the same nested table
  let table : Map[String, TomlValue] = Map::new()

  // Add multiple values at different levels
  set_dotted_key_value(table, ["database", "server"], TomlString("postgres"))
  set_dotted_key_value(table, ["database", "port"], TomlInteger(5432))
  set_dotted_key_value(
    table,
    ["database", "credentials", "user"],
    TomlString("admin"),
  )
  set_dotted_key_value(
    table,
    ["database", "credentials", "password"],
    TomlString("secret"),
  )
  set_dotted_key_value(table, ["database", "options", "ssl"], TomlBoolean(true))
  json_inspect(table, content={
    "database": [
      "TomlTable",
      {
        "server": ["TomlString", "postgres"],
        "port": ["TomlInteger", "5432"],
        "credentials": [
          "TomlTable",
          {
            "user": ["TomlString", "admin"],
            "password": ["TomlString", "secret"],
          },
        ],
        "options": ["TomlTable", { "ssl": ["TomlBoolean", true] }],
      },
    ],
  })
}

///|
test "set dotted key value - overwrite existing value" {
  // Test overwriting an existing value
  let table : Map[String, TomlValue] = Map::new()

  // Set initial value
  set_dotted_key_value(table, ["config", "timeout"], TomlInteger(30))

  // Overwrite with new value
  set_dotted_key_value(table, ["config", "timeout"], TomlInteger(60))
  json_inspect(table, content={
    "config": ["TomlTable", { "timeout": ["TomlInteger", "60"] }],
  })
}

///|
test "set dotted key value - add to existing table" {
  // Test adding values to an already existing table
  let table : Map[String, TomlValue] = Map::new()

  // Create initial structure
  set_dotted_key_value(table, ["app", "name"], TomlString("MyApp"))
  set_dotted_key_value(table, ["app", "version"], TomlString("1.0.0"))

  // Add more values to the same table later
  set_dotted_key_value(table, ["app", "author"], TomlString("Developer"))
  set_dotted_key_value(table, ["app", "license"], TomlString("MIT"))
  json_inspect(table, content={
    "app": [
      "TomlTable",
      {
        "name": ["TomlString", "MyApp"],
        "version": ["TomlString", "1.0.0"],
        "author": ["TomlString", "Developer"],
        "license": ["TomlString", "MIT"],
      },
    ],
  })
}

///|
test "set dotted key value - conflict with non-table value" {
  let table : Map[String, TomlValue] = {}

  // Set a string value at "config"
  set_dotted_key_value(table, ["config"], TomlString("simple value"))

  // Try to treat "config" as a table - this should raise an error
  try
    set_dotted_key_value(table, ["config", "nested"], TomlString("value"))
  catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|ExpectedTable("config", TomlString("simple value"))
        ),
      )
  } noraise {
    _ => fail("Expected error but got success")
  }
}

///|
test "set dotted key value - mixed types in path" {
  // Test with different value types at different levels
  let table : Map[String, TomlValue] = Map::new()
  set_dotted_key_value(
    table,
    ["root", "array"],
    TomlArray([TomlInteger(1), TomlInteger(2), TomlInteger(3)]),
  )
  set_dotted_key_value(table, ["root", "float"], TomlFloat(3.14))
  set_dotted_key_value(table, ["root", "nested", "bool"], TomlBoolean(false))
  set_dotted_key_value(
    table,
    ["root", "nested", "datetime"],
    TomlDateTime(@tokenize.TomlDateTime::OffsetDateTime("2024-01-01T12:00:00Z")),
  )
  json_inspect(table, content={
    "root": [
      "TomlTable",
      {
        "array": [
          "TomlArray",
          [["TomlInteger", "1"], ["TomlInteger", "2"], ["TomlInteger", "3"]],
        ],
        "float": ["TomlFloat", 3.14],
        "nested": [
          "TomlTable",
          {
            "bool": ["TomlBoolean", false],
            "datetime": [
              "TomlDateTime",
              ["OffsetDateTime", "2024-01-01T12:00:00Z"],
            ],
          },
        ],
      },
    ],
  })
}

///|
#skip("empty path edge case to fix later")
test "set dotted key value - empty path edge case" {
  // Test with empty path (edge case)
  let table : Map[String, TomlValue] = Map::new()

  // Set a value first
  set_dotted_key_value(table, ["key"], TomlString("value"))

  // Try with empty path - currently does nothing
  set_dotted_key_value(table, [], TomlString("should not appear"))

  // Table should only have the first key
  json_inspect(table, content={ "key": ["TomlString", "value"] })
}
