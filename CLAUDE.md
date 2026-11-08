# lua-bitn Development Guide

## Project Structure

```
lua-bitn/
├── src/bitn/
│   ├── init.lua      # Module aggregator, exports bit16/bit32/bit64
│   ├── _compat.lua   # Internal compatibility layer, backend detection
│   ├── bit16.lua     # 16-bit bitwise operations
│   ├── bit32.lua     # 32-bit bitwise operations
│   └── bit64.lua     # 64-bit bitwise operations (Int64 {high, low} pairs)
├── test/
│   ├── test_bit16.lua    # Tests per module; each returns its test function
│   ├── test_bit32.lua
│   ├── test_bit64.lua
│   ├── lpack_stub.lua    # Control4's lpack-shaped string.pack, for the lpack run
│   └── with_tests.lua    # Main chunk of the with-tests build
├── bench/
│   ├── bench_bit16.lua   # Benchmarks per module; each returns its function
│   ├── bench_bit32.lua
│   ├── bench_bit64.lua
│   └── benchmark.lua     # Benchmarking helper
├── .github/workflows/
│   ├── build.yml     # CI: check (format/lint/typecheck), test matrix, build
│   └── release.yml   # Release automation
├── .luarc-typecheck.json   # Hardened config for `make typecheck` (see below)
├── .luacheckrc
├── run_tests.sh            # Main test runner
├── run_tests_matrix.sh     # Multi-version test runner
├── run_benchmarks.sh       # Benchmark runner
├── run_benchmarks_matrix.sh
└── Makefile          # Build automation
```

Nothing under `src/` is test code: tests live in `test/`, benchmarks in `bench/`,
and `make build` fails if `build/bitn.lua` mentions `selftest` or `benchmark`.

## Key Commands

```bash
# Run tests
make test

# Run specific module tests
make test-bit32

# Run across Lua versions
make test-matrix

# Run benchmarks
make bench

# Run specific module benchmark
make bench-bit32

# Format code
make format

# Lint code
make lint

# Check LuaCATS annotations with lua-language-server
make typecheck

# Full gate: format-check + lint + typecheck
make check

# Build single-file distribution
make build
```

`make check` is the gate CI runs. `make all` is `format lint test build`, which
reformats in place and runs neither `format-check` nor `typecheck` — it is not a
substitute for `check`.

### typecheck

`make typecheck` runs lua-language-server against the committed
`.luarc-typecheck.json`. It catches what luacheck does not: undefined or duplicate
`@alias`, returns that disagree with `@return`, fields missing from a `@class`.

`runtime.version` is pinned to LuaJIT because that is what Control4 runs, and here
it is load-bearing for the check too: unset, the server assumes Lua 5.4 and reports
the `math.pow` shim in `_compat.lua` and the `unpack` fallbacks in bit16/32/64 as
deprecated, four findings that fail the gate. Any library carrying 5.1-era compat
shims trips the deprecation check the moment the server assumes a newer language.

