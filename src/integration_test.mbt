///| Integration tests for complex TOML structures

///| Test comprehensive TOML document with all features
test "integration complex toml document" {
  let complex_toml = "title = \"TOML Example\"\n\n[owner]\nname = \"Tom Preston-Werner\"\ndob = \"1979-05-27T00:32:00Z\"\n\n[database]\nserver = \"192.168.1.1\"\nports = [8001, 8001, 8002]\nconnection_max = 5000\nenabled = true\n\n[servers]\nalpha = {ip = \"10.0.0.1\", dc = \"eqdc10\"}\nbeta = {ip = \"10.0.0.2\", dc = \"eqdc10\"}"
  let result = @toml.parse(complex_toml)
  match result {
    @toml.TomlTable(table) => {
      // Check title
      match table.get("title") {
        Some(@toml.TomlString(title)) => inspect(title, content="TOML Example")
        _ => fail("Expected title to be a string")
      }

      // Check owner table
      match table.get("owner") {
        Some(@toml.TomlTable(owner)) =>
          match owner.get("name") {
            Some(@toml.TomlString(name)) =>
              inspect(name, content="Tom Preston-Werner")
            _ => fail("Expected owner name to be a string")
          }
        _ => fail("Expected owner to be a table")
      }

      // Check database table
      match table.get("database") {
        Some(@toml.TomlTable(db)) => {
          match db.get("enabled") {
            Some(@toml.TomlBoolean(enabled)) => inspect(enabled, content="true")
            _ => fail("Expected enabled to be a boolean")
          }
          match db.get("ports") {
            Some(@toml.TomlArray(ports)) => inspect(ports.length(), content="3")
            _ => fail("Expected ports to be an array")
          }
        }
        _ => fail("Expected database to be a table")
      }

      // Check servers table
      match table.get("servers") {
        Some(@toml.TomlTable(servers)) => {
          inspect(servers.contains("alpha"), content="true")
          inspect(servers.contains("beta"), content="true")
        }
        _ => fail("Expected servers to be a table")
      }
    }
    _ => fail("Expected result to be a table")
  }
}

