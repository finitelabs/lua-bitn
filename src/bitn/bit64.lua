--- @module "bitn.bit64"
--- 64-bit bitwise operations library.
--- This module provides 64-bit bitwise operations using {high, low} pairs,
--- where high is the upper 32 bits and low is the lower 32 bits.
--- Works across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.
--- Uses native bit operations where available for optimal performance.
local bit64 = {}

local bit32 = require("bitn.bit32")
local _compat = require("bitn._compat")
local impl_name = _compat.impl_name

-- Cache bit32 methods as locals for faster access
local bit32_band = bit32.band
local bit32_bor = bit32.bor
local bit32_bxor = bit32.bxor
local bit32_bnot = bit32.bnot
local bit32_lshift = bit32.lshift
local bit32_rshift = bit32.rshift
local bit32_arshift = bit32.arshift
local bit32_u32_to_be_bytes = bit32.u32_to_be_bytes
local bit32_u32_to_le_bytes = bit32.u32_to_le_bytes
local bit32_be_bytes_to_u32 = bit32.be_bytes_to_u32
local bit32_le_bytes_to_u32 = bit32.le_bytes_to_u32

-- Private metatable for Int64 type identification
local Int64Meta = { __name = "Int64" }

-- Type definitions
--- @alias Int64HighLow [integer, integer] Array with [1]=high 32 bits, [2]=low 32 bits

--------------------------------------------------------------------------------
-- Constructor and type checking
--------------------------------------------------------------------------------

--- Create a new Int64 value with metatable marker.
--- @param high? integer Upper 32 bits (default: 0)
--- @param low? integer Lower 32 bits (default: 0)
--- @return Int64HighLow value Int64 value with metatable marker
function bit64.new(high, low)
  return setmetatable({ high or 0, low or 0 }, Int64Meta)
end

--- Check if a value is an Int64 (created by bit64 functions).
--- @param value any Value to check
--- @return boolean is_int64 True if value is an Int64
function bit64.is_int64(value)
  return type(value) == "table" and getmetatable(value) == Int64Meta
end

--------------------------------------------------------------------------------
-- Bitwise operations
--------------------------------------------------------------------------------

--- Bitwise AND operation.
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} AND result
function bit64.band(a, b)
  return bit64.new(bit32_band(a[1], b[1]), bit32_band(a[2], b[2]))
end

--- Bitwise OR operation.
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} OR result
function bit64.bor(a, b)
  return bit64.new(bit32_bor(a[1], b[1]), bit32_bor(a[2], b[2]))
end

--- Bitwise XOR operation.
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} XOR result
function bit64.bxor(a, b)
  return bit64.new(bit32_bxor(a[1], b[1]), bit32_bxor(a[2], b[2]))
end

--- Bitwise NOT operation.
--- @param a Int64HighLow Operand {high, low}
--- @return Int64HighLow result {high, low} NOT result
function bit64.bnot(a)
  return bit64.new(bit32_bnot(a[1]), bit32_bnot(a[2]))
end

--------------------------------------------------------------------------------
-- Shift operations
--------------------------------------------------------------------------------

--- Left shift operation.
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.lshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  elseif n >= 64 then
    return bit64.new(0, 0)
  elseif n >= 32 then
    -- Shift by 32 or more: low becomes 0, high gets bits from low
    return bit64.new(bit32_lshift(x[2], n - 32), 0)
  else
    -- Shift by less than 32
    local new_high = bit32_bor(bit32_lshift(x[1], n), bit32_rshift(x[2], 32 - n))
    local new_low = bit32_lshift(x[2], n)
    return bit64.new(new_high, new_low)
  end
end

--- Logical right shift operation (fills with 0s).
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.rshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  elseif n >= 64 then
    return bit64.new(0, 0)
  elseif n >= 32 then
    -- Shift by 32 or more: high becomes 0, low gets bits from high
    return bit64.new(0, bit32_rshift(x[1], n - 32))
  else
    -- Shift by less than 32
    local new_low = bit32_bor(bit32_rshift(x[2], n), bit32_lshift(x[1], 32 - n))
    local new_high = bit32_rshift(x[1], n)
    return bit64.new(new_high, new_low)
  end
end

