# E2E Test Suite

End-to-end tests against the official [toml-test](https://github.com/toml-lang/toml-test) suite.

## Running

```bash
moon test e2e --target native
```

The `--target native` flag is required because the tests use filesystem APIs (`@fs`) to read test data files.

## Test Structure

- `e2e_test.mbt` — Main test runner: iterates over `testdata/valid/` and `testdata/invalid/` directories
- `runner.mbt` — Test execution helpers: file collection, JSON comparison, float/datetime normalization
- `convert.mbt` — Converts MoonBit `TomlValue` to toml-test JSON format (`{"type": "...", "value": "..."}`)
- `known_failures_test.mbt` — Regression tests for previously-fixed bugs
- `testdata/valid/` — Valid TOML files with expected `.json` output (262 tests)
- `testdata/invalid/` — Invalid TOML files that must be rejected (483 tests)

## Current Status

| Suite       | Passed | Total | Rate     |
|-------------|--------|-------|----------|
| Valid       | 262    | 262   | **100%** |
| Invalid     | 474    | 483   | 98.1%    |
| **Total**   | **736**| **745**| **98.8%**|

## Known TOML 1.0 vs 1.1 Differences (9 expected failures)

The parser targets **TOML 1.1**. These 9 invalid-test "failures" are TOML 1.0 restrictions
that TOML 1.1 intentionally relaxes — the parser is correct:

| Test File | TOML 1.1 Feature |
|-----------|-----------------|
| `datetime/no-secs.toml` | Seconds optional in time |
| `local-time/no-secs.toml` | Seconds optional in time |
| `local-datetime/no-secs.toml` | Seconds optional in time |
| `inline-table/linebreak-01.toml` | Newlines in inline tables |
| `inline-table/linebreak-02.toml` | Newlines in inline tables |
| `inline-table/linebreak-03.toml` | Newlines in inline tables |
| `inline-table/linebreak-04.toml` | Newlines in inline tables |
| `inline-table/trailing-comma.toml` | Trailing comma in inline tables |
| `string/basic-byte-escapes.toml` | `\xHH` hex escape sequence |
