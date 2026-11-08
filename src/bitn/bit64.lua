--- @module "bitn.bit64"
--- 64-bit bitwise operations library.
--- This module provides 64-bit bitwise operations using {high, low} pairs,
--- where high is the upper 32 bits and low is the lower 32 bits.
--- Works across Lua 5.1, 5.2, 5.3, 5.4, 5.5, and LuaJIT.
--- Uses native bit operations where available for optimal performance.
--- @class bitn.bit64
local bit64 = {}

local bit32 = require("bitn.bit32")
local _compat = require("bitn._compat")

-- Cache methods as locals for faster access
local bit32_arshift = bit32.arshift
local bit32_band = bit32.band
local bit32_be_bytes_to_u32 = bit32.be_bytes_to_u32
local bit32_bnot = bit32.bnot
local bit32_bor = bit32.bor
local bit32_bxor = bit32.bxor
local bit32_le_bytes_to_u32 = bit32.le_bytes_to_u32
local bit32_lshift = bit32.lshift
local bit32_raw_arshift = bit32.raw_arshift
local bit32_raw_band = bit32.raw_band
local bit32_raw_bnot = bit32.raw_bnot
local bit32_raw_bor = bit32.raw_bor
local bit32_raw_bxor = bit32.raw_bxor
local bit32_raw_lshift = bit32.raw_lshift
local bit32_raw_rshift = bit32.raw_rshift
local bit32_rshift = bit32.rshift
local math_floor = math.floor
local string_char = string.char
local string_pack = _compat.string_pack
local string_unpack = _compat.string_unpack

-- Private metatable for Int64 type identification
local Int64Meta = { __name = "Int64" }

-- Type definitions
--- @alias Int64HighLow [integer, integer] Array with [1]=high 32 bits, [2]=low 32 bits

--------------------------------------------------------------------------------
-- Constructor and type checking
--------------------------------------------------------------------------------

--- Create a new Int64 value with metatable marker.
--- Normalizes signed 32-bit values to unsigned (for LuaJIT raw_* compatibility).
--- @param high? integer Upper 32 bits (default: 0)
--- @param low? integer Lower 32 bits (default: 0)
--- @return Int64HighLow value Int64 value with metatable marker
function bit64.new(high, low)
  high = high or 0
  low = low or 0
  -- Normalize signed to unsigned (handles LuaJIT raw_* results)
  if high < 0 then
    high = high + 0x100000000
  end
  if low < 0 then
    low = low + 0x100000000
  end
  return setmetatable({ high, low }, Int64Meta)
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
  local high, low = x[1] % 0x100000000, x[2] % 0x100000000
  if string_pack then
    return string_pack(">I4I4", high, low)
  end
  return string_char(
    math_floor(high / 16777216) % 256,
    math_floor(high / 65536) % 256,
    math_floor(high / 256) % 256,
    math_floor(high % 256),
    math_floor(low / 16777216) % 256,
    math_floor(low / 65536) % 256,
    math_floor(low / 256) % 256,
    math_floor(low % 256)
  )
end

--- Convert 64-bit value to 8 bytes (little-endian).
--- @param x Int64HighLow 64-bit value {high, low}
--- @return string bytes 8-byte string in little-endian order
function bit64.u64_to_le_bytes(x)
  local high, low = x[1] % 0x100000000, x[2] % 0x100000000
  if string_pack then
    return string_pack("<I4I4", low, high)
  end
  return string_char(
    math_floor(low % 256),
    math_floor(low / 256) % 256,
    math_floor(low / 65536) % 256,
    math_floor(low / 16777216) % 256,
    math_floor(high % 256),
    math_floor(high / 256) % 256,
    math_floor(high / 65536) % 256,
    math_floor(high / 16777216) % 256
  )
end

--- Convert 8 bytes to 64-bit value (big-endian).
--- @param str string Binary string (at least 8 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return Int64HighLow value {high, low} 64-bit value
function bit64.be_bytes_to_u64(str, offset)
  offset = offset or 1
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 7 then
    error("Insufficient bytes for u64")
  end
  if string_unpack then
    local high, low = string_unpack(">I4I4", str, offset)
    return setmetatable({ high, low }, Int64Meta)
  end
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
  if offset ~= offset or offset < 1 then
    error("Offset must be at least 1")
  end
  if #str < offset + 7 then
    error("Insufficient bytes for u64")
  end
  if string_unpack then
    local low, high = string_unpack("<I4I4", str, offset)
    return setmetatable({ high, low }, Int64Meta)
  end
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
  if type(value) == "table" and getmetatable(value) == Int64Meta then
    --- @cast value Int64HighLow
    return value
  end
  --- @cast value -Int64HighLow
  return setmetatable({ math_floor(value / 0x100000000) % 0x100000000, math_floor(value % 0x100000000) }, Int64Meta)
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
-- Raw (zero-overhead) operations
--------------------------------------------------------------------------------
-- These functions use bit32.raw_* internally for performance-critical code.
-- On LuaJIT, the internal 32-bit values may be signed, but bit patterns are correct.
-- Use for crypto code and tight loops where sign interpretation doesn't matter.

--- Raw bitwise AND (uses bit32.raw_band internally).
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} AND result
function bit64.raw_band(a, b)
  return bit64.new(bit32_raw_band(a[1], b[1]), bit32_raw_band(a[2], b[2]))
end