///| Test array of tables simulation using nested structures
test "integration array of tables simulation" {
  // let products_toml = "[[products]]\nname = \"Hammer\"\nsku = 738594937\n\n[[products]]\nname = \"Nail\"\nsku = 284758393\ncolor = \"gray\""

  // Since we don't support array of tables syntax yet, let's test with inline tables
  let products_inline = "products = [{name = \"Hammer\", sku = 738594937}, {name = \"Nail\", sku = 284758393, color = \"gray\"}]"
  let result = @toml.parse(products_inline)
  match result {
    @toml.TomlTable(table) =>
      match table.get("products") {
        Some(@toml.TomlArray(products)) => {
          inspect(products.length(), content="2")
          match products[0] {
            @toml.TomlTable(product1) =>
              match product1.get("name") {
                Some(@toml.TomlString(name)) => inspect(name, content="Hammer")
                _ => fail("Expected product name to be a string")
              }
            _ => fail("Expected first product to be a table")
          }
        }
        _ => fail("Expected products to be an array")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test mixed data types in complex structure
test "integration mixed data types" {
  let mixed_toml = "config = {string_val = \"text\", int_val = 42, float_val = 3.14, bool_val = true, array_val = [1, 2, 3], nested = {inner = \"value\"}}"
  let result = @toml.parse(mixed_toml)
  match result {
    @toml.TomlTable(table) =>
      match table.get("config") {
        Some(@toml.TomlTable(config)) => {
          // Check all data types
          match config.get("string_val") {
            Some(@toml.TomlString(s)) => inspect(s, content="text")
            _ => fail("Expected string_val to be a string")
          }
          match config.get("int_val") {
            Some(@toml.TomlInteger(i)) => inspect(i, content="42")
            _ => fail("Expected int_val to be an integer")
          }
          match config.get("float_val") {
            Some(@toml.TomlFloat(f)) => inspect(f, content="3.14")
            _ => fail("Expected float_val to be a float")
          }
          match config.get("bool_val") {
            Some(@toml.TomlBoolean(b)) => inspect(b, content="true")
            _ => fail("Expected bool_val to be a boolean")
          }
          match config.get("array_val") {
            Some(@toml.TomlArray(arr)) => inspect(arr.length(), content="3")
            _ => fail("Expected array_val to be an array")
          }
          match config.get("nested") {
            Some(@toml.TomlTable(nested)) =>
              match nested.get("inner") {
                Some(@toml.TomlString(inner)) => inspect(inner, content="value")
                _ => fail("Expected inner to be a string")
              }
            _ => fail("Expected nested to be a table")
          }
        }
        _ => fail("Expected config to be a table")
      }
    _ => fail("Expected result to be a table")
  }
}

///| Test configuration file simulation
test "integration configuration file simulation" {
  let config_toml = "# Application configuration\n\n[app]\nname = \"MyApp\"\nversion = \"1.0.0\"\ndebug = false\n\n[database]\nhost = \"localhost\"\nport = 5432\nname = \"myapp_db\"\nuser = \"admin\"\npassword = \"secret123\"\nssl = true\n\n[redis]\nhost = \"127.0.0.1\"\nport = 6379\ndb = 0\n\n[logging]\nlevel = \"info\"\nfile = \"/var/log/myapp.log\"\nmax_size = 10485760"
  let result = @toml.parse(config_toml)
  match result {
    @toml.TomlTable(table) => {
      // Verify all sections exist
      inspect(table.contains("app"), content="true")
      inspect(table.contains("database"), content="true")
      inspect(table.contains("redis"), content="true")
      inspect(table.contains("logging"), content="true")

      // Verify app section
      match table.get("app") {
        Some(@toml.TomlTable(app)) =>
          match app.get("debug") {
            Some(@toml.TomlBoolean(debug)) => inspect(debug, content="false")
            _ => fail("Expected debug to be a boolean")
          }
        _ => fail("Expected app to be a table")
      }

      // Verify database section
      match table.get("database") {
        Some(@toml.TomlTable(db)) => {
          match db.get("port") {
            Some(@toml.TomlInteger(port)) => inspect(port, content="5432")
            _ => fail("Expected port to be an integer")
          }
          match db.get("ssl") {
            Some(@toml.TomlBoolean(ssl)) => inspect(ssl, content="true")
            _ => fail("Expected ssl to be a boolean")
          }
        }
        _ => fail("Expected database to be a table")
      }

      // Verify logging section
      match table.get("logging") {
        Some(@toml.TomlTable(logging)) =>
          match logging.get("max_size") {
            Some(@toml.TomlInteger(size)) => inspect(size, content="10485760")
            _ => fail("Expected max_size to be an integer")
          }
        _ => fail("Expected logging to be a table")
      }
    }
    _ => fail("Expected result to be a table")
  }
}

///| Test server configuration with arrays and nested tables
test "integration server configuration" {
  let server_config = "name = \"web-server\"\n\n[server]\nhost = \"0.0.0.0\"\nport = 8080\nworkers = 4\ntls = {enabled = true, cert_file = \"/etc/ssl/server.crt\", key_file = \"/etc/ssl/server.key\"}\n\n[middleware]\ncors = {enabled = true, origins = [\"http://localhost:3000\", \"https://example.com\"]}\nauth = {type = \"jwt\", secret = \"super-secret-key\"}\n\n[database]\nconnections = [{host = \"db1.example.com\", port = 5432}, {host = \"db2.example.com\", port = 5432}]"
  let result = @toml.parse(server_config)
  match result {
    @toml.TomlTable(table) => {
      // Check main server config
      match table.get("server") {
        Some(@toml.TomlTable(server)) => {
          match server.get("port") {
            Some(@toml.TomlInteger(port)) => inspect(port, content="8080")
            _ => fail("Expected port to be an integer")
          }

          // Check nested TLS config
          match server.get("tls") {
            Some(@toml.TomlTable(tls)) =>
              match tls.get("enabled") {
                Some(@toml.TomlBoolean(enabled)) =>
                  inspect(enabled, content="true")
                _ => fail("Expected TLS enabled to be a boolean")
              }
            _ => fail("Expected tls to be a table")
          }
        }
        _ => fail("Expected server to be a table")
      }

      // Check middleware config
      match table.get("middleware") {
        Some(@toml.TomlTable(middleware)) =>
          match middleware.get("cors") {
            Some(@toml.TomlTable(cors)) =>
              match cors.get("origins") {
                Some(@toml.TomlArray(origins)) =>
                  inspect(origins.length(), content="2")
                _ => fail("Expected origins to be an array")
              }
            _ => fail("Expected cors to be a table")
          }
        _ => fail("Expected middleware to be a table")
      }

      // Check database connections array
      match table.get("database") {
        Some(@toml.TomlTable(db)) =>
          match db.get("connections") {
            Some(@toml.TomlArray(connections)) => {
              inspect(connections.length(), content="2")
              match connections[0] {
                @toml.TomlTable(conn1) =>
                  match conn1.get("host") {
                    Some(@toml.TomlString(host)) =>
                      inspect(host, content="db1.example.com")
                    _ => fail("Expected host to be a string")
                  }
                _ => fail("Expected connection to be a table")
              }
            }
            _ => fail("Expected connections to be an array")
          }
        _ => fail("Expected database to be a table")
      }
    }
    _ => fail("Expected result to be a table")
  }
}

///| Test validation of complex structures
test "integration complex structure validation" {
  // Create a complex valid structure
  let main_table : Map[String, @toml.TomlValue] = Map::new()

  // Add string array
  let string_array = Array::new()
  string_array.push(@toml.TomlString("item1"))
  string_array.push(@toml.TomlString("item2"))
  main_table["strings"] = @toml.TomlArray(string_array)

  // Add nested table with arrays
  let nested_table : Map[String, @toml.TomlValue] = Map::new()
  let int_array = Array::new()
  int_array.push(@toml.TomlInteger(1L))
  int_array.push(@toml.TomlInteger(2L))
  nested_table["numbers"] = @toml.TomlArray(int_array)
  let float_array = Array::new()
  float_array.push(@toml.TomlFloat(1.5))
  float_array.push(@toml.TomlFloat(2.5))
  nested_table["floats"] = @toml.TomlArray(float_array)
  main_table["nested"] = @toml.TomlTable(nested_table)
  let complex_value = @toml.TomlTable(main_table)

  // This should be valid
  inspect(complex_value.validate(), content="true")

  // Now create an invalid structure
  let invalid_table : Map[String, @toml.TomlValue] = Map::new()
  let mixed_array = Array::new()
  mixed_array.push(@toml.TomlString("string"))
  mixed_array.push(@toml.TomlInteger(42L)) // Mixed types
  invalid_table["mixed"] = @toml.TomlArray(mixed_array)
  let invalid_value = @toml.TomlTable(invalid_table)

  // This should be invalid
  inspect(invalid_value.validate(), content="false")
}

///| Test edge cases in complex parsing
test "integration complex parsing edge cases" {
  // Test with extensive whitespace and comments
  let complex_with_whitespace = "# Main config\n\n  # App section  \n  [  app  ]  \n  name  =  \"MyApp\"  \n  \n  # Database section\n  [  database  ]\n  host  =  \"localhost\"\n  port  =  5432\n  \n  # Array with trailing comma and whitespace\n  servers  =  [\n    \"server1\"  ,\n    \"server2\"  ,\n    \"server3\"  ,  # trailing comma\n  ]\n"
  let result = @toml.parse(complex_with_whitespace)
  match result {
    @toml.TomlTable(table) => {
      // Should parse correctly despite formatting
      match table.get("app") {
        Some(@toml.TomlTable(app)) =>
          match app.get("name") {
            Some(@toml.TomlString(name)) => inspect(name, content="MyApp")
            _ => fail("Expected name to be a string")
          }
        _ => fail("Expected app to be a table")
      }
      match table.get("database") {
        Some(@toml.TomlTable(db)) => {
          match db.get("port") {
            Some(@toml.TomlInteger(port)) => inspect(port, content="5432")
            _ => fail("Expected port to be an integer")
          }
          match db.get("servers") {
            Some(@toml.TomlArray(servers)) =>
              inspect(servers.length(), content="3")
            _ => fail("Expected servers to be an array")
          }
        }
        _ => fail("Expected database to be a table")
      }
    }
    _ => fail("Expected result to be a table")
  }
}
