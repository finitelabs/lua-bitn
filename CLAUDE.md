# lua-bitn Development Guide

## Project Structure

```
lua-bitn/
├── src/bitn/
│   ├── init.lua      # Module aggregator, exports bit16/bit32/bit64
│   ├── bit16.lua     # 16-bit bitwise operations
│   ├── bit32.lua     # 32-bit bitwise operations
│   └── bit64.lua     # 64-bit bitwise operations (uses {high, low} pairs)
├── tests/
│   ├── test_bit16.lua    # 16-bit test vectors
│   ├── test_bit32.lua    # 32-bit test vectors
│   └── test_bit64.lua    # 64-bit test vectors
├── .github/workflows/
│   ├── build.yml     # CI: lint, test matrix, build
│   └── release.yml   # Release automation
├── run_tests.sh      # Main test runner
├── run_tests_matrix.sh   # Multi-version test runner
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

### Pure Lua Implementation

All operations are implemented using basic Lua arithmetic to ensure
compatibility across all Lua versions without native bit library dependencies.

## Testing

Tests use Lua table-based vectors for easy maintenance:

```lua
local test_vectors = {
  { name = "band(0xFF, 0x0F)", fn = bit32.band, inputs = {0xFF, 0x0F}, expected = 0x0F },
  -- ...
}
```

Run with: `./run_tests.sh` or `make test`

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
