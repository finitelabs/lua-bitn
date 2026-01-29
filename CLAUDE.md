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

# Build single-file distribution
make build
```

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
