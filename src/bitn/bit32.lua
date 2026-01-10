--- @module "bitn.bit32"
--- Pure Lua 32-bit bitwise operations library.
--- This module provides a complete, version-agnostic implementation of 32-bit
--- bitwise operations that works across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT
--- without depending on any built-in bit libraries.
--- @class bit32
local bit32 = {}

-- 32-bit mask constant
local MASK32 = 0xFFFFFFFF

--- Ensure value fits in 32-bit unsigned integer.
--- @param n number Input value
--- @return integer result 32-bit unsigned integer (0 to 0xFFFFFFFF)
function bit32.mask(n)
  return math.floor(n % 0x100000000)
end

--- Bitwise AND operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a AND b
function bit32.band(a, b)
  a = bit32.mask(a)
  b = bit32.mask(b)

  local result = 0
  local bit_val = 1

  for _ = 0, 31 do
    if (a % 2 == 1) and (b % 2 == 1) then
      result = result + bit_val
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit_val = bit_val * 2

    if a == 0 and b == 0 then
      break
    end
  end

  return result
end

--- Bitwise OR operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a OR b
function bit32.bor(a, b)
  a = bit32.mask(a)
  b = bit32.mask(b)

  local result = 0
  local bit_val = 1

  for _ = 0, 31 do
    if (a % 2 == 1) or (b % 2 == 1) then
      result = result + bit_val
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit_val = bit_val * 2

    if a == 0 and b == 0 then
      break
    end
  end

  return result
end

--- Bitwise XOR operation.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of a XOR b
function bit32.bxor(a, b)
  a = bit32.mask(a)
  b = bit32.mask(b)

  local result = 0
  local bit_val = 1

  for _ = 0, 31 do
    if (a % 2) ~= (b % 2) then
      result = result + bit_val
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit_val = bit_val * 2

    if a == 0 and b == 0 then
      break
    end
  end

  return result
end

--- Bitwise NOT operation.
--- @param a integer Operand (32-bit)
--- @return integer result Result of NOT a
function bit32.bnot(a)
  return bit32.mask(MASK32 - bit32.mask(a))
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
  return bit32.mask(bit32.mask(a) * math.pow(2, n))
end

--- Logical right shift operation (fills with 0s).
--- @param a integer Value to shift (32-bit)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n (logical)
function bit32.rshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  a = bit32.mask(a)
  if n >= 32 then
    return 0
  end
  return math.floor(a / math.pow(2, n))
end

--- Arithmetic right shift operation (sign-extending, fills with sign bit).
--- @param a integer Value to shift (32-bit, treated as signed)
--- @param n integer Number of positions to shift (must be >= 0)
--- @return integer result Result of a >> n with sign extension
function bit32.arshift(a, n)
  assert(n >= 0, "Shift amount must be non-negative")
  a = bit32.mask(a)

  -- Check if sign bit is set (bit 31)
  local is_negative = a >= 0x80000000

  if n >= 32 then
    -- All bits shift out, result is all 1s if negative, all 0s if positive
    return is_negative and 0xFFFFFFFF or 0
  end

  -- Perform logical right shift first
  local result = math.floor(a / math.pow(2, n))

  -- If original was negative, fill high bits with 1s
  if is_negative then
    -- Create mask for high bits that need to be 1
    local fill_mask = MASK32 - (math.pow(2, 32 - n) - 1)
    result = bit32.bor(result, fill_mask)
  end

  return result
end

