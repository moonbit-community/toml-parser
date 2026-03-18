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
    _ => typed_value("time-local", normalize_time_value(s))
  }
}

///|
/// Normalize datetime: uppercase T separator, Z suffix, and ensure seconds present.
fn normalize_datetime(s : String) -> String {
  let buf = StringBuilder::new()
  for c in s {
    match c {
      't' | ' ' => buf.write_char('T')
      'z' => buf.write_char('Z')
      _ => buf.write_char(c)
    }
  }
  normalize_time_seconds(buf.to_string())
}

///|
/// Normalize a time value to always include seconds (HH:MM → HH:MM:00).
fn normalize_time_value(s : String) -> String {
  // Count colons to check if seconds are present
  let mut colons = 0
  for c in s {
    if c == ':' {
      colons += 1
    }
  }
  if colons == 1 {
    // Only HH:MM, add :00
    s + ":00"
  } else {
    s
  }
}

///|
/// Ensure the time portion of a datetime string has seconds.
/// Handles formats like "1979-05-27T07:32Z" → "1979-05-27T07:32:00Z"
fn normalize_time_seconds(s : String) -> String {
  // Find the time portion (after T or at start for local time)
  let mut t_pos = -1
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == 'T' {
      t_pos = i
    }
  }
  // Count colons in the time portion, stopping at timezone indicator (+/- after time, or Z)
  let time_start = if t_pos >= 0 { t_pos + 1 } else { 0 }
  let mut colons = 0
  let mut first_colon = -1
  // Find end of time portion (before timezone)
  let mut time_end = s.length()
  for i = time_start; i < s.length(); i = i + 1 {
    let c = s[i]
    if c == 'Z' || ((c == '+' || c == '-') && i > time_start + 2) {
      time_end = i
      break
    }
  }
  for i = time_start; i < time_end; i = i + 1 {
    if s[i] == ':' {
      colons += 1
      if first_colon < 0 {
        first_colon = i
      }
    }
  }
  if colons == 1 {
    // HH:MM without seconds, insert :00 after MM (at time_end)
    let before = s[:time_end].to_string()
    let after = s[time_end:].to_string()
    "\{before}:00\{after}"
  } else {
    s
  }
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
