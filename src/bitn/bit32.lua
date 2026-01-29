--- @module "bitn.bit32"
--- 32-bit bitwise operations library.
--- This module provides a complete, version-agnostic implementation of 32-bit
--- bitwise operations that works across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.
--- Uses native bit operations where available for optimal performance.
--- @class bitn.bit32
local bit32 = {}

local _compat = require("bitn._compat")

-- Cache methods as locals for faster access
local compat_arshift = _compat.arshift
local compat_band = _compat.band
local compat_bnot = _compat.bnot
local compat_bor = _compat.bor
local compat_bxor = _compat.bxor
local compat_lshift = _compat.lshift
local compat_raw_arshift = _compat.raw_arshift
local compat_raw_band = _compat.raw_band
local compat_raw_bnot = _compat.raw_bnot
local compat_raw_bor = _compat.raw_bor
local compat_raw_bxor = _compat.raw_bxor
local compat_raw_lshift = _compat.raw_lshift
local compat_raw_rol = _compat.raw_rol
local compat_raw_ror = _compat.raw_ror
local compat_raw_rshift = _compat.raw_rshift
local compat_rshift = _compat.rshift
local compat_to_unsigned = _compat.to_unsigned
local impl_name = _compat.impl_name
local math_floor = math.floor

-- 32-bit mask constant
local MASK32 = 0xFFFFFFFF

--------------------------------------------------------------------------------
-- Core operations
--------------------------------------------------------------------------------

--- Convert signed 32-bit value to unsigned.
--- On LuaJIT, bit operations return signed 32-bit integers. This function
--- converts them to unsigned by adding 2^32 to negative values.
--- @param n number Potentially signed 32-bit value
--- @return integer result Unsigned 32-bit value (0 to 0xFFFFFFFF)
function bit32.to_unsigned(n)
  return compat_to_unsigned(n)
end

--- Ensure value fits in 32-bit unsigned integer.
--- @param n number Input value
--- @return integer result 32-bit unsigned integer (0 to 0xFFFFFFFF)
function bit32.mask(n)
  return compat_band(math_floor(n), MASK32)
end

--- Bitwise AND operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a AND b
function bit32.band(a, b)
  return compat_band(compat_band(a, MASK32), compat_band(b, MASK32))
end

--- Bitwise OR operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a OR b
function bit32.bor(a, b)
  return compat_band(compat_bor(a, b), MASK32)
end

--- Bitwise XOR operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a XOR b
function bit32.bxor(a, b)
  return compat_band(compat_bxor(a, b), MASK32)
end

--- Bitwise NOT operation.
--- @param a integer Operand (32-bit)
--- @return integer result Result of NOT a
function bit32.bnot(a)
  return compat_band(compat_bnot(a), MASK32)
end

--- Left shift operation.
--- @param a integer Value to shift (32-bit)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a << n
function bit32.lshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  if n >= 32 then
    return 0
  end
  return compat_band(compat_lshift(compat_band(a, MASK32), n), MASK32)
end

--- Logical right shift operation (fills with 0s).
--- @param a integer Value to shift (32-bit)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n (logical)
function bit32.rshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  if n >= 32 then
    return 0
  end
  return compat_rshift(compat_band(a, MASK32), n)
end

--- Arithmetic right shift operation (sign-extending, fills with sign bit).
--- @param a integer Value to shift (32-bit, treated as signed)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n with sign extension
function bit32.arshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  return compat_arshift(a, n)
end