--- Left rotate operation.
--- @param x integer Value to rotate (32-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x left by n positions
function bit32.rol(x, n)
  n = n % 32
  x = bit32.mask(x)
  return bit32.mask(bit32.lshift(x, n) + bit32.rshift(x, 32 - n))
end

--- Right rotate operation.
--- @param x integer Value to rotate (32-bit)
--- @param n integer Number of positions to rotate
--- @return integer result Result of rotating x right by n positions
function bit32.ror(x, n)
  n = n % 32
  x = bit32.mask(x)
  return bit32.mask(bit32.rshift(x, n) + bit32.lshift(x, 32 - n))
end

--- 32-bit addition with overflow handling.
--- @param a integer First operand (32-bit)
--- @param b integer Second operand (32-bit)
--- @return integer result Result of (a + b) mod 2^32
function bit32.add(a, b)
  return bit32.mask(bit32.mask(a) + bit32.mask(b))
end

--------------------------------------------------------------------------------
-- Byte conversion functions
--------------------------------------------------------------------------------

--- Convert 32-bit unsigned integer to 4 bytes (big-endian).
--- @param n integer 32-bit unsigned integer
--- @return string bytes 4-byte string in big-endian order
function bit32.u32_to_be_bytes(n)
  n = bit32.mask(n)
  return string.char(math.floor(n / 16777216) % 256, math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256)
end

--- Convert 32-bit unsigned integer to 4 bytes (little-endian).
--- @param n integer 32-bit unsigned integer
--- @return string bytes 4-byte string in little-endian order
function bit32.u32_to_le_bytes(n)
  n = bit32.mask(n)
  return string.char(n % 256, math.floor(n / 256) % 256, math.floor(n / 65536) % 256, math.floor(n / 16777216) % 256)
end

--- Convert 4 bytes to 32-bit unsigned integer (big-endian).
--- @param str string Binary string (at least 4 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 32-bit unsigned integer
function bit32.be_bytes_to_u32(str, offset)
  offset = offset or 1
  assert(#str >= offset + 3, "Insufficient bytes for u32")
  local b1, b2, b3, b4 = string.byte(str, offset, offset + 3)
  return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
end

--- Convert 4 bytes to 32-bit unsigned integer (little-endian).
--- @param str string Binary string (at least 4 bytes from offset)
--- @param offset? integer Starting position (default: 1)
--- @return integer n 32-bit unsigned integer
function bit32.le_bytes_to_u32(str, offset)
  offset = offset or 1
  assert(#str >= offset + 3, "Insufficient bytes for u32")
  local b1, b2, b3, b4 = string.byte(str, offset, offset + 3)
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
      expected = string.char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_be_bytes(1)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 1 },
      expected = string.char(0x00, 0x00, 0x00, 0x01),
    },
    {
      name = "u32_to_be_bytes(0x12345678)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0x12345678 },
      expected = string.char(0x12, 0x34, 0x56, 0x78),
    },
    {
      name = "u32_to_be_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string.char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- u32_to_le_bytes tests
    {
      name = "u32_to_le_bytes(0)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0 },
      expected = string.char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(1)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 1 },
      expected = string.char(0x01, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(0x12345678)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0x12345678 },
      expected = string.char(0x78, 0x56, 0x34, 0x12),
    },
    {
      name = "u32_to_le_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string.char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- be_bytes_to_u32 tests
    {
      name = "be_bytes_to_u32(0x00000000)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "be_bytes_to_u32(0x00000001)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string.char(0x00, 0x00, 0x00, 0x01) },
      expected = 1,
    },
    {
      name = "be_bytes_to_u32(0x12345678)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string.char(0x12, 0x34, 0x56, 0x78) },
      expected = 0x12345678,
    },
    {
      name = "be_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string.char(0xFF, 0xFF, 0xFF, 0xFF) },
      expected = 0xFFFFFFFF,
    },

    -- le_bytes_to_u32 tests
    {
      name = "le_bytes_to_u32(0x00000000)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "le_bytes_to_u32(0x00000001)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string.char(0x01, 0x00, 0x00, 0x00) },
      expected = 1,
    },
    {
      name = "le_bytes_to_u32(0x12345678)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string.char(0x78, 0x56, 0x34, 0x12) },
      expected = 0x12345678,
    },
    {
      name = "le_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string.char(0xFF, 0xFF, 0xFF, 0xFF) },
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
          exp_hex = exp_hex .. string.format("%02X", string.byte(test.expected, i))
        end
        for i = 1, #result do
          got_hex = got_hex .. string.format("%02X", string.byte(result, i))
        end
        print("    Expected: " .. exp_hex)
        print("    Got:      " .. got_hex)
      else
        print(string.format("    Expected: 0x%08X", test.expected))
        print(string.format("    Got:      0x%08X", result))
      end
    end
  end

  print(string.format("\n32-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

return bit32
