///|
let version : String = "0.2.3"

///|
fn toml_command() -> @argparse.Command {
  @argparse.Command(
    "toml",
    about="Parse, validate, and format TOML files.",
    version~,
    arg_required_else_help=true,
    positionals=[
      @argparse.PositionArg(
        "file",
        about="Parse TOML and print normalized TOML.",
      ),
    ],
    subcommands=[
      @argparse.Command(
        "format",
        about="Parse TOML and print normalized TOML.",
        positionals=[
          @argparse.PositionArg(
            "file",
            about="TOML file to format.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
      ),
      @argparse.Command(
        "check",
        about="Validate TOML without printing parsed output.",
        positionals=[
          @argparse.PositionArg(
            "file",
            about="TOML file to validate.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
      ),
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
  let matches = @argparse.parse(toml_command(), argv=args, env={}) catch {
    err => {
      println(err)
      return 2
    }
  }
  match matches.subcommand {
    Some(("format", child)) => dispatch_file(child, format_file)
    Some(("check", child)) => dispatch_file(child, check_file)
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
