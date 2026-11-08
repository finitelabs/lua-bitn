--- @module "bitn.bit16"
--- 16-bit bitwise operations library.
--- This module provides a complete, version-agnostic implementation of 16-bit
--- bitwise operations that works across Lua 5.1, 5.2, 5.3, 5.4, 5.5, and LuaJIT.
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
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 1 then
    error("Insufficient bytes for u16")
  end
  local b1, b2 = string_byte(str, offset, offset + 1)
  return b1 * 256 + b2
end

--- Convert 2 bytes to 16-bit unsigned integer (little-endian).
--- @param str string Binary string (at least 2 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 16-bit unsigned integer
function bit16.le_bytes_to_u16(str, offset)
  offset = offset or 1
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 1 then
    error("Insufficient bytes for u16")
  end
  local b1, b2 = string_byte(str, offset, offset + 1)
  return b1 + b2 * 256
end

return bit16
