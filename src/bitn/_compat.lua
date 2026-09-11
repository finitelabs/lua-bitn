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

-- string.pack/unpack are bound only if they answer in the 5.3 dialect. Control4's
-- LuaJIT ships lpack under the same names: no size suffixes, and unpack takes
-- (data, fmt, pos) and returns the position first, so existence proves nothing.
local function probe_string_pack()
  local pack, unpack = rawget(string, "pack"), rawget(string, "unpack")
  if not (pack and unpack) then
    return nil, nil
  end
  local packed_ok, packed = pcall(pack, "<I4", 0x04030201)
  if not packed_ok or packed ~= "\1\2\3\4" then
    return nil, nil
  end
  packed_ok, packed = pcall(pack, ">I4", 0x04030201)
  if not packed_ok or packed ~= "\4\3\2\1" then
    return nil, nil
  end
  local unpacked_ok, value, next_pos = pcall(unpack, "<I4", "\0\1\2\3\4", 2)
  if not unpacked_ok or value ~= 0x04030201 or next_pos ~= 6 then
    return nil, nil
  end
  return pack, unpack
end

_compat.string_pack, _compat.string_unpack = probe_string_pack()

--------------------------------------------------------------------------------
-- Implementation 1: Native operators (Lua 5.3+)
--------------------------------------------------------------------------------

-- Parsing `a & b` does not mean the result has 64-bit integer semantics. LuaJIT
-- rolling releases from 2026 accept the syntax and return a signed 32-bit number,
-- as from its `bit` library, while this branch assumes 5.3+ integers and skips the
-- to_unsigned() normalisation such a host needs.
--
-- So test the value, not the runtime: 5.3+ answers 0xFFFFFFFF and anything with
-- 32-bit semantics answers -1. Asking the question this way needs no list of which
-- runtimes exist, so it stays correct for whatever grows the syntax next.
local ok, result = pcall(load, "return function(a,b) return a & b end")
if ok and result then
  local fn = result()
  if fn and fn(0xFFFFFFFF, 0xFFFFFFFF) == 0xFFFFFFFF then
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

-- Try LuaJIT's bit library first. Fresh locals rather than the pcall results
-- from the native-operator probe above: that `result` is a compiled chunk, this
-- one is a library table.
local bit_ok, bit_module = pcall(require, "bit")
if bit_ok and bit_module then
  bit_lib = bit_module
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

-- 4-bit truth tables, indexed [a * 16 + b + 1], so each op is at most 8 steps.
local AND4, OR4, XOR4 = {}, {}, {}
for a = 0, 15 do
  for b = 0, 15 do
    local x, y, r_and, r_or, r_xor, bit_val = a, b, 0, 0, 0, 1
    for _ = 1, 4 do
      local xb, yb = x % 2, y % 2
      if xb == 1 and yb == 1 then
        r_and = r_and + bit_val
      end
      if xb == 1 or yb == 1 then
        r_or = r_or + bit_val
      end
      if xb ~= yb then
        r_xor = r_xor + bit_val
      end
      x, y, bit_val = (x - xb) / 2, (y - yb) / 2, bit_val * 2
    end
    local i = a * 16 + b + 1
    AND4[i], OR4[i], XOR4[i] = r_and, r_or, r_xor
  end
end

-- band(a, 2^k - 1) is a % 2^k. Built by doubling so the values are integers on 5.3+.
local LOW_MASK = {}
do
  local m = 1
  for _ = 1, 32 do
    m = m * 2
    LOW_MASK[m - 1] = m
  end
end

function _compat.band(a, b)
  a, b = math_floor(a) % 0x100000000, math_floor(b) % 0x100000000
  local m = LOW_MASK[b] or LOW_MASK[a]
  if m then
    return (LOW_MASK[b] and a or b) % m
  end
  local r, scale = 0, 1
  while a > 0 and b > 0 do
    local na, nb = a % 16, b % 16
    r = r + AND4[na * 16 + nb + 1] * scale
    a, b, scale = (a - na) / 16, (b - nb) / 16, scale * 16
  end
  return r
end

function _compat.bor(a, b)
  a, b = math_floor(a) % 0x100000000, math_floor(b) % 0x100000000
  if a == 0 then
    return b
  elseif b == 0 then
    return a
  end
  local r, scale = 0, 1
  while a > 0 or b > 0 do
    local na, nb = a % 16, b % 16
    r = r + OR4[na * 16 + nb + 1] * scale
    a, b, scale = (a - na) / 16, (b - nb) / 16, scale * 16
  end
  return r
end

function _compat.bxor(a, b)
  a, b = math_floor(a) % 0x100000000, math_floor(b) % 0x100000000
  if a == 0 then
    return b
  elseif b == 0 then
    return a
  end
  local r, scale = 0, 1
  while a > 0 or b > 0 do
    local na, nb = a % 16, b % 16
    r = r + XOR4[na * 16 + nb + 1] * scale
    a, b, scale = (a - na) / 16, (b - nb) / 16, scale * 16
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
