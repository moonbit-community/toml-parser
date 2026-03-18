# TOML Parser — toml-test Compliance

E2E results against [toml-lang/toml-test](https://github.com/toml-lang/toml-test):

| Suite   | Passed | Failed | Skipped (crash) | Total |
|---------|--------|--------|-----------------|-------|
| Valid   | 202    | 59     | 1               | 262   |
| Invalid | 347    | 131    | 5               | 478   |

Run: `moon test e2e -v --target native`

---

## Critical: tokenizer infinite loops (6 files)

- [ ] Dashed bare key in table header `[a-a-a]` → infinite loop in `read_identifier` regex
- [ ] Leading underscore values (`_1.2`, `_123`, `_0b1`, `_0x1`, `_0o1`) → infinite loop (5 invalid test files)

## Valid tests failing (59 files)

### Tokenizer: `+` prefix not supported (9 files)
- [ ] `+99`, `+1.0`, `+0`, `+0e0` — TOML spec allows `+` prefix on integers and floats

### Tokenizer: datetime space separator and edge cases (8 files)
- [ ] `1987-07-05 17:45:00Z` — space instead of `T` not recognized
- [ ] No-seconds datetimes, leap-year dates, edge cases

### Tokenizer: CRLF not handled (3 files)
- [ ] `\r\n` line endings rejected as unexpected `\r`

### Tokenizer: `-` as bare key start (2 files)
- [ ] `-key = 1` — dash at start of bare key not tokenized

### Escape: `\ ` line ending backslash in multiline strings (3 files)
- [ ] Backslash at end of line should trim newline + leading whitespace

### Escape: `\xHH` and `\e` — TOML 1.1 (3 files)
- [ ] `\xHH` hex escape not supported
- [ ] `\e` ESC escape not supported

### Multiline strings: consecutive quotes and edge cases (5 files)
- [ ] Up to 2 `"` inside `"""..."""` should be valid
- [ ] Multiline raw string edge cases

### Parser: array-of-tables reopen (5 files)
- [ ] `[[array]]` after sub-tables should reopen the array, not error

### Parser: keywords as table/key names (4 files)
- [ ] `true`, `false`, `inf`, `nan` valid as bare keys and table names

### Parser: inline table newlines — TOML 1.1 (4 files)
- [ ] Newlines and comments inside inline tables

### Parser: dotted key in table name edge cases (2 files)
- [ ] Certain dotted patterns in `[a.b.c]` headers

### Value: numeric key leading zeros stripped (4 files)
- [ ] `0123` as bare key becomes `123` — should preserve full string

### Value: datetime millisecond trailing zeros (1 file)
- [ ] `.600` truncated to `.6` — should preserve trailing zeros

### Value: multiline string whitespace trimming (2 files)
- [ ] `\ ` followed by blank lines not trimming correctly

### Other parse failures (4 files)
- [ ] `valid/datetime/local.toml` — local datetime fractional seconds
- [ ] `valid/float/underscore.toml` — float underscore grouping
- [ ] `valid/comment/tricky.toml` — comment edge case
- [ ] `valid/comment/after-literal-no-ws.toml` — comment after literal

## Invalid tests failing (131 files)

Parser accepts input that should be rejected:

- [ ] **Control characters** (27): bare control chars in strings/comments not rejected
- [ ] **Key validation** (19): newlines in keys, keys after array/table not caught
- [ ] **Table validation** (18): redefinition errors, duplicate tables, bracket mismatch
- [ ] **Datetime validation** (10): invalid dates (feb-29/30, day-zero, hour/month overflow)
- [ ] **Local datetime/date/time** (18): similar date validation issues
- [ ] **Integer validation** (9): double underscores, capital prefix (`0B`), leading zeros
- [ ] **Float validation** (9): trailing dot, leading zeros, underscore placement
- [ ] **Inline table** (9): trailing commas, duplicate keys, newline restrictions (1.0)
- [ ] **String** (3): unclosed string edge cases
- [ ] **Spec compliance** (8): spec-1.0.0 / spec-1.1.0 specific rejections
- [ ] **Array** (1): `tables-01.toml`