--- Arithmetic right shift operation (sign-extending, fills with sign bit).
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.arshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  -- Check sign bit (bit 31 of high word)
  local is_negative = bit32_band(x[1], 0x80000000) ~= 0

  if n >= 64 then
    -- All bits shift out, result is all 1s if negative, all 0s if positive
    if is_negative then
      return bit64.new(0xFFFFFFFF, 0xFFFFFFFF)
    else
      return bit64.new(0, 0)
    end
  elseif n >= 32 then
    -- High word shifts into low, high fills with sign
    local new_low = bit32_arshift(x[1], n - 32)
    local new_high = is_negative and 0xFFFFFFFF or 0
    return bit64.new(new_high, new_low)
  else
    -- Shift by less than 32
    local new_low = bit32_bor(bit32_rshift(x[2], n), bit32_lshift(x[1], 32 - n))
    local new_high = bit32_arshift(x[1], n)
    return bit64.new(new_high, new_low)
  end
end

--------------------------------------------------------------------------------
-- Rotate operations
--------------------------------------------------------------------------------

--- Left rotate operation.
--- @param x Int64HighLow Value to rotate {high, low}
--- @param n integer Number of positions to rotate
--- @return Int64HighLow result {high, low} rotated value
function bit64.rol(x, n)
  n = n % 64
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  local high, low = x[1], x[2]

  if n == 32 then
    -- Special case: swap high and low
    return bit64.new(low, high)
  elseif n < 32 then
    -- Rotate within 32-bit boundaries
    local new_high = bit32_bor(bit32_lshift(high, n), bit32_rshift(low, 32 - n))
    local new_low = bit32_bor(bit32_lshift(low, n), bit32_rshift(high, 32 - n))
    return bit64.new(new_high, new_low)
  else
    -- n > 32: rotate by (n - 32) after swapping
    n = n - 32
    local new_high = bit32_bor(bit32_lshift(low, n), bit32_rshift(high, 32 - n))
    local new_low = bit32_bor(bit32_lshift(high, n), bit32_rshift(low, 32 - n))
    return bit64.new(new_high, new_low)
  end
end

--- Right rotate operation.
--- @param x Int64HighLow Value to rotate {high, low}
--- @param n integer Number of positions to rotate
--- @return Int64HighLow result {high, low} rotated value
function bit64.ror(x, n)
  n = n % 64
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  local high, low = x[1], x[2]

  if n == 32 then
    -- Special case: swap high and low
    return bit64.new(low, high)
  elseif n < 32 then
    -- Rotate within 32-bit boundaries
    local new_low = bit32_bor(bit32_rshift(low, n), bit32_lshift(high, 32 - n))
    local new_high = bit32_bor(bit32_rshift(high, n), bit32_lshift(low, 32 - n))
    return bit64.new(new_high, new_low)
  else
    -- n > 32: rotate by (n - 32) after swapping
    n = n - 32
    local new_low = bit32_bor(bit32_rshift(high, n), bit32_lshift(low, 32 - n))
    local new_high = bit32_bor(bit32_rshift(low, n), bit32_lshift(high, 32 - n))
    return bit64.new(new_high, new_low)
  end
end

--------------------------------------------------------------------------------
-- Arithmetic operations
--------------------------------------------------------------------------------

--- 64-bit addition with overflow handling.
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} sum
function bit64.add(a, b)
  local low = a[2] + b[2]
  local high = a[1] + b[1]

  -- Handle carry from low to high
  if low >= 0x100000000 then
    high = high + 1
    low = low % 0x100000000
  end

  -- Keep high within 32 bits
  high = high % 0x100000000

  return bit64.new(high, low)
end

--------------------------------------------------------------------------------
-- Byte conversion functions
--------------------------------------------------------------------------------

--- Convert 64-bit value to 8 bytes (big-endian).
--- @param x Int64HighLow 64-bit value {high, low}
--- @return string bytes 8-byte string in big-endian order
function bit64.u64_to_be_bytes(x)
  return bit32_u32_to_be_bytes(x[1]) .. bit32_u32_to_be_bytes(x[2])
end

--- Convert 64-bit value to 8 bytes (little-endian).
--- @param x Int64HighLow 64-bit value {high, low}
--- @return string bytes 8-byte string in little-endian order
function bit64.u64_to_le_bytes(x)
  return bit32_u32_to_le_bytes(x[2]) .. bit32_u32_to_le_bytes(x[1])
end

