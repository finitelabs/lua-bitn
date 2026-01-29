--- @diagnostic disable: duplicate-set-field
--- @module "bitn._compat"
--- Internal compatibility layer for bitwise operations.
--- Provides feature detection and optimized primitives for use by bit16/bit32/bit64.
--- @class bitn._compat
local _compat = {}

--------------------------------------------------------------------------------
-- Helper functions (needed by all implementations)
--------------------------------------------------------------------------------

local math_floor = math.floor
local math_pow = math.pow or function(x, y)
  return x ^ y
end

--- Convert signed 32-bit to unsigned (for LuaJIT which returns signed values)
--- @param n number Potentially signed 32-bit value
--- @return number Unsigned 32-bit value
local function to_unsigned(n)
  if n < 0 then
    return n + 0x100000000
  end
  return n
end

_compat.to_unsigned = to_unsigned

-- Constants
local MASK32 = 0xFFFFFFFF

--------------------------------------------------------------------------------
-- Implementation 1: Native operators (Lua 5.3+)
--------------------------------------------------------------------------------

local ok, result = pcall(load, "return function(a,b) return a & b end")
if ok and result then
  local fn = result()
  if fn then
    -- Native operators available - define all functions using them
    local native_band = fn
    local native_bor = assert(load("return function(a,b) return a | b end"))()
    local native_bxor = assert(load("return function(a,b) return a ~ b end"))()
    local native_bnot = assert(load("return function(a) return ~a end"))()
    local native_lshift = assert(load("return function(a,n) return a << n end"))()
    local native_rshift = assert(load("return function(a,n) return a >> n end"))()

    _compat.has_native_ops = true
    _compat.has_bit_lib = false
    _compat.is_luajit = false

    function _compat.impl_name()
      return "native operators (Lua 5.3+)"
    end

    function _compat.band(a, b)
      return native_band(a, b)
    end

    function _compat.bor(a, b)
      return native_bor(a, b)
    end

    function _compat.bxor(a, b)
      return native_bxor(a, b)
    end

    function _compat.bnot(a)
      return native_band(native_bnot(a), MASK32)
    end

    function _compat.lshift(a, n)
      if n >= 32 then
        return 0
      end
      return native_band(native_lshift(a, n), MASK32)
    end

    function _compat.rshift(a, n)
      if n >= 32 then
        return 0
      end
      return native_rshift(native_band(a, MASK32), n)
    end

    function _compat.arshift(a, n)
      a = native_band(a, MASK32)
      local is_negative = a >= 0x80000000
      if n >= 32 then
        return is_negative and MASK32 or 0
      end
      local r = native_rshift(a, n)
      if is_negative then
        local fill_mask = native_lshift(MASK32, 32 - n)
        r = native_bor(r, native_band(fill_mask, MASK32))
      end
      return native_band(r, MASK32)
    end

    -- Raw operations provide direct access to native bit functions without the
    -- to_unsigned() wrapper. On Lua 5.3+, these are identical to wrapped versions
    -- since native operators already return unsigned values.
    -- Shifts must mask to 32 bits since native operators work on 64-bit values.
    _compat.raw_band = native_band
    _compat.raw_bor = native_bor
    _compat.raw_bxor = native_bxor
    _compat.raw_bnot = function(a)
      return native_band(native_bnot(a), MASK32)
    end
    _compat.raw_lshift = function(a, n)
      if n >= 32 then
        return 0
      end
      return native_band(native_lshift(a, n), MASK32)
    end
    _compat.raw_rshift = function(a, n)
      if n >= 32 then
        return 0
      end
      return native_rshift(native_band(a, MASK32), n)
    end
    _compat.raw_arshift = _compat.arshift
    -- No native rol/ror on Lua 5.3+
    _compat.raw_rol = nil
    _compat.raw_ror = nil

    return _compat
  end
end

--------------------------------------------------------------------------------
-- Implementation 2: Bit library (LuaJIT or Lua 5.2)
--------------------------------------------------------------------------------

local bit_lib
local is_luajit = false

-- Try LuaJIT's bit library first
ok, result = pcall(require, "bit")
if ok and result then
  bit_lib = result
  is_luajit = true
else
  -- Try Lua 5.2's bit32 library (use rawget to avoid recursion with our module name)
  bit_lib = rawget(_G, "bit32")
end

