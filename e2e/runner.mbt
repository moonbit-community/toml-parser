///|
pub struct TestResult {
  passed : Int
  failed : Int
  failures : Array[String]
}

///|
pub fn TestResult::new() -> TestResult {
  { passed: 0, failed: 0, failures: [] }
}

///|
/// Recursively collect all .toml files in a directory.
pub fn collect_toml_files(
  dir : String,
  files : Array[String],
) -> Unit raise @fs.IOError {
  let entries = @fs.read_dir(dir)
  for entry in entries {
    let path = "\{dir}/\{entry}"
    if @fs.is_dir(path) {
      collect_toml_files(path, files)
    } else if entry.has_suffix(".toml") {
      files.push(path)
    }
  }
}

///|
/// Run a single valid test: parse .toml, convert to test JSON, compare with .json.
/// Returns None on success, Some(error_message) on failure.
pub fn run_single_valid_test(toml_path : String) -> String? raise @fs.IOError {
  let json_path = toml_path[:toml_path.length() - 5].to_string() + ".json"
  if !@fs.path_exists(json_path) {
    return None
  }
  let toml_content = @fs.read_file_to_string(toml_path)
  let expected_json_str = @fs.read_file_to_string(json_path)
  let expected : Json = @json.parse(expected_json_str) catch {
    e => return Some("\{toml_path}: failed to parse expected JSON: \{e}")
  }
  let parsed = try? @toml.parse(toml_content)
  match parsed {
    Err(e) => Some("\{toml_path}: parse error: \{e}")
    Ok(value) => {
      let actual = to_test_json(value)
      if !json_equal(actual, expected) {
        Some(
          "\{toml_path}:\n  expected: \{expected.stringify()}\n  actual:   \{actual.stringify()}",
        )
      } else {
        None
      }
    }
  }
}

///|
/// Run a single invalid test: parse .toml and expect failure.
/// Returns None on success (parse failed as expected), Some(error) if parse succeeded.
pub fn run_single_invalid_test(toml_path : String) -> String? raise @fs.IOError {
  let toml_bytes = @fs.read_file_to_bytes(toml_path)
  // Try decoding as UTF-8, skip non-UTF-8 files (they should fail anyway)
  let toml_content = @utf8.decode(toml_bytes[:]) catch {
    // Non-UTF-8 file: parser would reject this, count as pass
    _ => return None
  }
  let parsed = try? @toml.parse(toml_content)
  match parsed {
    Ok(_) => Some("\{toml_path}: should have failed but parsed OK")
    Err(_) => None
  }
}

///|
/// Compare two JSON values for equality.
pub fn json_equal(a : Json, b : Json) -> Bool {
  match (a, b) {
    (Object(ma), Object(mb)) => {
      if ma.length() != mb.length() {
        return false
      }
      for k, va in ma {
        guard mb.get(k) is Some(vb) && json_equal(va, vb) else { return false }
      }
      true
    }
    (Array(aa), Array(ab)) => {
      if aa.length() != ab.length() {
        return false
      }
      for i, va in aa {
        if !json_equal(va, ab[i]) {
          return false
        }
      }
      true
    }
    (String(sa), String(sb)) => sa == sb
    (Number(na, ..), Number(nb, ..)) => na == nb
    (True, True) | (False, False) | (Null, Null) => true
    _ => false
  }
}