`--configpath` displaces each individual setting the committed config declares,
not each table, so a knob is only closed if it is named. Suppression keys can be
enumerated from the diagnostics read sites — paths below are inside a
lua-language-server source checkout, not this repo:

    grep -rhoE "config\.get\([^,]*, *'Lua\.[A-Za-z.]+'" \
      script/core/diagnostics/*.lua script/provider/diagnostic.lua

Treat that as a floor, not a ceiling: its file scope is the shape of its blind
spot. Anything that gates file loading or rewrites source before analysis is read
elsewhere, and has to be enumerated separately from `script/plugin.lua` and
`script/workspace.lua`. `runtime.plugin` is the case that matters, and the grep
cannot surface it by construction. `check_worker.lua` does `require 'plugin'`, so
an `OnSetText` returning an empty edit blanks every file in the repo and the check
passes having analysed nothing.

Two traps decide how a key gets declared, and neither is answered by the key's
type:

Empty is not always inert, so read the read site. `neededFileStatus` and
`groupFileStatus` are per-key lookups that fall back to the built-in default, so
`{}` leaves behaviour untouched. `enableScheme` defaults to `["file"]`, which makes
`[]` silence the whole check exactly as a local `["git"]` would. It is declared as
`["file"]` for that reason.

Immunity is per-code, so one planted probe does not measure a key.
`check_worker.lua`'s `downgrade_checks_to_opened` force-overwrites only codes whose
default status is `Any`, leaving everything defaulting to `Opened` under local
control, which is precisely the type-check group this gate exists for. An
`undefined-global` probe therefore reports `neededFileStatus` as inert while a
`return-type-mismatch` probe shows it silencing the check. Probe with a type-check
code.

Declared here as measured live bypasses: `enable`, `disable`, `severity`,
`globals`, `globalsRegex`, `enableScheme`, `neededFileStatus` and `groupFileStatus`
under `diagnostics`, plus `special` and `plugin` under `runtime`. `pluginArgs`,
`groupSeverity`, `maxPreload` and `preloadFileSize` are declared as belt and
braces rather than measured bypasses: `groupSeverity` relabels a finding that is
still counted and still exits non-zero, and `preloadFileSize: 0` fails loud rather
than hiding anything. Declaring them costs nothing and saves re-deriving that.

Any setting this file does not name, under any table, is still reachable from a
local `.luarc.json`. Re-run both enumerations when upgrading the server rather than
assuming this list stayed complete.

The server version is not pinned locally, though. `install-deps` takes whatever
Homebrew has while CI pins 3.19.2, so compare the version the target prints if a
local result disagrees with CI.

Part of `check`, so CI enforces it.

## Architecture

### Module Design

All three modules share a core API: `band`, `bor`, `bxor`, `bnot`, `lshift`,
`rshift`, `arshift`, `rol`, `ror`, `add`, and the byte conversions
`uN_to_be_bytes`, `uN_to_le_bytes`, `be_bytes_to_uN`, `le_bytes_to_uN`.

The surface is not uniform beyond that, and the differences bite callers:

- `mask` is **bit16 and bit32 only**. `bit64` has none.
- `to_unsigned` and `to_signed` are **bit32 only**.
- `bit64` alone adds the Int64 constructors and accessors below, plus the compat
  aliases `xor`, `shr`, `lsl`, `asr`.

### 64-bit Representation

`bit64` represents a 64-bit value as a `{high, low}` pair for Lua 5.1
compatibility, but the pair is **not a plain table**. `bit64.new` attaches a
private metatable, and `bit64.is_int64` tests for it, so a bare literal is not a
valid Int64:

```lua
-- Correct:
local value = bit64.new(0x12345678, 0x9ABCDEF0)
local also  = bit64.from_number(n)

-- Rejected by to_number/to_hex/eq/is_zero with
-- "Value is not a valid Int64HighLow pair":
local bad = {0x12345678, 0x9ABCDEF0}
```

The bitwise operations index `[1]`/`[2]` directly and so happen to accept a bare
literal; the accessors do not. Construct through `new`/`from_number` or the two
paths diverge silently until an accessor raises.

`to_number(value, strict)` returns `high * 2^32 + low`. Values above 53 bits lose
precision on a float build; passing `strict` raises instead of returning a lossy
result.

### Compatibility Layer (_compat)

`_compat` selects a backend by **probing behaviour, not by reading a version**. It
compiles `a & b` and checks that `fn(0xFFFFFFFF, 0xFFFFFFFF) == 0xFFFFFFFF`:

- **Native operators** when that probe returns unsigned (Lua 5.3+).
- **LuaJIT `bit`** otherwise, with signed-to-unsigned conversion.
- **`bit32`** only as a fallback after `require("bit")` fails.
- **Pure Lua arithmetic** when none is present.

The probe exists because a syntax check is not sufficient: LuaJIT rolling releases
from 2026 *parse* `a & b` but return signed 32-bit, so testing only whether the
expression compiles would route them into the native branch and skip
`to_unsigned()`. A consequence worth knowing: a Lua 5.1 install with LuaBitOp takes
the LuaJIT path and reports `_compat.is_luajit = true`.

### Raw Operations (bit32 and bit64)

Both modules expose `raw_*` variants of every operation (`raw_band`, `raw_bor`,
`raw_bxor`, `raw_bnot`, `raw_lshift`, `raw_rshift`, `raw_arshift`, `raw_rol`,
`raw_ror`, `raw_add`). `bit16` has none.

These bypass the `to_unsigned()` wrapper used on LuaJIT and return signed integers
when the high bit is set. Elsewhere they match the regular operations **for
in-range inputs only** — the wrapped versions also mask their arguments, the raw
ones do not. Use for crypto code and tight loops where the sign interpretation
does not matter.

Shift amounts >= 32 (>= 64 for bit64) are platform-specific in the raw functions.
Callers must keep shift amounts in range.

## Testing

`test/test_<module>.lua` returns a function that runs that module's vectors,
prints each result and returns true when all pass. The shell runners call them:

```bash
./run_tests.sh          # all modules, or `make test`
./run_tests.sh bit32    # one module, or `make test-bit32`
make test-matrix        # across Lua versions
make build test-bundle  # the same tests against the built files
```

`TEST_BUNDLE=build/bitn.lua ./run_tests.sh` loads that file first and takes
`src/` off the path, so a module missing from the bundle fails instead of
loading from source. `test-bundle` then runs the with-tests build's own
`selftest()`. CI runs both on every interpreter in the matrix, against the
files the build job made.

`make test-matrix` runs luaenv's `5.1.5 5.2.4 5.3.6 5.4.9 5.5.1 luajit-2.0-dev
luajit-2.1-dev`, the versions CI tests. The 5.4.9 and 5.5.1 builds need a
lua-build plugin with their definitions (upstream cehoffman/lua-build has had
them since August 2026).

## Benchmarking

`bench/bench_<module>.lua` returns a function built on `bench/benchmark.lua`,
which runs 3 warmup iterations, defaults to 100 iterations, and reports ms/op and
ops/sec. The benchmarks call it with 100000.

```bash
make bench                          # all, LuaJIT by default
make bench-bit64                    # one module
LUA_BINARY=lua5.4 ./run_benchmarks.sh
```

## Building

`amalg` produces two single files:

```bash
make build
# build/bitn.lua        the library (no dependencies, so also portable)
# build/bitn-tests.lua  the library plus test/ and bench/, from test/with_tests.lua
```

`dofile("build/bitn-tests.lua")` returns the library with `selftest()` and
`benchmark()` added, for running them where the library runs, a Control4
controller included. Version is injected from git tags into both.

## CI/CD

- **build.yml** (workflow name `Lua Tests`): on push/PR to `main` or `master`.
  - `check` job — `make check`, i.e. stylua format check, luacheck, and typecheck
    against lua-language-server 3.19.2.
  - `build` job — both single files, uploaded as the `bitn` artifact.
  - `test` job — `make test-all test-bundle` across Lua 5.1-5.5 and LuaJIT
    2.0/2.1, on the build job's files.

- **release.yml**: on version tags (`v*`) — builds, runs `make test-bundle`, and
  publishes `build/bitn.lua` and `build/bitn-tests.lua`.

## Code Style

- 2-space indentation
- 120 column width
- Double quotes preferred
- LuaCATS annotations for all public functions

stylua is invoked with these as CLI flags from the Makefile; there is no
`.stylua.toml`. Formatting and linting cover `src/`, `test/` and `bench/`, so the
root shell scripts and `.luacheckrc` are not checked.
