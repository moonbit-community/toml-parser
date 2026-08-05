///|
/// Convert a parsed TOML document to a plain JSON value: tables become
/// objects, arrays stay arrays, and datetimes become their TOML string
/// form. Integers keep their exact 64-bit decimal representation, and
/// non-finite floats become the strings "nan"/"inf"/"-inf" since JSON
/// cannot represent them as numbers.
fn to_json(value : @toml_lib.TomlValue) -> Json {
  match value {
    TomlString(s) => Json::string(s)
    TomlInteger(i) => Json::number(i.to_double(), repr=i.to_string())
    TomlFloat(f) =>
      if f.is_nan() {
        Json::string("nan")
      } else if f.is_inf() {
        Json::string(if f < 0.0 { "-inf" } else { "inf" })
      } else {
        Json::number(f)
      }
    TomlBoolean(b) => Json::boolean(b)
    TomlDateTime(_) => {
      let (_, s) = value.datetime_info().unwrap()
      Json::string(s)
    }
    TomlArray(arr) => Json::array([ for v in arr => to_json(v) ])
    TomlTable(table) =>
      Json::object(Map::from_array([ for k, v in table => (k, to_json(v)) ]))
  }
}

///|
fn tojson_file(path : String) -> Int {
  let source = @fs.read_file_to_string(path) catch {
    err => {
      println("error: failed to read \{path}: \{err}")
      return 1
    }
  }
  let value = @toml_lib.parse(source) catch {
    err => {
      println("error: failed to parse \{path}: \{err}")
      return 1
    }
  }
  println(to_json(value).stringify(indent=2))
  0
}
