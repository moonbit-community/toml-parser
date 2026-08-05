# TOML CLI Cram Tests

These Moon Cram tests document the native `toml` executable. `moon cram` builds
the native CLI and puts `toml_cli.exe` on `PATH`:

```bash
moon cram test --release tests/cram
```

## Help And Version

```mooncram
$ toml_cli.exe --version
0.1.0
```

```mooncram
$ toml_cli.exe --help
Usage: toml_cli [file] [command]

Parse, validate, and format TOML files.

Run it from mooncakes.io without installing (the binary is fetched and
cached on first use; pin a version with bobzhang/toml_cli@<version>):

  moonx bobzhang/toml_cli check config.toml
  moonx bobzhang/toml_cli format config.toml
  moonx bobzhang/toml_cli tojson config.toml

Exit codes:
  0  success
  1  the file could not be read or is not valid TOML; a human-readable
     error with position information is printed to stdout
  2  usage error (unknown subcommand or missing file argument)

`format` prints the normalized document to stdout; it never rewrites the
input file. To format in place, redirect stdout to a temporary file and
move it over the original after checking the exit code.

Commands:
  format  Parse TOML and print normalized TOML.
  check   Validate TOML without printing parsed output.
  tojson  Parse TOML and print it as JSON.
  help    Print help for the subcommand(s).

Arguments:
  file  Parse TOML and print normalized TOML.

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

```mooncram
$ toml_cli.exe
Usage: toml_cli [file] [command]

Parse, validate, and format TOML files.

Run it from mooncakes.io without installing (the binary is fetched and
cached on first use; pin a version with bobzhang/toml_cli@<version>):

  moonx bobzhang/toml_cli check config.toml
  moonx bobzhang/toml_cli format config.toml
  moonx bobzhang/toml_cli tojson config.toml

Exit codes:
  0  success
  1  the file could not be read or is not valid TOML; a human-readable
     error with position information is printed to stdout
  2  usage error (unknown subcommand or missing file argument)

`format` prints the normalized document to stdout; it never rewrites the
input file. To format in place, redirect stdout to a temporary file and
move it over the original after checking the exit code.

Commands:
  format  Parse TOML and print normalized TOML.
  check   Validate TOML without printing parsed output.
  tojson  Parse TOML and print it as JSON.
  help    Print help for the subcommand(s).

Arguments:
  file  Parse TOML and print normalized TOML.

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

## Format A File

```mooncram
$ cat > sample.toml <<'EOF'
> title = "MoonBit"
> ports = [8000, 8001]
> [server]
> enabled = true
> EOF
> toml_cli.exe format sample.toml
title = "MoonBit"

ports = [8000, 8001]

[server]
enabled = true

```

## Check A File

```mooncram
$ cat > valid.toml <<'EOF'
> package = "toml"
> version = "0.2.3"
> EOF
> toml_cli.exe check valid.toml
valid.toml: OK
```

## Convert To JSON

Integers keep their exact 64-bit decimal representation (note `big` below
is 2^53 + 1, which a double cannot represent), and datetimes become their
TOML string form:

```mooncram
$ cat > convert.toml <<'EOF'
> title = "MoonBit"
> ports = [8000, 8001]
> pi = 3.14
> big = 9007199254740993
> date = 1979-05-27T07:32:00Z
> [server]
> enabled = true
> EOF
> toml_cli.exe tojson convert.toml
{
  "title": "MoonBit",
  "ports": [
    8000,
    8001
  ],
  "pi": 3.14,
  "big": 9007199254740993,
  "date": "1979-05-27T07:32:00Z",
  "server": {
    "enabled": true
  }
}
```

## Report Parse Errors

```mooncram
$ cat > invalid.toml <<'EOF'
> key =
> EOF
> toml_cli.exe check invalid.toml
error: failed to parse invalid.toml: Failure(parser.mbt:*@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 6 }, end: { line: 2, column: 1 } }) (glob)
[1]
```
