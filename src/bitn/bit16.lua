--- @module "bitn.bit16"
--- 16-bit bitwise operations library.
--- This module provides a complete, version-agnostic implementation of 16-bit
--- bitwise operations that works across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.
--- Uses native bit operations where available for optimal performance.
--- @class bitn.bit16
local bit16 = {}

local _compat = require("bitn._compat")

-- Cache methods as locals for faster access
local compat_band = _compat.band
local compat_bnot = _compat.bnot
local compat_bor = _compat.bor
local compat_bxor = _compat.bxor
local compat_lshift = _compat.lshift
local compat_rshift = _compat.rshift
local impl_name = _compat.impl_name
local math_floor = math.floor

-- 16-bit mask constant
local MASK16 = 0xFFFF

--------------------------------------------------------------------------------
-- Core operations
--------------------------------------------------------------------------------

--- Ensure value fits in 16-bit unsigned integer.
--- @param n number Input value
--- @return integer result 16-bit unsigned integer (0 to 0xFFFF)
function bit16.mask(n)
  return compat_band(math_floor(n), MASK16)
end

--- Bitwise AND operation.
--- @param a integer First operand (16-bit)
--- @param b integer Second operand (16-bit)
--- @return integer result Result of a AND b
function bit16.band(a, b)
  return compat_band(compat_band(a, MASK16), compat_band(b, MASK16))
end

--- Bitwise OR operation.
--- @param a integer First operand (16-bit)
--- @param b integer Second operand (16-bit)
--- @return integer result Result of a OR b
function bit16.bor(a, b)
  return compat_band(compat_bor(a, b), MASK16)
end

--- Bitwise XOR operation.
--- @param a integer First operand (16-bit)
--- @param b integer Second operand (16-bit)
--- @return integer result Result of a XOR b
function bit16.bxor(a, b)
  return compat_band(compat_bxor(a, b), MASK16)
end

--- Bitwise NOT operation.
--- @param a integer Operand (16-bit)
--- @return integer result Result of NOT a
function bit16.bnot(a)
  return compat_band(compat_bnot(a), MASK16)
end

--- Left shift operation.
--- @param a integer Value to shift (16-bit)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a << n
function bit16.lshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  if n >= 16 then
    return 0
  end
  return compat_band(compat_lshift(compat_band(a, MASK16), n), MASK16)
end

--- Logical right shift operation (fills with 0s).
--- @param a integer Value to shift (16-bit)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n (logical)
function bit16.rshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  if n >= 16 then
    return 0
  end
  return compat_rshift(compat_band(a, MASK16), n)
end

--- Arithmetic right shift operation (sign-extending, fills with sign bit).
--- @param a integer Value to shift (16-bit, treated as signed)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n with sign extension
function bit16.arshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  a = compat_band(a, MASK16)

  -- Check if sign bit is set (bit 15)
  local is_negative = a >= 0x8000

  if n >= 16 then
    return is_negative and MASK16 or 0
  end

  -- Perform logical right shift
  local result = compat_rshift(a, n)

  -- If original was negative, fill high bits with 1s
  if is_negative then
    local fill_mask = compat_band(compat_lshift(MASK16, 16 - n), MASK16)
    result = compat_bor(result, fill_mask)
  end

  return compat_band(result, MASK16)
end

