# lua-bitn

A pure Lua implementation of bitwise operations for 16-bit, 32-bit, and 64-bit
integers with **zero external dependencies**. This library provides a complete,
portable implementation that runs on Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.

## Features

- **Zero Dependencies**: Pure Lua implementation, no C extensions or external
  libraries required
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
local a = {0x00000001, 0xFFFFFFFF}             -- 0x1FFFFFFFF
local b = {0x00000000, 0x00000001}             -- 0x1
local sum = bit64.add(a, b)                    -- {0x00000002, 0x00000000}
local xored = bit64.bxor(
  {0x12345678, 0x9ABCDEF0},
  {0x12345678, 0x9ABCDEF0}
)                                               -- {0, 0}
```

### 64-bit Value Representation

64-bit values are represented as `{high, low}` pairs where:
- `high` is the upper 32 bits
- `low` is the lower 32 bits

Example: `0x123456789ABCDEF0` is represented as `{0x12345678, 0x9ABCDEF0}`

## Testing

Run the test suite:

```bash
# Run all tests with default Lua interpreter
./run_tests.sh

# Run with specific Lua version
LUA_BINARY=lua5.1 ./run_tests.sh

# Run specific module
./run_tests.sh bit32

# Run test matrix across all Lua versions
./run_tests_matrix.sh
```

## Current Limitations

- Pure Lua performance is slower than native bit libraries
- No constant-time guarantees

## License

GNU Affero General Public License v3.0 - see LICENSE file for details

## Contributing

Contributions are welcome! Please ensure all tests pass and add new tests for
any new functionality.

---

<a href="https://www.buymeacoffee.com/derek.miller" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
