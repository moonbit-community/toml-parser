///|
let version : String = "0.2.0"

///|
let about : String =
  #|Parse, validate, and format TOML files.
  #|
  #|Run it from mooncakes.io without installing (the binary is fetched and
  #|cached on first use; pin a version with bobzhang/toml_cli@<version>):
  #|
  #|  moonx bobzhang/toml_cli check config.toml
  #|  moonx bobzhang/toml_cli format config.toml
  #|  moonx bobzhang/toml_cli tojson config.toml
  #|
  #|Exit codes:
  #|  0  success
  #|  1  the file could not be read or is not valid TOML; a human-readable
  #|     error with position information is printed to stdout
  #|  2  usage error (unknown subcommand or missing file argument)
  #|
  #|`format` prints the normalized document to stdout; it never rewrites the
  #|input file. To format in place, redirect stdout to a temporary file and
  #|move it over the original after checking the exit code.

///|
fn toml_command() -> @argparse.Command {
  Command(
    "toml_cli",
    about~,
    version~,
    arg_required_else_help=true,
    positionals=[
      PositionArg("file", about="Parse TOML and print normalized TOML."),
    ],
    subcommands=[
      Command("format", about="Parse TOML and print normalized TOML.", positionals=[
        PositionArg(
          "file",
          about="TOML file to format.",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      Command("check", about="Validate TOML without printing parsed output.", positionals=[
        PositionArg(
          "file",
          about="TOML file to validate.",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
      Command("tojson", about="Parse TOML and print it as JSON.", positionals=[
        PositionArg(
          "file",
          about="TOML file to convert.",
          num_args=@argparse.ValueRange::single(),
        ),
      ]),
    ],
  )
}

///|
fn main {
  let code = run(@env.args()[1:])
  if code != 0 {
    @sys.exit(code)
  }
}

///|
fn run(args : ArrayView[String]) -> Int {
  let matches = @argparse.parse(toml_command(), argv=args, env=Map([])) catch {
    err => {
      println(err)
      return 2
    }
  }
  match matches.subcommand {
    Some(("format", child)) => dispatch_file(child, format_file)
    Some(("check", child)) => dispatch_file(child, check_file)
    Some(("tojson", child)) => dispatch_file(child, tojson_file)
    Some((name, _)) => {
      println("error: unsupported command `\{name}`")
      2
    }
    None => dispatch_file(matches, format_file)
  }
}

///|
fn dispatch_file(matches : @argparse.Matches, action : (String) -> Int) -> Int {
  match matches.values.get("file") {
    Some([path]) => action(path)
    _ => 2
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
  let value = @toml_lib.parse(source) catch {
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
  let _ = @toml_lib.parse(source) catch {
    err => {
      println("error: failed to parse \{path}: \{err}")
      return 1
    }
  }
  println("\{path}: OK")
  0
}