--- Raw bitwise OR (uses bit32.raw_bor internally).
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} OR result
function bit64.raw_bor(a, b)
  return bit64.new(bit32_raw_bor(a[1], b[1]), bit32_raw_bor(a[2], b[2]))
end

--- Raw bitwise XOR (uses bit32.raw_bxor internally).
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} XOR result
function bit64.raw_bxor(a, b)
  return bit64.new(bit32_raw_bxor(a[1], b[1]), bit32_raw_bxor(a[2], b[2]))
end

--- Raw bitwise NOT (uses bit32.raw_bnot internally).
--- @param a Int64HighLow Operand {high, low}
--- @return Int64HighLow result {high, low} NOT result
function bit64.raw_bnot(a)
  return bit64.new(bit32_raw_bnot(a[1]), bit32_raw_bnot(a[2]))
end

--- Raw left shift (uses bit32.raw_* internally).
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.raw_lshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  elseif n >= 64 then
    return bit64.new(0, 0)
  elseif n >= 32 then
    return bit64.new(bit32_raw_lshift(x[2], n - 32), 0)
  else
    local new_high = bit32_raw_bor(bit32_raw_lshift(x[1], n), bit32_raw_rshift(x[2], 32 - n))
    local new_low = bit32_raw_lshift(x[2], n)
    return bit64.new(new_high, new_low)
  end
end

--- Raw logical right shift (uses bit32.raw_* internally).
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.raw_rshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  elseif n >= 64 then
    return bit64.new(0, 0)
  elseif n >= 32 then
    return bit64.new(0, bit32_raw_rshift(x[1], n - 32))
  else
    local new_low = bit32_raw_bor(bit32_raw_rshift(x[2], n), bit32_raw_lshift(x[1], 32 - n))
    local new_high = bit32_raw_rshift(x[1], n)
    return bit64.new(new_high, new_low)
  end
end

--- Raw arithmetic right shift (uses bit32.raw_* internally).
--- @param x Int64HighLow Value to shift {high, low}
--- @param n integer Number of positions to shift (must be >= 0)
--- @return Int64HighLow result {high, low} shifted value
function bit64.raw_arshift(x, n)
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  local is_negative = bit32_raw_band(x[1], 0x80000000) ~= 0

  if n >= 64 then
    if is_negative then
      return bit64.new(0xFFFFFFFF, 0xFFFFFFFF)
    else
      return bit64.new(0, 0)
    end
  elseif n >= 32 then
    local new_low = bit32_raw_arshift(x[1], n - 32)
    local new_high = is_negative and 0xFFFFFFFF or 0
    return bit64.new(new_high, new_low)
  else
    local new_low = bit32_raw_bor(bit32_raw_rshift(x[2], n), bit32_raw_lshift(x[1], 32 - n))
    local new_high = bit32_raw_arshift(x[1], n)
    return bit64.new(new_high, new_low)
  end
end

--- Raw left rotate (uses bit32.raw_* internally).
--- @param x Int64HighLow Value to rotate {high, low}
--- @param n integer Number of positions to rotate
--- @return Int64HighLow result {high, low} rotated value
function bit64.raw_rol(x, n)
  n = n % 64
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  local high, low = x[1], x[2]

  if n == 32 then
    return bit64.new(low, high)
  elseif n < 32 then
    local new_high = bit32_raw_bor(bit32_raw_lshift(high, n), bit32_raw_rshift(low, 32 - n))
    local new_low = bit32_raw_bor(bit32_raw_lshift(low, n), bit32_raw_rshift(high, 32 - n))
    return bit64.new(new_high, new_low)
  else
    n = n - 32
    local new_high = bit32_raw_bor(bit32_raw_lshift(low, n), bit32_raw_rshift(high, 32 - n))
    local new_low = bit32_raw_bor(bit32_raw_lshift(high, n), bit32_raw_rshift(low, 32 - n))
    return bit64.new(new_high, new_low)
  end
end

--- Raw right rotate (uses bit32.raw_* internally).
--- @param x Int64HighLow Value to rotate {high, low}
--- @param n integer Number of positions to rotate
--- @return Int64HighLow result {high, low} rotated value
function bit64.raw_ror(x, n)
  n = n % 64
  if n == 0 then
    return bit64.new(x[1], x[2])
  end

  local high, low = x[1], x[2]

  if n == 32 then
    return bit64.new(low, high)
  elseif n < 32 then
    local new_low = bit32_raw_bor(bit32_raw_rshift(low, n), bit32_raw_lshift(high, 32 - n))
    local new_high = bit32_raw_bor(bit32_raw_rshift(high, n), bit32_raw_lshift(low, 32 - n))
    return bit64.new(new_high, new_low)
  else
    n = n - 32
    local new_low = bit32_raw_bor(bit32_raw_rshift(high, n), bit32_raw_lshift(low, 32 - n))
    local new_high = bit32_raw_bor(bit32_raw_rshift(low, n), bit32_raw_lshift(high, 32 - n))
    return bit64.new(new_high, new_low)
  end
end

--- Raw 64-bit addition (uses bit32.raw_band for masking).
--- @param a Int64HighLow First operand {high, low}
--- @param b Int64HighLow Second operand {high, low}
--- @return Int64HighLow result {high, low} sum
function bit64.raw_add(a, b)
  local low = a[2] + b[2]
  local high = a[1] + b[1]

  if low >= 0x100000000 then
    high = high + 1
    low = low % 0x100000000
  end

  high = high % 0x100000000

  return bit64.new(high, low)
end

return bit64