if bit_lib then
  -- Bit library available - define all functions using it
  local bit_band = assert(bit_lib.band)
  local bit_bor = assert(bit_lib.bor)
  local bit_bxor = assert(bit_lib.bxor)
  local bit_bnot = assert(bit_lib.bnot)
  local bit_lshift = assert(bit_lib.lshift)
  local bit_rshift = assert(bit_lib.rshift)
  local bit_arshift = assert(bit_lib.arshift)

  _compat.has_native_ops = false
  _compat.has_bit_lib = true
  _compat.is_luajit = is_luajit

  function _compat.impl_name()
    return "bit library"
  end

  if is_luajit then
    -- LuaJIT returns signed integers, need to convert to unsigned
    function _compat.band(a, b)
      return to_unsigned(bit_band(a, b))
    end

    function _compat.bor(a, b)
      return to_unsigned(bit_bor(a, b))
    end

    function _compat.bxor(a, b)
      return to_unsigned(bit_bxor(a, b))
    end

    function _compat.bnot(a)
      return to_unsigned(bit_bnot(a))
    end

    function _compat.lshift(a, n)
      if n >= 32 then
        return 0
      end
      return to_unsigned(bit_lshift(a, n))
    end

    function _compat.rshift(a, n)
      if n >= 32 then
        return 0
      end
      return to_unsigned(bit_rshift(a, n))
    end

    function _compat.arshift(a, n)
      a = to_unsigned(bit_band(a, MASK32))
      if n >= 32 then
        local is_negative = a >= 0x80000000
        return is_negative and MASK32 or 0
      end
      return to_unsigned(bit_arshift(a, n))
    end
  else
    -- Lua 5.2 bit32 library returns unsigned integers
    function _compat.band(a, b)
      return bit_band(a, b)
    end

    function _compat.bor(a, b)
      return bit_bor(a, b)
    end

    function _compat.bxor(a, b)
      return bit_bxor(a, b)
    end

    function _compat.bnot(a)
      return bit_band(bit_bnot(a), MASK32)
    end

    function _compat.lshift(a, n)
      if n >= 32 then
        return 0
      end
      return bit_band(bit_lshift(a, n), MASK32)
    end

    function _compat.rshift(a, n)
      if n >= 32 then
        return 0
      end
      return bit_rshift(bit_band(a, MASK32), n)
    end

    function _compat.arshift(a, n)
      a = bit_band(a, MASK32)
      if n >= 32 then
        local is_negative = a >= 0x80000000
        return is_negative and MASK32 or 0
      end
      return bit_band(bit_arshift(a, n), MASK32)
    end
  end

  -- Raw operations provide direct access to native bit functions without the
  -- to_unsigned() wrapper. On LuaJIT, these return signed 32-bit integers.
  -- On Lua 5.2 (bit32 library), these are identical to wrapped versions.
  _compat.raw_band = bit_band
  _compat.raw_bor = bit_bor
  _compat.raw_bxor = bit_bxor
  _compat.raw_bnot = bit_bnot
  _compat.raw_lshift = bit_lshift
  _compat.raw_rshift = bit_rshift
  _compat.raw_arshift = bit_arshift
  -- rol/ror only available on LuaJIT (bit library), not Lua 5.2 (bit32 library)
  if bit_lib.rol then
    _compat.raw_rol = bit_lib.rol
    _compat.raw_ror = bit_lib.ror
  else
    _compat.raw_rol = nil
    _compat.raw_ror = nil
  end

  return _compat
end

--------------------------------------------------------------------------------
-- Implementation 3: Pure Lua fallback
--------------------------------------------------------------------------------

_compat.has_native_ops = false
_compat.has_bit_lib = false
_compat.is_luajit = false

function _compat.impl_name()
  return "pure Lua"
end

function _compat.band(a, b)
  local r = 0
  local bit_val = 1
  for _ = 0, 31 do
    if (a % 2 == 1) and (b % 2 == 1) then
      r = r + bit_val
    end
    a = math_floor(a / 2)
    b = math_floor(b / 2)
    bit_val = bit_val * 2
    if a == 0 and b == 0 then
      break
    end
  end
  return r
end

function _compat.bor(a, b)
  local r = 0
  local bit_val = 1
  for _ = 0, 31 do
    if (a % 2 == 1) or (b % 2 == 1) then
      r = r + bit_val
    end
    a = math_floor(a / 2)
    b = math_floor(b / 2)
    bit_val = bit_val * 2
    if a == 0 and b == 0 then
      break
    end
  end
  return r
end

function _compat.bxor(a, b)
  local r = 0
  local bit_val = 1
  for _ = 0, 31 do
    if (a % 2) ~= (b % 2) then
      r = r + bit_val
    end
    a = math_floor(a / 2)
    b = math_floor(b / 2)
    bit_val = bit_val * 2
    if a == 0 and b == 0 then
      break
    end
  end
  return r
end

function _compat.bnot(a)
  return MASK32 - (math_floor(a) % 0x100000000)
end

function _compat.lshift(a, n)
  if n >= 32 then
    return 0
  end
  return math_floor((a * math_pow(2, n)) % 0x100000000)
end

function _compat.rshift(a, n)
  if n >= 32 then
    return 0
  end
  a = math_floor(a) % 0x100000000
  return math_floor(a / math_pow(2, n))
end

function _compat.arshift(a, n)
  a = math_floor(a) % 0x100000000
  local is_negative = a >= 0x80000000
  if n >= 32 then
    return is_negative and MASK32 or 0
  end
  local r = math_floor(a / math_pow(2, n))
  if is_negative then
    local fill_mask = MASK32 - (math_pow(2, 32 - n) - 1)
    r = _compat.bor(r, fill_mask)
  end
  return r
end

-- Raw operations for pure Lua fallback are identical to wrapped versions
-- since there's no native library to bypass.
_compat.raw_band = _compat.band
_compat.raw_bor = _compat.bor
_compat.raw_bxor = _compat.bxor
_compat.raw_bnot = _compat.bnot
_compat.raw_lshift = _compat.lshift
_compat.raw_rshift = _compat.rshift
_compat.raw_arshift = _compat.arshift
_compat.raw_rol = nil
_compat.raw_ror = nil

return _compat
