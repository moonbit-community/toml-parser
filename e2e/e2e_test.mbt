///|
async test "valid toml-test suite" {
  let files : Array[String] = []
  collect_toml_files("e2e/testdata/valid", files)
  files.sort()
  let mut passed = 0
  let mut failed = 0
  let failures : Array[String] = []
  for toml_path in files {
    let json_path = toml_path[:toml_path.length() - 5].to_string() + ".json"
    if !@fs.path_exists(json_path) {
      continue
    }
    let toml_content = @fs.read_file_to_string(toml_path)
    let expected_json_str = @fs.read_file_to_string(json_path)
    let expected : Json = @json.parse(expected_json_str) catch {
      e => {
        failures.push("[JSON-ERROR] \{toml_path}: \{e}")
        failed += 1
        continue
      }
    }
    let parsed = try? @toml.parse(toml_content)
    match parsed {
      Err(e) => {
        failures.push("[PARSE-ERROR] \{toml_path}: \{e}")
        failed += 1
      }
      Ok(value) => {
        let actual = to_test_json(value)
        if !json_equal(actual, expected) {
          failures.push(
            "[MISMATCH] \{toml_path}\n    expected: \{expected.stringify()}\n    actual:   \{actual.stringify()}",
          )
          failed += 1
        } else {
          passed += 1
        }
      }
    }
  }
  println(
    "\{passed} passed, \{failed} failed out of \{passed + failed} valid tests",
  )
  if failed > 0 {
    let msg = StringBuilder::new()
    msg.write_string("\{failed} of \{passed + failed} valid tests failed:\n")
    for f in failures {
      msg.write_string("  \{f}\n")
    }
    let msg = msg.to_string()
    println(msg)
    @fs.write_string_to_file("e2e/_valid_failures.txt", msg)
  }
}

///|
async test "invalid toml-test suite" {
  let files : Array[String] = []
  collect_toml_files("e2e/testdata/invalid", files)
  files.sort()
  let mut passed = 0
  let mut failed = 0
  let failures : Array[String] = []
  for toml_path in files {
    match run_single_invalid_test(toml_path) {
      None => passed += 1
      Some(msg) => {
        failures.push(msg)
        failed += 1
      }
    }
  }
  println(
    "\{passed} passed, \{failed} failed out of \{passed + failed} invalid tests",
  )
  if failed > 0 {
    let msg = StringBuilder::new()
    msg.write_string("\{failed} of \{passed + failed} invalid tests failed:\n")
    for f in failures {
      msg.write_string("  \{f}\n")
    }
    let msg = msg.to_string()
    println(msg)
    @fs.write_string_to_file("e2e/_invalid_failures.txt", msg)
  }
}
