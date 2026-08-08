# lua-bitn Development Guide

## Project Structure

```
lua-bitn/
├── src/bitn/
│   ├── init.lua      # Module aggregator, exports bit16/bit32/bit64
│   ├── _compat.lua   # Internal compatibility layer, feature detection
│   ├── bit16.lua     # 16-bit bitwise operations
│   ├── bit32.lua     # 32-bit bitwise operations
│   ├── bit64.lua     # 64-bit bitwise operations (uses {high, low} pairs)
│   └── utils/
│       ├── init.lua      # Utils module aggregator
│       └── benchmark.lua # Benchmarking utilities
├── tests/
│   ├── test_bit16.lua    # 16-bit test vectors
│   ├── test_bit32.lua    # 32-bit test vectors
│   └── test_bit64.lua    # 64-bit test vectors
├── .github/workflows/
│   ├── build.yml     # CI: lint, test matrix, build
│   └── release.yml   # Release automation
├── run_tests.sh      # Main test runner
├── run_tests_matrix.sh   # Multi-version test runner
├── run_benchmarks.sh # Benchmark runner
└── Makefile          # Build automation
```

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

# Build single-file distribution
make build
```

### typecheck

`make typecheck` runs lua-language-server against the committed
`.luarc-typecheck.json`. It catches what luacheck does not: undefined or duplicate
`@alias`, returns that disagree with `@return`, fields missing from a `@class`.

`runtime.version` is pinned to LuaJIT because that is what Control4 runs, and here
it is load-bearing for the check too: unset, the server assumes Lua 5.4 and reports
the `math.pow` shim in `_compat.lua` and the `unpack` fallbacks in bit16/32/64 as
deprecated, four findings that fail the gate. That is the general shape of it, in
this repo and in lua-protobuf: a library carrying 5.1-era compat shims trips the
deprecation check the moment the server assumes a newer language. Libraries without
such shims, lua-noiseprotocol and lua-bthome-ble, are indifferent to the key.

`--configpath` displaces each individual setting the committed config declares,
not each table, so a knob is only closed if it is named. The candidate set is not a
matter of taste: `cli/check_worker.lua` derives `--check` suppression from
`diagnostics.disable` and `diagnostics.severity`, and every other vector is read by
a checker or the provider, so it can be enumerated with

    grep -rhoE "config\.get\([^,]*, *'Lua\.[A-Za-z.]+'" \
      script/core/diagnostics/*.lua script/provider/diagnostic.lua

Of the 17 keys that turns up on 3.19.0, six were measured as live bypasses and are
declared here: `enable`, `disable`, `severity`, `globals`, `globalsRegex` and
`enableScheme` under `diagnostics`, plus `special` under `runtime`.

`enableScheme` is the dangerous one and the reason "declare it empty" is not a rule
to apply blindly. It gates whether a document is diagnosed at all rather than
suppressing a code, its default is `["file"]`, and declaring `[]` silences the
entire check exactly as a local `["git"]` would. It is declared as `["file"]`.

Any setting this file does not name, under any table, is still reachable from a
local `.luarc.json`. Re-run the enumeration above when upgrading the server rather
than assuming this list stayed complete.

The server version is not pinned locally, though. `install-deps` takes whatever
Homebrew has while CI pins 3.19.0, so compare the version the target prints if a
local result disagrees with CI.

Part of `check`, so CI enforces it.

## Architecture

### Module Design

Each bit module (bit16, bit32, bit64) provides the same API:
- Bitwise: band, bor, bxor, bnot
- Shifts: lshift, rshift, arshift
- Rotates: rol, ror
- Arithmetic: add, mask
- Byte conversions: uN_to_be_bytes, uN_to_le_bytes, be_bytes_to_uN, le_bytes_to_uN

### 64-bit Representation

64-bit values use `{high, low}` pairs for Lua 5.1 compatibility:
```lua
-- 0x123456789ABCDEF0 represented as:
local value = {0x12345678, 0x9ABCDEF0}
```

### Compatibility Layer (_compat)

The `_compat` module provides automatic feature detection and optimized primitives:
- **Lua 5.3+**: Uses native bitwise operators (`&`, `|`, `~`, `<<`, `>>`)
- **Lua 5.2**: Uses built-in `bit32` library
- **LuaJIT**: Uses `bit` library with signed-to-unsigned conversion
- **Lua 5.1**: Falls back to pure Lua arithmetic implementation

This ensures optimal performance on modern Lua while maintaining compatibility
with older versions.

### Raw Operations (bit32 and bit64)

The bit32 and bit64 modules provide `raw_*` variants for performance-critical code:
- `raw_band`, `raw_bor`, `raw_bxor`, `raw_bnot`
- `raw_lshift`, `raw_rshift`, `raw_arshift`
- `raw_rol`, `raw_ror`
- `raw_add`

These bypass the `to_unsigned()` wrapper used on LuaJIT, returning signed
integers when the high bit is set. On other platforms they behave identically
to regular operations. Use for crypto code and tight loops where the sign
interpretation doesn't matter.

Note: Shift amounts >= 32 (or >= 64 for bit64) have platform-specific behavior
in raw functions. Callers should keep shift amounts in valid range.

## Testing

Tests use Lua table-based vectors for easy maintenance:

```lua
local test_vectors = {
  { name = "band(0xFF, 0x0F)", fn = bit32.band, inputs = {0xFF, 0x0F}, expected = 0x0F },
  -- ...
}
```

Run with: `./run_tests.sh` or `make test`

## Benchmarking

Each module includes a `benchmark()` function that measures performance of all
operations. Benchmarks use the `bitn.utils.benchmark` module for consistent
timing and output formatting.

```bash
# Run all benchmarks (uses LuaJIT by default for best performance)
./run_benchmarks.sh or `make bench`

# Run with specific Lua version
LUA_BINARY=lua5.4 ./run_benchmarks.sh

# Run specific module
./run_benchmarks.sh bit32
make bench-bit64
```

The benchmark utility performs:
- 3 warmup iterations before timing
- Configurable iteration count (default: 100, modules use 10000)
- Reports ms/op and ops/sec metrics

## Building

The build process uses `amalg` to create a single-file distribution:

```bash
make build
# Output: build/bitn.lua
```

Version is automatically injected from git tags during release.

## CI/CD

- **build.yml**: Runs on push/PR to main
  - Format check with stylua
  - Lint with luacheck
  - Test matrix (Lua 5.1-5.4, LuaJIT 2.0/2.1)
  - Build single-file distribution

- **release.yml**: Runs on version tags (v*)
  - Builds and publishes release with bitn.lua artifact

## Code Style

- 2-space indentation
- 120 column width
- Double quotes preferred
- LuaDoc annotations for all public functions
