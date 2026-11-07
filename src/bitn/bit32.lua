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

--- Convert unsigned 32-bit value to signed.
--- The inverse of `to_unsigned`: values of 2^31 and above wrap to negative.
--- @param n number Unsigned 32-bit value (already-signed values pass through)
--- @return integer result Signed 32-bit value (-2^31 to 2^31 - 1)
function bit32.to_signed(n)
  if n >= 0x80000000 then
    return n - 0x100000000
  end
  return n
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
local string_pack = _compat.string_pack
local string_unpack = _compat.string_unpack
-- % is the whole operation on the pure Lua backend; skip the call.
local fast_band = _compat.has_native_ops or _compat.has_bit_lib

--- Convert 32-bit unsigned integer to 4 bytes (big-endian).
--- @param n integer 32-bit unsigned integer
--- @return string bytes 4-byte string in big-endian order
function bit32.u32_to_be_bytes(n)
  if string_pack then
    return string_pack(">I4", n % 0x100000000)
  end
  n = fast_band and compat_band(n, MASK32) or n % 0x100000000
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
  if string_pack then
    return string_pack("<I4", n % 0x100000000)
  end
  n = fast_band and compat_band(n, MASK32) or n % 0x100000000
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
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 3 then
    error("Insufficient bytes for u32")
  end
  if string_unpack then
    return (string_unpack(">I4", str, offset))
  end
  local b1, b2, b3, b4 = string_byte(str, offset, offset + 3)
  return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
end

--- Convert 4 bytes to 32-bit unsigned integer (little-endian).
--- @param str string Binary string (at least 4 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 32-bit unsigned integer
function bit32.le_bytes_to_u32(str, offset)
  offset = offset or 1
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 3 then
    error("Insufficient bytes for u32")
  end
  if string_unpack then
    return (string_unpack("<I4", str, offset))
  end
  local b1, b2, b3, b4 = string_byte(str, offset, offset + 3)
  return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

return bit32
