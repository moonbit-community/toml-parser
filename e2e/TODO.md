# e2e TODO: misleading `test_unqualified_package` warning & alias confusion

## The problem we hit

The `e2e/` directory is a nested module — its `moon.mod` declares
`name = "bobzhang/toml-e2e"`. When code in this package uses a symbol
unqualified in tests, the compiler emits:

```
Warning (test_unqualified_package): `collect_toml_files` is implicitly
imported in test. Use `@toml-e2e.collect_toml_files` instead.
```

That suggestion is wrong in two ways:

1. `@toml-e2e.collect_toml_files` is **not syntactically valid** — the dash
   in `toml-e2e` makes it parse as `@toml` minus `e2e.collect_toml_files`.
   The compiler proposes a fix that the compiler itself would reject.
2. It ignores the alias actually in scope. `e2e/moon.pkg` declares
   `"bobzhang/toml-e2e" @e2e`, so the correct qualification is
   `@e2e.collect_toml_files`. The diagnostic should know that.

## Why it confuses

There's a triple mismatch sitting on top:

| What                                  | Value                  |
| ------------------------------------- | ---------------------- |
| Directory                             | `e2e/`                 |
| Module name (`e2e/moon.mod`)          | `bobzhang/toml-e2e`    |
| Default-derived alias (last segment)  | `toml-e2e` (invalid)   |
| Actual alias in `moon.pkg`            | `@e2e`                 |

For sub-packages (those inside a parent module) the dirname *is* the
last path segment, so users learn "dirname ≈ default alias". `e2e/` is a
nested module — last segment comes from `name =`, not the dirname —
which silently breaks that mental model.

See `MEMORY.md` entry [moon.pkg alias syntax] for the workaround.

## Possible improvements (from the toolchain author's point of view)

1. **Fix the warning message.** When emitting
   `test_unqualified_package`, look up the importing package's alias
   table and quote the actual alias:
   > `` `collect_toml_files` from `bobzhang/toml-e2e` (imported as
   > `@e2e`). Qualify it as `@e2e.collect_toml_files`. ``
   If no alias exists and the last segment is not a valid identifier,
   say so explicitly instead of inventing `@toml-e2e`.

2. **Reject dashed default-aliased imports at `moon.pkg` parse time.**
   `import { "bobzhang/toml-e2e" }` (no alias) should fail at the
   `moon.pkg` load site with a diagnostic pointing at the import line
   and the exact patched line to use.

3. **Surface the alias table in hover / completion.** `moon ide hover`
   on a symbol that triggered `test_unqualified_package` should list
   the available aliases; completion should offer
   `@e2e.collect_toml_files` as the top suggestion.

4. **Doc the rule in `moon explain --diagnostics test_unqualified_package`.**
   Cover (a) how the default alias is derived, (b) when that derivation
   fails (dashes, leading digits, reserved words), and (c) the
   recommended fix.

### What NOT to enforce: `dirname == last segment of module name`

It is tempting to add a lint that fires when a nested `moon.mod`'s
`name` does not match the directory it lives in. Don't — too many
legitimate cases break it:

- **Root checkout.** A module is `bobzhang/toml` but I clone it into
  `toml-parser/` or `~/work/foo/`. The root `moon.mod` has no control
  over the checkout dir.
- **Workspace-style sub-modules.** A `bobzhang/toml-cli` module sitting
  in `cli/` next to `parser/` is clearer than `cli/toml-cli/`.
- **Vendoring.** `vendor/toml-e2e/` is a fine layout.
- **Tests-as-a-module.** `e2e/` is a more readable dirname than
  `toml-e2e/` even when the module is renamed for dependency-graph
  clarity.

The lint would fire on legitimate code, which is the failure mode that
makes warnings get muted and ignored.

The dirname-vs-name mismatch is a *correlated symptom*, not the root
cause. The root cause is the gap between "package path syntax" (dashes
legal) and "identifier syntax" (dashes illegal). Enforce **alias
validity** (improvements 1 and 2 above), not stylistic dirname
agreement. If a team wants internal consistency, it can be offered as
an opt-in style warning (e.g. `+module_dirname_mismatch`), off by
default — but never on as policy.

## Possible improvements (local workaround)

Either rename brings dir, module name, and alias back into agreement:

- **Rename the nested module** to `bobzhang/toml/e2e` (or `bobzhang/e2e`)
  so the last segment matches the dirname and no alias is needed.
- **Rename the directory** to `toml-e2e/` so dir and module agree (the
  `@e2e` alias is still needed because of the dash, but at least
  dir↔module no longer drift).

The first is the more conventional MoonBit layout for tests-as-a-module.