--- Convert 8 bytes to 64-bit value (big-endian).
--- @param str string Binary string (at least 8 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return Int64HighLow value {high, low} 64-bit value
function bit64.be_bytes_to_u64(str, offset)
  offset = offset or 1
  assert(#str >= offset + 7, "Insufficient bytes for u64")
  local high = bit32_be_bytes_to_u32(str, offset)
  local low = bit32_be_bytes_to_u32(str, offset + 4)
  return bit64.new(high, low)
end

--- Convert 8 bytes to 64-bit value (little-endian).
--- @param str string Binary string (at least 8 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return Int64HighLow value {high, low} 64-bit value
function bit64.le_bytes_to_u64(str, offset)
  offset = offset or 1
  assert(#str >= offset + 7, "Insufficient bytes for u64")
  local low = bit32_le_bytes_to_u32(str, offset)
  local high = bit32_le_bytes_to_u32(str, offset + 4)
  return bit64.new(high, low)
end

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

--- Converts a {high, low} pair to a 16-character hexadecimal string.
--- @param value Int64HighLow The {high_32, low_32} pair.
--- @return string hex The hexadecimal string (e.g., "0000180000001000").
function bit64.to_hex(value)
  return string.format("%08X%08X", value[1], value[2])
end

--- Converts a {high, low} pair to a Lua number.
--- Warning: Lua numbers use 64-bit IEEE 754 doubles with 53-bit mantissa precision.
--- Values exceeding 53 bits (greater than 9007199254740991) will lose precision.
--- To maintain full 64-bit precision, keep values in {high, low} format.
--- @param value number|integer|Int64HighLow The {high_32, low_32} pair (or number to pass through).
--- @param strict? boolean If true, errors when value exceeds 53-bit precision.
--- @return number|integer result The value as a Lua number (may lose precision for large values unless strict).
--- @overload fun(value: number, strict?: boolean): number
--- @overload fun(value: integer, strict?: boolean): integer
--- @overload fun(value: Int64HighLow, strict?: boolean): integer
--- @overload fun(value: number): number
--- @overload fun(value: integer): integer
--- @overload fun(value: Int64HighLow): integer
function bit64.to_number(value, strict)
  if type(value) == "number" then
    return value
  end
  if not bit64.is_int64(value) then
    error("Value is not a valid Int64HighLow pair", 2)
  end
  if strict and value[1] > 0x001FFFFF then
    error("Value exceeds 53-bit precision (max: 9007199254740991)", 2)
  end
  return value[1] * 0x100000000 + value[2]
end

--- Creates a {high, low} pair from a Lua number.
--- @param value number|Int64HighLow The number to convert (or Int64HighLow to pass through).
--- @return Int64HighLow pair The {high_32, low_32} pair.
function bit64.from_number(value)
  if bit64.is_int64(value) then
    --- @cast value Int64HighLow
    return value
  end
  --- @cast value -Int64HighLow
  local low = math.floor(value % 0x100000000)
  local high = math.floor(value / 0x100000000)
  return bit64.new(high, low)
end

--- Checks if two {high, low} pairs are equal.
--- @param a Int64HighLow The first {high_32, low_32} pair.
--- @param b Int64HighLow The second {high_32, low_32} pair.
--- @return boolean equal True if the values are equal.
function bit64.eq(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

--- Checks if a {high, low} pair is zero.
--- @param value Int64HighLow The {high_32, low_32} pair.
--- @return boolean is_zero True if the value is zero.
function bit64.is_zero(value)
  return value[1] == 0 and value[2] == 0
end

--------------------------------------------------------------------------------
-- Aliases for compatibility
--------------------------------------------------------------------------------

--- Alias for bxor (compatibility with older API).
bit64.xor = bit64.bxor

--- Alias for rshift (compatibility with older API).
bit64.shr = bit64.rshift

--- Alias for lshift (compatibility with older API).
bit64.lsl = bit64.lshift

--- Alias for arshift (compatibility with older API).
bit64.asr = bit64.arshift

--- Alias for is_int64 (compatibility with older API).
bit64.isInt64 = bit64.is_int64

--------------------------------------------------------------------------------
-- Self-test
--------------------------------------------------------------------------------

-- Compatibility for unpack
local unpack_fn = unpack or table.unpack

--- Compare two 64-bit values (high/low pairs).
--- @param a Int64HighLow First value {high, low}
--- @param b Int64HighLow Second value {high, low}
--- @return boolean equal True if equal
local function eq64(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

--- Format 64-bit value as hex string.
--- @param x Int64HighLow Value {high, low}
--- @return string formatted Hex string
local function fmt64(x)
  return string.format("{0x%08X, 0x%08X}", x[1], x[2])
end

--- Run comprehensive self-test with test vectors.
--- @return boolean result True if all tests pass, false otherwise
function bit64.selftest()
  print("Running 64-bit operations test vectors...")
  print(string.format("  Using: %s", impl_name()))
  local passed = 0
  local total = 0

  local test_vectors = {
    -- band tests
    {
      name = "band({0xFFFFFFFF, 0}, {0, 0xFFFFFFFF})",
      fn = bit64.band,
      inputs = { { 0xFFFFFFFF, 0 }, { 0, 0xFFFFFFFF } },
      expected = { 0, 0 },
    },
    {
      name = "band({0xFFFFFFFF, 0xFFFFFFFF}, {0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.band,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "band({0xAAAAAAAA, 0x55555555}, {0x55555555, 0xAAAAAAAA})",
      fn = bit64.band,
      inputs = { { 0xAAAAAAAA, 0x55555555 }, { 0x55555555, 0xAAAAAAAA } },
      expected = { 0, 0 },
    },

    -- bor tests
    {
      name = "bor({0xFFFF0000, 0}, {0, 0x0000FFFF})",
      fn = bit64.bor,
      inputs = { { 0xFFFF0000, 0 }, { 0, 0x0000FFFF } },
      expected = { 0xFFFF0000, 0x0000FFFF },
    },
    { name = "bor({0, 0}, {0, 0})", fn = bit64.bor, inputs = { { 0, 0 }, { 0, 0 } }, expected = { 0, 0 } },
    {
      name = "bor({0xAAAAAAAA, 0x55555555}, {0x55555555, 0xAAAAAAAA})",
      fn = bit64.bor,
      inputs = { { 0xAAAAAAAA, 0x55555555 }, { 0x55555555, 0xAAAAAAAA } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },

    -- bxor tests
    {
      name = "bxor({0xFFFFFFFF, 0}, {0, 0xFFFFFFFF})",
      fn = bit64.bxor,
      inputs = { { 0xFFFFFFFF, 0 }, { 0, 0xFFFFFFFF } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "bxor({0x12345678, 0x9ABCDEF0}, {0x12345678, 0x9ABCDEF0})",
      fn = bit64.bxor,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, { 0x12345678, 0x9ABCDEF0 } },
      expected = { 0, 0 },
    },

    -- bnot tests
    { name = "bnot({0, 0})", fn = bit64.bnot, inputs = { { 0, 0 } }, expected = { 0xFFFFFFFF, 0xFFFFFFFF } },
    {
      name = "bnot({0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.bnot,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = { 0, 0 },
    },
    {
      name = "bnot({0xAAAAAAAA, 0x55555555})",
      fn = bit64.bnot,
      inputs = { { 0xAAAAAAAA, 0x55555555 } },
      expected = { 0x55555555, 0xAAAAAAAA },
    },

    -- lshift tests
    { name = "lshift({0, 1}, 0)", fn = bit64.lshift, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "lshift({0, 1}, 1)", fn = bit64.lshift, inputs = { { 0, 1 }, 1 }, expected = { 0, 2 } },
    { name = "lshift({0, 1}, 32)", fn = bit64.lshift, inputs = { { 0, 1 }, 32 }, expected = { 1, 0 } },
    { name = "lshift({0, 1}, 63)", fn = bit64.lshift, inputs = { { 0, 1 }, 63 }, expected = { 0x80000000, 0 } },
    { name = "lshift({0, 1}, 64)", fn = bit64.lshift, inputs = { { 0, 1 }, 64 }, expected = { 0, 0 } },
    {
      name = "lshift({0, 0xFFFFFFFF}, 8)",
      fn = bit64.lshift,
      inputs = { { 0, 0xFFFFFFFF }, 8 },
      expected = { 0xFF, 0xFFFFFF00 },
    },

    -- rshift tests
    { name = "rshift({0, 1}, 0)", fn = bit64.rshift, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "rshift({0, 2}, 1)", fn = bit64.rshift, inputs = { { 0, 2 }, 1 }, expected = { 0, 1 } },
    { name = "rshift({1, 0}, 32)", fn = bit64.rshift, inputs = { { 1, 0 }, 32 }, expected = { 0, 1 } },
    {
      name = "rshift({0x80000000, 0}, 63)",
      fn = bit64.rshift,
      inputs = { { 0x80000000, 0 }, 63 },
      expected = { 0, 1 },
    },
    { name = "rshift({1, 0}, 64)", fn = bit64.rshift, inputs = { { 1, 0 }, 64 }, expected = { 0, 0 } },
    {
      name = "rshift({0xFF000000, 0}, 8)",
      fn = bit64.rshift,
      inputs = { { 0xFF000000, 0 }, 8 },
      expected = { 0x00FF0000, 0 },
    },

    -- arshift tests (sign-extending)
    {
      name = "arshift({0x80000000, 0}, 1)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 1 },
      expected = { 0xC0000000, 0 },
    },
    {
      name = "arshift({0x80000000, 0}, 32)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 32 },
      expected = { 0xFFFFFFFF, 0x80000000 },
    },
    {
      name = "arshift({0x80000000, 0}, 63)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 63 },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x80000000, 0}, 64)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 64 },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x7FFFFFFF, 0xFFFFFFFF}, 1)",
      fn = bit64.arshift,
      inputs = { { 0x7FFFFFFF, 0xFFFFFFFF }, 1 },
      expected = { 0x3FFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x7FFFFFFF, 0}, 63)",
      fn = bit64.arshift,
      inputs = { { 0x7FFFFFFF, 0 }, 63 },
      expected = { 0, 0 },
    },

    -- rol tests
    { name = "rol({0, 1}, 0)", fn = bit64.rol, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "rol({0, 1}, 1)", fn = bit64.rol, inputs = { { 0, 1 }, 1 }, expected = { 0, 2 } },
    { name = "rol({0x80000000, 0}, 1)", fn = bit64.rol, inputs = { { 0x80000000, 0 }, 1 }, expected = { 0, 1 } },
    { name = "rol({0, 1}, 32)", fn = bit64.rol, inputs = { { 0, 1 }, 32 }, expected = { 1, 0 } },
    { name = "rol({0, 1}, 64)", fn = bit64.rol, inputs = { { 0, 1 }, 64 }, expected = { 0, 1 } },
    {
      name = "rol({0x12345678, 0x9ABCDEF0}, 16)",
      fn = bit64.rol,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, 16 },
      expected = { 0x56789ABC, 0xDEF01234 },
    },

    -- ror tests
    { name = "ror({0, 1}, 0)", fn = bit64.ror, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "ror({0, 1}, 1)", fn = bit64.ror, inputs = { { 0, 1 }, 1 }, expected = { 0x80000000, 0 } },
    { name = "ror({0, 2}, 1)", fn = bit64.ror, inputs = { { 0, 2 }, 1 }, expected = { 0, 1 } },
    { name = "ror({1, 0}, 32)", fn = bit64.ror, inputs = { { 1, 0 }, 32 }, expected = { 0, 1 } },
    { name = "ror({0, 1}, 64)", fn = bit64.ror, inputs = { { 0, 1 }, 64 }, expected = { 0, 1 } },
    {
      name = "ror({0x12345678, 0x9ABCDEF0}, 16)",
      fn = bit64.ror,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, 16 },
      expected = { 0xDEF01234, 0x56789ABC },
    },

    -- add tests
    { name = "add({0, 0}, {0, 0})", fn = bit64.add, inputs = { { 0, 0 }, { 0, 0 } }, expected = { 0, 0 } },
    { name = "add({0, 1}, {0, 1})", fn = bit64.add, inputs = { { 0, 1 }, { 0, 1 } }, expected = { 0, 2 } },
    {
      name = "add({0, 0xFFFFFFFF}, {0, 1})",
      fn = bit64.add,
      inputs = { { 0, 0xFFFFFFFF }, { 0, 1 } },
      expected = { 1, 0 },
    },
    {
      name = "add({0xFFFFFFFF, 0xFFFFFFFF}, {0, 1})",
      fn = bit64.add,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0, 1 } },
      expected = { 0, 0 },
    },
    {
      name = "add({0xFFFFFFFF, 0xFFFFFFFF}, {0, 2})",
      fn = bit64.add,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0, 2 } },
      expected = { 0, 1 },
    },

    -- u64_to_be_bytes tests
    {
      name = "u64_to_be_bytes({0, 0})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0, 0 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_be_bytes({0, 1})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0, 1 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01),
    },
    {
      name = "u64_to_be_bytes({0x12345678, 0x9ABCDEF0})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0x12345678, 0x9ABCDEF0 } },
      expected = string.char(0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0),
    },

    -- u64_to_le_bytes tests
    {
      name = "u64_to_le_bytes({0, 0})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0, 0 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_le_bytes({0, 1})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0, 1 } },
      expected = string.char(0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_le_bytes({0x12345678, 0x9ABCDEF0})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0x12345678, 0x9ABCDEF0 } },
      expected = string.char(0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12),
    },

    -- be_bytes_to_u64 tests
    {
      name = "be_bytes_to_u64(zeros)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 0 },
    },
    {
      name = "be_bytes_to_u64(one)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01) },
      expected = { 0, 1 },
    },
    {
      name = "be_bytes_to_u64(0x123456789ABCDEF0)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0) },
      expected = { 0x12345678, 0x9ABCDEF0 },
    },

    -- le_bytes_to_u64 tests
    {
      name = "le_bytes_to_u64(zeros)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 0 },
    },
    {
      name = "le_bytes_to_u64(one)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 1 },
    },
    {
      name = "le_bytes_to_u64(0x123456789ABCDEF0)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12) },
      expected = { 0x12345678, 0x9ABCDEF0 },
    },

    -- to_hex tests
    {
      name = "to_hex({0x00001800, 0x00001000})",
      fn = bit64.to_hex,
      inputs = { { 0x00001800, 0x00001000 } },
      expected = "0000180000001000",
    },
    {
      name = "to_hex({0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.to_hex,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = "FFFFFFFFFFFFFFFF",
    },
    {
      name = "to_hex({0x00000000, 0x00000000})",
      fn = bit64.to_hex,
      inputs = { { 0x00000000, 0x00000000 } },
      expected = "0000000000000000",
    },

    -- to_number tests
    {
      name = "to_number({0x00000000, 0x00000001})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000000, 0x00000001) },
      expected = 1,
    },
    {
      name = "to_number({0x00000000, 0xFFFFFFFF})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000000, 0xFFFFFFFF) },
      expected = 4294967295,
    },
    {
      name = "to_number({0x00000001, 0x00000000})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000001, 0x00000000) },
      expected = 4294967296,
    },

    -- from_number tests
    {
      name = "from_number(1)",
      fn = bit64.from_number,
      inputs = { 1 },
      expected = { 0x00000000, 0x00000001 },
    },
    {
      name = "from_number(4294967296)",
      fn = bit64.from_number,
      inputs = { 4294967296 },
      expected = { 0x00000001, 0x00000000 },
    },
    {
      name = "from_number(0)",
      fn = bit64.from_number,
      inputs = { 0 },
      expected = { 0x00000000, 0x00000000 },
    },

    -- eq tests
    { name = "eq({1,2}, {1,2})", fn = bit64.eq, inputs = { { 1, 2 }, { 1, 2 } }, expected = true },
    { name = "eq({1,2}, {1,3})", fn = bit64.eq, inputs = { { 1, 2 }, { 1, 3 } }, expected = false },
    { name = "eq({1,2}, {2,2})", fn = bit64.eq, inputs = { { 1, 2 }, { 2, 2 } }, expected = false },

    -- is_zero tests
    { name = "is_zero({0,0})", fn = bit64.is_zero, inputs = { { 0, 0 } }, expected = true },
    { name = "is_zero({0,1})", fn = bit64.is_zero, inputs = { { 0, 1 } }, expected = false },
    { name = "is_zero({1,0})", fn = bit64.is_zero, inputs = { { 1, 0 } }, expected = false },

    -- to_number strict mode tests (values within 53-bit range)
    {
      name = "to_number({0x001FFFFF, 0xFFFFFFFF}, true) -- max 53-bit",
      fn = bit64.to_number,
      inputs = { bit64.new(0x001FFFFF, 0xFFFFFFFF), true },
      expected = 9007199254740991,
    },
    {
      name = "to_number({0, 1}, true)",
      fn = bit64.to_number,
      inputs = { bit64.new(0, 1), true },
      expected = 1,
    },
  }

  for _, test in ipairs(test_vectors) do
    total = total + 1
    local result = test.fn(unpack_fn(test.inputs))

    if type(test.expected) == "table" then
      -- 64-bit comparison
      if eq64(result, test.expected) then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        print("    Expected: " .. fmt64(test.expected))
        print("    Got:      " .. fmt64(result))
      end
    elseif type(test.expected) == "string" then
      -- Byte string comparison
      if result == test.expected then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        if type(result) ~= "string" then
          print("    Expected: string")
          print("    Got:      " .. type(result))
        else
          local exp_hex, got_hex = "", ""
          for i = 1, #test.expected do
            exp_hex = exp_hex .. string.format("%02X", string.byte(test.expected, i))
          end
          for i = 1, #result do
            got_hex = got_hex .. string.format("%02X", string.byte(result, i))
          end
          print("    Expected: " .. exp_hex)
          print("    Got:      " .. got_hex)
        end
      end
    else
      if result == test.expected then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        print("    Expected: " .. tostring(test.expected))
        print("    Got:      " .. tostring(result))
      end
    end
  end

  -- Int64 type identification tests
  print("\nRunning Int64 type identification tests...")

  -- Test bit64.new() creates Int64 values
  total = total + 1
  local new_val = bit64.new(0x12345678, 0x9ABCDEF0)
  if bit64.is_int64(new_val) and new_val[1] == 0x12345678 and new_val[2] == 0x9ABCDEF0 then
    print("  PASS: new() creates Int64 with correct values")
    passed = passed + 1
  else
    print("  FAIL: new() creates Int64 with correct values")
  end

  -- Test bit64.new() with defaults
  total = total + 1
  local zero_val = bit64.new()
  if bit64.is_int64(zero_val) and zero_val[1] == 0 and zero_val[2] == 0 then
    print("  PASS: new() with no args creates {0, 0}")
    passed = passed + 1
  else
    print("  FAIL: new() with no args creates {0, 0}")
  end

  -- Test is_int64() returns false for regular tables
  total = total + 1
  local plain_table = { 0x12345678, 0x9ABCDEF0 }
  if not bit64.is_int64(plain_table) then
    print("  PASS: is_int64() returns false for plain table")
    passed = passed + 1
  else
    print("  FAIL: is_int64() returns false for plain table")
  end

  -- Test is_int64() returns false for non-tables
  total = total + 1
  if not bit64.is_int64(123) and not bit64.is_int64("string") and not bit64.is_int64(nil) then
    print("  PASS: is_int64() returns false for non-tables")
    passed = passed + 1
  else
    print("  FAIL: is_int64() returns false for non-tables")
  end

  -- Test all operations return Int64 values
  local ops_returning_int64 = {
    {
      name = "band",
      fn = function()
        return bit64.band({ 1, 2 }, { 3, 4 })
      end,
    },
    {
      name = "bor",
      fn = function()
        return bit64.bor({ 1, 2 }, { 3, 4 })
      end,
    },
    {
      name = "bxor",
      fn = function()
        return bit64.bxor({ 1, 2 }, { 3, 4 })
      end,
    },
    {
      name = "bnot",
      fn = function()
        return bit64.bnot({ 1, 2 })
      end,
    },
    {
      name = "lshift",
      fn = function()
        return bit64.lshift({ 1, 2 }, 1)
      end,
    },
    {
      name = "rshift",
      fn = function()
        return bit64.rshift({ 1, 2 }, 1)
      end,
    },
    {
      name = "arshift",
      fn = function()
        return bit64.arshift({ 1, 2 }, 1)
      end,
    },
    {
      name = "rol",
      fn = function()
        return bit64.rol({ 1, 2 }, 1)
      end,
    },
    {
      name = "ror",
      fn = function()
        return bit64.ror({ 1, 2 }, 1)
      end,
    },
    {
      name = "add",
      fn = function()
        return bit64.add({ 1, 2 }, { 3, 4 })
      end,
    },
    {
      name = "be_bytes_to_u64",
      fn = function()
        return bit64.be_bytes_to_u64("\0\0\0\1\0\0\0\2")
      end,
    },
    {
      name = "le_bytes_to_u64",
      fn = function()
        return bit64.le_bytes_to_u64("\2\0\0\0\1\0\0\0")
      end,
    },
  }

  for _, op in ipairs(ops_returning_int64) do
    total = total + 1
    local result = op.fn()
    if bit64.is_int64(result) then
      print("  PASS: " .. op.name .. "() returns Int64")
      passed = passed + 1
    else
      print("  FAIL: " .. op.name .. "() returns Int64")
    end
  end

  -- Test to_number strict mode error case
  print("\nRunning to_number strict mode tests...")
  total = total + 1
  local ok, err = pcall(function()
    bit64.to_number(bit64.new(0x00200000, 0x00000000), true) -- 2^53, exceeds 53-bit
  end)
  if not ok and type(err) == "string" and string.find(err, "53%-bit precision") then
    print("  PASS: to_number strict mode errors on values > 53 bits")
    passed = passed + 1
  else
    print("  FAIL: to_number strict mode errors on values > 53 bits")
    if ok then
      print("    Expected error but got success")
    else
      print("    Expected '53-bit precision' error but got: " .. tostring(err))
    end
  end

  print(string.format("\n64-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

--------------------------------------------------------------------------------
-- Benchmarking
--------------------------------------------------------------------------------

local benchmark_op = require("bitn.utils.benchmark").benchmark_op

--- Run performance benchmarks for 64-bit operations.
function bit64.benchmark()
  local iterations = 100000

  print("64-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a = bit64.new(0xAAAAAAAA, 0x55555555)
  local b = bit64.new(0x55555555, 0xAAAAAAAA)

  benchmark_op("band", function()
    bit64.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit64.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit64.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit64.bnot(a)
  end, iterations)

  print("\n64-bit Shift Operations:")

  benchmark_op("lshift (small)", function()
    bit64.lshift(a, 8)
  end, iterations)

  benchmark_op("lshift (large)", function()
    bit64.lshift(a, 40)
  end, iterations)

  benchmark_op("rshift (small)", function()
    bit64.rshift(a, 8)
  end, iterations)

  benchmark_op("rshift (large)", function()
    bit64.rshift(a, 40)
  end, iterations)

  benchmark_op("arshift", function()
    bit64.arshift(bit64.new(0x80000000, 0), 8)
  end, iterations)

  print("\n64-bit Rotate Operations:")

  benchmark_op("rol (small)", function()
    bit64.rol(a, 8)
  end, iterations)

  benchmark_op("rol (large)", function()
    bit64.rol(a, 40)
  end, iterations)

  benchmark_op("ror (small)", function()
    bit64.ror(a, 8)
  end, iterations)

  benchmark_op("ror (large)", function()
    bit64.ror(a, 40)
  end, iterations)

  print("\n64-bit Arithmetic:")

  benchmark_op("add", function()
    bit64.add(a, b)
  end, iterations)

  benchmark_op("add (with carry)", function()
    bit64.add(bit64.new(0, 0xFFFFFFFF), bit64.new(0, 1))
  end, iterations)

  print("\n64-bit Byte Conversions:")

  local val = bit64.new(0x12345678, 0x9ABCDEF0)
  local bytes_be = bit64.u64_to_be_bytes(val)
  local bytes_le = bit64.u64_to_le_bytes(val)

  benchmark_op("u64_to_be_bytes", function()
    bit64.u64_to_be_bytes(val)
  end, iterations)

  benchmark_op("u64_to_le_bytes", function()
    bit64.u64_to_le_bytes(val)
  end, iterations)

  benchmark_op("be_bytes_to_u64", function()
    bit64.be_bytes_to_u64(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u64", function()
    bit64.le_bytes_to_u64(bytes_le)
  end, iterations)

  print("\n64-bit Utility Functions:")

  benchmark_op("new", function()
    bit64.new(0x12345678, 0x9ABCDEF0)
  end, iterations)

  benchmark_op("is_int64", function()
    bit64.is_int64(a)
  end, iterations)

  benchmark_op("to_hex", function()
    bit64.to_hex(a)
  end, iterations)

  benchmark_op("to_number", function()
    bit64.to_number(a)
  end, iterations)

  benchmark_op("from_number", function()
    bit64.from_number(12345678901234)
  end, iterations)

  benchmark_op("eq", function()
    bit64.eq(a, b)
  end, iterations)

  benchmark_op("is_zero", function()
    bit64.is_zero(a)
  end, iterations)
end

return bit64
