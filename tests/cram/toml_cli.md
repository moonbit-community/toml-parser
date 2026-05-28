# TOML CLI Cram Tests

These Moon Cram tests document the native `toml` executable. Set `TOML_CLI` to
the native release binary before running them:

```bash
moon build --target native --release
TOML_CLI="$PWD/_build/native/release/build/bobzhang/toml/cmd/main/main.exe" moon cram test tests/cram
```

## Help And Version

```mooncram
$ "$TOML_CLI" --version
0.2.3
```

```mooncram
$ "$TOML_CLI" --help
Usage: toml [file] [command]

Parse, validate, and format TOML files.

Commands:
  format  Parse TOML and print normalized TOML.
  check   Validate TOML without printing parsed output.
  help    Print help for the subcommand(s).

Arguments:
  file  Parse TOML and print normalized TOML.

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

```mooncram
$ "$TOML_CLI"
Usage: toml [file] [command]

Parse, validate, and format TOML files.

Commands:
  format  Parse TOML and print normalized TOML.
  check   Validate TOML without printing parsed output.
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
> "$TOML_CLI" format sample.toml
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
> "$TOML_CLI" check valid.toml
valid.toml: OK
```

## Report Parse Errors

```mooncram
$ cat > invalid.toml <<'EOF'
> key =
> EOF
> "$TOML_CLI" check invalid.toml
error: failed to parse invalid.toml: Failure(parser.mbt:*@bobzhang/toml FAILED: Expected value at { start: { line: 1, column: 6 }, end: { line: 2, column: 1 } }) (glob)
[1]
```
