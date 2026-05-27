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
toml 0.2.3
```

```mooncram
$ "$TOML_CLI" --help
toml 0.2.3

Usage:
  toml format <file>
  toml check <file>
  toml <file>

Commands:
  format <file>  Parse TOML and print normalized TOML.
  check <file>   Validate TOML without printing parsed output.

Options:
  -h, --help     Show this help.
  --version      Show the CLI version.
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
