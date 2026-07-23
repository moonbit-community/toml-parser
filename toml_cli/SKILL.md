---
name: toml-cli
description: Validate and format TOML files using the bobzhang/toml_cli tool. Use when the user asks to check whether a TOML file is valid, normalize/format a TOML file, or debug TOML syntax errors.
---

# TOML CLI

`bobzhang/toml_cli` is a prebuilt WebAssembly CLI on mooncakes.io that parses,
validates, and formats TOML files. It requires the MoonBit toolchain (`moon`)
but no installation step — `moon runwasm` fetches and caches the binary on
first use.

## Commands

Validate a TOML file (prints `<file>: OK` or a parse error):

```bash
moon runwasm bobzhang/toml_cli -- check path/to/file.toml
```

Format (parse and print normalized TOML to stdout):

```bash
moon runwasm bobzhang/toml_cli -- format path/to/file.toml
```

Show help:

```bash
moon runwasm bobzhang/toml_cli -- --help
```

## Behavior

- Exit code `0`: success.
- Exit code `1`: the file could not be read or is not valid TOML; a
  human-readable error with position information is printed to stdout.
- Exit code `2`: usage error (unknown subcommand or missing file argument).
- `format` prints the normalized document; it never rewrites the input file.
  To format in place, redirect stdout to a temporary file and move it over the
  original after checking the exit code.

## Notes

- Pin a version with `moon runwasm bobzhang/toml_cli@<version> -- ...` for
  reproducible behavior.
- When working inside this repository, run the local build instead so changes
  are exercised: `moon runwasm ./toml_cli -- check file.toml` from the
  workspace root.
