# lua-bitn

A portable bitwise operations library for 16-bit, 32-bit, and 64-bit integers
with **zero external dependencies**. This library provides a complete,
cross-platform implementation that runs on Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.

## Features

- **Zero Dependencies**: No C extensions or external libraries required
- **Automatic Optimization**: Uses native bit operations when available (Lua 5.2+
  bit32 library, Lua 5.3+ operators, LuaJIT bit library) with pure Lua fallback
- **Portable**: Runs on any Lua interpreter (5.1+)
- **Complete**: Full bitwise operations API for 16-bit, 32-bit, and 64-bit integers
- **Byte Conversions**: Big-endian and little-endian byte string conversions
- **Well-tested**: Comprehensive self-tests with embedded test vectors

## Installation

Clone this repository:

```bash
git clone https://github.com/finitelabs/lua-bitn.git
cd lua-bitn
```

Add the `src` directory to your Lua path, or copy the files to your project.

## Usage

### Basic Example

```lua
local bitn = require("bitn")

-- Check version
print(bitn.version())

-- 32-bit operations
local bit32 = bitn.bit32
local result = bit32.band(0xFF00, 0x0FF0)      -- 0x0F00
local shifted = bit32.lshift(1, 8)             -- 256
local rotated = bit32.ror(0x12345678, 8)       -- 0x78123456

-- Byte conversions (big-endian)
local bytes = bit32.u32_to_be_bytes(0x12345678)
local num = bit32.be_bytes_to_u32(bytes)       -- 0x12345678

-- 16-bit operations
local bit16 = bitn.bit16
local masked = bit16.mask(0x12345)             -- 0x2345
local negated = bit16.bnot(0xFF00)             -- 0x00FF

-- 64-bit operations (using {high, low} pairs)
local bit64 = bitn.bit64
local a = bit64.new(0x00000001, 0xFFFFFFFF)    -- 0x1FFFFFFFF
local b = bit64.new(0x00000000, 0x00000001)    -- 0x1
local sum = bit64.add(a, b)                    -- {0x00000002, 0x00000000}
local xored = bit64.bxor(
  bit64.new(0x12345678, 0x9ABCDEF0),
  bit64.new(0x12345678, 0x9ABCDEF0)
)                                               -- {0, 0}
```

### 64-bit Value Representation

64-bit values are represented as `{high, low}` pairs where:
- `high` is the upper 32 bits
- `low` is the lower 32 bits

Example: `0x123456789ABCDEF0` is represented as `{0x12345678, 0x9ABCDEF0}`

### Raw Operations (Performance-Critical Code)

The `bit32` and `bit64` modules provide `raw_*` variants for performance-critical
code paths like cryptographic operations. These bypass the unsigned conversion
wrapper used on LuaJIT, providing direct access to native bit library functions.

**Available functions (bit32 and bit64):**
- `raw_band`, `raw_bor`, `raw_bxor`, `raw_bnot`
- `raw_lshift`, `raw_rshift`, `raw_arshift`
- `raw_rol`, `raw_ror`
- `raw_add`

**Important:** On LuaJIT, raw_* functions may return **signed** 32-bit integers:

```lua
local bit32 = require("bitn").bit32

-- Regular function (always unsigned)
bit32.bxor(0x80000000, 1)      --> 2147483649

-- Raw function (signed on LuaJIT)
bit32.raw_bxor(0x80000000, 1)  --> -2147483647 (same bit pattern!)
```

**When to use raw_* functions:**
- Chained bitwise operations (XOR, AND, OR, rotate) where sign doesn't matter
- Crypto algorithms (ChaCha20, etc.) that only care about bit patterns
- Tight loops where the `to_unsigned()` overhead is measurable

**When NOT to use raw_* functions:**
- When comparing results (`<`, `>`, `==`)
- When doing arithmetic on the results
- When formatting/displaying values
- When you need guaranteed unsigned semantics

## Development

### Setup

```bash
# Install development dependencies (stylua, luacheck, amalg)
make install-deps
```

### Testing

```bash
make test                # Run all tests
make test-bit32          # Run specific module tests
make test-matrix         # Run tests across all Lua versions
make test-matrix-bit32   # Run specific module across all Lua versions

# Or use scripts directly with custom Lua binary
LUA_BINARY=lua5.1 ./run_tests.sh
```

### Benchmarking

```bash
make bench               # Run all benchmarks
make bench-bit32         # Run specific module benchmark
make bench-matrix        # Run benchmarks across all Lua versions
make bench-matrix-bit64  # Run specific module across all Lua versions

# Or use scripts directly with custom Lua binary
LUA_BINARY=lua5.4 ./run_benchmarks.sh
```

### Code Quality

```bash
make check               # Run format check and lint
make format              # Format code with stylua
make format-check        # Check formatting without modifying
make lint                # Run luacheck
```

### Building

```bash
make build               # Build single-file distribution (build/bitn.lua)
make clean               # Remove generated files
```

### Help

```bash
make help                # Show all available targets
```

## Current Limitations

- Pure Lua fallback (Lua 5.1 without LuaJIT) is slower than native bit libraries
- No constant-time guarantees

## License

GNU Affero General Public License v3.0 - see LICENSE file for details

## Contributing

Contributions are welcome! Please ensure all tests pass and add new tests for
any new functionality.

---

<a href="https://www.buymeacoffee.com/derek.miller" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
