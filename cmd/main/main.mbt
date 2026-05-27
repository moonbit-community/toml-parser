///|
let version : String = "0.2.3"

///|
let usage : String =
  #|toml 0.2.3
  #|
  #|Usage:
  #|  toml format <file>
  #|  toml check <file>
  #|  toml <file>
  #|
  #|Commands:
  #|  format <file>  Parse TOML and print normalized TOML.
  #|  check <file>   Validate TOML without printing parsed output.
  #|
  #|Options:
  #|  -h, --help     Show this help.
  #|  --version      Show the CLI version.

///|
fn main {
  let code = run(@env.args()[1:])
  if code != 0 {
    @sys.exit(code)
  }
}

///|
fn run(args : ArrayView[String]) -> Int {
  match args {
    [] | ["help"] | ["-h"] | ["--help"] => {
      println(usage)
      0
    }
    ["--version"] | ["version"] => {
      println("toml \{version}")
      0
    }
    ["format"] => usage_error("missing file for `format`")
    ["check"] => usage_error("missing file for `check`")
    ["format", path] | [path] => format_file(path)
    ["check", path] => check_file(path)
    [command, ..] =>
      usage_error("unknown command or extra arguments: `\{command}`")
  }
}

///|
fn format_file(path : String) -> Int {
  let source = @fs.read_file_to_string(path) catch {
    err => {
      println("error: failed to read \{path}: \{err}")
      return 1
    }
  }
  let value = @toml.parse(source) catch {
    err => {
      println("error: failed to parse \{path}: \{err}")
      return 1
    }
  }
  println(value.to_string())
  0
}

///|
fn check_file(path : String) -> Int {
  let source = @fs.read_file_to_string(path) catch {
    err => {
      println("error: failed to read \{path}: \{err}")
      return 1
    }
  }
  let _ = @toml.parse(source) catch {
    err => {
      println("error: failed to parse \{path}: \{err}")
      return 1
    }
  }
  println("\{path}: OK")
  0
}

///|
fn usage_error(message : String) -> Int {
  println("error: \{message}")
  println("")
  println(usage)
  2
}
