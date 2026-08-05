# toml_cli

A command-line tool to parse, validate, and format TOML files, built on
[`bobzhang/toml`](https://mooncakes.io/docs/bobzhang/toml).

## Run without installing

The prebuilt binary can be run directly from mooncakes.io — it is fetched
and cached on first use, and arguments are passed straight through (no `--`
separator needed). Pin a version with `bobzhang/toml_cli@<version>` for
reproducible behavior:

```bash
moonx bobzhang/toml_cli --help
moonx bobzhang/toml_cli check config.toml
moonx bobzhang/toml_cli format config.toml
```

## Usage

```
toml <file>           Parse TOML and print normalized TOML (same as `format`)
toml format <file>    Parse TOML and print normalized TOML
toml check <file>     Validate TOML without printing parsed output
```

Exit codes: `0` on success, `1` on read/parse failure, `2` on usage errors.

## Run from source

```bash
moon runwasm .                          # in this directory
moon run --target native . -- --help    # native build
```