--- Left rotate operation.
--- @param x integer Value to rotate (16-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x left by n positions
function bit16.rol(x, n)
  n = n % 16
  x = compat_band(x, MASK16)
  return compat_band(compat_bor(compat_lshift(x, n), compat_rshift(x, 16 - n)), MASK16)
end

--- Right rotate operation.
--- @param x integer Value to rotate (16-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x right by n positions
function bit16.ror(x, n)
  n = n % 16
  x = compat_band(x, MASK16)
  return compat_band(compat_bor(compat_rshift(x, n), compat_lshift(x, 16 - n)), MASK16)
end

--- 16-bit addition with overflow handling.
--- @param a integer First operand (16-bit)
--- @param b integer Second operand (16-bit)
--- @return integer result Result of (a + b) mod 2^16
function bit16.add(a, b)
  return compat_band(compat_band(a, MASK16) + compat_band(b, MASK16), MASK16)
end

--------------------------------------------------------------------------------
-- Byte conversion functions
--------------------------------------------------------------------------------

local string_char = string.char
local string_byte = string.byte

--- Convert 16-bit unsigned integer to 2 bytes (big-endian).
--- @param n integer 16-bit unsigned integer
--- @return string bytes 2-byte string in big-endian order
function bit16.u16_to_be_bytes(n)
  n = compat_band(n, MASK16)
  return string_char(math_floor(n / 256), n % 256)
end

--- Convert 16-bit unsigned integer to 2 bytes (little-endian).
--- @param n integer 16-bit unsigned integer
--- @return string bytes 2-byte string in little-endian order
function bit16.u16_to_le_bytes(n)
  n = compat_band(n, MASK16)
  return string_char(n % 256, math_floor(n / 256))
end

--- Convert 2 bytes to 16-bit unsigned integer (big-endian).
--- @param str string Binary string (at least 2 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 16-bit unsigned integer
function bit16.be_bytes_to_u16(str, offset)
  offset = offset or 1
  assert(#str >= offset + 1, "Insufficient bytes for u16")
  local b1, b2 = string_byte(str, offset, offset + 1)
  return b1 * 256 + b2
end

--- Convert 2 bytes to 16-bit unsigned integer (little-endian).
--- @param str string Binary string (at least 2 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 16-bit unsigned integer
function bit16.le_bytes_to_u16(str, offset)
  offset = offset or 1
  assert(#str >= offset + 1, "Insufficient bytes for u16")
  local b1, b2 = string_byte(str, offset, offset + 1)
  return b1 + b2 * 256
end

--------------------------------------------------------------------------------
-- Self-test
--------------------------------------------------------------------------------

-- Compatibility for unpack
local unpack_fn = unpack or table.unpack

--- Run comprehensive self-test with test vectors.
--- @return boolean result True if all tests pass, false otherwise
function bit16.selftest()
  print("Running 16-bit operations test vectors...")
  print(string.format("  Using: %s", impl_name()))
  local passed = 0
  local total = 0

  local test_vectors = {
    -- mask tests
    { name = "mask(0)", fn = bit16.mask, inputs = { 0 }, expected = 0 },
    { name = "mask(1)", fn = bit16.mask, inputs = { 1 }, expected = 1 },
    { name = "mask(0xFFFF)", fn = bit16.mask, inputs = { 0xFFFF }, expected = 0xFFFF },
    { name = "mask(0x10000)", fn = bit16.mask, inputs = { 0x10000 }, expected = 0 },
    { name = "mask(0x10001)", fn = bit16.mask, inputs = { 0x10001 }, expected = 1 },
    { name = "mask(-1)", fn = bit16.mask, inputs = { -1 }, expected = 0xFFFF },
    { name = "mask(-256)", fn = bit16.mask, inputs = { -256 }, expected = 0xFF00 },

    -- band tests
    { name = "band(0xFF00, 0x00FF)", fn = bit16.band, inputs = { 0xFF00, 0x00FF }, expected = 0 },
    { name = "band(0xFFFF, 0xFFFF)", fn = bit16.band, inputs = { 0xFFFF, 0xFFFF }, expected = 0xFFFF },
    { name = "band(0xAAAA, 0x5555)", fn = bit16.band, inputs = { 0xAAAA, 0x5555 }, expected = 0 },
    { name = "band(0xF0F0, 0xFF00)", fn = bit16.band, inputs = { 0xF0F0, 0xFF00 }, expected = 0xF000 },

    -- bor tests
    { name = "bor(0xFF00, 0x00FF)", fn = bit16.bor, inputs = { 0xFF00, 0x00FF }, expected = 0xFFFF },
    { name = "bor(0, 0)", fn = bit16.bor, inputs = { 0, 0 }, expected = 0 },
    { name = "bor(0xAAAA, 0x5555)", fn = bit16.bor, inputs = { 0xAAAA, 0x5555 }, expected = 0xFFFF },

    -- bxor tests
    { name = "bxor(0xFF00, 0x00FF)", fn = bit16.bxor, inputs = { 0xFF00, 0x00FF }, expected = 0xFFFF },
    { name = "bxor(0xFFFF, 0xFFFF)", fn = bit16.bxor, inputs = { 0xFFFF, 0xFFFF }, expected = 0 },
    { name = "bxor(0xAAAA, 0x5555)", fn = bit16.bxor, inputs = { 0xAAAA, 0x5555 }, expected = 0xFFFF },
    { name = "bxor(0x1234, 0x1234)", fn = bit16.bxor, inputs = { 0x1234, 0x1234 }, expected = 0 },

    -- bnot tests
    { name = "bnot(0)", fn = bit16.bnot, inputs = { 0 }, expected = 0xFFFF },
    { name = "bnot(0xFFFF)", fn = bit16.bnot, inputs = { 0xFFFF }, expected = 0 },
    { name = "bnot(0xAAAA)", fn = bit16.bnot, inputs = { 0xAAAA }, expected = 0x5555 },
    { name = "bnot(0x1234)", fn = bit16.bnot, inputs = { 0x1234 }, expected = 0xEDCB },

    -- lshift tests
    { name = "lshift(1, 0)", fn = bit16.lshift, inputs = { 1, 0 }, expected = 1 },
    { name = "lshift(1, 1)", fn = bit16.lshift, inputs = { 1, 1 }, expected = 2 },
    { name = "lshift(1, 15)", fn = bit16.lshift, inputs = { 1, 15 }, expected = 0x8000 },
    { name = "lshift(1, 16)", fn = bit16.lshift, inputs = { 1, 16 }, expected = 0 },
    { name = "lshift(0xFF, 8)", fn = bit16.lshift, inputs = { 0xFF, 8 }, expected = 0xFF00 },
    { name = "lshift(0x8000, 1)", fn = bit16.lshift, inputs = { 0x8000, 1 }, expected = 0 },

    -- rshift tests
    { name = "rshift(1, 0)", fn = bit16.rshift, inputs = { 1, 0 }, expected = 1 },
    { name = "rshift(2, 1)", fn = bit16.rshift, inputs = { 2, 1 }, expected = 1 },
    { name = "rshift(0x8000, 15)", fn = bit16.rshift, inputs = { 0x8000, 15 }, expected = 1 },
    { name = "rshift(0x8000, 16)", fn = bit16.rshift, inputs = { 0x8000, 16 }, expected = 0 },
    { name = "rshift(0xFF00, 8)", fn = bit16.rshift, inputs = { 0xFF00, 8 }, expected = 0xFF },
    { name = "rshift(0xFFFF, 8)", fn = bit16.rshift, inputs = { 0xFFFF, 8 }, expected = 0xFF },

    -- arshift tests (arithmetic shift - sign extending)
    { name = "arshift(0x8000, 1)", fn = bit16.arshift, inputs = { 0x8000, 1 }, expected = 0xC000 },
    { name = "arshift(0x8000, 15)", fn = bit16.arshift, inputs = { 0x8000, 15 }, expected = 0xFFFF },
    { name = "arshift(0x8000, 16)", fn = bit16.arshift, inputs = { 0x8000, 16 }, expected = 0xFFFF },
    { name = "arshift(0x7FFF, 1)", fn = bit16.arshift, inputs = { 0x7FFF, 1 }, expected = 0x3FFF },
    { name = "arshift(0x7FFF, 15)", fn = bit16.arshift, inputs = { 0x7FFF, 15 }, expected = 0 },
    { name = "arshift(0xFF00, 8)", fn = bit16.arshift, inputs = { 0xFF00, 8 }, expected = 0xFFFF },
    { name = "arshift(0x0F00, 8)", fn = bit16.arshift, inputs = { 0x0F00, 8 }, expected = 0x000F },

    -- rol tests
    { name = "rol(1, 0)", fn = bit16.rol, inputs = { 1, 0 }, expected = 1 },
    { name = "rol(1, 1)", fn = bit16.rol, inputs = { 1, 1 }, expected = 2 },
    { name = "rol(0x8000, 1)", fn = bit16.rol, inputs = { 0x8000, 1 }, expected = 1 },
    { name = "rol(1, 16)", fn = bit16.rol, inputs = { 1, 16 }, expected = 1 },
    { name = "rol(0x1234, 8)", fn = bit16.rol, inputs = { 0x1234, 8 }, expected = 0x3412 },
    { name = "rol(0x1234, 4)", fn = bit16.rol, inputs = { 0x1234, 4 }, expected = 0x2341 },

    -- ror tests
    { name = "ror(1, 0)", fn = bit16.ror, inputs = { 1, 0 }, expected = 1 },
    { name = "ror(1, 1)", fn = bit16.ror, inputs = { 1, 1 }, expected = 0x8000 },
    { name = "ror(2, 1)", fn = bit16.ror, inputs = { 2, 1 }, expected = 1 },
    { name = "ror(1, 16)", fn = bit16.ror, inputs = { 1, 16 }, expected = 1 },
    { name = "ror(0x1234, 8)", fn = bit16.ror, inputs = { 0x1234, 8 }, expected = 0x3412 },
    { name = "ror(0x1234, 4)", fn = bit16.ror, inputs = { 0x1234, 4 }, expected = 0x4123 },

    -- add tests
    { name = "add(0, 0)", fn = bit16.add, inputs = { 0, 0 }, expected = 0 },
    { name = "add(1, 1)", fn = bit16.add, inputs = { 1, 1 }, expected = 2 },
    { name = "add(0xFFFF, 1)", fn = bit16.add, inputs = { 0xFFFF, 1 }, expected = 0 },
    { name = "add(0xFFFF, 2)", fn = bit16.add, inputs = { 0xFFFF, 2 }, expected = 1 },
    { name = "add(0x8000, 0x8000)", fn = bit16.add, inputs = { 0x8000, 0x8000 }, expected = 0 },

    -- u16_to_be_bytes tests
    { name = "u16_to_be_bytes(0)", fn = bit16.u16_to_be_bytes, inputs = { 0 }, expected = string.char(0x00, 0x00) },
    { name = "u16_to_be_bytes(1)", fn = bit16.u16_to_be_bytes, inputs = { 1 }, expected = string.char(0x00, 0x01) },
    {
      name = "u16_to_be_bytes(0x1234)",
      fn = bit16.u16_to_be_bytes,
      inputs = { 0x1234 },
      expected = string.char(0x12, 0x34),
    },
    {
      name = "u16_to_be_bytes(0xFFFF)",
      fn = bit16.u16_to_be_bytes,
      inputs = { 0xFFFF },
      expected = string.char(0xFF, 0xFF),
    },

    -- u16_to_le_bytes tests
    { name = "u16_to_le_bytes(0)", fn = bit16.u16_to_le_bytes, inputs = { 0 }, expected = string.char(0x00, 0x00) },
    { name = "u16_to_le_bytes(1)", fn = bit16.u16_to_le_bytes, inputs = { 1 }, expected = string.char(0x01, 0x00) },
    {
      name = "u16_to_le_bytes(0x1234)",
      fn = bit16.u16_to_le_bytes,
      inputs = { 0x1234 },
      expected = string.char(0x34, 0x12),
    },
    {
      name = "u16_to_le_bytes(0xFFFF)",
      fn = bit16.u16_to_le_bytes,
      inputs = { 0xFFFF },
      expected = string.char(0xFF, 0xFF),
    },

    -- be_bytes_to_u16 tests
    {
      name = "be_bytes_to_u16(0x0000)",
      fn = bit16.be_bytes_to_u16,
      inputs = { string.char(0x00, 0x00) },
      expected = 0,
    },
    {
      name = "be_bytes_to_u16(0x0001)",
      fn = bit16.be_bytes_to_u16,
      inputs = { string.char(0x00, 0x01) },
      expected = 1,
    },
    {
      name = "be_bytes_to_u16(0x1234)",
      fn = bit16.be_bytes_to_u16,
      inputs = { string.char(0x12, 0x34) },
      expected = 0x1234,
    },
    {
      name = "be_bytes_to_u16(0xFFFF)",
      fn = bit16.be_bytes_to_u16,
      inputs = { string.char(0xFF, 0xFF) },
      expected = 0xFFFF,
    },

    -- le_bytes_to_u16 tests
    {
      name = "le_bytes_to_u16(0x0000)",
      fn = bit16.le_bytes_to_u16,
      inputs = { string.char(0x00, 0x00) },
      expected = 0,
    },
    {
      name = "le_bytes_to_u16(0x0001)",
      fn = bit16.le_bytes_to_u16,
      inputs = { string.char(0x01, 0x00) },
      expected = 1,
    },
    {
      name = "le_bytes_to_u16(0x1234)",
      fn = bit16.le_bytes_to_u16,
      inputs = { string.char(0x34, 0x12) },
      expected = 0x1234,
    },
    {
      name = "le_bytes_to_u16(0xFFFF)",
      fn = bit16.le_bytes_to_u16,
      inputs = { string.char(0xFF, 0xFF) },
      expected = 0xFFFF,
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
      else
        print(string.format("    Expected: 0x%04X", test.expected))
        print(string.format("    Got:      0x%04X", result))
      end
    end
  end

  print(string.format("\n16-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

--------------------------------------------------------------------------------
-- Benchmarking
--------------------------------------------------------------------------------

local benchmark_op = require("bitn.utils.benchmark").benchmark_op

--- Run performance benchmarks for 16-bit operations.
function bit16.benchmark()
  local iterations = 100000

  print("16-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a, b = 0xAAAA, 0x5555

  benchmark_op("band", function()
    bit16.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit16.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit16.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit16.bnot(a)
  end, iterations)

  print("\n16-bit Shift Operations:")

  benchmark_op("lshift", function()
    bit16.lshift(a, 4)
  end, iterations)

  benchmark_op("rshift", function()
    bit16.rshift(a, 4)
  end, iterations)

  benchmark_op("arshift", function()
    bit16.arshift(0x8000, 4)
  end, iterations)

  print("\n16-bit Rotate Operations:")

  benchmark_op("rol", function()
    bit16.rol(a, 4)
  end, iterations)

  benchmark_op("ror", function()
    bit16.ror(a, 4)
  end, iterations)

  print("\n16-bit Arithmetic:")

  benchmark_op("add", function()
    bit16.add(a, b)
  end, iterations)

  benchmark_op("mask", function()
    bit16.mask(0x12345)
  end, iterations)

  print("\n16-bit Byte Conversions:")

  local bytes_be = bit16.u16_to_be_bytes(0x1234)
  local bytes_le = bit16.u16_to_le_bytes(0x1234)

  benchmark_op("u16_to_be_bytes", function()
    bit16.u16_to_be_bytes(0x1234)
  end, iterations)

  benchmark_op("u16_to_le_bytes", function()
    bit16.u16_to_le_bytes(0x1234)
  end, iterations)

  benchmark_op("be_bytes_to_u16", function()
    bit16.be_bytes_to_u16(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u16", function()
    bit16.le_bytes_to_u16(bytes_le)
  end, iterations)
end

return bit16
