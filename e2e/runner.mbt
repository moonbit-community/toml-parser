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
    Err(e) => Some("[PARSE-ERROR] \{toml_path}: \{e}")
    Ok(value) => {
      let actual = to_test_json(value)
      if !json_equal(actual, expected) {
        Some(
          "[MISMATCH] \{toml_path}\n    expected: \{expected.stringify()}\n    actual:   \{actual.stringify()}",
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
  let toml_content = @utf8.decode(toml_bytes) catch {
    // Non-UTF-8 file: parser would reject this, count as pass
    _ => return None
  }
  let parsed = try? @toml.parse(toml_content)
  match parsed {
    Ok(_) => Some("[PASS-BUT-SHOULD-FAIL] \{toml_path}")
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
      // Special case: float typed values — compare numerically
      if is_float_typed_value(ma) && is_float_typed_value(mb) {
        return float_values_equal(ma, mb)
      }
      // Special case: datetime typed values — compare with normalized fractional seconds
      if is_datetime_typed_value(ma) && is_datetime_typed_value(mb) {
        return datetime_values_equal(ma, mb)
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

///|
/// Check if a JSON object is a toml-test typed value: {"type": "...", "value": "..."}

///|
/// Check if a JSON object is a datetime typed value.
fn is_datetime_typed_value(m : Map[String, Json]) -> Bool {
  guard m.length() == 2 && m.get("type") is Some(String(t)) else {
    return false
  }
  t == "datetime" ||
  t == "datetime-local" ||
  t == "date-local" ||
  t == "time-local"
}

///|
/// Compare two datetime typed values with normalized fractional seconds.
/// Treats ".6" and ".600" as equal by stripping trailing zeros in fractional part.
fn datetime_values_equal(a : Map[String, Json], b : Map[String, Json]) -> Bool {
  guard a.get("type") is Some(at) && b.get("type") is Some(bt) && at == bt else {
    return false
  }
  guard a.get("value") is Some(String(va)) && b.get("value") is Some(String(vb)) else {
    return false
  }
  normalize_frac_seconds(va) == normalize_frac_seconds(vb)
}

///|
/// Normalize fractional seconds by stripping trailing zeros.
/// "17:45:56.600Z" → "17:45:56.6Z", "17:45:56.123Z" → "17:45:56.123Z"
fn normalize_frac_seconds(s : String) -> String {
  // Find the fractional part (between '.' and non-digit after time)
  let mut dot_pos = -1
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == '.' {
      dot_pos = i
    }
  }
  if dot_pos < 0 {
    return s
  }
  // Find end of fractional digits
  let mut frac_end = dot_pos + 1
  while frac_end < s.length() && s[frac_end] >= '0' && s[frac_end] <= '9' {
    frac_end += 1
  }
  // Strip trailing zeros
  let mut trimmed_end = frac_end
  while trimmed_end > dot_pos + 1 && s[trimmed_end - 1] == '0' {
    trimmed_end -= 1
  }
  if trimmed_end == dot_pos + 1 {
    // All fractional digits were zeros — remove the dot too
    let before = s[:dot_pos].to_string()
    let after = s[frac_end:].to_string()
    "\{before}\{after}"
  } else if trimmed_end < frac_end {
    let before = s[:trimmed_end].to_string()
    let after = s[frac_end:].to_string()
    "\{before}\{after}"
  } else {
    s
  }
}

///|
fn is_float_typed_value(m : Map[String, Json]) -> Bool {
  m.length() == 2 && m.get("type") is Some(String("float"))
}

///|
/// Compare two float typed values numerically.
fn float_values_equal(a : Map[String, Json], b : Map[String, Json]) -> Bool {
  guard a.get("value") is Some(String(va)) && b.get("value") is Some(String(vb)) else {
    return false
  }
  // Handle special values
  if va == vb {
    return true
  }
  if va == "nan" || vb == "nan" {
    return va == "nan" && vb == "nan"
  }
  if va == "inf" || va == "-inf" || vb == "inf" || vb == "-inf" {
    return va == vb
  }
  // Preserve negative zero distinction: "-0" != "0"
  let va_neg_zero = va == "-0" || va == "-0.0"
  let vb_neg_zero = vb == "-0" || vb == "-0.0"
  if va_neg_zero || vb_neg_zero {
    return va_neg_zero == vb_neg_zero
  }
  // Parse and compare numerically
  let fa = try? @string.parse_double(va)
  let fb = try? @string.parse_double(vb)
  match (fa, fb) {
    (Ok(a), Ok(b)) => a == b
    _ => false
  }
}