--- Left rotate operation.
--- @param x integer Value to rotate (32-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x left by n positions
function bit32.rol(x, n)
  n = n % 32
  x = compat_band(x, MASK32)
  return compat_band(compat_bor(compat_lshift(x, n), compat_rshift(x, 32 - n)), MASK32)
end

--- Right rotate operation.
--- @param x integer Value to rotate (32-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x right by n positions
function bit32.ror(x, n)
  n = n % 32
  x = compat_band(x, MASK32)
  return compat_band(compat_bor(compat_rshift(x, n), compat_lshift(x, 32 - n)), MASK32)
end

--- 32-bit addition with overflow handling.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of (a + b) mod 2^32
function bit32.add(a, b)
  return compat_band(compat_band(a, MASK32) + compat_band(b, MASK32), MASK32)
end

--------------------------------------------------------------------------------
-- Raw (zero-overhead) operations
--------------------------------------------------------------------------------
-- These functions provide direct access to the underlying bit library without
-- unsigned conversion. On LuaJIT, results may be negative when the high bit
-- is set. The bit pattern is identical to the regular function.
-- Use for performance-critical code where sign interpretation doesn't matter.

--- Raw bitwise AND (may return signed on LuaJIT).
--- @type fun(a: integer, b: integer): integer
--- @see bit32.band For guaranteed unsigned results
bit32.raw_band = compat_raw_band

--- Raw bitwise OR (may return signed on LuaJIT).
--- @type fun(a: integer, b: integer): integer
--- @see bit32.bor For guaranteed unsigned results
bit32.raw_bor = compat_raw_bor

--- Raw bitwise XOR (may return signed on LuaJIT).
--- @type fun(a: integer, b: integer): integer
--- @see bit32.bxor For guaranteed unsigned results
bit32.raw_bxor = compat_raw_bxor

--- Raw bitwise NOT (may return signed on LuaJIT).
--- @type fun(a: integer): integer
--- @see bit32.bnot For guaranteed unsigned results
bit32.raw_bnot = compat_raw_bnot

--- Raw left shift (may return signed on LuaJIT).
--- @type fun(a: integer, n: integer): integer
--- @see bit32.lshift For guaranteed unsigned results
bit32.raw_lshift = compat_raw_lshift

--- Raw logical right shift (may return signed on LuaJIT).
--- @type fun(a: integer, n: integer): integer
--- @see bit32.rshift For guaranteed unsigned results
bit32.raw_rshift = compat_raw_rshift

--- Raw arithmetic right shift (may return signed on LuaJIT).
--- @type fun(a: integer, n: integer): integer
--- @see bit32.arshift For guaranteed unsigned results
bit32.raw_arshift = compat_raw_arshift

--- Raw left rotate (uses native bit.rol on LuaJIT, falls back to computed otherwise).
--- @type fun(x: integer, n: integer): integer
--- @see bit32.rol For guaranteed unsigned results
bit32.raw_rol = compat_raw_rol or bit32.rol

--- Raw right rotate (uses native bit.ror on LuaJIT, falls back to computed otherwise).
--- @type fun(x: integer, n: integer): integer
--- @see bit32.ror For guaranteed unsigned results
bit32.raw_ror = compat_raw_ror or bit32.ror

--- Raw 32-bit addition with overflow handling.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of (a + b) mod 2^32 (signed on LuaJIT, unsigned elsewhere)
--- @see bit32.add For guaranteed unsigned results
function bit32.raw_add(a, b)
  return compat_raw_band(a + b, MASK32)
end

--------------------------------------------------------------------------------
-- Byte conversion functions
--------------------------------------------------------------------------------

local string_char = string.char
local string_byte = string.byte

--- Convert 32-bit unsigned integer to 4 bytes (big-endian).
--- @param n integer 32-bit unsigned integer
--- @return string bytes 4-byte string in big-endian order
function bit32.u32_to_be_bytes(n)
  n = compat_band(n, MASK32)
  return string_char(
    math_floor(n / 16777216) % 256,
    math_floor(n / 65536) % 256,
    math_floor(n / 256) % 256,
    math_floor(n % 256)
  )
end

--- Convert 32-bit unsigned integer to 4 bytes (little-endian).
--- @param n integer 32-bit unsigned integer
--- @return string bytes 4-byte string in little-endian order
function bit32.u32_to_le_bytes(n)
  n = compat_band(n, MASK32)
  return string_char(
    math_floor(n % 256),
    math_floor(n / 256) % 256,
    math_floor(n / 65536) % 256,
    math_floor(n / 16777216) % 256
  )
end

--- Convert 4 bytes to 32-bit unsigned integer (big-endian).
--- @param str string Binary string (at least 4 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 32-bit unsigned integer
function bit32.be_bytes_to_u32(str, offset)
  offset = offset or 1
  assert(#str >= offset + 3, "Insufficient bytes for u32")
  local b1, b2, b3, b4 = string_byte(str, offset, offset + 3)
  return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
end

--- Convert 4 bytes to 32-bit unsigned integer (little-endian).
--- @param str string Binary string (at least 4 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 32-bit unsigned integer
function bit32.le_bytes_to_u32(str, offset)
  offset = offset or 1
  assert(#str >= offset + 3, "Insufficient bytes for u32")
  local b1, b2, b3, b4 = string_byte(str, offset, offset + 3)
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

--------------------------------------------------------------------------------
-- Self-test
--------------------------------------------------------------------------------

-- Compatibility for unpack
local unpack_fn = unpack or table.unpack

--- Run comprehensive self-test with test vectors.
--- @return boolean result True if all tests pass, false otherwise
function bit32.selftest()
  print("Running 32-bit operations test vectors...")
  print(string.format("  Using: %s", impl_name()))
  local passed = 0
  local total = 0

  local test_vectors = {
    -- mask tests
    { name = "mask(0)", fn = bit32.mask, inputs = { 0 }, expected = 0 },
    { name = "mask(1)", fn = bit32.mask, inputs = { 1 }, expected = 1 },
    { name = "mask(0xFFFFFFFF)", fn = bit32.mask, inputs = { 0xFFFFFFFF }, expected = 0xFFFFFFFF },
    { name = "mask(0x100000000)", fn = bit32.mask, inputs = { 0x100000000 }, expected = 0 },
    { name = "mask(0x100000001)", fn = bit32.mask, inputs = { 0x100000001 }, expected = 1 },
    { name = "mask(-1)", fn = bit32.mask, inputs = { -1 }, expected = 0xFFFFFFFF },
    { name = "mask(-256)", fn = bit32.mask, inputs = { -256 }, expected = 0xFFFFFF00 },

    -- to_unsigned tests
    { name = "to_unsigned(0)", fn = bit32.to_unsigned, inputs = { 0 }, expected = 0 },
    { name = "to_unsigned(1)", fn = bit32.to_unsigned, inputs = { 1 }, expected = 1 },
    { name = "to_unsigned(0x7FFFFFFF)", fn = bit32.to_unsigned, inputs = { 0x7FFFFFFF }, expected = 0x7FFFFFFF },
    { name = "to_unsigned(-1)", fn = bit32.to_unsigned, inputs = { -1 }, expected = 0xFFFFFFFF },
    { name = "to_unsigned(-2147483648)", fn = bit32.to_unsigned, inputs = { -2147483648 }, expected = 0x80000000 },
    { name = "to_unsigned(-2147483647)", fn = bit32.to_unsigned, inputs = { -2147483647 }, expected = 0x80000001 },

    -- band tests
    { name = "band(0xFF00FF00, 0x00FF00FF)", fn = bit32.band, inputs = { 0xFF00FF00, 0x00FF00FF }, expected = 0 },
    {
      name = "band(0xFFFFFFFF, 0xFFFFFFFF)",
      fn = bit32.band,
      inputs = { 0xFFFFFFFF, 0xFFFFFFFF },
      expected = 0xFFFFFFFF,
    },
    { name = "band(0xAAAAAAAA, 0x55555555)", fn = bit32.band, inputs = { 0xAAAAAAAA, 0x55555555 }, expected = 0 },
    {
      name = "band(0xF0F0F0F0, 0xFF00FF00)",
      fn = bit32.band,
      inputs = { 0xF0F0F0F0, 0xFF00FF00 },
      expected = 0xF000F000,
    },
    { name = "band(0, 0xFFFFFFFF)", fn = bit32.band, inputs = { 0, 0xFFFFFFFF }, expected = 0 },

    -- bor tests
    {
      name = "bor(0xFF00FF00, 0x00FF00FF)",
      fn = bit32.bor,
      inputs = { 0xFF00FF00, 0x00FF00FF },
      expected = 0xFFFFFFFF,
    },
    { name = "bor(0, 0)", fn = bit32.bor, inputs = { 0, 0 }, expected = 0 },
    {
      name = "bor(0xAAAAAAAA, 0x55555555)",
      fn = bit32.bor,
      inputs = { 0xAAAAAAAA, 0x55555555 },
      expected = 0xFFFFFFFF,
    },
    {
      name = "bor(0xF0F0F0F0, 0x0F0F0F0F)",
      fn = bit32.bor,
      inputs = { 0xF0F0F0F0, 0x0F0F0F0F },
      expected = 0xFFFFFFFF,
    },

    -- bxor tests
    {
      name = "bxor(0xFF00FF00, 0x00FF00FF)",
      fn = bit32.bxor,
      inputs = { 0xFF00FF00, 0x00FF00FF },
      expected = 0xFFFFFFFF,
    },
    { name = "bxor(0xFFFFFFFF, 0xFFFFFFFF)", fn = bit32.bxor, inputs = { 0xFFFFFFFF, 0xFFFFFFFF }, expected = 0 },
    {
      name = "bxor(0xAAAAAAAA, 0x55555555)",
      fn = bit32.bxor,
      inputs = { 0xAAAAAAAA, 0x55555555 },
      expected = 0xFFFFFFFF,
    },
    { name = "bxor(0x12345678, 0x12345678)", fn = bit32.bxor, inputs = { 0x12345678, 0x12345678 }, expected = 0 },

    -- bnot tests
    { name = "bnot(0)", fn = bit32.bnot, inputs = { 0 }, expected = 0xFFFFFFFF },
    { name = "bnot(0xFFFFFFFF)", fn = bit32.bnot, inputs = { 0xFFFFFFFF }, expected = 0 },
    { name = "bnot(0xAAAAAAAA)", fn = bit32.bnot, inputs = { 0xAAAAAAAA }, expected = 0x55555555 },
    { name = "bnot(0x12345678)", fn = bit32.bnot, inputs = { 0x12345678 }, expected = 0xEDCBA987 },

    -- lshift tests
    { name = "lshift(1, 0)", fn = bit32.lshift, inputs = { 1, 0 }, expected = 1 },
    { name = "lshift(1, 1)", fn = bit32.lshift, inputs = { 1, 1 }, expected = 2 },
    { name = "lshift(1, 31)", fn = bit32.lshift, inputs = { 1, 31 }, expected = 0x80000000 },
    { name = "lshift(1, 32)", fn = bit32.lshift, inputs = { 1, 32 }, expected = 0 },
    { name = "lshift(0xFF, 8)", fn = bit32.lshift, inputs = { 0xFF, 8 }, expected = 0xFF00 },
    { name = "lshift(0x80000000, 1)", fn = bit32.lshift, inputs = { 0x80000000, 1 }, expected = 0 },

    -- rshift tests
    { name = "rshift(1, 0)", fn = bit32.rshift, inputs = { 1, 0 }, expected = 1 },
    { name = "rshift(2, 1)", fn = bit32.rshift, inputs = { 2, 1 }, expected = 1 },
    { name = "rshift(0x80000000, 31)", fn = bit32.rshift, inputs = { 0x80000000, 31 }, expected = 1 },
    { name = "rshift(0x80000000, 32)", fn = bit32.rshift, inputs = { 0x80000000, 32 }, expected = 0 },
    { name = "rshift(0xFF00, 8)", fn = bit32.rshift, inputs = { 0xFF00, 8 }, expected = 0xFF },
    { name = "rshift(0xFFFFFFFF, 16)", fn = bit32.rshift, inputs = { 0xFFFFFFFF, 16 }, expected = 0xFFFF },

    -- arshift tests (arithmetic shift - sign extending)
    { name = "arshift(0x80000000, 1)", fn = bit32.arshift, inputs = { 0x80000000, 1 }, expected = 0xC0000000 },
    { name = "arshift(0x80000000, 31)", fn = bit32.arshift, inputs = { 0x80000000, 31 }, expected = 0xFFFFFFFF },
    { name = "arshift(0x80000000, 32)", fn = bit32.arshift, inputs = { 0x80000000, 32 }, expected = 0xFFFFFFFF },
    { name = "arshift(0x7FFFFFFF, 1)", fn = bit32.arshift, inputs = { 0x7FFFFFFF, 1 }, expected = 0x3FFFFFFF },
    { name = "arshift(0x7FFFFFFF, 31)", fn = bit32.arshift, inputs = { 0x7FFFFFFF, 31 }, expected = 0 },
    { name = "arshift(0xFF000000, 8)", fn = bit32.arshift, inputs = { 0xFF000000, 8 }, expected = 0xFFFF0000 },
    { name = "arshift(0x0F000000, 8)", fn = bit32.arshift, inputs = { 0x0F000000, 8 }, expected = 0x000F0000 },

    -- rol tests
    { name = "rol(1, 0)", fn = bit32.rol, inputs = { 1, 0 }, expected = 1 },
    { name = "rol(1, 1)", fn = bit32.rol, inputs = { 1, 1 }, expected = 2 },
    { name = "rol(0x80000000, 1)", fn = bit32.rol, inputs = { 0x80000000, 1 }, expected = 1 },
    { name = "rol(1, 32)", fn = bit32.rol, inputs = { 1, 32 }, expected = 1 },
    { name = "rol(0x12345678, 8)", fn = bit32.rol, inputs = { 0x12345678, 8 }, expected = 0x34567812 },
    { name = "rol(0x12345678, 16)", fn = bit32.rol, inputs = { 0x12345678, 16 }, expected = 0x56781234 },

    -- ror tests
    { name = "ror(1, 0)", fn = bit32.ror, inputs = { 1, 0 }, expected = 1 },
    { name = "ror(1, 1)", fn = bit32.ror, inputs = { 1, 1 }, expected = 0x80000000 },
    { name = "ror(2, 1)", fn = bit32.ror, inputs = { 2, 1 }, expected = 1 },
    { name = "ror(1, 32)", fn = bit32.ror, inputs = { 1, 32 }, expected = 1 },
    { name = "ror(0x12345678, 8)", fn = bit32.ror, inputs = { 0x12345678, 8 }, expected = 0x78123456 },
    { name = "ror(0x12345678, 16)", fn = bit32.ror, inputs = { 0x12345678, 16 }, expected = 0x56781234 },

    -- add tests
    { name = "add(0, 0)", fn = bit32.add, inputs = { 0, 0 }, expected = 0 },
    { name = "add(1, 1)", fn = bit32.add, inputs = { 1, 1 }, expected = 2 },
    { name = "add(0xFFFFFFFF, 1)", fn = bit32.add, inputs = { 0xFFFFFFFF, 1 }, expected = 0 },
    { name = "add(0xFFFFFFFF, 2)", fn = bit32.add, inputs = { 0xFFFFFFFF, 2 }, expected = 1 },
    { name = "add(0x80000000, 0x80000000)", fn = bit32.add, inputs = { 0x80000000, 0x80000000 }, expected = 0 },

    -- u32_to_be_bytes tests
    {
      name = "u32_to_be_bytes(0)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0 },
      expected = string_char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_be_bytes(1)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 1 },
      expected = string_char(0x00, 0x00, 0x00, 0x01),
    },
    {
      name = "u32_to_be_bytes(0x12345678)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0x12345678 },
      expected = string_char(0x12, 0x34, 0x56, 0x78),
    },
    {
      name = "u32_to_be_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string_char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- u32_to_le_bytes tests
    {
      name = "u32_to_le_bytes(0)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0 },
      expected = string_char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(1)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 1 },
      expected = string_char(0x01, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(0x12345678)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0x12345678 },
      expected = string_char(0x78, 0x56, 0x34, 0x12),
    },
    {
      name = "u32_to_le_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string_char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- be_bytes_to_u32 tests
    {
      name = "be_bytes_to_u32(0x00000000)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "be_bytes_to_u32(0x00000001)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x01) },
      expected = 1,
    },
    {
      name = "be_bytes_to_u32(0x12345678)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x12, 0x34, 0x56, 0x78) },
      expected = 0x12345678,
    },
    {
      name = "be_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0xFF, 0xFF, 0xFF, 0xFF) },
      expected = 0xFFFFFFFF,
    },

    -- le_bytes_to_u32 tests
    {
      name = "le_bytes_to_u32(0x00000000)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "le_bytes_to_u32(0x00000001)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x01, 0x00, 0x00, 0x00) },
      expected = 1,
    },
    {
      name = "le_bytes_to_u32(0x12345678)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x78, 0x56, 0x34, 0x12) },
      expected = 0x12345678,
    },
    {
      name = "le_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0xFF, 0xFF, 0xFF, 0xFF) },
      expected = 0xFFFFFFFF,
    },
  }

  for _, test in ipairs(test_vectors) do
    total = total + 1
    local result = test.fn(unpack_fn(test.inputs))
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      if type(test.expected) == "string" then
        local exp_hex, got_hex = "", ""
        for i = 1, #test.expected do
          exp_hex = exp_hex .. string.format("%02X", string_byte(test.expected, i))
        end
        for i = 1, #result do
          got_hex = got_hex .. string.format("%02X", string_byte(result, i))
        end
        print("    Expected: " .. exp_hex)
        print("    Got:      " .. got_hex)
      else
        print(string.format("    Expected: 0x%08X", test.expected))
        print(string.format("    Got:      0x%08X", result))
      end
    end
  end

  -- Test raw_* operations
  print("\n  Testing raw_* operations...")

  local raw_tests = {
    -- Core bitwise (test high-bit cases where sign matters)
    {
      name = "raw_band(0xFFFFFFFF, 0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_band(0xFFFFFFFF, 0x80000000))
      end,
      expected = bit32.band(0xFFFFFFFF, 0x80000000),
    },
    {
      name = "raw_bor(0x80000000, 0x00000001)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bor(0x80000000, 0x00000001))
      end,
      expected = bit32.bor(0x80000000, 0x00000001),
    },
    {
      name = "raw_bxor(0xAAAAAAAA, 0x55555555)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bxor(0xAAAAAAAA, 0x55555555))
      end,
      expected = bit32.bxor(0xAAAAAAAA, 0x55555555),
    },
    {
      name = "raw_bnot(0)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bnot(0))
      end,
      expected = bit32.bnot(0),
    },
    {
      name = "raw_bnot(0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bnot(0x80000000))
      end,
      expected = bit32.bnot(0x80000000),
    },

    -- Shifts
    {
      name = "raw_lshift(1, 31)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_lshift(1, 31))
      end,
      expected = bit32.lshift(1, 31),
    },
    {
      name = "raw_rshift(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rshift(0x80000000, 1))
      end,
      expected = bit32.rshift(0x80000000, 1),
    },
    {
      name = "raw_arshift(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_arshift(0x80000000, 1))
      end,
      expected = bit32.arshift(0x80000000, 1),
    },

    -- Shift masking (ensure 32-bit semantics on all platforms)
    -- Note: n >= 32 behavior is platform-specific for raw shifts; callers should use n in 0-31
    {
      name = "raw_lshift(0x12345678, 16) masks to 32 bits",
      fn = function()
        return bit32.to_unsigned(bit32.raw_lshift(0x12345678, 16))
      end,
      expected = 0x56780000,
    },
    {
      name = "raw_rshift(0xFFFFFFFF, 16) masks to 32 bits",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rshift(0xFFFFFFFF, 16))
      end,
      expected = 0x0000FFFF,
    },

    -- Addition overflow
    {
      name = "raw_add(0xFFFFFFFF, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_add(0xFFFFFFFF, 1))
      end,
      expected = bit32.add(0xFFFFFFFF, 1),
    },
    {
      name = "raw_add(0x80000000, 0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_add(0x80000000, 0x80000000))
      end,
      expected = bit32.add(0x80000000, 0x80000000),
    },
  }

  for _, test in ipairs(raw_tests) do
    total = total + 1
    local result = test.fn()
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      print(string.format("    Expected: 0x%08X", test.expected))
      print(string.format("    Got:      0x%08X", result))
    end
  end

  -- Test raw_rol/raw_ror (always available - falls back to computed if no native)
  print("\n  Testing raw_rol/raw_ror...")
  local rol_ror_tests = {
    {
      name = "raw_rol(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rol(0x80000000, 1))
      end,
      expected = bit32.rol(0x80000000, 1),
    },
    {
      name = "raw_rol(0x12345678, 8)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rol(0x12345678, 8))
      end,
      expected = bit32.rol(0x12345678, 8),
    },
    {
      name = "raw_ror(1, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_ror(1, 1))
      end,
      expected = bit32.ror(1, 1),
    },
    {
      name = "raw_ror(0x12345678, 8)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_ror(0x12345678, 8))
      end,
      expected = bit32.ror(0x12345678, 8),
    },
  }

  for _, test in ipairs(rol_ror_tests) do
    total = total + 1
    local result = test.fn()
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      print(string.format("    Expected: 0x%08X", test.expected))
      print(string.format("    Got:      0x%08X", result))
    end
  end

  -- Test zero-overhead on LuaJIT (identity check)
  if _compat.is_luajit then
    print("\n  Testing zero-overhead (LuaJIT function identity)...")
    local bit = require("bit")

    local identity_tests = {
      { name = "raw_band == bit.band", got = bit32.raw_band, expected = bit.band },
      { name = "raw_bor == bit.bor", got = bit32.raw_bor, expected = bit.bor },
      { name = "raw_bxor == bit.bxor", got = bit32.raw_bxor, expected = bit.bxor },
      { name = "raw_bnot == bit.bnot", got = bit32.raw_bnot, expected = bit.bnot },
      { name = "raw_lshift == bit.lshift", got = bit32.raw_lshift, expected = bit.lshift },
      { name = "raw_rshift == bit.rshift", got = bit32.raw_rshift, expected = bit.rshift },
      { name = "raw_arshift == bit.arshift", got = bit32.raw_arshift, expected = bit.arshift },
      { name = "raw_rol == bit.rol", got = bit32.raw_rol, expected = bit.rol },
      { name = "raw_ror == bit.ror", got = bit32.raw_ror, expected = bit.ror },
    }

    for _, test in ipairs(identity_tests) do
      total = total + 1
      if rawequal(test.got, test.expected) then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name .. " (not identical function reference)")
      end
    end
  end

  print(string.format("\n32-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

--------------------------------------------------------------------------------
-- Benchmarking
--------------------------------------------------------------------------------

local benchmark_op = require("bitn.utils.benchmark").benchmark_op

--- Run performance benchmarks for 32-bit operations.
function bit32.benchmark()
  local iterations = 100000

  print("32-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a, b = 0xAAAAAAAA, 0x55555555

  benchmark_op("band", function()
    bit32.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit32.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit32.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit32.bnot(a)
  end, iterations)

  print("\n32-bit Shift Operations:")

  benchmark_op("lshift", function()
    bit32.lshift(a, 8)
  end, iterations)

  benchmark_op("rshift", function()
    bit32.rshift(a, 8)
  end, iterations)

  benchmark_op("arshift", function()
    bit32.arshift(0x80000000, 8)
  end, iterations)

  print("\n32-bit Rotate Operations:")

  benchmark_op("rol", function()
    bit32.rol(a, 8)
  end, iterations)

  benchmark_op("ror", function()
    bit32.ror(a, 8)
  end, iterations)

  print("\n32-bit Arithmetic:")

  benchmark_op("add", function()
    bit32.add(a, b)
  end, iterations)

  benchmark_op("mask", function()
    bit32.mask(0x123456789)
  end, iterations)

  print("\n32-bit Byte Conversions:")

  local bytes_be = bit32.u32_to_be_bytes(0x12345678)
  local bytes_le = bit32.u32_to_le_bytes(0x12345678)

  benchmark_op("u32_to_be_bytes", function()
    bit32.u32_to_be_bytes(0x12345678)
  end, iterations)

  benchmark_op("u32_to_le_bytes", function()
    bit32.u32_to_le_bytes(0x12345678)
  end, iterations)

  benchmark_op("be_bytes_to_u32", function()
    bit32.be_bytes_to_u32(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u32", function()
    bit32.le_bytes_to_u32(bytes_le)
  end, iterations)
end

return bit32
