///|
/// Convert a TomlValue to the toml-test JSON format.
/// Leaf values become {"type": "...", "value": "..."}
/// Tables become plain JSON objects, arrays become JSON arrays.
pub fn to_test_json(value : @toml.TomlValue) -> Json {
  match value {
    @toml.TomlString(s) => typed_value("string", s)
    @toml.TomlInteger(i) => typed_value("integer", i.to_string())
    @toml.TomlFloat(f) => typed_value("float", format_test_float(f))
    @toml.TomlBoolean(b) =>
      typed_value("bool", if b { "true" } else { "false" })
    @toml.TomlDateTime(_) => datetime_to_test_json(value.to_json())
    @toml.TomlArray(arr) => Json::array(arr.map(to_test_json))
    @toml.TomlTable(table) => {
      let obj : Map[String, Json] = {}
      table.each(fn(k, v) { obj[k] = to_test_json(v) })
      Json::object(obj)
    }
  }
}

///|
fn typed_value(ty : String, value : String) -> Json {
  let obj : Map[String, Json] = {}
  obj["type"] = Json::string(ty)
  obj["value"] = Json::string(value)
  Json::object(obj)
}

///|
/// Extract datetime from derived ToJson format:
/// ["TomlDateTime", ["OffsetDateTime", "..."]]
fn datetime_to_test_json(json : Json) -> Json {
  // json is ["TomlDateTime", [variant, value_string]]
  guard json is Array([_, Array([String(variant), String(s)])]) else {
    abort("unexpected datetime JSON: \{json.stringify()}")
  }
  match variant {
    "OffsetDateTime" => typed_value("datetime", normalize_datetime(s))
    "LocalDateTime" => typed_value("datetime-local", normalize_datetime(s))
    "LocalDate" => typed_value("date-local", s)
    _ => typed_value("time-local", s)
  }
}

///|
/// Normalize datetime: uppercase T separator and Z suffix.
fn normalize_datetime(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      't' | ' ' => buf.write_char('T')
      'z' => buf.write_char('Z')
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Format float for toml-test comparison.
fn format_test_float(f : Double) -> String {
  if f.is_nan() {
    return "nan"
  }
  if f.is_inf() {
    return if f < 0.0 { "-inf" } else { "inf" }
  }
  // Handle -0.0
  if f == 0.0 && 1.0 / f < 0.0 {
    return "-0"
  }
  let s = f.to_string()
  // Remove trailing .0 for integer-like floats to match toml-test format
  if s.has_suffix(".0") {
    return s[:s.length() - 2].to_string()
  }
  s
}
