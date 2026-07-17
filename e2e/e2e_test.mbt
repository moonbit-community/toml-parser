///|
async test "valid toml-test suite" {
  let files : Array[String] = []
  @e2e.collect_toml_files("testdata/valid", files)
  files.sort()
  let mut passed = 0
  let mut failed = 0
  let failures : Array[String] = []
  for toml_path in files {
    let json_path = "\{toml_path[:toml_path.length() - 5]}.json"
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
    let parsed = try @toml.parse(toml_content) catch {
      err => Err(err)
    } noraise {
      value => Ok(value)
    }
    match parsed {
      Err(e) => {
        failures.push("[PARSE-ERROR] \{toml_path}: \{e}")
        failed += 1
      }
      Ok(value) => {
        let actual = @e2e.to_test_json(value)
        if !@e2e.json_equal(actual, expected) {
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
  guard passed + failed > 0 else {
    fail(
      "valid corpus is empty — no .toml/.json pairs found under testdata/valid",
    )
  }
  if failed > 0 {
    let msg = StringBuilder()
    msg <+ "\{failed} of \{passed + failed} valid tests failed:\n"
    for f in failures {
      msg <+ "  \{f}\n"
    }
    fail("valid toml-test suite:\n\{msg}")
  }
}

///|
/// Invalid-suite fixtures this parser intentionally accepts.
///
/// The corpus encodes TOML 1.0 restrictions; this parser targets TOML 1.1,
/// which relaxes them, so accepting these inputs is correct behaviour rather
/// than a conformance bug.
///
/// The suite compares the failing set against this list *exactly*: a new
/// failure is a regression, and an entry that stops failing is a stale
/// exemption. Both fail the test, so the list cannot silently rot.
let known_toml11_diffs : Array[String] = [
  // Seconds are optional in a time.
  "testdata/invalid/datetime/no-secs.toml", "testdata/invalid/local-datetime/no-secs.toml",
  "testdata/invalid/local-time/no-secs.toml",
  // Newlines are allowed inside inline tables.
   "testdata/invalid/inline-table/linebreak-01.toml", "testdata/invalid/inline-table/linebreak-02.toml",
  "testdata/invalid/inline-table/linebreak-03.toml", "testdata/invalid/inline-table/linebreak-04.toml",
  // A trailing comma is allowed in an inline table.
   "testdata/invalid/inline-table/trailing-comma.toml",
  // `\xHH` hex escapes are allowed.
   "testdata/invalid/string/basic-byte-escapes.toml",
]

///|
async test "invalid toml-test suite" {
  let files : Array[String] = []
  @e2e.collect_toml_files("testdata/invalid", files)
  files.sort()
  guard files.length() > 0 else {
    fail("invalid corpus is empty — testdata/invalid did not resolve")
  }
  let mut passed = 0
  let accepted : Array[String] = []
  for toml_path in files {
    match @e2e.run_single_invalid_test(toml_path) {
      None => passed += 1
      Some(_) => accepted.push(toml_path)
    }
  }
  println(
    "\{passed} passed, \{accepted.length()} failed out of \{files.length()} invalid tests",
  )
  let regressions = accepted.filter(p => !known_toml11_diffs.contains(p))
  let stale = known_toml11_diffs.filter(p => !accepted.contains(p))
  if regressions.length() > 0 || stale.length() > 0 {
    let msg = StringBuilder()
    for p in regressions {
      msg <+ "  [REGRESSION] accepted an invalid document: \{p}\n"
    }
    for p in stale {
      msg <+
        "  [STALE-EXEMPTION] now rejected correctly, drop from known_toml11_diffs: \{p}\n"
    }
    fail("invalid toml-test suite:\n\{msg}")
  }
}
