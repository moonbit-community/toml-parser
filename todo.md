# TOML Parser — toml-test Compliance

E2E results against [toml-lang/toml-test](https://github.com/toml-lang/toml-test):

| Suite   | Passed | Failed | Skipped (crash) | Total |
|---------|--------|--------|-----------------|-------|
| Valid   | 256    | 5      | 1               | 262   |
| Invalid | 326    | 152    | 5               | 483   |

Run: `moon test e2e -v --target native`

---

## Critical: tokenizer infinite loops (6 files)

- [ ] Dashed bare key in table header `[a-a-a]` → infinite loop in `read_identifier` regex
- [ ] Leading underscore values (`_1.2`, `_123`, `_0b1`, `_0x1`, `_0o1`) → infinite loop (5 invalid test files)

## Valid tests: 5 remaining (all value representation, no parse errors)

- [ ] `float/exponent.toml` — `"300"` vs expected `"300.0"` (test suite format inconsistency)
- [ ] `float/underscore.toml` — `"3e+14"` vs expected `"3.0e14"` (exponent format)
- [ ] `float/max-int.toml` — Double precision loss: `9007199254740991` vs `9.007...987e+15`
- [ ] `comment/tricky.toml` — `"1000"` vs expected `"1000.0"` (same float `.0` issue)
- [ ] `datetime/milliseconds.toml` — `.6` vs `.600` (test suite expects padding but other tests don't)

## Fixed valid tests (54 files)

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

## Invalid tests failing (152 files)

Parser accepts input that should be rejected:

- [ ] **Control characters** (~30): bare control chars in strings/comments not rejected
- [ ] **Key validation** (~19): newlines in keys, keys after array/table not caught
- [ ] **Table validation** (~18): redefinition errors, duplicate tables, bracket mismatch
- [ ] **Datetime validation** (~28): invalid dates, time ranges, semantic checks
- [ ] **Integer validation** (~9): double underscores, capital prefix (`0B`), etc.
- [ ] **Float validation** (~12): trailing dot, leading zeros, underscore placement
- [ ] **Inline table** (~15): duplicate keys, TOML 1.0 newline restrictions
- [ ] **String** (~5): unclosed string edge cases, control chars
- [ ] **Spec compliance** (~8): spec-specific rejections
- [ ] **Array** (~1): array/table interaction edge cases
