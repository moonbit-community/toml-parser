# TOML Parser — toml-test Compliance

E2E results against [toml-lang/toml-test](https://github.com/toml-lang/toml-test):

| Suite   | Passed | Failed | Total | Rate   |
|---------|--------|--------|-------|--------|
| Valid   | **262** | 0     | 262   | **100%** |
| Invalid | 474    | 9      | 483   | 98.1%  |
| **Total** | **736** | **9** | **745** | **98.8%** |

Run: `moon test e2e -v --target native`

---

## Invalid tests: 9 remaining (all TOML 1.0-only — intentionally supported for 1.1)

These tests are invalid in TOML 1.0 but valid in TOML 1.1 (which we support):

- `datetime/no-secs.toml` — optional seconds (TOML 1.1 feature)
- `local-time/no-secs.toml` — optional seconds
- `local-datetime/no-secs.toml` — optional seconds
- `inline-table/linebreak-01..04.toml` — inline table newlines (TOML 1.1)
- `inline-table/trailing-comma.toml` — trailing commas (TOML 1.1)
- `string/basic-byte-escapes.toml` — `\xHH` escapes (TOML 1.1)

## All fixes applied (187 tests fixed from original 73.7% → 98.8%)

- [x] Tokenizer infinite loops on `[a-a-a]` and `_value` (was critical, now fixed)
- [x] Key-position detection for bare keys (`10e3`, `2018_10`)
- [x] `+` prefix for integers/floats (9 files)
- [x] Datetime space/`t`/`z` separators (8 files)
- [x] CRLF line endings (3 files)
- [x] `-` and mixed alphanumeric bare keys (2 files)
- [x] `\ ` line ending backslash in multiline strings (5 files)
- [x] `\xHH` and `\e` escape sequences — TOML 1.1 (3 files)
- [x] Consecutive quotes in multiline strings (6 files)
- [x] Array-of-tables reopen with subtable navigation (5 files)
- [x] Keywords as table/key names (4 files)
- [x] Inline table newlines and trailing commas — TOML 1.1 (3 files)
- [x] Dotted key float splitting in table paths (2 files)
- [x] Numeric key leading zeros preserved (4 files)
- [x] Date-like bare keys (1 file)
- [x] Exponent notation in floats (1 file)
- [x] Lowercase `z` timezone (1 file)
- [x] Optional seconds in datetime — TOML 1.1 (4 files)
- [x] Control character rejection in strings/comments (31 files)
- [x] Float/integer number format validation (17 files)
- [x] Datetime semantic validation — ranges, leap years (28 files)
- [x] Timezone offset validation (2 files)
- [x] Duplicate key rejection (20 files)
- [x] Newline/EOF required after table headers (2 files)
- [x] Duplicate `[table]` definition rejection (4 files)
- [x] Inline table immutability (6 files)
- [x] Multiline strings rejected as keys (6 files)
- [x] Uppercase `0X/0O/0B` prefix rejection (3 files)
- [x] Invalid backslash-space in multiline strings (4 files)
- [x] Dotted-key table redefinition rejection (8 files)
- [x] Spaced bracket rejection `[ [` and `] ]` (2 files)
- [x] Static array immutability (2 files)
- [x] Bare `\r` rejection (3 files)
- [x] Numeric float comparison in e2e comparator (3 files)
- [x] Datetime fractional-second normalization in e2e comparator (1 file)
- [x] DateTimeToken in bare keys restricted to LocalDate only (codex P2)
- [x] Inline table immutability in create_array_of_tables (codex P2)
- [x] Negative zero preservation in float comparator (codex P3)
