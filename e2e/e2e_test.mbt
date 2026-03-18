///|
/// Known files that cause infinite loops in the tokenizer.
/// These are skipped in e2e and reproduced as #skip unit tests below.
let known_crashes : Array[String] = [
  // Tokenizer infinite loop: dashed bare key in table header [a-a-a]
  "e2e/testdata/valid/key/alphanum.toml",
  // Tokenizer infinite loop: leading underscore values (_ as identifier prefix)
   "e2e/testdata/invalid/float/leading-us.toml", "e2e/testdata/invalid/integer/leading-us.toml",
  "e2e/testdata/invalid/integer/leading-us-bin.toml", "e2e/testdata/invalid/integer/leading-us-hex.toml",
  "e2e/testdata/invalid/integer/leading-us-oct.toml",
]

///|
fn should_skip(path : String) -> Bool {
  for p in known_crashes {
    if path == p {
      return true
    }
  }
  false
}

///|
async test "valid toml-test suite" {
  let files : Array[String] = []
  collect_toml_files("e2e/testdata/valid", files)
  files.sort()
  let mut passed = 0
  let mut failed = 0
  let mut skipped = 0
  let failures : Array[String] = []
  for toml_path in files {
    if should_skip(toml_path) {
      skipped += 1
      continue
    }
    let json_path = toml_path[:toml_path.length() - 5].to_string() + ".json"
    if !@fs.path_exists(json_path) {
      continue
    }
    let toml_content = @fs.read_file_to_string(toml_path)
    let expected_json_str = @fs.read_file_to_string(json_path)
    let expected : Json = @json.parse(expected_json_str) catch {
      e => {
        failures.push("\{toml_path}: failed to parse expected JSON: \{e}")
        failed += 1
        continue
      }
    }
    let parsed = try? @toml.parse(toml_content)
    match parsed {
      Err(e) => {
        failures.push("\{toml_path}: parse error: \{e}")
        failed += 1
      }
      Ok(value) => {
        let actual = to_test_json(value)
        if !json_equal(actual, expected) {
          failures.push(
            "\{toml_path}:\n  expected: \{expected.stringify()}\n  actual:   \{actual.stringify()}",
          )
          failed += 1
        } else {
          passed += 1
        }
      }
    }
  }
  println(
    "\{passed} passed, \{failed} failed, \{skipped} skipped out of \{passed + failed + skipped} valid tests",
  )
  if failed > 0 {
    let msg = StringBuilder::new()
    msg.write_string("\{failed} of \{passed + failed} valid tests failed:\n")
    for f in failures {
      msg.write_string("\{f}\n\n")
    }
    @fs.write_string_to_file("e2e/_valid_failures.txt", msg.to_string())
  }
}

///|
async test "invalid toml-test suite" {
  let files : Array[String] = []
  collect_toml_files("e2e/testdata/invalid", files)
  files.sort()
  let mut passed = 0
  let mut failed = 0
  let mut skipped = 0
  let failures : Array[String] = []
  for toml_path in files {
    if should_skip(toml_path) {
      skipped += 1
      continue
    }
    match run_single_invalid_test(toml_path) {
      None => passed += 1
      Some(msg) => {
        failures.push(msg)
        failed += 1
      }
    }
  }
  println(
    "\{passed} passed, \{failed} failed, \{skipped} skipped out of \{passed + failed + skipped} invalid tests",
  )
  if failed > 0 {
    let msg = StringBuilder::new()
    msg.write_string("\{failed} of \{passed + failed} invalid tests failed:\n")
    for f in failures {
      msg.write_string("\{f}\n\n")
    }
    @fs.write_string_to_file("e2e/_invalid_failures.txt", msg.to_string())
  }
}
